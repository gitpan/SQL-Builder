#!/usr/bin/perl
package SQL::Builder;

$VERSION = "0.033";

#use 5.008005;
use strict;
use warnings;

our $VERSION = '0.033';

use SQL::Builder::Table;
use SQL::Builder::Select;
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

sub qtable	{ return SQL::Builder::Table->new(@_) }
sub qselect	{ return SQL::Builder::Select->new(@_) }
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

Version 0.033 ALPHA - this software isn't production-ready yet and the API is
likely to change. Some methods and functionality aren't documented completely
and some documentation exists without the functionality. USE AT YOUR OWN RISK

=head1 SYNOPSIS

THIS IS CURRENTLY UNSTABLE SOFTWARE. DO NOT USE IT IN PRODUCTION CODE; IT IS STILL
UNDERGOING DEVELOPMENT. THE CURRENT TESTS COMPILE AND MOST FUNCTIONALITY SHOULD WORK,
BUT I MAKE NO GUARANTEE

SQL::Builder is a collection of modules sharing common interfaces for SQL
manipulation with the goal of providing maximum reuse and scalability. It is
not specifically a SQL abstraction (although it does sort of abstract it out
for you in some cases), but a structured interface for its manipulation. Because
SQL::Builder is a stateful interface, one's SQL is as portable as they write it,
with the possibility to traverse a SQL construct at runtime and, for example,
convert instances of MySQL's OR operator ("||") with an appropriate "OR", or to
replace the standard concatenation operator ("||"), to MySQL's "CONCAT".

SQL::Builder's goal is not SQL portability, object-relation mapping, or
abstraction. SQL::Builder would hopefully provide a solid foundation for all of
these ideas.

=head1 PROPAGANDA

I had spent a lot of time trying to gather my reasoning for developing
SQL::Builder and why it's better than any current SQL abstraction/generation
mechanism I've encountered, but it turns out that SQL::Builder is nothing
special and the concepts on which it is based are not new. There are existing
modules which have similar goals and have somewhat similar approaches, but I've
found them to be a bit overwhelming for most needs. My
reasoning/advocation for SQL::Builder bottom-lines reasoning for object-oriented
programming: granularity, encapsulation, reuse, etc.

SQL::Builder is a collection of granular objects that share a common base,
which allow them to interact easily, consitently, and flexibly without the
"overhead" (problems) created by certain abstraction/generation modules. I hope
that at some point, ORMs, SQL abstractions, et. al. will
utilize SQL::Builder as a base for their provided functionality. Building
components with consistent and meaningful interfaces from the ground up is vital
for any system that needs to work.

I will outline some of the problems with existing SQL abstraction/generation
mechanisms that are solved by SQL::Builder.

=head2 String Manipulation

Building queries dynamically based on user data (or similar) is a nasty job and
often results in difficult-to-debug, unmaintainable code. The need to manipulate
strings based on a variety of criteria will clutter code and obfuscate it
quickly.

SQL phrasebooks/templates are the worst; they should be avoided like a plague.
Their initial requirements usually appear basic, but user demands change, so the
code changes. Joe Coder usually adds arguments to a function to control its
return, essentially trying to harness the power of SQL in a single function.
Then he does it again... and again. join(), map(), keys(), etc are applied
liberally until the job is done. What's left is code like this:
	
	# taken from SQL::Abstract::select()

	my $f = (ref $fields eq 'ARRAY') ? join ', ', map { $self->_quote($_) } @$fields : $fields;
	my $sql = join ' ', $self->_sqlcase('select'), $f, $self->_sqlcase('from'), $table;

and it's everywhere. Using functions and objects to hide the work will help
with this process, but they must be granular to be effective on a large scale

=head2 Basic Data Structures

The smart programmers will often develop or use a library like DBIx::Abstract
because it helps reduce the amount of string manipulation and allows SQL to
built a little bit faster and cleaner. The typical interface (taken from
DBIx::Abstract) usually looks something like:

	select($fields,[$table,[$where[,$order]]])

	select({fields=>$fields,table=>$table[,where=>$where][,order=>$order][,join=>$join][,group=>$group]})

