#!/usr/bin/perl

package SQL::Builder::Join;

use warnings;
use strict;
use Carp qw(confess);

use SQL::Builder::BinaryOp;
use SQL::Builder::Using;
use SQL::Builder::Table;

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub init	{
	my $self = shift;

	$self->SUPER::init();
	
	my $on = SQL::Builder::BinaryOp->new(op => "AND");
	$on->options(parens => 0);
	$self->on($on);

	my $using = SQL::Builder::Using->new();
	$self->using($using);

	my $table = SQL::Builder::Table->new();
	$self->table($table);

	$self->use_table_aliases(1);

	return $self;
}

sub children	{
	my $self = shift;

	return $self->_make_children_iterator([
		$self->left_table,
		$self->type,
		$self->right_table,
		$self->alias,
		$self->using,
		$self->on
	])
}

sub alias	{
	return shift->_set('alias', @_)
}

sub on	{
	return shift->_set('on', @_)
}

sub right_table	{
	return shift->_set('right_table', @_)
}

*table = *right_table;

sub left_table	{
	return shift->_set('left_table', @_)
}

sub type	{
	return shift->_set('type', @_)
}

sub using	{
	return shift->_set('using', @_);
}

sub natural	{
	return shift->options('natural', @_)
}

#[ INNER ] JOIN, LEFT [ OUTER ] JOIN, RIGHT [ OUTER ] JOIN, FULL [ OUTER ] JOIN

sub inner	{ return "INNER" }
sub left	{ return "LEFT" }
sub left_outer	{ return "LEFT OUTER" }
sub right	{ return "RIGHT" }
sub right_outer	{ return "RIGHT OUTER" }
sub full	{ return "FULL" }
sub full_outer	{ return "FULL OUTER" }
sub cross	{ return "CROSS" }

sub set_inner		{ shift->type(inner()) }
sub set_left		{ shift->type(left()) }
sub set_left_outer	{ shift->type(left_outer()) }
sub set_right		{ shift->type(right()) }
sub set_right_outer	{ shift->type(right_outer()) }
sub set_full		{ shift->type(full()) }
sub set_full_outer	{ shift->type(full_outer()) }
sub set_cross		{ shift->type(cross()) }
sub set_notype		{ shift->type("") }

sub use_table_aliases	{
	return shift->options('use_table_aliases', @_)
}

sub sql	{
	my $self  = shift;
	
	my $rtable  = $self->right_table;
	my $ltable  = $self->left_table;

		for($rtable, $ltable)	{

			if($self->use_table_aliases && UNIVERSAL::can($_, 'alias_sql'))	{

				my $alias = $_->alias;

				if(defined($alias) && length($alias))	{

					$_ = $_->alias_sql
				}
				else	{

					$_ = $self->dosql($_)
				}
			}
			else	{

				$_ = $self->dosql($_)
			}
		}

	my $type    = $self->dosql($self->type);
	my $on      = $self->dosql($self->on);
	my $using   = $self->dosql($self->using);
	my $natural = $self->natural;
	my $sql;
	
	my $tpl = $type ? "$type JOIN $rtable" : "JOIN $rtable";

	$tpl = "NATURAL $tpl" if $natural;

	if(!$natural && $on)	{
		$sql = "$tpl ON $on"
	}
	elsif(!$natural && $using)	{
		$sql = "$tpl $using"
	}
	else	{
		$sql = $tpl;
	}

	if(defined($ltable) && length($ltable))	{
		return "$ltable $sql"
	}
	else	{
		return $sql
	}
}

1;

=head1 NAME

SQL::Builder::Join - Represent a SQL JOIN statement

=head1 SYNOPSIS

This class can represent:

	[NATURAL] [JOIN_TYPE] JOIN [anything] [ON anything| USING(anything)]

Basically:

	my $join = SQL::Builder::Join->new(
		type => 'LEFT',
		right_table => 'table1',
		on => 'foo = bar'
	);

	# LEFT JOIN table1 ON foo = bar
	print $join->sql

USING is possible, too

	my $join = SQL::Builder::Join->new(
		type => 'LEFT',
		right_table => 'table1',
		using => 'c1, c2'
	);

	# LEFT JOIN table1 USING (c1, c2)
	print $join->sql

