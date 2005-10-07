#!/usr/bin/perl

package SQL::Builder::Having;

use warnings;
use strict;

use SQL::Builder::BinaryOp;

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub init	{
	my $self = shift;

	$self->SUPER::init();
	
	my $and = SQL::Builder::BinaryOp->new();
	$and->op("AND");

	$self->expr($and);

	return $self;
}

sub set	{
	return shift->expr->list(@_)
}

sub expr	{
	return shift->_set('expr', @_)
}

sub sql	{
	my $self = shift;
	my $expr = $self->cansql($self->expr);

	return "" unless $expr;

	return "HAVING " . $expr
}

sub quick	{
	my $class = shift;
		$class = ref($class) || $class;

	my $self = $class->new();
	
	my @stuff = SQL::Builder::BinaryOp->quick(@_);

	$self->expr->list_push(@stuff);
	
	return $self;
}

1;
