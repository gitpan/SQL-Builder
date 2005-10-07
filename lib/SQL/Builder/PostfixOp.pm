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

	return sprintf "%s%s",
		$self->cansql($self->oper),
		$self->cansql($self->op)
}


1;
