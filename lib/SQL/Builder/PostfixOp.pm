#!/usr/bin/perl

package SQL::Builder::PostfixOp;

use warnings;
use strict;
use Carp qw(confess);
use SQL::Builder::UnaryOp;

use base qw(SQL::Builder::UnaryOp);

sub sql	{
	my $self = shift;

	confess "Op/arg not yet set"
		unless defined $self->op && defined $self->oper;

	return $self->_sql_filter(sprintf "%s %s",
		$self->dosql($self->oper),
		$self->dosql($self->op))
}


1;

=head1 NAME

SQL::Builder::PostfixOp - Represent a SQL unary (postfix) operator/expression

=head1 SYNOPSIS

Basically:

	foo Bar

where foo is the expression/operand, and Bar is the operator:

	my $po = SQL::Builder::PostfixOp(op => "!", oper => "foo");

	# foo !
	print $po->sql;

	$po->parens(1);
		
	# (foo !)
	print $po->sql;

	$po->op(undef);

	# error
	print $po->sql;

=head1 DESCRIPTION

This is a subclass of SQL::Builder::UnaryOp(3), which represents unary operations

=head1 METHODS

=head2 sql()

This method returns the SQL serialization in the format of:

	$oper $op

where $oper and $op are the values of oper() and op() passed through
SQL::Builder::Base::dosql(). See SQL::Builder::UnaryOp(3) for docs. If parens()
returns true, the resulting expression is wrapped in parenthesis.

=head1 SEE ALSO

SQL::Builder::Base(3)
SQL::Builder(3)
SQL::Builder::UnaryOp(3)
SQL::Builder::PrefixOp(3)
