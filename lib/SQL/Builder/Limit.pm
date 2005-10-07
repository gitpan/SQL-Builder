#!/usr/bin/perl

package SQL::Builder::Limit;

use warnings;
use strict;
use Carp qw(confess);

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

#sets LIMIT/OFFSET
sub set	{
	my $self  = shift;
	my $limit = shift;

	$self->limit($limit);

	if(@_)	{
		$self->offset(shift)
	}
}

sub limit	{
	return shift->_set(limit => @_)
}

sub offset	{
	return shift->_set(offset => @_)
}

sub sql	{
	my $self = shift;

	my $limit = $self->limit;
	
	return "" unless defined $limit;

	my $offset = $self->offset;

	my $sql = "LIMIT $limit";

	$sql .= " OFFSET $offset" if defined $offset;

	return $sql;
}

sub quick	{
	my $class = shift;
	
	if(ref $_[0] eq 'HASH')	{
		my $info = shift;
		my @args;

		if(defined $$info{limit})	{
			push @args, $$info{limit};

			if(defined $$info{offset})	{
				push @args, $$info{offset}
			}
		}
		
		if(@args)	{
			return $class->new(@args)
		}
		else	{
			confess "Expecting at least offset, empty hash passed"
		}
	}
	elsif(@_)	{
		return $class->new(@_)
	}
	else	{
		confess "Expecting at least one argument"
	}
}

1;
