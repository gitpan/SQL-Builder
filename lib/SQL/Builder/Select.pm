#!/usr/bin/perl

package SQL::Builder::Select;

use warnings;
use strict;

use Carp qw(confess);


use SQL::Builder::Distinct;
use SQL::Builder::FromList;
use SQL::Builder::Where;
use SQL::Builder::GroupBy;
use SQL::Builder::Having;
use SQL::Builder::OrderBy;
use SQL::Builder::Limit;


use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

#
#	SELECT [ ALL | DISTINCT [ ON ( expression [, ...] ) ] ]
#	    * | expression [ AS output_name ] [, ...]
#	    [ FROM from_item [, ...] ]
#	    [ WHERE condition ]
#	    [ GROUP BY expression [, ...] ]
#	    [ HAVING condition [, ...] ]
#	    [ { UNION | INTERSECT | EXCEPT } [ ALL ] select ]G
#	    [ ORDER BY expression [ ASC | DESC | USING operator ] [, ...] ]
#	    [ LIMIT { count | ALL } ]
#	    [ OFFSET start ]
#	    [ FOR UPDATE [ OF table_name [, ...] ] ]
#
#	where from_item can be one of:
#
#	    [ ONLY ] table_name [ * ] [ [ AS ] alias [ ( column_alias [, ...] ) ] ]
#	    ( select ) [ AS ] alias [ ( column_alias [, ...] ) ]
#	    function_name ( [ argument [, ...] ] ) [ AS ] alias [ ( column_alias [, ...] | column_definition [, ...] ) ]
#	    function_name ( [ argument [, ...] ] ) AS ( column_definition [, ...] )
#	    from_item [ NATURAL ] join_type from_item [ ON join_condition | USING ( join_column [, ...] ) ]
#

sub init	{
	my $self = shift;

	$self->SUPER::init;

	my $distinct = SQL::Builder::Distinct->new;
		$distinct->options(distinct => 0);
		$self->_distinct($distinct);
	
	my $from = SQL::Builder::FromList->new;
		$self->tables($from);
	
	my $where = SQL::Builder::Where->new;
		$self->where($where);

	my $group = SQL::Builder::GroupBy->new;
		$self->groupby($group);

	my $having = SQL::Builder::Having->new;
		$self->_having($having);

	my $orderby = SQL::Builder::OrderBy->new;
		$self->orderby($orderby);

	my $limit = SQL::Builder::Limit->new;
		$self->_limit($limit);
	
	return $self
}

# get the list obj containing select cols
sub cols	{
	return shift->_distinct->cols(@_)
}

# get the distinct_on list
sub distinct_on	{
	return shift->_distinct->on(@_)
}

# the internal distinct object
sub _distinct	{
	return shift->_set('distinct', @_)
}

# turn on/off distinct
sub distinct	{
	my $self = shift;
	
	if(@_)	{
		return $self->_distinct->distinct(@_)
	}
	else	{
		return $self->_distinct->distinct
	}
}

# list obj of tables
sub tables	{
	return shift->_set('fromlist', @_)
}

# list obj of joins
sub joins	{
	return shift->tables->joins(@_)
}

# list obj of AND for exprs
sub where	{
	return shift->_set('where', @_)
}

# list obj of groups
sub groupby	{
	return shift->_set('groupby', @_)
}

# obj of having
sub _having	{
	return shift->_set('having', @_)
}

# list obj of binary op AND
sub having	{
	return shift->_having->expr(@_)
}

# list obj of order by
sub orderby	{
	return shift->_set('orderby', @_)
}

# limit obj
sub _limit	{
	return shift->_set('limit', @_)
}

# limit val
sub limit	{
	return shift->_limit->limit(@_)
}

# offset val
sub offset	{
	return shift->_limit->offset(@_)
}

