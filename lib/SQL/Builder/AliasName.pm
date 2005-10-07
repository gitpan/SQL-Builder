#!/usr/bin/perl

package SQL::Builder::AliasName;

use warnings;
use strict;

use SQL::Builder::Alias;

use base qw(SQL::Builder::Alias);

sub sql	{
	my $self = shift;
	
	my $alias = $self->cansql($self->name);

	return $alias if defined $alias && length $alias;

	my $expr = $self->cansql($self->expr);

	return "" unless defined $expr && length $expr;
	
	return $expr
}

1;
