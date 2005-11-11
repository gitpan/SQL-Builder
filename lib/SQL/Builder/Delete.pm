#!/usr/bin/perl

package SQL::Builder::Delete;

use warnings;
use strict;

use SQL::Builder::Where;
use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub init	{
	my $self = shift;

	$self->SUPER::init;

	{
		my $where = SQL::Builder::Where->new;
		$self->where($where);
	}

	return $self;
}

sub table	{
	return shift->_set('table', @_)
}

*from = *table;

sub only	{
	return shift->options('only', @_);
}

sub where	{
	return shift->_set('where', @_)
}

sub sql	{
	my $self = shift;
	my $only = $self->only;
	my $where = $self->dosql($self->where);
	my $table = $self->dosql($self->table);

	return "" unless defined($table) && length($table);

	my $sql = "DELETE FROM";

	if($only)	{
		
		$sql .= " ONLY $table";
	}
	else	{
		
		$sql .= " $table"
	}

	if(defined($where) && length($where))	{
		
		$sql .= " $where"
	}

	return $sql;
}

sub children	{
	my $self = shift;

	return $self->_make_children_iterator([
		$self->table,
		$self->where
	])
}

1;

=head1 NAME

SQL::Builder::Delete - Represent SQL DELETE statements

=head1 SYNOPSIS

	# $table is a SQL::Builder::Table object or a string

	my $del = SQL::Builder::Delete->new;

	$del->table($table);

	$del->where->list_push(
		# primary_key = 50
		SQL::Builder::BinaryOp->new(
			lhs => "primary_key",
			op  => "=",
			rhs => 50
		)
	);

	# DELETE FROM table WHERE primary_key = 50
	print $del->sql;

	$del->only(1);
	
	# DELETE FROM ONLY table WHERE primary_key = 50
	print $del->sql;

	$del->table("");

	# ""
	print $del->sql;

	$del->table($table);
	
	$del->where->list_clear();

	$del->only(0);

	# DELETE FROM table
	print $del->sql

=head1 DESCRIPTION

This is a subclass of SQL::Builder::Base

=head1 METHODS

=head2 init()

This calls init() on the parent class and passes a SQL::Builder::Where object to
where()

=head2 table([$table])

Get/set the table from which the data will be deleted. If a table is passed the
value is set and current object is returned. If no arguments are passed the
current table is returned

=head2 from([$table])

An alias of table()

=head2 only([1|0])

Toggle the "ONLY" keyword in the SQL serialization. Pass a 1 or 0 to turn it on
or off, respectively. If arguments are passed the value is set and current
object is returned; otherwise the current value is returned. This is turned off
by default

=head2 where([$where])

Set the object expected to maintain the WHERE clause. If arguments are passed
the value is set and current object returned; otherwise the current value is
returned. This method is populated with a SQL::Builder::Where(3) object by
default. sql() serialization expects the sql() method to include the "WHERE"
keyword if there is a search condition -- see SQL::Builder::Where

=head2 sql()

Return the SQL serialization of the DELETE statement. If there is no table
(table()) set, then an empty string is returned. See the synopsis for examples
of behavior. The return values of table() and where() are passed through
SQL::Builder::Base::dosql() for serialization. They are then connected to the
rest of the DELETE statement, optionally using the ONLY keyword (see only()).

=head2 children()

Return a SQL::Builder::Iterator(3) object to iterate over the values of
table() and where()

=head1 SEE ALSO

SQL::Builder::Select(3)
SQL::Builder::Base(3)
SQL::Builder(3)
