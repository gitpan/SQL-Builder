#!/usr/bin/perl

package SQL::Builder::Having;

use warnings;
use strict;

use SQL::Builder::BinaryOp;

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub init	{
	my $self = shift;

	$self->SUPER::init();
	
	my $and = SQL::Builder::BinaryOp->new();
	$and->op("AND");

	$self->expr($and);

	return $self;
}

sub children	{
	my $self = shift;

	return $self->_make_children_iterator([
		$self->expr
	])
}

sub expr	{
	return shift->_set('expr', @_)
}

sub sql	{
	my $self = shift;
	my $expr = $self->dosql($self->expr);

	return "" unless defined($expr) && length($expr);

	return "HAVING " . $expr
}

1;

=head1 NAME

SQL::Builder::Having - Represent SQL's HAVING clause

=head1 SYNOPSIS

This class can represent the following SQL:

	HAVING expr

Here's the gist of it:

	my $having = SQL::Builder::Having->new;
	
	$having->expr->list_push('COUNT(*) > 5');

	# HAVING COUNT(*) > 5
	print $having->sql;

	$having->expr->list_push('COUNT(*) < 10');

	# HAVING COUNT(*) > 5 AND COUNT(*) < 10
	print $having->sql

=head1 DESCRIPTION

This is a SQL::Builder::Base(3) subclass

=head1 METHODS

=head2 expr()

Get/set the expr. Called with arguments sets the current expression and returns
the current object. If no arguments are passed, the current expression is
returned. By default, this method is populated with a SQL::Builder::BinaryOp(3)
object

=head2 init()

This calls SQL::Builder::Base::init and populates expr() with a default vaule

=head2 sql()

Returns an empty string if the value returned by expr() is defined and has a length. The value of
expr() is passed through SQL::Builder::Base::dosql()

=head2 children()

Return a SQL::Builder::Iterator object to iterate over the value of expr()

=head1 SEE ALSO

SQL::Builder::Base(3)
SQL::Builder::BinaryOp(3)
