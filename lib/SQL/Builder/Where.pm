#!/usr/bin/perl

package SQL::Builder::Where;

use warnings;
use strict;

use SQL::Builder::BinaryOp;

use SQL::Builder::List;

use base qw(SQL::Builder::List);

sub init	{
	my $self = shift;

	$self->SUPER::init();

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

	return "" unless defined($sql) && length($sql);

	return "WHERE $sql"
}

1;

=head1 NAME

SQL::Builder::Where - Represent a SQL WHERE clause

=head1 SYNOPSIS

	my $where = SQL::Builder::Where->new();

	$where->list_push("foo = bar");
	$where->list_push("bar > 10");

	# WHERE foo = bar AND bar > 10
	print $where->sql;
	
	# same as list_push()
	$where->and("baz = 50");

	# WHERE foo = bar AND bar > 10 AND baz = 50
	...

=head1 DESCRIPTION

This class is a subclass of SQL::Builder::List. It maintains a list of
expressiosn to be sql()ised and joined with an AND statement. This allows one to
keep push()ing expressions

=head1 METHODS

=head2 and(@args)

A wrapper to SQL::Builder::List::list_push()

=head2 init()

Configures the list options - no parens, joined by " AND ". See
SQL::Builder::Base(3)

=head2 sql()

Returns the SQL serialization. SQL::Builder::List::sql() is called and if it
returns a defined value with a length, "WHERE $value" is returned. Otherwise an
empty string is returned

=head1 SEE ALSO

SQL::Builder::List(3)
SQL::Builder::BinaryOp(3)
SQL::Builder::Base(3)
SQL::Builder(3)
SQL::Builder::Select(3)
