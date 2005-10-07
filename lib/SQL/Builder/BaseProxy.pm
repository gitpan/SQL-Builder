#!/usr/bin/perl

package SQL::Builder::BaseProxy;

use warnings;
use strict;
use Carp qw(confess);

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

# this is only added for simplicity to call the parent
sub init	{
	my $self = shift;
	$self->SUPER::init;
	
	return $self
}


# get/set the base property/object
sub _base	{
	return shift->_set('proxy_base', @_)
}

# determine whether to use $self or $self->_base
sub _base_or_child	{
	my $self = shift;
	my $base = $self->_base;

	# this assumes that the class is a sub-class of $self->_class

	my $class = ref $base;

	if($class && ref($self) ne $class)	{
		$self = $self->_base;
	}

	return $self;
}

# convert to another class
sub convert_to	{
	my ($self, $class) = @_;

	confess "Required class argument not passed and default not found"
		unless $class;

	return bless $self, $class;
}


1;
