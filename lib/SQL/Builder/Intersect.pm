#!/usr/bin/perl

package SQL::Builder::Intersect;

use warnings;
use strict;

use SQL::Builder::Junction;

use base qw(SQL::Builder::Junction);

sub init	{
	my $self = shift;

	$self->SUPER::init;

	$self->junction("INTERSECT");

	return $self;
}

1;

=head1 NAME

SQL::Builder::Intersect - Represent a SQL 'INTERSECT' junction

=head1 SYNOPSIS

This class can generate:

	anything INTERSECT anything

Basically, do:

	my $intersection = SQL::Builder::Intersect->new;

	$intersection->list_push("SELECT 1");
	$intersection->list_push("SELECT 2");

	# SELECT 1 INTERSECT SELECT 2
	print $intersection->sql

=head1 DESCRIPTION

This is a subclass of SQL::Builder::Junction(3)

=head1 METHODS

=head2 init()

Sets the junction() value to "INTERSECT"

=head1 SEE ALSO

SQL::Builder::Junction(3)
SQL::Builder::List(3)
SQL::Builder::Base(3)
SQL::Builder(3)
SQL::Builder::Except(3)
SQL::Builder::Union(3)
