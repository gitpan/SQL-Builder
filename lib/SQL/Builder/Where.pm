#!/usr/bin/perl

package SQL::Builder::Where;

use warnings;
use strict;

use SQL::Builder::BinaryOp;

use SQL::Builder::List;

use base qw(SQL::Builder::List);

sub init	{
	my $self = shift;

	$self->options(parens => 0);
	$self->joiner("AND");
	$self->options(join_padding => ' ');
	
	return $self;
}

# changes `WHERE foo = 1` to `WHERE foo = 1 AND bar = 2` if you $obj->and("bar = 2")
sub and	{
	return shift->list_push(@_)
}

sub sql	{
	my $self = shift;
	my $sql = $self->SUPER::sql();

	return "" unless $sql;

	return "WHERE $sql"
}

sub quick	{
	my $class = shift;
	my $new   = $class->new();

	foreach my $item (@_)	{
		$new->list_push(SQL::Builder::BinaryOp->quick($item));
	}

	return $new;
}

1;