NATURAL joins work:

	my $join = SQL::Builder::Join->new(
		type => 'LEFT',
		right_table => 'table1',
		natural => 1
	);

	# NATURAL LEFT JOIN table1
	print $join->sql

The left/outer table can be easily represented:

	my $join = SQL::Builder::Join->new(
		type => 'LEFT',
		right_table => 'table2',
		natural => 1,
		left_table => 'table1'
	);

	# table1 NATURAL LEFT JOIN table2
	print $join->sql

There are also methods which return the SQL for certain join types

	my $join = SQL::Builder::Join->new(
		type => SQL::Builder::Join->cross,
		right_table => 'table',
		on => 'foo = bar'
	);

	# CROSS JOIN table ON foo = bar
	print $join->sql
	
Modifying the JOIN type is easy:

	$join->set_cross; # CROSS JOIN
	$join->set_full_outer; # FULL OUTER JOIN
	$join->set_inner; # INNER JOIN
	
	...

=head1 DESCRIPTION

See the SYNOPSIS for examples of the SQL that can be generated and how to use
this class. This is a SQL::Builder::Base(3) subclass

=head1 METHODS

=head2 SETTING THE JOIN TYPE

The following methods will set the corresponding join type using a JOIN constant
(see below):

	set_cross, set_full, set_full_outer, set_inner, set_left,
	set_left_outer, set_right, set_right_outer, set_notype

Don't forget to see natural(), which toggles the NATURAL join. set_notype() sets
type() to "", effectively enforcing whatever default your DBMS uses for joins
(typically, anyway)

If there's any I missed, please contact me and I'll add it in right away.

=head2 JOIN CONSTANTS

The following methods return strings representing to join type. For example,
cross() returns "CROSS"

	cross, full, full_outer, inner, left, left_outer, right, right_outter

=head2 new()

See SQL::Builder::Base(3) for set() and new()

=head2 on([$expr])

Get/set the expression used in the ON expression. When called with an
expression, the expression is set and the current object is returned. When
called without arguments, the current value is returned. By default, the value
is set to a SQL::Builder::BinaryOp object. This makes it easy to start adding
conditions

	my $join = SQL::Builder::Join->new(
		'on->list_push' => 'foo = bar'
		# ...
	);

	$join->list_push("bar > 10");

	# JOIN table1 ON foo = bar AND bar > 10
	print $join->sql

=head2 natural([1|0])

Toggle the NATURAL keyword for the join. See your DBMS for support. When called
with arguments, the value is set and the current object is returned. Without
arguments, it returns the current value.

=head2 sql()

Returns the SQL serialization of the object. left_table(), right_table, type(),
on(), and using() are all passed through SQL::Builder::Base::dosql() before
being strigified. NATURAL takes precedence over the values returned by on() and
using() -- if natural() returns true, it is used and on()/using() are ignored.
The value of left_table is shown only if it's dosql() return value is defined
and has a length. The dosql() value of on() is checked before the value of
using().

=head2 left_table([$table])

This gets/sets the value of the left table in a JOIN. Returns the current value
when called with no arguments, otherwise it returns the current object.

=head2 right_table([$table])

Same as left_table(), but for the right table in the JOIN

=head2 table(...)

This is an alias for left_table()

=head2 init()

This calls init() on the parent class, installs a SQL::Builder::BinaryOp(3) object
to on(), and a SQL::Builder::Using(3) object to using()

=head2 alias([$alias])

Get/set the alias for the join. When called with arguments, sets the value and
returns the current object. When no arguments are provided, the current value is
returned.

This method doesn't have any effect in this class, but would be most useful to
classes like SQL::Builder::FromList(3) etc where a join alias would be useful.

=head2 children()

Return a SQL::Builder::Iterator to iterate over the values of left_table(),
type(), right_table(), alias(), using(), and on() - in that order

=head2 use_table_aliases([1|0])

Get/set the option to call alias_sql() for serialization in sql() instead of
just filtering them through SQL::Builder::Base::dosql(). Pass a 1 or 0 to turn
this on or off. If arguments are passed, the option is set and current object
($self) is returned. Otherwise, the current value is returned. This is turned on
by default and basically defines the difference between

	JOIN table AS foo ON ...

and

	JOIN table ON ...

=head1 SEE ALSO

SQL::Builder::Table(3)
SQL::Builder::FromList(3)
SQL::Builder::Base(3)
