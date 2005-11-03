#!/usr/bin/perl

package SQL::Builder::Except;

use warnings;
use strict;

use SQL::Builder::Junction;

use base qw(SQL::Builder::Junction);

sub init	{
	my $self = shift;

	$self->SUPER::init;

	$self->junction("EXCEPT");

	return $self;
}

1;

=head1 NAME

SQL::Builder::Except - Object representation of the SQL "EXCEPT" junction

=head1 SYNOPSIS

This is a subclass of SQL::Builder::Junction(3) which is a subclass of
SQL::Builder::List(3). See those for complete documentation. This class
generates the following SQL:

	anything EXCEPT anything [EXCEPT anything ...]

Here's a basic example:

	my $ex = SQL::Builder::Except->new;

	$ex->list_push("SELECT 1");

	$ex->list_push("SELECT 2");
	
	# SELECT 1 EXCEPT SELECT 2
	print $ex->sql


=head1 METHODS

=head2 init()

Sets the junction() value to "EXCEPT"

=head1 SEE ALSO

SQL::Builder::Junction(3)
SQL::Builder::List(3)
SQL::Builder::Union(3)
SQL::Builder::Intersect(3)
