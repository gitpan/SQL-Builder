#!/usr/bin/perl

package SQL::Builder::Update;

use warnings;
use strict;

use Carp qw(confess);

use SQL::Builder::Where;
use SQL::Builder::List;
use SQL::Builder::BinaryOp;
use SQL::Builder::Join;
use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub init	{
	my $self = shift;

	$self->SUPER::init;

	{
		my $list = SQL::Builder::List->new();

		$self->columns($list);
	}

	{
		my $where = SQL::Builder::Where->new();

		$self->where($where);
	}

	{
		my $list = SQL::Builder::List->new;
		$list->options(parens => 0);
		$list->joiner("\n");
		$list->use_aliases(1);
		$self->joins($list);
	}

	$self->use_names(1);

	return $self;
}

sub columns	{
	return shift->_set('columns', @_)
}

sub use_names	{
	return shift->options('use_name', @_)
}

sub update	{
	my $self = shift;
	my ($column, $value) = @_;

	confess "Expecting arguments (column, value); not passed"
		unless defined ($column) && length($column)
			&& defined($value) && length($value);

	my $name;

		if($self->use_names && UNIVERSAL::can($column, 'name'))	{

			$name = $column->name;
		}
		else	{

			$name = $column;
		}

	my $set = SQL::Builder::BinaryOp->new(
		lhs => $name,
		op  => "=",
		rhs => $value
	);

	$self->columns->list_push($set);

	return $self;
}

sub table	{
	return shift->_set('table', @_)
}

*target = *table;

sub joins	{
	return shift->_set('from_expr', @_)
}

*from = *joins;

sub add_join	{
	my ($self, @args) = @_;

	confess "Need at least one arg, see Join docs"
		unless @args;
	
	my $join = SQL::Builder::Join->new(@args);

	$self->joins->list_push($join);

	return $self
}

sub where	{
	return shift->_set('where', @_)
}

sub only	{
	return shift->_set('only', @_)
}

sub sql	{
	my $self = shift;

	my $table = $self->dosql($self->table);
	my $from  = $self->dosql($self->from);
	my $where = $self->dosql($self->where);
	my $cols  = $self->dosql($self->columns);

	return "" unless defined($table) && length($table)
			&& defined($cols) && length($cols);

	my $only = $self->only ? "ONLY " : "";
	my $sql = "UPDATE $only$table SET $cols";

	if(defined($from) && length $from)	{
		
		$sql .= " FROM $from";
	}

	if(defined($where) && length($where))	{
		$sql .= "\n$where";
	}

	return $sql
}

sub children	{
	my $self = shift;

	return $self->_make_children_iterator([
		$self->table,
		$self->columns,
		$self->from,
		$self->where
	])
}

1;

=head1 NAME

SQL::Builder::Update - Represent SQL UPDATE statements

=head1 SYNOPSIS

	my $upd = SQL::Builder::Update->new;

	is($upd->sql, "", "empty returns empty");
	# ""
	print $upd->sql;

	$upd->table("tbl");

	# ""
	print $upd->sql;

	$upd->columns->list_push("foo = 15");

	# UPDATE tbl SET foo = 15
	print $upd->sql;

	$upd->only(1);

	# UPDATE ONLY tbl SET foo = 15
	print $upd->sql;

	$upd->only(0);

	$upd->where->list_push("primary_id = 50");

	# UPDATE tbl SET foo = 15 WHERE primary_id = 50
	print $upd->sql;

	$upd->from->list_push("foo");

	# UPDATE tbl SET foo = 15 FROM foo WHERE primary_id = 50
	print $upd->sql;


	$upd->add_join(
		table => "bar",
		on    => "bar.id = foo.id"
	);

	# UPDATE tbl SET foo = 15 FROM foo JOIN bar ON bar.id = foo.id WHERE primary_id = 50
	print $upd->sql;

	$upd->update(
		baz => 50
	);

	# UPDATE tbl SET foo = 15, baz = 50 FROM foo JOIN bar ON bar.id = foo.id WHERE primary_id = 50
	print $upd->sql;

