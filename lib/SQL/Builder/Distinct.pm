#!/usr/bin/perl

package SQL::Builder::Distinct;

use warnings;
use strict;
use Carp;

use SQL::Builder::ColumnList;
use SQL::Builder::List;

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub init	{
	my $self = shift;
	$self->SUPER::init();
	
	$self->cols(SQL::Builder::ColumnList->new);
	
	{
		my $on = SQL::Builder::ColumnList->new;

		$on->options(
			default_select => '', parens => 1
		);

		$self->on($on);
	}

	$self->options('distinct' => 1);

	return $self
}

sub children	{
	my $self = shift;
	
	return $self->_make_children_iterator([$self->on, $self->cols]);
}

sub cols	{
	return shift->_set('cols', @_)
}

sub on	{
	return shift->_set('on', @_)
}

sub distinct	{
	return shift->options('distinct', @_)
}

sub sql	{
	my $self = shift;
	my $on   = $self->dosql($self->on);
	my $cols = $self->dosql($self->cols);

	if($self->options('distinct'))	{

		if(defined($on) && length $on)	{
			return $cols ? "DISTINCT ON $on $cols" : "DISTINCT ON $on"
		}
		elsif (defined($cols) && length $cols)	{
			return "DISTINCT $cols"
		}
		elsif ($self->options('always_return'))	{
			return "DISTINCT"
		}
		else	{
			return ""
		}
	}
	else	{
		return $cols;
	}
}

1;


=head1 NAME

SQL::Builder::Distinct - Object representation of a SELECT column list with
support for DISTINCT/DISTINCT ON

=head1 SYNOPSIS

This class can generate the following possible SQL statements

=head2 A basic SELECT column list

	col1, col2 as c2, 39+3+c3 AS some_num, c4 num

=head2 DISTINCT on all columns

	DISTINCT col1, col2 as c2, 39+3+c3 AS some_num, c4 num

=head2 DISTINCT ON certain columns

	DISTINCT ON (c5) col1, col2 as c2, 39+3+c3 AS some_num, c4 num

=head2 DISTINCT by itself

	DISTINCT

=head2 DISTINCT *

	DISTINCT *

=head1

This class is mainly composed of two SQL::Builder::ColumnList(3) objects. It's
basically:

	[DISTINCT [ON (<SQL::Builder::ColumnList>)] [<SQL::Builder::ColumnList>]

The ON list is accessible via on(), the other list is accessible via cols().
Here is an example of its usage:

	my $d = SQL::Builder::Distinct->new();

	$d->cols->list_push(qw(col1 col2));

	# DISTINCT col1, col2
	print $d->sql;

	$d->on->list_push(qw(col3, col4));

	# DISTINCT ON (col3, col4) col1, col2
	print $d->sql;
	
	# remove the DISTINCT keyword
	$d->distinct(0);

	# col1, col2
	print $d->sql;

	# turn the DISTINCT keyword back on
	$d->distinct(1);

	# clear the lists
	$d->cols->list_clear;
	$d->on->list_clear;

	# DISTINCT *
	print $d->sql;

=head1 DESCRIPTION

This is a SQL::Builder::Base(3) object, mostly composed of
SQL::Builder::List(3) objects. The values of on() and cols() can be manipulated
as desired without breakage, their values will just be passed through
SQL::Builder::Base::dosql()

=head1 METHODS

=head2 new()

This method is inherited from SQL::Builder::Base -- see new() and set()

=head2 cols()

This method gets/sets the SQL::Builder::ColumnList(3) object. It can be set
without consequent, so that raw SQL can be used, but I don't recommend it. See
the SYNOPSIS for examples of exactly what SQL this will generate. Examples:
	
	$distinct = SQL::Builder::Distinct->new;
	
	# add columns to the list
	$distinct->cols->list_push(qw(c1 c2 c3));

	# DISTINCT c1, c2, c3
	print $distinct->sql

=head2 init()

Initialization method which sets up on() and cols() with ColumnList objects

=head2 on()

This will get/set the object used to maintain the DISTINCT ON (...) list. It can
be set without consequence, but this shouldn't be done without understanding the
consequences. By default, this is a SQL::BBuilder::ColumnList(3) with
parenthesis turned on. default_select() is set to ''

=head2 distinct([1|0])

Turn on/off the option to use the 'DISTINCT' keyword. If this is turned off,
on() is not processed and the DISTINCT keyword is not used. When called with no
arguments, this method returns the current value. When this is turned
off, 'DISTINCT ON (...)' will be omitted from the SQL serialization; cols() is
passed through SQL::Builder::Base::dosql() and returned.

=head2 sql()

See the SYNOPSIS for examples of how this object serializes to SQL. on() and
cols() are both passed through SQL::Builder::Base::dosql(). If on() returns
anything useful, and distinct() is turned on, "DISTINCT ON($on_sql)" is used. If
cols() returns anything useful (defined and has a length), "DISTINCT [ON(...)]
$cols_sql" is returned

=head2 children()

Returns an iterator to iterate over the return values of on() and cols()

=head1 SEE ALSO

SQL::Builder::ColumnList(3)
SQL::Builder::Column(3)
SQL::Builder::Base(3)
SQL::Builder::Select(3)
