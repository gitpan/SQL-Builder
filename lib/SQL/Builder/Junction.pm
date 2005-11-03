#!/usr/bin/perl

package SQL::Builder::Junction;

use warnings;
use strict;
use Carp qw(confess);

use SQL::Builder::List;

use base qw(SQL::Builder::List);

sub junction	{
	return shift->joiner(@_)
}

sub init	{
	my $self = shift;

	$self->SUPER::init;

	$self->junction(undef);

	return $self
}

sub all	{
	return shift->options('all', @_)
}

sub parens	{
	return shift->options('parens', @_)
}

sub sql	{
	my $self = shift;
	my $list = $self->list;

	return "" unless $list && @{$list};

	my $junction = $self->dosql($self->junction());

	confess "Invalid junction - should be defined and have a length"
		unless defined($junction) && length($junction);

	my $tpl = $self->all ? " $junction ALL " : " $junction ";

	my $sql = join $tpl, map {$self->dosql($_)} @{$list};

	return $self->parens ? "($sql)" : $sql;
}

sub children	{
	my $self = shift;

	return $self->_make_children_iterator([
		$self->junction,
		ref $self->list eq 'ARRAY' ? @{$self->list} : $self->list
	])
}

1;

=head1 NAME

SQL::Builder::Junction - Represent a SQL junction, typically including INTERSECT, UNION, and EXCEPT

=head1 SYNOPSIS

	my $junction = SQL::Builder::Junction->new();

	$junction->list_push("SELECT 1");
	$junction->list_push("SELECT 2");

	$junction->junction("INTERSECT");

	# SELECT 1 INTERSECT SELECT 2
	print $junction->sql;

	$junction->junction("EXCEPT");
	
	# SELECT 1 EXCEPT SELECT 2
	print $junction->sql;

	$junction->junction("UNION");
	$junction->all(1);

	# SELECT 1 UNION ALL SELECT 2
	print $junction->sql

=head1 DESCRIPTION

This is a SQL::Builder::List(3) subclass. Make sure to see the following classes
for common junctions

	SQL::Builder::Intersect(3)
	SQL::Builder::Except(3)
	SQL::Builder::Union(3)

=head1 METHODS

=head2 all([1|0])

Turn on/off the 'ALL' keyword used in sql(). Turned off by default. When called
with arguments, the value is set and current object is returned; otherwise, the
current value is returned. If this is on, the 'ALL' keyword will be used between
all items in the list

=head2 init()

Calls the init() method of the parent class and sets the joiner() value to
undef.

=head2 junction([$j])

Get/set the junction value. This is a wrapper to SQL::Builder::List::joiner()

=head2 sql()

Return the SQL serialization or an empty string if the list is empty. If the
junction() value is not defined with a length, then an exception is thrown. The
value of junction() is passed through SQL::Builder::Base::dosql() before being
used.

=head2 children()

Return a SQL::Builder::Iterator object to first iterate over the value of
junction(), then if list() is an array its elements are included, otherwise the
value of list() is used directly. Basically:

	$self->junction,
	ref $self->list eq 'ARRAY' ? @{$self->list} : $self->list

=head1 SEE ALSO

SQL::Builder::Intersect(3)
SQL::Builder::Except(3)
SQL::Builder::Union(3)
SQL::Builder::List(3)
SQL::Builder::Select(3)
SQL::Builder::Base(3)