sub sql	{
	my $self = shift;
	
	# just one thing
	my $sql = "SELECT" ;

	#distinct
	$sql .= " " . $self->dosql($self->_distinct);

	#tables -- make sure we have some or throw an error
	$sql .= "\n" . $self->dosql($self->tables);

	confess "Expecting at least one table in SELECT"
		unless length($self->dosql($self->tables)) && defined $self->dosql($self->tables);

	# where clause
	$sql .= "\n" . $self->dosql($self->where);

	#groupby
	$sql .= "\n" . $self->dosql($self->groupby);

	#having
	$sql .= "\n" . $self->dosql($self->_having);

	#order
	$sql .= "\n" . $self->dosql($self->orderby);

	#limit
	$sql .= "\n" . $self->dosql($self->_limit);
	
	return $sql
}

sub children	{
	my $self = shift;
	return $self->_make_children_iterator([
		$self->_distinct,
		$self->tables,
		$self->where,
		$self->groupby,
		$self->_having,
		$self->orderby,
		$self->_limit,
	])
}

1;

=pod

=head1 NAME

SQL::Builder::Select - Represent a SQL SELECT statement

=head1 SYNOPSIS

	In the following examples I'll be using figurative database tables that
	look like:

	users
	---------
	user_id
	name
	age
	salary_id

	salaries
	---------
	salary_id
	salary_amount

Most of the functionality provided by this module is provided by the various
classses is uses. This module actually does very little.

	# new select object

	my $sel = SQL::Builder::Select->new;

	# add a table

	$sel->tables->add_table(table => "users", alias => "u");

	# SELECT * FROM users AS u
	print $sel->sql;

We can add more tables to the table list like so:

	$sel->tables->add_table(table => "salaries", alias => "sals");

	# SELECT * FROM users AS u, salaries AS sals
	print $sel->sql;

And of course add a WHERE clause

	$sel->where->list_push("u.salary_id = sals.salary_id");

Suppose the database supports JOINs, we can use those to:

	my $sel = SQL::Builder::Select->new();

	$sel->tables->add_table(table => "users", alias => "u");

	$sel->tables->add_join(
		table => "salaries",
		'using->expr->list_push' => "salary_id"
	);

	# SELECT * FROM users AS u JOIN salaries USING (salary_id)

Since we care about state, we can do the same thing, except more statefully, and
instead of using the USING operator, we'll use ON for the join:
	
	# I'm using globals for simplicity. Please don't do it in code that
	# matters


	# define a users table
	our $tbl_users    = SQL::Builder::Table->new(
				name => "users",
				alias => "u"
			);
	
	# define the salaries table
	our $tbl_salaries = SQL::Builder::Table->new(
				name => "salaries",
				alias => "sals"
			);


	sub get_user_pay	{
		
		# declare a new SELECT object
		my $sel = SQL::Builder::Select->new();
		
		
		# add the users table to the SELECT list
		$sel->tables->list_push($tbl_users);
		
		# join against the salaries table
		$sel->tables->joins->list_push(
			SQL::Builder::Join->new(
				table => $tbl_salaries,
				'on->list_push' => SQL::Builder::BinaryOp->new(
					op  => "=",
					lhs => $tbl_salaries->col(name => 'salary_id'),
					rhs => $tbl_users->col(name => 'salary_id')
				)
			)
		);

		return $sel
	}

Now that we have a stateful representation of our query, it's easy to reuse and
modify:

	my $query = get_user_pay();

	# suppose we only want the user_id and salary_amount columns returned

	$query->cols->list_push(
	    $tbl_users->col(name => 'user_id'),
	    $tbl_salaries->col(name => 'salary_amount')
	);

	# SELECT u.user_id, sals.salary_amount
	# FROM users AS u
	# JOIN salaries AS sals ON sals.salary_id = u.salary_id

We can also filter the results by using a WHERE clause. The following will
return users who earn more than $20,000

	$query->where->list_push(
		SQL::Builder::BinaryOp->(
			op  => ">",
			lhs => $tbl_salaries->col(name => 'salary_amount'),
			rhs => 20_000
		)
	);

	# SELECT u.user_id, sals.salary_amount
	# FROM users AS u
	# JOIN salaries AS sals ON sals.salary_id = u.salary_id
	# WHERE u.salary_amount > 20000

