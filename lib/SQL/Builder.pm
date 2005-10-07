#!/usr/bin/perl
package SQL::Builder;

$VERSION = "0.01";

#use 5.008005;
use strict;
use warnings;

our $VERSION = '0.01';

use SQL::Builder::Table;
use SQL::Builder::Select;
use SQL::Builder::Any;
use SQL::Builder::List;
use SQL::Builder::OrderBy;
use SQL::Builder::Join;
use SQL::Builder::Column;
use SQL::Builder::Text;
use SQL::Builder::Using;
use SQL::Builder::Function;
use SQL::Builder::In;
use SQL::Builder::Limit;
use SQL::Builder::Having;
use SQL::Builder::PrefixOp;
use SQL::Builder::BinaryOp;
use SQL::Builder::GroupBy;
use SQL::Builder::Order;
use SQL::Builder::Distinct;
use SQL::Builder::Union;
use SQL::Builder::Junction;
use SQL::Builder::Intersect;
use SQL::Builder::Except;
use SQL::Builder::Alias;

sub qtable	{ return SQL::Builder::Table->new(@_) }
sub qselect	{ return SQL::Builder::Select->new(@_) }
sub qany	{ return SQL::Builder::Any->new(@_) }
sub qlist	{ return SQL::Builder::List->new(@_) }
sub qorderby	{ return SQL::Builder::OrderBy->new(@_) }
sub qjoin	{ return SQL::Builder::Join->new(@_) }
sub qcol	{ return SQL::Builder::Column->new(@_) }
sub qtext	{ return SQL::Builder::Text->new(@_) }
sub qusing	{ return SQL::Builder::Using->new(@_) }
sub qfunc	{ return SQL::Builder::Function->new(@_) }
sub qin		{ return SQL::Builder::In->new(@_) }
sub qlimit	{ return SQL::Builder::Limit->new(@_) }
sub qhaving	{ return SQL::Builder::Having->new(@_) }
sub qprefix	{ return SQL::Builder::PrefixOp->new(@_) }
sub qop		{ return SQL::Builder::BinaryOp->new(@_) }
sub qgroupby	{ return SQL::Builder::GroupBy->new(@_) }
sub qorder	{ return SQL::Builder::Order->new(@_) }
sub qdistinct	{ return SQL::Builder::Distinct->new(@_) }
sub qunion	{ return SQL::Builder::Union->new(@_) }
sub qintersect	{ return SQL::Builder::Intersect->new(@_) }
sub qexcept	{ return SQL::Builder::Except->new(@_) }
sub qalias	{ return SQL::Builder::Alias->new(@_) }

sub EQ		{ return qop("=", @_) }
sub AND		{ return qop("AND", @_) }
sub OR		{ return qop("OR", @_) }
sub LIKE	{ return qop("LIKE", @_) }
sub ILIKE	{ return qop("ILIKE", @_) }
sub REGEX	{ return qop("~", @_) }


1;

=head1 NAME

SQL::Builder - a structured SQL manipulation interface

=head1 VERSION

Version 0.01 ALPHA - this software isn't production-ready yet and the API is
likely to change

=head1 SYNOPSIS

SQL::Builder is a collection of modules sharing common interfaces for SQL
manipulation with the goal of providing maximum reuse and scalability. It is
not a SQL abstraction (although it does sort of abstract it out
for you), but a structured interface for its manipulation. Because
SQL::Builder is a stateful interface, one's SQL is as portable as they write it,
with the possibility to traverse a SQL construct at runtime and, for example,
convert instances of MySQL's OR operator ("||") with an appropriate "OR", or to
replace the standard concatenation operator ("||"), to MySQL's "CONCAT".

This module doesn't have any methods (yet). See SQL::Builder::*

=head1 DESCRIPTION

