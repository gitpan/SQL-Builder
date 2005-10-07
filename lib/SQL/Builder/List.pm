#!/usr/bin/perl

package SQL::Builder::List;

use warnings;
use strict;
use Carp qw(confess);

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

#interface consistency
sub set	{
	return shift->list(@_)
}

#always pass an arrayref
sub list	{
	my $self = shift;

	if(@_)	{
		my $ref = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
		
		for(@$ref)	{
			$_->parent($self) if $self->is_sb($_) && $_->id ne $self->id;
		}

		return $self->_set('list', $ref)
	}
	else	{
		return $self->_set('list')
	}
}

sub list_push	{
	my $self = shift;

	if(ref $_[0] eq 'ARRAY')	{
		push @{$$self{list}}, @{$_[0]}
	}
	else	{
		push @{$$self{list}}, @_;
	}

	return $self;
}

sub list_pop	{
	my $self = shift;
	confess "Trying to pop empty list"
		unless @{$$self{list}};
	
	return pop @{$$self{list}}
}

sub list_shift	{
	my $self = shift;
	confess "Trying to shift empty list"
		unless @{$$self{list}};
	return shift @{$$self{list}}
}

sub list_unshift	{
	my $self = shift;
	unshift @{$$self{list}}, @_
}

sub list_clear	{
	my $self = shift;
	$self->list([]);
}

sub init	{
	my $self = shift;

	$self->joiner(', ');
	$self->options(join_padding => '');

	$self->list([]);

	return $self
}

sub joiner	{
	shift->_set('joiner', @_)
}

#options: parens, join_padding
sub sql	{
	my $self = shift;
	
	return "" unless $self->list && @{$self->list};

	my $joiner = $self->joiner;

	if(my $pad = $self->options('join_padding'))	{
		$joiner = $pad.$joiner.$pad;
	}

	return "" unless defined $self->list;

	my $sql = join(
		$joiner,
		map {
			my $val = $self->cansql($_);
			defined $val ? $val : ""
		} (ref $self->list eq 'ARRAY' ? @{$self->list} : $self->list)
	);

	if($self->options('parens'))	{
		$sql = "($sql)"
	}

	return $sql
}

sub quick	{
	return shift->new(@_)
}

sub children	{
	my $self = shift;
	return $self->_make_children_iterator($self->list)
}


1;