But that's not all, we can use a "macro" to modify the query to return all users who
have a salary of less than $20,000. We'll just flip all instances of ">" with
"<":

	# find all objects in the WHERE clause with an op()
	# method that returns ">"

	my $iterator = $query->where->look_down(
		op => ">"
	);

	while($iterator->pull)	{
		my $binary_op = $iterator->current;
		
		# flip the sign
		$binary_op->op("<");
	}

	# SELECT u.user_id, sals.salary_amount
	# FROM users AS u
	# JOIN salaries AS sals ON sals.salary_id = u.salary_id
	# WHERE u.salary_amount < 20000

For databases that support them, we can easily limit the amount of results also:

	$query->limit(10);

	# SELECT u.user_id, sals.salary_amount
	# FROM users AS u
	# JOIN salaries AS sals ON sals.salary_id = u.salary_id
	# WHERE u.salary_amount > 20000
	# LIMIT 10

pagination is also useful:

	$query->offset(10);

	# SELECT u.user_id, sals.salary_amount
	# FROM users AS u
	# JOIN salaries AS sals ON sals.salary_id = u.salary_id
	# WHERE u.salary_amount > 20000
	# LIMIT 10 OFFSET 10

There is also support for the other common constructs:
	
	# ORDER BY u.name, sals.salary_amount
	$query->orderby->list_push(
		$tbl_salaries->col(name => 'salary_amount')
	);

	# GROUP BY u.user_id, sals.salary_amount
	$query->orderby->list_push(
		$tbl_users->col(name => 'user_id'),
		$tbl_salaries->col(name => 'salary_amount'),
	);

	# DISTINCT 
	$query->distinct(1);

	# HAVING
	$query->having(SQL::Builder::BinaryOp->new(
		op  => ">",
		lhs => SQL::Builder::AggregateFunction->new(
			name => 'COUNT',
			args => "*"
		),
		rhs => 0
	))

=head1 DESCRIPTION

SQL::Builder::Select is a child of SQL::Builder::Base(3). Its functionality is
provided by the objects it implements. These objects can be changed and even
removed; any replacements will be passed through SQL::Builder::Base::dosql()
before SQL serialization (sql()). It's possible to use these objects without
provided a state (using strings instead of objects), but that would defeat much
of the purpose of SQL::Builder.

Some of the example code in the SYNOPSIS is rather wordy, but the future
interface will expected to be a little more lightweight. At the very least I
expect to have exportable functions that wrap to the object constructors. The
more intelligent way of removing wordiness is to subclass the objects you use.
This will allow you to apply more useful defaults and states to the objects or
constructs used in SQL queries. In the above example, it would have been wise to
subclass SQL::Builder::Table for the "users" and "salaries" table. Through these
we could encapsulate table name, alias, and write convenience methods. Instead
of writing
	
	$tbl_users->col(name => 'user_id')

one can write

	Users->user_id

Future docs should cover this in more depth.

=head1 METHODS

=head2 _distinct()

A private method used to get/set the object used for managing the SELECT
columns and toggle the DISTINCT keyword. When called with arguments, the value
is set and current object ($self) is returned. Otherwise the value (or
SQL::Builder::Distinct(3) object by default) is returned. distinct(), sql(),
cols(), and distinct_on() rely on this method to act like
SQL::Builder::Distinct(3) does.

=head2 _having()

A private method used to get/set the object used for manaing the HAVING clause.
When called with arguments, the value is set and current object is returned;
otherwise the current value (SQL::Builder::Having(3) by default) is returned.
having() and sql() rely on this method to be like SQL::Builder::Having(3)

=head2 _limit()

A private method used to get/set the object used for manaing the LIMIT/OFFSET
clauses.
When called with arguments, the value is set and current object is returned;
otherwise the current value (SQL::Builder::Limit(3) by default) is returned.
limit(), offset() and sql() rely on this method to be like SQL::Builder::Limit(3)

=head2 children()

Return a SQL::Builder::Iterator(3) object to iterate over the values returned by 
_distinct(), tables(), where(), groupby(), _having(), orderby(), and _limit()

=head2 cols(@args)

This is a wrapper to _distinct()->cols(@args) which represents the columns used
in a SELECT clause. See SQL::Builder::Distinct::cols()

=head2 distinct([0|1])