THIS IS CURRENTLY UNSTABLE SOFTWARE. DO NOT USE IT IN PRODUCTION CODE; IT IS STILL
UNDERGOING DEVELOPMENT. THE CURRENT TESTS COMPILE AND MOST COULD SHOULD WORK,
BUT ALL IS LACKING IN DOCUMENTATION

This module may be "too much" or "unbenefitial" for certain applications. I work
on data warehouses which provide interfaces for generating reports, and find the
functionality provided by SQL::Builder to be quitessential. Given the dynamics
of most applications I've written, I see little reason not to use SQL::Builder
because I care about the maintainability of my query logic.

One of my goals was to create structured interfaces for SQL constructs. I
started with the most basic constructs, then started combining them to achieve
necessary functionality for SQL statements such as SELECT. SQL::Builder::Select
is a relatively small module; most of it's functionality has been contributed by
underlying modules such as SQL::Builder::GroupBy, SQL::Builder::Join,
SQL::Builder::ColumnList, etc. The benefit of the provided granularity should be
obvious.

All modules currently inherit from SQL::Builder::Base which provides many
methods which makes creating new SQL constructs quick and easy. It also provides
a common base for all constructs which makes subclassing them easy, too. I've found that
most of my time has been spent creating convenience methods so that one can do
more and type less. I tried to keep all database vendors in mind when developing
small constructs, but avoided making any assumptions of how constructs can be
used together; this hopefully will result in awesome portability.

=head1 METHODS

This module doesn't have any methods yet. See one of the modules below. This is
only a summary and might not be 100% accurate, definitely see the module for
complete documentation

=head2 SQL::Builder::Select(3)

	- SELECT statements

=head2 SQL::Builder::AggregateFunction(3)

	 - Subclasses Function.pm, no methods implemented: FUNCTION(arg, arg)

=head2 SQL::Builder::Any(3)

	 - Used to represent anything, useful for subclassing

=head2 SQL::Builder::Base(3)

	 - Common base class/API

=head2 SQL::Builder::BinaryOp(3)

	 - Represent binary operators: LHS OP RHS
	 - Can also do: foo OP bar OP baz OP bang

=head2 SQL::Builder::Column(3)

	 - Represent a SQL column and the table/schema/data to which it belongs
	 - Produces: "column[.table[.schema|database[. ...]]]"

=head2 SQL::Builder::ColumnList(3)

	 - Used to represent the columns used in a SELECT statement because they
	   have special semantics. Inherits List.pm
	 - Produces: anything, anything_possibly_an_alias, blah

=head2 SQL::Builder::Distinct(3)

	 - Used in SELECT statements, maintains ColumnLists
	 - Produces: DISTINCT [ON(anything [, ...])] [anthing, [...]]

=head2 SQL::Builder::Except(3)

	 - Represents the EXCEPT junction
	 - Produces: <anything> EXCEPT <anything>

=head2 SQL::Builder::FromList(3)

	 - Represents the list of tables (or anything) used in SELECT
	 - Produces: FROM anything [, ...] [anything]

=head2 SQL::Builder::FromTable(3)

	 - Represents a table used in a FROM list. Made particularly for
	   stateful usage of table aliases
	 - Produces: table [as Alias] [(col_alias [, ...])]

=head2 SQL::Builder::Function(3)

	 - Stateful representation of a function call and its arguments
	 - Produces: anything(anything [, ...])

=head2 SQL::Builder::GroupBy(3)

	 - Represents GROUP BY anything [, ...]
	 - See SQL::Builder::Group

=head2 SQL::Builder::Having(3)

	 - The HAVING clause
	 - Produces: HAVING anything

=head2 SQL::Builder::In(3)

	 - Representation of the IN operator
	 - Produces: IN(anything [, ...])

=head2 SQL::Builder::Intersect(3)

	 - Another junction representation
	 - Produces: anything INTERSECT anything

=head2 SQL::Builder::Iterator(3)

	 - An iterator object particularly used for walking SQL constructs

