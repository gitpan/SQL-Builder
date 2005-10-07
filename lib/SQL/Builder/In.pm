#!/usr/bin/perl

package SQL::Builder::In;

use warnings;
use strict;

use SQL::Builder::Base;

use base qw(SQL::Builder::List);

sub init	{
	$_[0]->SUPER::init();

	$_[0]->options('parens' => 1);
}

sub sql	{
	my $self = shift;
	my $sql = $self->SUPER::sql();

	return "IN $sql"
}

sub quick	{
	return shift->new(@_);
}

1;
