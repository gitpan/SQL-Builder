#!/usr/bin/perl

package SQL::Builder::FromList;

use warnings;
use strict;
use Carp qw(confess);

use SQL::Builder::FromTable;
use SQL::Builder::Table;
use SQL::Builder::Join;
use SQL::Builder::List;

use base qw(SQL::Builder::Base);

sub init	{
	my $self = shift;

	$self->SUPER::init();
	
	{
		my $list = SQL::Builder::List->new;
		$list->options(parens => 0);
		$list->joiner("\n");
		$list->use_aliases(1);
		$self->joins($list);
	}

	{
		my $list = SQL::Builder::List->new;
		$list->options(parens => 0);
		$list->joiner(", ");
		$self->tables($list);
		$list->use_aliases(1);
	}

	return $self;
}

sub children	{
	my $self = shift;

	return $self->_make_children_iterator([
		$self->tables, $self->joins
	])
}

sub sql	{
	my $self = shift;

	my $list  = $self->dosql($self->tables);
	my $joins = $self->dosql($self->joins);

	return "" unless $list;
	
	return $joins ? "FROM $list\n$joins" : "FROM $list"
}

########
########

sub add_table	{
	my ($self, @args) = @_;

	confess "Need at least one arg, see Table docs"
		unless @args;
	
	my $table = SQL::Builder::FromTable->new(@args);

	$self->tables->list_push($table);

	return $self
}

sub add_join	{
	my ($self, @args) = @_;

	confess "Need at least one arg, see Join docs"
		unless @args;
	
	my $join = SQL::Builder::Join->new(@args);

	$self->joins->list_push($join);

	return $self
}

sub joins	{
	return shift->_set('joins', @_)
}

sub tables	{
	return shift->_set('tables', @_)
}

sub list_push	{

	return shift->tables->list_push(@_)
}



1;

=head1 NAME

SQL::Builder::FromList - Represent the joins and tables in SQL's FROM clause

=head1 SYNOPSIS

This class can represent the following:

	FROM anything [ [AS anything] [( anything )] ]
	[ [LEFT|RIGHT|anything] JOIN [anything] ]

Or the more concrete example of:

	FROM table1 AS t1 (c1, c2, c3, c4)
	JOIN table2 AS t2 USING (foozle)

	...

Or one can consider:

	[FROM <SQL::Builder::List> [<SQL::Builder::List>]]

Here's the gist of it:

	my $frmlist = SQL::Builder::FromList->new;
	my $tbl1 = SQL::Builder::FromTable->new(
		table => "table1",
		alias => "t1",
		other => [qw(c1 c2)]
	);
	my $tbl2 = SQL::BUilder::Table->new(
		table => "table2",
		alias => "t2",
		other => "schema"
	);
	
	$frmlist->tables->list_push($tbl, $tbl2);
	
	# FROM table1 AS t1 (c1, c2), schema.table2
	print $frmlist->sql;

You can also generate JOINs
	
	$frmlist = SQL::Builder::FromList->new;

	$frmlist->tables->list_push($tbl1);

	my $join = SQL::Builder::Join->new;

		$join->table($tbl2);
		$join->type('LEFT');
		$join->using('common_col');

	$frmlist->joins->list_push($join);

	# FROM table1 AS t1 (c1, c2) LEFT JOIN schema.table2 USING (common_col)
	print $frmlist->sql;

For extra convenience, I've added some useful wrapper methods for adding JOINs
and tables to the FROM list:

	$frmlist = SQL::Builder::FromList->new;
	
	# arguments are passed to SQL::Builder::FromTable->new
	$frmlist->add_table("t1");

	# arguments are passed to SQL::Builder::Join->new
	$frmlist->add_join("t2", undef, undef, "foozle");

	# FROM t1 JOIN t2 USING(foozle)
	print $frmlist->sql

=head1 DESCRIPTION

This is a child of SQL::Builder::Base(3) and is composed mostly of SQL::Builder::List(3)
objects. The values of joins() and tables() can be manipulated as desired, but
add_join() and add_table() expect tables() and joins() to return objects that
have a list_push() method.

This object can be used to represent the list of items used in a FROM clause.
It can generate a comma-delimited list in the FROM clause, as well as a list of
JOIN statements. While SQL::Builder::FromList maintains two lists by default, it
is prepared for representing the following SQL:

	FROM anything

or

	FROM anything anything

This means it would be easy to extend or customize its functionality, but if
that's unnecessary, one can utilize the default lists, which serialize to SQL
like:

	FROM $table_list $join_list

where $table_list and $join_list are both SQL::Builder::List(3) objects,
available through tables() and joins(), respectively. If $join_list does not
have any elements,

	FROM $table_list

is returned in the SQL serialization (sql()).

This class is implemented in SQL::Builder::Select(3)

=head1 METHODS

=head2 new()

See SQL::Builder::Base(3) for new() and set() - they are inherited

=head2 add_join(...)

This method is essentially the same as doing:

	my $join = SQL::Builder::Join->new(@args);
	$frmlist->joins->list_push($join);

Arguments passed here are passed to SQL::Builder::Join->new(). An exception is
thrown when no arguments are passed. If the object is created successfully, the
current SQL::Builder::FromList object ($self) is returned -- this can be useful
for chaining method calls.

=head2 add_table(...)

This method is essentially the same as doing:

	my $table = SQL::Builder::Table->new(@args);
	$frmlist->tables->list_push($table);

Arguments passed here are passed to SQL::Builder::Join->new(). An exception is
thrown when no arguments are passed. If the object is created successfully, the
current SQL::Builder::FromList object ($self) is returned -- this can be useful
for chaining method calls.

=head2 init()

This performs object initialization like creating a list for tables() and
joins()

=head2 joins([$anything])

By default, this method provides access to the SQL::Builder::List(3) object
which is used for maintaining the list of JOINs. The default value can be
overwritten without consequence (mostly) - do this by passing the new value as an
argument. The default SQL::Builder::List(3) object has use_alises() turned on (1).
When an argument is passed, the current SQL::Builder::FromList object
is returned (useful for chaining). To add joins to the FromList, usually one
would do something like:

	$frmlist->joins->list_push($join_object)

or

	$frmlist->joins->list_push("LEFT JOIN termintator3 AS t3 USING (baz)")

=head2 sql()

This returns the SQL serialization of the object. The current value of tables()
and joins() are passed through SQL::Builder::Base::dosql(). If $joins is
empty, "FROM $tables" is returned. If $tables is empty, "" is returned.
Basically:

	[FROM $tables [$joins]]

=head2 tables()

By default, this method provides access to the SQL::Builder::List(3) object
which is used for maintaining the list of tables. The default value can be
overwritten without consequence (mostly) - do this by passing the new value as an
argument. The default object has use_aliases() turned on. When an argument
is passed, the current SQL::Builder::FromList object
is returned (useful for chaining). To add tables to the FromList, usually one
would do something like:

	$frmlist->tables->list_push($table_object)

or

	$frmlist->tables->list_push("employees e");

=head2 children()

Return an iterator to iterate on the return values of tables() and joins(), in
that order

=head2 list_push(@args)

This is a wrapper to list_push() called on tables(), meaning:

	$frm_list->list_push(@args);

is the same as

	$frm_list->tables->list_push(@args)

=head1 SEE ALSO

SQL::Builder::List(3)
SQL::Builder::Select(3)
SQL::Builder::FromTable(3)
SQL::Builder::Join(3)
SQL::Builder::Table(3)
