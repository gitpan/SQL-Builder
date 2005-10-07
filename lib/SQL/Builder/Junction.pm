#!/usr/bin/perl

package SQL::Builder::Junction;

use warnings;
use strict;
use Carp qw(confess);

use SQL::Builder::List;

use base qw(SQL::Builder::List);

sub junction	{
	confess "Not implemented -- required";
}

sub init	{
	my $self = shift;
	$self->SUPER::init();
	$self->list([])
}

sub all	{
	return shift->options('all', @_)
}

sub sql	{
	my $self = shift;
	my $list = $self->list;

	return "" unless $list && @{$list};

	my $junction = $self->junction();

	my $tpl = $self->all ? " $junction ALL " : " $junction ";

	return join $tpl, map {$self->cansql($_)} @{$list};
}

sub quick	{
	return shift->new(@_);
}

1;
