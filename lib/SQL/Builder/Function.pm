#!/usr/bin/perl

package SQL::Builder::Function;

use warnings;
use strict;
use Carp qw(confess);
use SQL::Builder::Base;
use SQL::Builder::List;

use base qw(SQL::Builder::Base);

sub init	{
	my $self = shift;

	$self->SUPER::init();

	my $list = SQL::Builder::List->new();

	$self->args($list);

	$self->options(parens => 1);
	
	#$self->options(auto_parens => 1);

	return $self
}

sub set	{
	my $self = shift;
	
	confess "Expecting set(func, args*), not enough args @_"
		unless @_ >= 1;

	$self->func(shift);
	$self->args->list_push(@_);
}

sub func	{
	return shift->_set('func', @_);
}

sub args	{
	return shift->_set('args', @_);
}

sub sql	{
	my $self = shift;

	no warnings 'uninitialized';#avoid errors about undef

	if($self->options('auto_parens'))	{
		my $func = $self->cansql($self->func);
		my $args = $self->cansql($self->args);

		if($args)	{
			return "$func($args)"
		}
		else	{
			return "$func"
		}
	}
	else	{
		if ($self->options('parens'))	{
			return sprintf "%s(%s)",
				$self->cansql($self->func),
				$self->cansql($self->args)
		}
		else	{
			my $tpl = exists $$self{args} ? "%s %s" : "%s";

			return sprintf $tpl,
				$self->cansql($self->func),
				$self->cansql($self->args)
		}
	}
}

sub quick	{
	my $class = shift;
		$class = ref($class) || $class;
	
	my $new = $class->new;

	if(ref $_[0] eq 'HASH')	{
		my $info = shift;

		if(defined $$info{func})	{
			$new->func($$info{func});
		}
		else	{
			confess "Expecting function"
		}

		if(defined $$info{args})	{
			$new->args->list($$info{args})
		}
	}
	elsif(ref $_[0] eq 'ARRAY')	{
		my $info = shift;

		$new->func(shift @$info);
		$new->args->list_push(@$info);
	}
	elsif(@_)	{
		$new->func(shift);
		$new->args->list_push(@_);
	}
	else	{
		confess "Expecting at least one argument"
	}
	
	return $new
}

1;
