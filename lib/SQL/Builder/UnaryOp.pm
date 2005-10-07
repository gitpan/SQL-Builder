#!/usr/bin/perl

package SQL::Builder::UnaryOp;

use warnings;
use strict;
use Carp qw(confess);
use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

#retrieval methods
sub set	{
	my $self = shift;
	confess "Invalid argument count. Expecting set(op, arg)" unless @_ == 2;

	$self->op($_[0]);
	$self->arg($_[1]);
}

sub op	{
	return shift->_set("op", @_)
}

#operand, really
sub arg	{
	return shift->_set("arg", @_)
}

sub oper	{
	return shift->_set("arg", @_)
}

sub sql	{
	my $self = shift;
	confess "Function not implemented - must be subclassed"
}

#for convenience
sub not	{
	return shift->new("!", $_[0]);
}

sub quick	{
	return shift->new(shift, shift);
}

1;
