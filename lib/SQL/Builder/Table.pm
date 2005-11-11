#!/usr/bin/perl

package SQL::Builder::Table;

use warnings;
use strict;
use Carp;

use Scalar::Util qw(blessed);

use SQL::Builder::Column;
use SQL::Builder::Base;

use SQL::Builder::List;

use base qw(SQL::Builder::Base);


our $DEFAULT_QUOTER = sub {
	my $self = shift;
	my $var = shift;

	no warnings;

	return "\"$var\""
};

our $QUOTER = $DEFAULT_QUOTER;

sub default_quoter	{
	return $DEFAULT_QUOTER;
}

sub quoter	{
	my $class = shift;

	if(@_)	{
		$QUOTER = shift;
		return $class
	}

	return $QUOTER
}

sub decide_quoter	{
	my $self = shift;

	if(!$self->force_custom_quoting && $self->dbh)	{
		return sub	{
			# get rid of the object
			shift;

			return $self->dbh->quote_identifier(@_)
		}
	}
	elsif($self->quoter)	{
		return $self->quoter
	}
	else	{
		return undef
	}
}

sub force_custom_quoting	{
	return shift->options('force_custom_quoting', @_)
}

sub init	{
	my $self = shift;
	
	{
		my $other = SQL::Builder::List->new;
		$self->other($other);
	}

	$self->schema_elem(0);
	$self->db_elem(1);

	$self->use_as(1);

	$self->columns(SQL::Builder::List->new);

	return $self;
}

sub name	{
	my $self = shift;
	return $self->_set("table", @_)
}

*table = *name;

sub other	{
	my $self = shift;
	return $self->_set("other", @_)
}

sub schema_elem	{
	return shift->options('schema_elem', @_)
}

sub schema	{
	my $self = shift;

	return $self->other->element(
		$self->schema_elem,
		@_
	)
}

sub db_elem	{
	return shift->options('db_elem', @_)
}

sub db	{
	my $self = shift;

	return $self->other->element(
		$self->db_elem,
		@_
	)
}

sub alias	{
	return shift->_set('table_alias', @_)
}

sub quote	{
	return shift->options('quote', @_)
}

sub sql	{
	my $self = shift;

	confess "No table set" unless defined $self->table;
	
	my $other;

		if(UNIVERSAL::can($self->other, 'list'))	{
			
			$other = $self->other->list;
		}
		elsif(ref $self->other ne 'ARRAY') {
			$other = [$self->other];
		}

	my $fqn = join ".", map {

		my $item = $_;
		
		if(blessed $item)	{
			$self->dosql($item)
		}
		else	{

			if($self->quote && $self->decide_quoter)	{
				
				$self->decide_quoter->($self, $item)
			}
			else	{
				$item
			}
		}

	} (reverse(@$other), $self->table);

	return $fqn;
}

sub use_as	{
	return shift->options('use_as', @_)
}

sub alias_sql	{
	my $self = shift;
	my $sql = $self->sql;
	
	return "" unless defined($self->alias) && length($self->alias);

	if($self->use_as)	{
		return "$sql AS " . $self->dosql($self->alias)
	}
	else	{
		return $sql . " " . $self->dosql($self->alias)
	}
}

sub col	{
	my $self = shift;
	
	return SQL::Builder::Column->new(
		'other->list_push' => $self,
		@_
	)
}

sub columns	{
	return shift->_set('column_list', @_)
}

sub children	{
	my $self = shift;

	return $self->_make_children_iterator([
		$self->other,
		$self->table,
		$self->alias
	])
}

1;

=head1 NAME

SQL::Builder::Table - Represent a SQL table syntax

=head1 SYNOPSIS

	# build an object

	my $table = SQL::Builder::Table->new(
		name => "hello",
		alias => "hi",
		'other->list_push' => 'schema',
	);


	# schema.hello
	print $table->sql;

	# modify quoting behavior

	$table->quote(1);
	$table->quoter(sub {return "`$_[1]`"});

	# schema.`hello`
	print $table->sql;

	$table->dbh($some_dbh_for_postgresql);
	
	# schema."hello"
	print $table->sql;

	# we can force the object to use our own
	# quoting mechanism

	$table->force_custom_quoting(1);

	# schema.`hello`
	print $table->sql;

	# turn quoting off
	$table->quote(0);

	# store other information for other modules to use
	$table->alias("foozle");

	# get a column object

	my $col = $table->col(name => foo);

	# schema.hello.foo
	print $col->sql


=head1 DESCRIPTION

This is a child of SQL::Builder::Base(3). This module is capable of representing
SQL table [syntax] and generating SQL::Builder::Column(3) objects. This probably
isn't what one wants for building SELECT queries, see SQL::Builder::FromTable(3).
The way joins are built and represent is likely to change.

=head1 METHODS

=head1 alias([$alias])

Get/set an alias. If an argument is passed the alias is set and current object
is returned. If no arguments are passed, the current alias value is returned.
This method isn't directly useful for this class, but may be used in other
classes such as SQL::Builder::FromTable(3) or SQL::Builder::FromList(3)

