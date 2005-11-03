#!/usr/bin/perl

package SQL::Builder::Placeholder;

use warnings;
use strict;

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub tag	{
	return shift->_set('tag', @_)
}

sub sql	{
	my $self = shift;

	return "?"
}

1;

=head1 NAME

SQL::Builder::Placeholder - Represent a DBI placeholder in a SQL::Builder tree

=head1 SYNOPSIS

	my $bop = SQL::Builder::BinaryOp->new(
		op => '+',
		lhs => SQL::Builder::Placeholder->new(tag => "some_string_identifier"),
		rhs => SQL::Builder::Placeholder->new(tag => "another_id")
	);

	my @placeholders = $bop->placeholders;
	
	# returns: 50, 60
	my @ordered_values = $bop->ph_order(
		another_id => 60,
		some_string_identifier => 50
	)

=head1 DESCRIPTION

This object's role is to identify the usage of placeholders with a SQL::Builder
tree. SQL::Builder::Placeholder inherits from SQL::Builder::Base(3).
SQL::Builder::Base provides important functionality that is likely to be used
with Placeholder objects -- see the placeholders() and ph_order() methods.

Basically, one needs to manage a "tag" (see tag()) which provides a useful
handle for identifying a placeholder in a query. When necessary, a user can
obtain the ordered list of Placeholder objects from a query and have a hash of
placeholder-values ordered for use with DBI::execute or similar

=head1 METHODS

=head2 tag([$tag])

Get/set the tag. On set, the tag is set and current object returned. Otherwise,
current tag is returned

=head2 sql()

This returns the SQL serialization of placeholder - a question mark: ?

=head1 SEE ALSO

SQL::Builder::Base(3)
SQL::Builder(3)
