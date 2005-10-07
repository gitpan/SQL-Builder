#!/usr/bin/perl

package SQL::Builder::GroupBy;

use warnings;
use strict;
use Carp qw(confess);

use SQL::Builder::List;

use base qw(SQL::Builder::List);

sub sql	{
	my $self = shift;

	$self->options(parens => 0);

	my $sql  = $self->SUPER::sql;

	return "" unless $sql;

	return "GROUP BY $sql"
}

sub quick	{
	return shift->new(@_)
}

1;
