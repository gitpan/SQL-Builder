#!/usr/bin/perl

package SQL::Builder::GroupBy;

use warnings;
use strict;
use Carp qw(confess);

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

	$self->parens(0);

	my $sql  = $self->SUPER::sql;

	return "" unless $sql;

	return "GROUP BY $sql"
}

1;

=head1 NAME

SQL::Builder::GroupBy - Manage the list of expressions in a SQL's GROUP BY clause

=head1 SYNOPSIS

	my $groupby = SQL::Builder::GroupBy->new;

	$groupby->list_push("col*5", "foozle");
	
	# GROUP BY col*5, foozle
	print $groupby->sql

=head1 DESCRIPTION

This is a subclass of SQL::Builder::List(3)

=head1 METHODS

=head2 sql()

This utilizes SQL::Builder::List::sql(), but adds the 'GROUP BY' clause. Returns
an empty string if the list of expressions is empty

=head2 init()

This calls SQL::Builder::List::init() and parens(0) to make sure parenthesis are
turned off.

=head1 SEE ALSO

SQL::Builder::List(3)
SQL::Builder::Base(3)
