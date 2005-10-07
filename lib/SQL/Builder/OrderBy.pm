#!/usr/bin/perl

package SQL::Builder::OrderBy;

use warnings;
use strict;

use SQL::Builder::Order;
use SQL::Builder::List;

use base qw(SQL::Builder::List);

sub sql	{
	my $self = shift;

	$self->options(parens => 0);

	my $sql = $self->SUPER::sql();

	return "" unless $sql;

	return "ORDER BY $sql";
}

sub quick	{
	my $class = shift;
	my $new   = $class->new;

	$new->list_push(SQL::Builder::Order->quick(@_));

	return $new
}

1;
