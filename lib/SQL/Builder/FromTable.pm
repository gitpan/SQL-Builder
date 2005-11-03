#!/usr/bin/perl

package SQL::Builder::FromTable;

use warnings;
use strict;

use SQL::Builder::List;
use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub init	{
	my $self = shift;

	$self->SUPER::init();
	
	{
		my $list = SQL::Builder::List->new;
		$list->options(parens => 1);
		$self->col_container($list);
	}

	return $self
}

sub children	{
	my $self = shift;

	return $self->_make_children_iterator([
		$self->table, $self->alias,
		$self->col_container
	])
}

sub alias	{
	return shift->_set('table_alias', @_)
}

sub table	{
	return shift->_set('table', @_)
}

sub cols	{
	return shift->col_container->list(@_)
}

sub col_container	{
	return shift->_set('cols', @_)
}

sub only	{
	return shift->options('from_only', @_)
}

sub use_as	{
	return shift->options('use_as', @_)
}

sub use_table_alias	{
	return shift->options('use_table_alias', @_)
}

sub sql	{
	my $self  = shift;
	my $table = $self->dosql($self->table);
	my $cols  = $self->dosql($self->col_container->sql);
	my $template;

		if(defined $table)	{
			$template = $self->only ? "ONLY $table" : "$table";
		}

	my $has_tbl_alias = UNIVERSAL::can($self->table, 'alias')
				&& defined $self->table->alias;
	my $use_tbl_alias = !defined($self->use_table_alias)
				|| $self->use_table_alias;
	my $alias;

	return "" unless defined $table;
	
	# determine the alias
	if ($use_tbl_alias && $has_tbl_alias)	{
		$alias = $self->table->alias
	}
	elsif (defined $self->alias)	{
		$alias = $self->alias
	}
	
	# set the alias if we can
	if(defined $alias)	{

		my $use_as = $self->use_as;
		
		if($use_as || !defined $use_as)	{
			$template .= " AS $alias"
		}
		else	{
			$template .= " $alias"
		}
	}
	
	# add column aliases if needed
	if (length($cols) && defined $cols)	{
		return "$template $cols"
	}
	else	{
		return $template
	}
}


1;

=head1 NAME

SQL::Builder::FromTable - Represents a table used in the SQL FROM clause

=head1 SYNOPSIS

This class can generate the following SQL:

	[ONLY] anything [ [AS] anything [anything] ]

or something most likely like:

	table1 AS alias (c1, c2, c3)

SQL::Builder::FromTable is meant to be used as an item in a
SQL::Builder::FromList(3), but can easily be used for other purposes.

Here's how to use it:

	my $tbl = SQL::Builder::FromTable->new();
	
	$tbl->table("table1");
	$tbl->alias("t1");

	# table1 AS t1
	print $tbl->sql;

	$tbl->cols(qw(c1 c2 c3));

	# table1 AS t1 (c1, c2, c3)
	print $tbl->sql

=head1 DESCRIPTION

This object will likely be used for the composition of SQL::Builder::FromList(3)
objects. It is a SQL::Builder::Base(3) subclass and utilizes
SQL::Builder::List(3) for maintaining the list of columns

=head1 METHODS

=head2 new()

See SQL::Builder::Base for new() and set() -- these are inherited

=head2 alias([$alias_name])

This will get/set an alias for the table (see table()). This will return the
current value if called with no arguments. If an argument is passed, the value
is set and the current object is returned

=head2 col_container([$obj])

When called with $obj, the value will be set to $obj and return the current
object. When called with no arguments, the current value is returned. This
object is used to maintain the list of alias columns

=head2 cols([@list])

This is a wrapper method to col_container->list() (see
SQL::Builder::List::list())

=head2 init()

This calls the init() method of the parent class SQL::Builder::Base(3) and sets
up the col_container() object with a SQL::Builder::List(3) object. It is called
in the constructor new() - see SQL::Builder::Base(3) for new(), set(), and
init()

=head2 only([1|0])

This toggles the 'ONLY' keyword (see the SYNOPSIS) for possible SQL generation.
This keyword is typically used for relations that inherit from other relations;
it typically prevents the inheritence of data, but see your DBMS to see what
support is provided. Pass a 1 value to turn on the keyword, 0 to turn it off,
and no arguments to get the current value. If a value is passed, the current
object is returned. This is turned off by default. An undef value enforces
the default.

=head2 sql()

This is the SQL serialization method. It generates the possible SQL provided in
the SYNOPSIS. If only() returns a true value, they SQL "ONLY" keyword is used.
If the value of table() has an alias() method, its alias is used if
use_table_alias() returns a true or undefined value; when this happens, use_as()
is checked. If it returns a true or undefined value, the 'AS' keyword is used.
The value of table(), col_container(), and alias() are passed through
SQL::Builder::Base::dosql() for serialization. If table() returns an undefined
value, an empty string is returned

=head2 table([$table])

Gets/sets the current table() value which may be any value. A defined value is
required for SQL serialization. When called with an argument, the current value
is set and the current object is returned. When no arguments are provided, the
current value is returned

=head2 use_as([1|0|undef])

Turn on/off the usage of the 'AS' keyword between the relation identifier and
its alias. This is turned on by default. Setting a value of 1, 0, or undef sets
the current value and returns the current object. When no arguments are
provided, the current object is returned. A value of undef enforces default
behavior

=head2 use_table_alias([1|0|undef])

If table() has an alias() method its value is used unless this method returns
false (not including undef, which enforces default behavior) in sql(). Passing a value of
1, 0, or undef sets the current value and returns the current object. Calling
without an argument returns the current value. If this method is false (0, not
undef), the value of alias() is used in sql() instead of the alias() value
returned from table()

=head2 children()

Return an SQL::Builder::Iterator to iterate over the values of table(), alias(), and
col_container(), in that order

=head1 SEE ALSO

SQL:;Builder::List(3)
SQL:;Builder::Base(3)
SQL:;Builder::FromList(3)
SQL:;Builder(3)