=head1 DESCRIPTION

This is a subclass of SQL::Builder::Base. It implements a number of different
modules which provide the majority of its functionality

=head1 METHODS

=head2 add_join(@args)

The arguments passed here are used to construct a SQL::Builder::Join(3) object.
This object is then added to the list of tables that will be joined against for
the update. This is really a shortcut for 

	$self->joins->list_push($join);

where $join is the object previously constructed. The current object ($self)
is returned

=head2 children()

Return a SQL::Builder::Iterator(3) object to iterate over the return values of
table(), columns(), from(), and where()

=head2 init()

This method calls init() on the parent class and provides other methods with
default values. A special SQL::Builder::List(3) object is passed to joins(),
another to columns(), and a SQL::Builder::Where(3) object to where()

=head2 joins([$maintainer])

Get/set the SQL (or SQL object) that is used in the UPDATE joins (FROM clause,
not supported everywhere). By default this is populated with a special
SQL::Builder::Join(3) object and typically won't need to be overwritten, but
it's possible. Pass an argument to set the value and return the current object;
or don't pass any and return the current value.

=head2 only([1|0])

Some vendors support the "ONLY" keyword; use this function to turn it on/off.
Pass a 1 or 0 to set the value on or off and have the current object returned;
don't pass any to return the current value. This basically controls the
difference between

	UPDATE ONLY foo

and

	UPDATE foo

This is turned off by default

=head2 sql()

Return the SQL serialization of the object. table(), columns, where(), and
joins() are all passed through SQL::Builder::Base::dosql() before being
processed. If $table or $columns is not defined or without a length, an empty
string is returned. If $joins has a length, then "FROM $joins" is added to the
serialization. If $where has a length, it too is added, except as-is (it's
expected to have the "WHERE" keyword included). Of course, only() controls the
optional use of the ONLY keyword

=head2 table([$table])

This gets/sets the target table for the UPDATE. Called with arguments it sets
the target and returns the current object, without arguments it returns the
current value.

=head2 update($col, $value)

This is a convenience method which assumes that columns() maintains a List
object of some sort (implements list_push() as it does by default). Given $col
and $value, this method will construct a SQL::Builder::BinaryOp(3) object
representing "foo = 15" (or whatever the case), and passes it to
columns->list_push(). The current object is always returned.

=head2 where([$where])

Get/set the object used for maintaining the search condition of the UPDATE
statement (the WHERE clause). Called with arguments the clause is set and
current object is returned. Without arguments, the current WHERE value is
returned. The serialization of this value is expected to maintain the "WHERE"
keyword

=head2 use_names([1|0])

This is turned on by default and takes effect in update(). If this is turned on
and the $column argument passed to update() has a 'name' method, its return
value is used in the LHS of the generated BinaryOp object to prevent certain
SQL issues. Basically, the result is:

	$update->use_names(1);

	my $col = SQL::Builder::Column->new(
		name => "foo",
		'other->list_push' => "schema"
	);

	$update->update($col => 15);

	# UPDATE table SET foo = 15
	print $update->sql;

opposed to:

	$update->use_names(0);

	my $col = SQL::Builder::Column->new(
		name => "foo",
		'other->list_push' => "schema"
	);

	$update->update($col => 15);

	# UPDATE table SET schema.foo = 15
	print $update->sql;

which is likely to result in an error because of "schema.foo"

To change the setting pass a 1 or 0 to turn this behavior on or off and return
the current object; calling with no arguments returns the current value

=head2 SEE ALSO

SQL::Builder::Select(3)
SQL::Builder::Delete(3)
SQL::Builder::Base(3)
SQL::Builder::List(3)
SQL::Builder::Where(3)
SQL::Builder::BinaryOp(3)
