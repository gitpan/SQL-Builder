#!/usr/bin/perl

package SQL::Builder::Distinct;

use warnings;
use strict;
use Carp;

use SQL::Builder::ColumnList;
use SQL::Builder::List;

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub init	{
	my $self = shift;
	$self->SUPER::init();
	
	$self->cols(SQL::Builder::ColumnList->new);
	
	{
		my $on = SQL::Builder::ColumnList->new;

		$on->options(
			default_select => '', parens => 1
		);

		$self->on($on);
	}

	$self->options('distinct' => 1);

	return $self
}

sub cols	{
	return shift->_set('cols', @_)
}

sub on	{
	return shift->_set('on', @_)
}

sub sql	{
	my $self = shift;
	my $on   = $self->cansql($self->on);
	my $cols = $self->cansql($self->cols);

	if($self->options('distinct'))	{

		if($on)	{
			return $cols ? "DISTINCT ON $on $cols" : "DISTINCT ON $on"
		}
		elsif ($cols)	{
			return "DISTINCT $cols"
		}
		elsif ($self->options('always_return'))	{
			return "DISTINCT"
		}
		else	{
			return ""
		}
	}
	else	{
		return $cols;
	}
}

sub quick	{
	my $class = shift;
		$class = ref($class) || $class;

	confess "Expecting at least one argument" unless @_;

	my $new = $class->new();
	
	if(ref $_[0] eq 'HASH')	{
		my $info = shift;

		if(defined $$info{cols})	{
			$new->cols->list($$info{cols})
		}

		if(defined $$info{on})	{
			$new->on->list($$info{on});
		}
	}
	elsif(@_)	{
		my($cols, $on) = @_;

		if($cols)	{
			$new->cols->list($cols)
		}

		if($on)	{
			$new->on->list($on)
		}
	}
	else	{
		confess "At least one argument expected"
	}

	return $new;
}

1;
