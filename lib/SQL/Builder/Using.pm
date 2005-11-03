#!/usr/bin/perl

package SQL::Builder::Using;

use warnings;
use strict;

use SQL::Builder::List;

use base qw(SQL::Builder::List);

sub init	{
	$_[0]->SUPER::init();
	$_[0]->options(parens => 1)
}

sub sql	{
	my $self = shift;
	my $sql  = $self->SUPER::sql();

	return "" unless $sql;

	return "USING$sql"
}

1;
