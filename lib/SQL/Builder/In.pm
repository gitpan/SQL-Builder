#!/usr/bin/perl

package SQL::Builder::In;

use warnings;
use strict;

use SQL::Builder::List;
use SQL::Builder::BinaryOp;

use base qw(SQL::Builder::BinaryOp);

sub init	{
	my $self = shift;
	
	$self->SUPER::init();

	{
		my $list = SQL::Builder::List->new;

		$list->parens(1);

		$self->rhs($list);
	}

	$self->op('IN');

	return $self
}

1;

=head1 NAME

SQL::Builder::In - Represent the SQL IN operator

=head1 SYNOPSIS

This class can build the following SQL

	expr IN (anything [, ...])

Basically:

	my $in = SQL::Builder::In->new();

	$in->lhs('col1');
	$in->rhs->list_push(1..5);

	# col1 IN (1, 2, 3, 4, 5)
	print $in->sql

and of course, you can do it all through the inherited constructor:

	my $in = SQL::Builder::In->new(
		lhs => 'col1',
		'rhs->list_push' => [1..5]
	);

=head1 DESCRIPTION

This is a SQL::Builder::BinaryOp(3) subclass. Chances are the most useful
methods useful in this class are rhs(), lhs(), and sql()

=head1 METHODS

=head2 init()

This calls SQL::Builder::BinaryOp::init() and provides rhs() with a
SQL::Builder::List(3) object as well as setting op() to 'IN'

=head2 rhs

This method is not overwritten in this class, but init() sets its value to a
List object. See SQL::Builder::List(3) for its documentation

=head1 SEE ALSO

SQL::Builder::List(3)
SQL::Builder::BinaryOp(3)
SQL::Builder::Base(3)
SQL::Builder(3)
