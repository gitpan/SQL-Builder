#!/usr/bin/perl

package SQL::Builder::UnaryOp;

use warnings;
use strict;
use Carp qw(confess);
use SQL::Builder::Base;

use base qw(SQL::Builder::Base);


sub op	{
	return shift->_set("op", @_)
}

#operand, really
sub arg	{
	return shift->_set("arg", @_)
}

sub oper	{
	return shift->_set("arg", @_)
}

sub sql	{
	my $self = shift;
	confess "Function not implemented - must be subclassed"
}

sub parens	{
	return shift->options('parens', @_)
}

sub _sql_filter	{
	my ($self, $val) = @_;

	return "" unless defined($val) && length $val;

	if($self->parens)	{
		return "($val)"
	}
	else	{
		return $val
	}
}

sub children	{
	my $self = shift;

	return $self->_make_children_iterator([
		$self->op,
		$self->oper
	]);
}

1;

=head1 NAME

SQL::Builder::UnaryOp - Represent a SQL unary operator/expression

=head1 SYNOPSIS
	
	# generate a new unary op object with a subclass
	my $op = SQL::Builder::...

	$op->op("!");

	$op->oper(50);
	
	# see the child class for what this does
	print $op->sql;
	
	# turn on parenthesis
	$op->parens(1);

=head1 DESCRIPTION

This is just a skeleton class, intended to be subclassed. See
SQL::Builder::PrefixOp(3) and
SQL::Builder::PostfixOp(3) for examples.

=head1 METHODS

=head2 op([$op])

Get/set the operator. When called with arguments, the operator is set and
current object is returned; otherwise, the current operator is returned.

=head2 oper([$operand])

Get/set the operand to be used in the unary operator expression. If called with
an argument, the operand is set and current obejct is returned; otherwise the
current value is returned

=head2 sql()

This doesn't do anything except throw an error because it should always be
implemented in subclasses

=head2 children()

Return a SQL::Builder::Iterator object to iterate over the values of op() and
oper()

=head1 SEE ALSO

SQL::Builder(3)
SQL::Builder::Base(3)
SQL::Builder::PrefixOp(3)
SQL::Builder::PostfixOp(3)
