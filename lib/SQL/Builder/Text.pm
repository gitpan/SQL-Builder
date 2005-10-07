#!/usr/bin/perl

package SQL::Builder::Text;

use warnings;
use strict;

use SQL::Builder::Base;
use base qw(SQL::Builder::Base);

our $QUOTER = sub {
	my $var = shift;

	return "NULL" unless defined $var;
	
	$var =~ s/'/\\'/g;
	
	return "'$var'"
};

sub quoter	{
	shift;#get rid of object

	if(@_)	{
		$QUOTER = shift;
	}

	return $QUOTER
}

sub set	{
	return shift->text(@_)
}

sub text	{
	return shift->_set('text', @_)
}

sub sql	{
	my $self = shift;
	my $text = $self->cansql($self->text);

	return $self->quoter->($text)
}

1;
