#!/usr/bin/perl

package SQL::Builder::AliasSelect;

use warnings;
use strict;

use SQL::Builder::Alias;

use base qw(SQL::Builder::Alias);

sub sql	{
	my $self  = shift;
	my $expr  = $self->cansql($self->expr);
	my $alias = $self->cansql($self->alias);

	return "" unless defined $expr && length $expr;
	
	if($alias)	{
		no warnings;
		return "$expr AS $alias"
	}
	else	{
		return $expr
	}
}


1;
