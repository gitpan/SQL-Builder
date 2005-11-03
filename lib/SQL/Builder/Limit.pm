#!/usr/bin/perl

package SQL::Builder::Limit;

use warnings;
use strict;
use Carp qw(confess);

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub limit	{
	return shift->_set(limit => @_)
}

sub offset	{
	return shift->_set(offset => @_)
}

sub sql	{
	my $self = shift;

	my $limit = $self->dosql($self->limit);
	
	my $offset = $self->dosql($self->offset);

	my $sql = ''; 
	
	$sql = "LIMIT $limit" if defined($limit) && length $limit;

	$sql .= " OFFSET $offset" if defined($offset) && length $offset;

	return $sql;
}

sub children	{
	my $self = shift;

	return $self->_make_children_iterator([
		$self->limit, $self->offset
	])
}

1;

=head1 NAME

SQL::Builder::Limit - Represent LIMIT/OFFSET clauses

=head1 SYNOPSIS

	my $lim = SQL::Builder::Limit->new(
		limit => 10,
		offset=> 10
	);

	# LIMIT 10 OFFSET 10
	print $lim->sql

	$lim->offset(undef);

	# LIMIT 10
	print $lim->sql

=head1 METHODS

=head2 limit([$lim])

Get/set the LIMIT value. When arguments are passed, the value is set and current
object is returned; returns the current value otherwise. undef by default

=head2 offset([$offset])

Get/set the OFFSET value. When arguments are passed, the value iss et and the
current object is returned; returns the current value otherwise. undef by
default

=head2 sql()

Returns the SQL serialization. limit() and offset() are passed through
SQL::Builder::Base::dosql() before being processed. If $limit is defined and has
a length, it is used. If $offset is defined and has a length, it is used. If
neither $limit or $offset can be used, an empty string is returned. One could
end up with any of the following, including the empty string

	LIMIT x OFFSET y
	LIMIT x
	OFFSET y

=head2 children()

Return a SQL::Builder::Iterator to iterate over the values of limit() and
offset()

=head1 SEE ALSO

SQL::Builder::Base(3)
SQL::Builder(3)
