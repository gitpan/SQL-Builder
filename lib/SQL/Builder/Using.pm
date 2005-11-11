#!/usr/bin/perl

package SQL::Builder::Using;

use warnings;
use strict;

use SQL::Builder::Base;
use SQL::Builder::List;

use base qw(SQL::Builder::Base);

sub init	{
	my $self = shift;

	$self->SUPER::init();

	{
		my $list = SQL::Builder::List->new;
		$list->parens(0);
		$self->expr($list);
	}

	return $self
}

sub expr	{
	return shift->_set('expr', @_)
}

sub sql	{
	my $self = shift;
	my $sql  = $self->dosql($self->expr);

	return "" unless defined ($sql) && length $sql;

	return "USING($sql)"
}

1;

=head1 NAME

SQL::Builder::Using - Represent SQL's JOIN/USING constrct

=head1 SYNOPSIS

	my $using = SQL::Builder::Using->new();

	$using->expr->list_push("foo");

	# USING(foo)
	print $using->sql;

	$using->expr->list_push("bar");

	# USING(foo, bar)
	print $using->sql;

	# use our own expression
	$using->expr("foo, bar");
	
	# USING(foo, bar)
	print $using->sql;

	# observe "empty" behavior
	$using->expr("");

	# ""
	print $using->sql

=head1 DESCRIPTION

By default expr() is populated with a SQL::Builder::List(3) object, but it can
be replaced with anything. sql() will pass it through
SQL::Builder::Base::dosql().

This is a subclass of SQL::Builder::Base(3)

=head1 METHODS

=head2 init()

Call init() on the parent class and pass a SQL::Builder::List(3) object to
expr().

=head2 expr([$expr])

Get/set the expression used in the USING clause. If arguments are passed the
expression is set and current object is returned. If no arguments are passed,
the current expression is returned. By default expr() is populated with a
SQL::Builder::List(3) object

=head2 sql()

Return the SQL serialization of the USING expression. If expr() returns a value
that is not defined or doesn't have a length, then an empty string is returned.
Otherwise the return value is passed through SQL::Builder::Base::dosql() and
used like so:

	USING($expr)

=head1 SEE ALSO

SQL::Builder::Join(3)
SQL::Builder::Select(3)
SQL::Builder::Base(3)
SQL::Builder(3)
