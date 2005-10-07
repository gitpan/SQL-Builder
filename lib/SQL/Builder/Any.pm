#!/usr/bin/perl

package SQL::Builder::Any;

#creates space delimited list

use warnings;
use strict;

use SQL::Builder::List;

use base qw(SQL::Builder::List);

sub init	{
	$_[0]->SUPER::init();

	$_[0]->joiner(" ");
	$_[0]->options(parens => 0);
}

sub quick	{
	my $class = shift;

	return $class->new(@_);
}

1;