=head1 children()

Return SQL::Builder::Iterator(3) object for the values of other(), name(), and alias()

=head2 col(@args)

This generates a SQL::Builder::Column(3) object, adds the current object ($self)
to the list provided by SQL::Builder::Column::other(), and passes @args along to
the constructor

=head2 decide_quoter()

This is a method to determine the appropriate quoting mechanism to use for
identifiers. This method returns undef unless quote() is turned on. If dbh() is
set, then a code ref. that quotes a value is returned, otherwise, the value of
quoter() is returned. If force_custom_quoting() is true, then quoter() is
always returned. When a code ref. is returned, it should accept two arguments.
The first argument is the calling object, the second is the item to be quoted.

=head2 default_quoter()

This method returns the class-default quoting routine

=head2 force_custom_quoting([1|0])

This controls the behavior of decide_quoter(). If this value is true, then items
will always be quoted when quote() is turned on. See decide_quoter() and sql().
When called with arguments the value is set and current object returned,
otherwise the current value is returned

=head2 init()

Calls init() on the parent class, then passes a SQL::Builder::List(3) object to
other()

=head2 other([@other])

Get/set "other" information about a table. Typically this would be schema or
database name. Any value can be passed. If called with a value, the "other"
information is set and current object returned. Otherwise the current value is
returned. It accepts any scalar value, but it should generally be an object or
an array reference. When sql() is called, the value of other() is determined and
converted to a list if possible. If other() is an object with a list() method
that list is used. Otherwise if other() is not an array reference it is wrapped
in one. This list is then traversed in reverse order to generate like so:

	my $table = SQL::Builder::Table->new(
		name => "foo",
		'other->list_push' => ['schema', 'db']
	);

	# db.schema.table
	print $table->sql

	$table->other->list_push('anything');

	# anything.db.schema.table
	print $table->sql

=head2 schema_elem([$idx])
=head2 schema([$schema])

schema_elem() and schema() are convenience methods which wrap calls to the
default list maintained by other() for maintaing information about the schema to
which the current table belongs. schema() basically does:

	$self->other->element(
		$self->schema_elem,
		@args
	)

By default, init() populated schema_elem() with a value of 0, meaning schema()
wraps to element 0 (the first) of the List object. See
SQL::Builder::List::element() for its documentation.

This method will die if other() does not have an element() method. These methods
have the expected behavior: pass arguments to set the values and return the
current object, don't pass any to retrieve current values

=head2 db_elem([$idx])
=head2 db([$db])

db_elem() and db() are just like schema_elem() and schema(), except db_elem() is
populated with a value of 1 by init(). db() and db_elem() are to be used for
tracking information about the database to which the table belongs. It might be
particularly useful to set db_elem() to 0 if the DBMS in use doesn't support
schemas.

If other() doesn't have an element() method, this function will die. The typical
behavior can be expected from these methods

=head2 quote([1|0])

Turn on/off identifier quoting. If a value is passed
to this method, quoting is turned off/on and the current object is returned. If
no arguments are passed, the current quoting value is returned

=head2 quoter([$quote_code])

Get/set the custom quoting routine. If arguments are passed the quoter() routine
is set and current object returned, otherwise the current routine is returned.
The routine must accept two arguments: the
first is the calling object, second is the item to be quoted. It must return the
quoted result. See decide_quoter(), quote() and sql()

=head2 sql()

Return the SQL serialization. The reversed values of other() (see other()), then
name() are traversed. Objects are filtered through dosql(), otherwise if quote()
is turned on and decide_quoter() returns a value, the item in the list is
quoted. Otherwise it is serialized as-is. See the SYNOPSIS for examples

=head2 name([$name])

Get/set the name of the table. If arguments are passed the name of the table is
set and current object returned. If no arguments are passed the current value is
returned.

=head2 table()

An alias for name()

=head2 dbh()

This method is inherited from SQL::Builder::Base(3) so see it for its documentation.
Setting this value changes the behavior of decide_quoter(). If present and usable,
DBI::quote_identifier() will be used for quoting unless force_custom_quoting() is
turned on or quote() is turned off

=head2 use_as([1|0])

This controls the use of the 'AS' keyword used by alias_sql(). If this method
is set to false, the 'AS' keyword is not used; otherwise it is. To set the value
pass the argument, in which case the value will be set and the current object
returned. The current value is returned otherwise. It basically controls whether
or not alias_sql() produces

	table AS alias

or

	table alias

This is turned on (1) by default

=head2 alias_sql()

If alias() returns a value that is defined and has a length, then the return of
sql() is used to generate the SQL required to alias the table. Basically if an
alias is set the following SQL is returned:


	table AS alias

or

	table alias

depending on the value of use_as

=head1 SEE ALSO

SQL::Builder::Base(3)
SQL::Builder::FromList(3)
SQL::Builder::FromTable(3)
SQL::Builder::Column(3)
SQL::Builder::Select(3)
SQL::Builder(3)