=head2 SQL::Builder::Join(3)

	 - Used to represent any JOIN
	 - Produces: [anything] JOIN [anything] [ON anything | USING(anything)]

=head2 SQL::Builder::JoinGroup(3)

	 - Maintains a group of JOINs, useful for nested JOINs
	 - Produces: (anything [\n ...]) AS anything

=head2 SQL::Builder::Junction(3)

	 - A base object for juntions
	 - Produces: anything anything anything

=head2 SQL::Builder::Limit(3)

	 - LIMIT/OFFSET clause
	 - Produces: [LIMIT anything] [OFFSET anything]

=head2 SQL::Builder::List(3)

	 - Used for as a common base for anything that represents a list

=head2 SQL::Builder::Order(3)

	 - Represents an item in the list of ORDER BY
	 - Produces: anything [ASC|DESC]

=head2 SQL::Builder::OrderBy(3)

	 - Represents the list of expressions in ORDER BY
	 - Produces: ORDER BY anything [, ...]

=head2 SQL::Builder::PostfixOp(3)

	 - Representation of postfix operators (like foo++)
	 - Produces: anything anything

=head2 SQL::Builder::PrefixOp(3)

	 - Representation of prefix operators (like ++foo)
	 - Produces: anything anything

=head2 SQL::Builder::Select(3)

	 - Almost everything in a SELECT statement
	 - Produces: ... see SQL::Builder::Select

=head2 SQL::Builder::SubSelect(3)

	 - Representation of a sub SELECT. This may be badly broken

=head2 SQL::Builder::Table(3)

	 - Representation of a relation and the schema/database to which it
	   belongs, and its alias
	 - Produces: table[.anything]

=head2 SQL::Builder::Text(3)

	 - Represents text to be quoted
	 - Produces NULL if undef or 'escaped_text'

=head2 SQL::Builder::UnaryOp(3)

	 - Base class for PrefixOp and PostfixOp
	 - Does not produce anything by itself

=head2 SQL::Builder::Union(3)

	 - Represents UNION junction
	 - Produces: anything UNION anything

=head2 SQL::Builder::Using(3)

	 - Used to represent the USING clause in a JOIN
	 - Produces: USING(anything [, ...])

=head2 SQL::Builder::Where(3)

	 - Maintains an AND list of expressions
	 - Produces: WHERE anything

=head1 TODO

	- Placeholders**
	- Fix circular references**
	- More convenience methods
	- Improved/more tests
	- UPDATE, DELETE support

=head1 LICENSE

Perl Artistic

=head1 AUTHOR

sili@cpan.org -- Feel free to email me with questions, suggestions, etc

=head1 SEE ALSO

perl(1)
SQL::Builder::Select(3)
SQL::Builder::AggregateFunction(3)
SQL::Builder::Any(3)
SQL::Builder::Base(3)
SQL::Builder::BinaryOp(3)
SQL::Builder::Column(3)
SQL::Builder::ColumnList(3)
SQL::Builder::Distinct(3)
SQL::Builder::Except(3)
SQL::Builder::FromList(3)
SQL::Builder::FromTable(3)
SQL::Builder::Function(3)
SQL::Builder::GroupBy(3)
SQL::Builder::Having(3)
SQL::Builder::In(3)
SQL::Builder::Intersect(3)
SQL::Builder::Iterator(3)
SQL::Builder::Join(3)
SQL::Builder::JoinGroup(3)
SQL::Builder::Junction(3)
SQL::Builder::Limit(3)
SQL::Builder::List(3)
SQL::Builder::Order(3)
SQL::Builder::OrderBy(3)
SQL::Builder::PostfixOp(3)
SQL::Builder::PrefixOp(3)
SQL::Builder::Select(3)
SQL::Builder::SubSelect(3)
SQL::Builder::Table(3)
SQL::Builder::Text(3)
SQL::Builder::UnaryOp(3)
SQL::Builder::Union(3)
SQL::Builder::Using(3)
SQL::Builder::Where(3)

=end

