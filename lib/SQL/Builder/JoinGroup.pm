#!/usr/bin/perl

# ($join\n$join) as foo
package SQL::Builder::JoinGroup;

use warnings;
use strict;

use SQL::Builder::Join;
use SQL::Builder::List;

use base qw(SQL::Builder::List);

sub init	{
	my $self = shift;

	$self->SUPER::init();

	$self->options(parens => 1);
	$self->joiner("\n");

	return $self
}

# a wrapper for list()
sub joins	{
	return shift->list(@_)
}

sub alias	{
	return shift->_set('join_group_alias', @_)
}

sub sql	{
	my $self = shift;
	my $alias = $self->dosql($self->alias);
	my $list = $self->SUPER::sql;

	my $have_alias = defined($alias) && length $alias;
	my $have_list  = defined($list)  && length $list;

	if($have_alias && $have_list)	{
		return "$list AS $alias"
	}
	elsif($have_list)	{
		return $list
	}
	else	{
		return ""
	}
}

sub add_join	{
	my $self = shift;

	my $join = SQL::Builder::Join->new(@_);

	$self->list_push($join);

	return $join
}

1;

=head1 NAME

SQL::Builder::JoinGroup - Represent a group of JOINs

=head1 SYNOPSIS

This class can build the following SQL:

	(NATURAL JOIN foo LEFT JOIN bar USING (bar_id)) AS alias

or without an alias
	
	(NATURAL JOIN foo LEFT JOIN bar USING (bar_id))

or an empty join list

	"" #an empty string

or more flexibly speaking

	anything [AS anything]

Typically, one would do something like:

	my $jgroup = SQL::Builder::JoinGroup->new;
	
	$jgroup->add_join(
		type => "LEFT",
		table => "foo"
		on => "foozle = boozle"
	);

	$jgroup->add_join(
		type => "RIGHT",
		table => "bar",
		using => "omghi"
	);

	$jgroup->alias("alias");

	# (JOIN foo ON foozle = boozle RIGHT JOIN bar USING (omghi)) AS alias
	print $jgroup->sql

=head1 DESCRIPTION

This is a SQL::Builder::List(3) subclass

=head1 METHODS

=head2 alias([$alias])

Get/set the alias. Returns the current object when called with arguments and
sets the current value, otherwise returns the current value

=head2 init()

This calls init() on the parent class, parens(1), and sets the joiner() to "\n"

=head2 joins([@list])

This is a wrapper to SQL::Builder::List::list()

=head2 sql()

Returns the SQL serialization or an empty string. The alias is only used if it
is defined and has a length. SQL::Builder::List::sql() is used here. The value
of alias() is passed through SQL::Builder::Base::dosql()

=head1 SEE ALSO

SQL::Builder::List(3)
SQL::Builder::Join(3)
SQL::Builder::Base(3)
SQL::Builder(3)
