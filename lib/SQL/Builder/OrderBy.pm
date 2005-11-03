#!/usr/bin/perl

package SQL::Builder::OrderBy;

use warnings;
use strict;

use Carp qw(confess);

use SQL::Builder::Order;
use SQL::Builder::List;

use base qw(SQL::Builder::List);

sub init	{
	my $self = shift;

	$self->SUPER::init;

	$self->parens(0);

	return $self
}

sub sql	{
	my $self = shift;

	my $sql = $self->SUPER::sql();

	return "" unless defined($sql) && length $sql;

	return "ORDER BY $sql";
}

sub _add_item	{

	my $self = shift;
	my $order = shift;
	
	if(@_ == 1 && UNIVERSAL::isa($_[0], 'SQL::Builder::Order'))	{
		$self->list_push($_[0]);
		
		return $self;
	}
	else	{
		
		my $order = SQL::Builder::Order->new(@_);
		
		$order->order($order);

		$self->list_push($order);

		return $order;
	}
}

sub asc	{
	return shift->_add_item(SQL::Builder::Order->ASC, @_)
}

sub desc	{
	return shift->_add_item(SQL::Builder::Order->DESC, @_)
}

1;

=head1 NAME

SQL::Builder::OrderBy - An object representation of the ORDER BY clause

=head1 SYNPOSIS

	my $orderby = SQL::Builder::OrderBy->new;

	$orderby->list_push("foo ASC");
	$orderby->list_push("bar");
	$orderby->list_push("baz DESC");

	# ORDER BY foo ASC, bar, baz DESC
	print $orderby->sql;

	my $expr = SQL::Builder::Order->new(
		expr => "col1",
		order => "DESC"
	);
	
	$orderby->list_push($expr);

	# ORDER BY foo ASC, bar, baz DESC, col1 DESC
	print $orderby->sql;

	$orderby->asc("col2");

	# ORDER BY foo ASC, bar, baz DESC, col1 DESC, col2 ASC
	print $orderby->sql;

	$orderby->desc("col3");

	# ORDER BY foo ASC, bar, baz DESC, col1 DESC, col2 ASC, col3 DESC
	print $orderby->sql;

=head1 DESCRIPTION

This class inherits from SQL::Builder::List

=head1 METHODS

=head2 init()

Calls init() on the parent class and turns off parenthesis on the list

=head2 asc(@args)

If a single argument is passed and it is a SQL::Builder::Order object, it is
immediately added to the current object ($self->list_push($obj)) and the current
object ($self) is returned. Any other pattern of arguments is passed to the constructor
of a SQL::Builder::Order object. This object is added to the list (list_push())
and is returned. After the object is created, asc() is called on it

=head2 desc(@args)

This method works just like asc(), except after the object is created, desc() is
called on it

=head2 _add_item($order[, @args])

This is a private method used by asc() and desc(). It is described in asc(), the
only difference is that it accepts the sort order as the first argument. eg,

	_add_item("DESC", expr => "col1")

=head1 SEE ALSO

SQL::Builder::List(3)
SQL::Builder::Order(3)
SQL::Builder(3)
