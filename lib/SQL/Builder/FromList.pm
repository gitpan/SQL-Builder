#!/usr/bin/perl

package SQL::Builder::FromList;

use warnings;
use strict;
use Carp qw(confess);

use SQL::Builder::FromTable;
use SQL::Builder::Table;
use SQL::Builder::Join;

use SQL::Builder::List;

use base qw(SQL::Builder::List);

sub init	{
	my $self = shift;

	$self->SUPER::init();
	
	{
		my $list = SQL::Builder::List->new;
		$list->options(parens => 0);
		$list->joiner("\n");
		$self->joins($list);
	}

	return $self;
}

sub sql	{
	my $self = shift;

	my $list = $self->SUPER::sql();
	my $joins = $self->cansql($self->joins);

	return "" unless $list;
	
	return $joins ? "FROM $list\n$joins" : "FROM $list"
}

########
########

sub add_table	{
	my ($self, @args) = @_;

	confess "Need at least one arg, see Table docs"
		unless @args;
	
	my $table = SQL::Builder::FromTable->new(@args);

	$self->list_push($table);

	return $table
}

sub add_join	{
	my ($self, @args) = @_;

	confess "Need at least one arg, see Join docs"
		unless @args;
	
	my $join = SQL::Builder::Join->new(@args);

	$self->joins->list_push($join);

	return $join
}

sub joins	{
	return shift->_set('joins', @_)
}

sub tables	{
	return shift->list(@_)
}



1;