Basically we pass "vague data structures" which represent some piece of SQL.
This is a start, but the effort is incomplete. In the process of building a
query, the programmer is required to maintain the list of columns in a SELECT,
the tables it JOINs, and the order in which results are displayed. The code is
usually something like:

	if(foo())	{

		push @cols, "username"
		push @joins, "users";

		$users_was_joined = 1;
	}

	if(bar())	{
		
		if(!$users_was_joined)	{

			push @joins, "users";
		}

		push @cols, "birthdate";
		push @cols, "zipcode";
	}

	$dbh->select(\@cols, \@tables, \@joins ...

The dirty job of string manipulation has mostly (note I said
"mostly": at some point modules like DBIx::Abstract break and force one to write
SQL - consider writing a query to SELECT MAX(...)) been cleaned up, but the
messy job of maintaing state of our query is still there. Joe Coder needs to
keep track of all his columns, joins, and WHERE clause manually until he can
hand them off to select().

The intelligent solution here would be to turn the arguments into object
attributes and build intelligent methods around them. This can't all be in one
class, though; it would hurt reusability and flexibility. Components need to be
granular and stateful.

=head2 Query Objects

Once Joe Coder realizes that objects will solve many of his problems, he can't
just code up an object to represent a SELECT statement, another for UPDATE, and
yet another for DELETE. These operations/objects have way too much in common and
require too much functionality to be sloppily placed in so few classes. SQL
statements should be built from the ground up and given common interfaces where
possible. The goal is to obtain perfect granularity so that larger objects can
be composed as necessary without decreasing flexibility or repeating/copying (not
reusing) code. Without common interfaces, these objects won't fit together
easily.

=head2 ORM / Object Modeling

The ORM hype/buzz/movement is a movement in the right direction, but they (like the
aforementioned) have serious problems. In a simple system, these ORMs do a good
job abstracting SQL and building relationships, but at some point the complexity
of relationships may forces a programmer to write SQL. This is especially
problematic because these ORMs build SQL using one of the aforementioned broken
implementations. Reusing logic in these ORMs is often difficult or
impossible. If, at the point an ORM fails, one can easily utilize existing logic
to inifnitely reuse and abstract it while maintaining state of it, a flexible and
scalable system is possible.

=head1 GETTING STARTED

SQL::Builder is a relatively simple set of modules but the number of them may be
overwhelming. Reading SQL::Builder::Select(3) then SQL::Builder::Base(3) should
provide a nice overview over some of the internals and module usage. Once the
overall picture is understood, it should be a little easier to see how the
pieces fit together.

While using these modules it's helpful to remember that they inherit from a
common base and thrive on interface consistency. Here are a few key points to
keep in mind:

	* Get/set behavior is implemented with common functions. When arguments
	  are passed, "set" behavior is assumed. This means that a value will be
	  set (or stored), and for convenience the current object (think $self)
	  is returned. This makes chaining calls easier:

	  	$foo->bar(10)->baz(50)

	  When called without arguments, the current value (of whatever) is
	  returned

	* sql() methods will filter all children (see SQL::Builder::Base(3))
	  through SQL::Builder::Base::dosql()

	* SQL::Builder doesn't much care for the validity of SQL. It doesn't
	  care which database vendor is being used or what SQL constructs it
	  supports. SQL::Buider will let the user mix and use components as
	  necessary without placing restrictions; this means it's possible to
	  generate SQL syntax errors

	* No object should be referenced twice within the same tree

=head1 SQL::Builder OBJECT SUMMARY

=head2 SQL::Builder::Select(3)

	- SELECT statements

=head2 SQL::Builder::AggregateFunction(3)

	 - Subclasses Function.pm, no methods implemented: FUNCTION(arg, arg)

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

=head2 SQL::Builder::Placeholder(3)

	- Intelligently apply placeholders to your SQL

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

	See the TODO file

=head1 LICENSE

Perl Artistic

=head1 AUTHOR

sili@cpan.org -- Feel free to email me with questions, suggestions, etc

=head1 CREDITS

Sam Vilain - bugs, tests

=head1 CONTACT / GETTING INVOLVED

sili@cpan.org

feenode / #perl

irc.perl.org / #dbix-class

DBIx::Class mailing lists (temporarily)

=head1 GETTING HELP

See "CONTACT / GETTING INVOLVED"

=head1 BUGS

I'm sure there are plenty. See the BUGS file for known issues

=head1 SEE ALSO

SQL::Builder::Select(3)
SQL::Builder::AggregateFunction(3)
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
SQL::Builder::Placeholder(3)
SQL::Builder::Select(3)
SQL::Builder::SubSelect(3)
SQL::Builder::Table(3)
SQL::Builder::Text(3)
SQL::Builder::UnaryOp(3)
SQL::Builder::Union(3)
SQL::Builder::Using(3)
SQL::Builder::Where(3)

=cut

