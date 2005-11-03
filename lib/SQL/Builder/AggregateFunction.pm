#!/usr/bin/perl

package SQL::Builder::AggregateFunction;

use SQL::Builder::Function;

use base SQL::Builder::Function;


1;

=head1 NAME

SQL::Builder::AggregateFunction - A class for adding statefulness to aggregate SQL functions

=head1 SYNOPSIS

SQL::Builder::AggregateFunction is a subclass of SQL::Builder::Function(3); its
purpose is simply to add statefulness to Function objects so that SQL functions
like COUNT can be identified. See the docs for SQL::Builder::Function for
complete information. This class does not overwrite any inherited methods

	my $agfunc =
	SQL::Builder::AggregateFunction->new(func => 'COUNT',
	                                     'args->list_push' => '*');

	# COUNT(*)
	print $agfunc->sql

=head1 SEE ALSO

SQL::Builder(3)
SQL::Builder::Function(3)

=cut
