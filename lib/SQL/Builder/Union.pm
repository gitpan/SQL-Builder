#!/usr/bin/perl

package SQL::Builder::Union;

use warnings;
use strict;

use SQL::Builder::Junction;

use base qw(SQL::Builder::Junction);

sub init	{
	my $self = shift;

	$self->SUPER::init;

	$self->junction("UNION");

	return $self;
}

1;

=head1 NAME

SQL::Builder::Union - Object representation of the SQL "UNION" junction

=head1 SYNOPSIS

This is a subclass of SQL::Builder::Junction(3) which is a subclass of
SQL::Builder::List(3). See those for complete documentation. This class
generates the following SQL:

	anything UNION anything [UNION anything ...]

Here's a basic example:

	my $ex = SQL::Builder::UNION->new;

	$ex->list_push("SELECT 1");

	$ex->list_push("SELECT 2");
	
	# SELECT 1 UNION SELECT 2
	print $ex->sql


=head1 METHODS

=head2 init()

Sets the junction() value to "UNION"

=head1 SEE ALSO

SQL::Builder::Junction(3)
SQL::Builder::List(3)
SQL::Builder::Except(3)
SQL::Builder::Intersect(3)