This can be used to turn on/off the DISTINCT keyword in a SELECT statement. When
called with arguments, the keyword is turned on and distinct_on() values are
effective... See SQL::Builder::Distinct(3). This method is wrapped using the
object returned by _distinct()

=head2 distinct_on()

This is a wrapper to SQL::Builder::Distinct::on() which maintains a
SQL::Builder::List(3) object by default. See SQL::Builder::Distinct(3). The
object on which on() is called is obtained through _distinct()

=head2 groupby()

Get/set the groupby() object. This probably won't need to be called with
arguments, but if it is, the value is set to the first argument and current
object is returned; otherwise the current value (a SQL::Builder::GroupBy(3)
object by default) is returned. Typical usage is like:

	$select->groupby()->list_push("user_id");

which yields

	GROUP BY user_id

See SQL::Builder::GroupBy(3) and SQL::Builder::Group(3) for more information

=head2 having()

This is a wrapper to SQL::Builder::Having::expr() which is populated with an
"AND" SQL::Builder::BinaryOp(3) object. The object on which expr() is called is
obtained through _having(). Typical usage is:

	$select->having->list_push("foo > 10");
	$select->having->list_push("bar > 20");

which should return something like:

	HAVING foo > 10 AND bar > 20

See SQL::Builder::Having(3) and _having()

=head2 joins()

This is a wrapper to SQL::Builder::FromList::joins() which is called on
tables(). This is used to add JOINs to the SELECT statement

	$select->joins->list_push("JOIN salaries AS sals USING (salary_id)");

=head2 init()

This calls init() on the parent class and sets up the various members with
default objects. See the rest of the documentation...

=head2 limit()

This is a wrapper to SQL::Builder::Limit::limit(), which is called on _limit()

	$select->limit(10);

yields

	LIMIT 10

See SQL::Builder::Limit(3)

=head2 offset()

This is a wrapper to SQL::Builder::Limit::offset(), which is called on _limit()

	$select->offset(10);

yields

	OFFSET 10

See SQL::Builder::Limit(3)

=head2 orderby()

Get/set the object used to manage the ORDER BY clause. By default this is
populated with a SQL::Builder::GroupBy(3) object, but can be replaced by passing a
new value, in which case the current object ($self) is returned. If no no
arguments are passed, the current value is returned.

	$select->orderby->list_push("user_id DESC");

yields

	ORDER BY user_id DESC

See SQL::Builder::OrderBy(3) and SQL::Builder::Order(3)

=head2 sql()

This method generates the SQL serialization of the object by passing the values
of _distinct(), tables(), where(), groupby(), _having(), orderby(), and _limit()
through SQL::Builder::Base::dosql() and assembling the results to construct a
SELECT statement. SQL::Builder makes few assumptions about what is valid SQL, so
expect bad code to generate bad SQL. If no tables are set, this method will
throw an exception. The SQL string is returned

=head2 tables()

By default this method returns a SQL::Builder::FromList(3) object, but can be
replaced by passing an argument; if an argument is passed, the value is set and
current object returned - otherwise the current value is returned. Typically
this method is used like

	$select->tables->list_push("users");
	$select->tables->joins->list_push("JOIN salaries USING (salary_id)");

which generates something like

	...
	FROM users JOIN salaries USING (salary_id)
	...

=head2 where()

This is the container for the WHERE clause. By default it's populated with a
SQL::Builder::Where(3) object so manipulating the WHERE clause is easy. The
WHERE object can be replaced by passing the replacement as an argument, in which
case the value is set and current object is returned, otherwise the current
value is returned. Typically

	$select->where->list_push("foo > 10")

will generate

	WHERE foo > 10

=head1 SEE ALSO

SQL::Builder(3)
SQL::Builder::Distinct(3)
SQL::Builder::Limit(3)
SQL::Builder::GroupBy(3)
SQL::Builder::Group(3)
SQL::Builder::Having(3)
SQL::Builder::Base(3)
SQL::Builder::FromList(3)
SQL::Builder::Table(3)
SQL::Builder::Join(3)
SQL::Builder::OrderBy(3)
SQL::Builder::Order(3)
SQL::Builder::Where(3)

SQL::Builder::Update(3)
SQL::Builder::Delete(3)
