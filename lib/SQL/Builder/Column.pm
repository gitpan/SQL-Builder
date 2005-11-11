#!/usr/bin/perl

package SQL::Builder::Column;

use warnings;
use strict;
use Carp;

use Scalar::Util qw(blessed);

use SQL::Builder::List;
use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

our $DEFAULT_QUOTER = sub {
	my $self = shift;
	my $var = shift;

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

sub use_alias	{
	return shift->options('use_alias', @_)
}

sub has_alias	{
	my $self = shift;
	my $alias = $self->alias;

	return defined($alias) && length $alias
}

sub init	{
	my $self = shift;

	$self->SUPER::init();
	
	{
		my $list = SQL::Builder::List->new();

		$self->other($list);
	}

	$self->use_alias(1);

	return $self;
}

sub col	{
	return shift->_set("col", @_)
}

*name = *col;

sub other	{
	return shift->_set("other", @_)
}

sub alias	{
	return shift->_set('col_alias', @_)
}

sub quote	{
	return shift->options('quote', @_)
}

sub full_name	{
	my $self = shift;

	confess "No column set"
		unless defined($self->col) && length($self->col);
	
	my $other;

		if(UNIVERSAL::can($self->other, 'list'))	{
			
			$other = $self->other->list;
		}
		else	{
			$other = [$self->other];
		}

	my $fqn = join ".", map {

		my $item = $_;
		
		if(blessed $item)	{
			if(UNIVERSAL::can($item, 'alias') && defined($item->alias) && length($item->alias))	{
				
				$self->dosql($item->alias)
			}
			else	{

				$self->dosql($item)
			}
		}
		else	{

			if($self->quote && $self->decide_quoter)	{
				
				$self->decide_quoter->($self, $item)
			}
			else	{
				$item
			}
		}

	} (reverse(@$other), $self->col);

	return $fqn;
}

sub sql	{
	my $self = shift;

	if(defined($self->alias) && length $self->alias)	{
		return $self->dosql($self->alias)
	}
	else	{
		return $self->full_name
	}
}

sub children	{
	my $self = shift;
	return $self->_make_children_iterator([
		$self->other,
		$self->name,
		$self->alias
	])
}

sub references_many	{
	my $self = shift;

	$self->references(shift);
	$self->references_n("many");

	return $self;
}

sub references_one	{
	my $self = shift;

	$self->references(shift);
	$self->references_n("one");
}

sub references	{
	return shift->_meta('references', @_)
}

# one|many
sub references_n	{
	return shift->_meta('references_n', @_)
}

sub is_primary	{
	return shift->_meta('is_primary', @_)
}

sub data_type	{
	return shift->_meta('data_type', @_);
}

1;

=head1 NAME

SQL::Builder::Column - Represents a SQL table column

=head1 SYNOPSIS

This class inherits from SQL::Builder::Base(3) and generates the following SQL:

	[[... .]schema.]table.]colname

or

	colalias

This module has support for custom field quoting or automatic quoting via DBI's
quote_identifier(). Here's how to use it:

	my $col = SQL::Builder::Column->new(
		name => 'colname', # or: col => 'colname'
		alias => 'alias',
		'other->list_push' => [qw(table schema catalog)]
	);

	# alias
	print $col->sql;

	# turn on quoting

	$col->quote(1);

	# "catalog"."schema"."table"."colname"
	print $col->full_name;

	# override the built in quoting mechanism with DBI::quote_identifier()
	$col->dbh($dbh);

=head1 METHODS

This class inherits from SQL::Builder::Base(3)

=head2 new()

See SQL::Builder::Base::new() and SQL::Builder::Base::set() for documentation on
this - it's an inherited method

=head2 alias([$alias])

Use this to get/set the alias of the column.

=head2 col([$colname])

Use this to get/set the column name. When you set it, the current object is
returned

=head2 decide_quoter()

This probably doesn't need to be called directly. It is called in sql() or
full_name() when the quoting mechanism needs to be determined. When dbh() is
set we return a coderef that wraps a call to DBI::quote_identifier($item),
unless force_custom_quoting() is set, in which case quoter() is returned.

=head2 default_quoter()

This just returns the builtin quoting mechanism so you can use it in the event
quoter() has been changed

=head2 force_custom_quoting([1|0])

This method is used to get/set the option to force custom quoting (ie, use the
quoter set via quoter()) of identifiers. This will ignore the availability of dbh(), but still
only works when quote() is turned on. Returns the current object when called
with arguments

=head2 full_name()

This returns the fully qualified SQL representation of the column. eg,

	[[... .]schema.]table.]colname

SQL::Builder::Base::dosql() is called for all objects returned by col() and other() and joined by a
period "." - this means that a BinaryOp objects can be passed and aliased for
use in a SELECT statement. Non-objects are quoted if quote() is turned on and
decide_quoter() returns a coderef. A quoted SQL serialization might look like:

	"schema"."table"."colname"

Notice that each identifier is quoted individually. Objects are not quoted
because their SQL serialization (sql()) is expected to perform any necessary
quoting. This allows a table object to be passed to other() and its own quoting
mechanisms can be used.

When the value of other() is processed and an item in the list is an object that
has an alias() method that returns something defined and with a length, the
alias is used instead. Consider the following:

	my $users   = SQL::Builder::Table->new(name => "users", alias => "u");

	my $user_id = SQL::Builder::Column->new(
			name => "user_id",
			other => $users
		);

	# u.user_id
	print $user_id->sql

This method throws an error if no column is set

=head2 init()

This call's SQL::Builder::Base::init() then sets some defaults. It returns the
current object. See SQL::Builder::Base(3) for documentation on this method. This
is just an initialization method and probably shouldn't be called directly.

=head2 other()

other() returns a SQL::Builder::List(3) object. Its purpose is to store catalog
information about the schema/table/whatever to which the column belongs and
ultimately turns into "schema.table" upon SQL serialization. The Column
object doesn't rely on SQL::Builder::List::sql(), it simply uses List.pm for the
list interface which may become useful in the future. It is possible to change
the maintained list object and swap it with a SQL::Builder::List(3) subclass
without breakage - just pass the object to other().

The maintained list can be infinitely long or empty and no assumptions or
constraints will be placed on what is in the list or how it should be used.
Upon SQL serialization this list is reversed - this means
arguments should be passed in order of magnitude from smallest to largest. For
example, tables are defined in schemas which belongs to databases, so we'll
build our Column object like so:

	$col->other->list_push(qw(table schema db))

and when serialized, the list will be reversed and turn into something like:

	db.schema.table

For maximum code reuse, it might be wise to pass a SQL::Builder::Table(3) object
and have it as the only list item. Any object passed here will be processed
as SQL::Builder::Base::dosql($obj) on SQL serialization (sql()); non-objects are
subject to quoting (see full_name())

=head2 quoter([$quote_coderef])

This is used to get/set the custom quoter. This is a class method, not an object
method. If you set it once, it will be used for all Column objects without a
dbh() set (see decide_quoter()). When called with an argument, the class/object is returned.
Otherwise, the subroutine is returned. By default, the quoting
routine is basically:

	return "\"$var\""

The method set here will be called on each element provided by col() and other()
if a dbh() isn't available (see decide_quoter()). The quoting routine should
accept the current object (think $self) as the first argument, and the item to
be quoted as the second argument

=head2 quote([1|0])

This is used to turn on and off quoting. If turned off, dbh() and quoter() are
ignored

=head2 sql()

If use_alias() is on, and the alias is defined and has a length, it is returned. otherwise, full_name()
is returned

=head2 use_alias([1|0])

When turned on, this option affects the result of sql() and causes it to return
the column alias if it is available. It is turned on (1) by default. When turned
off, sql() will always return the value returned by full_name(). If use_alias()
is called with no arguments, the current value is returned

=head1 METHODS TO IGNORE

The following methods are only used for some of my experimenting. Please ignore them
completely.

=head2 references([$obj])

Useful for tracking information about whether or not this column is a foreign
key, and determine where/what it references. Pass a value to set it and return
the current object; don't pass any to return the current reference. See
references_n() for keeping track of the sort of relationship. Typically the
object passed here is a SQL::Builder::Column(3) object as it will help determine
which column of which table is being referenced

=head2 references_n([one|many])

If this field is a foreign key, keep track of the relationship type. eg, "many
to many", "one to many" etc. Pass "one" or "many" to set the relationship type
and return the current object; don't pass any arguments to get the current
value. See references(), references_one(), references_many()

=head2 references_one($obj)

=head2 references_many($obj)

references_one() and references_many() are convenience method. The required
argument that is passed is passed to references(), then references_n("one") or
references_n("many") is called accordingly. The current object is always
returned

=head2 is_primary([1|0])

Toggle whether or not this field is a primary key. Pass an argument to turn it
on/off and return the current object, don't pass arguments to retrieve the
current value.

=head2 data_type([$type])

Get/set the data type of the column. The value can be anything desired, it's left
to the implementor to decide. Pass arguments to have the value set and current
object returned; don't pass any to return the current value.

=head2 has_alias()

Returns true if alias() returns a value that is defined and has a length - basically
specifiying that the column has an alias

=head1 SEE ALSO

SQL::Builder::Base(3)
SQL::Builder::ColumnList(3)
SQL::Builder::List(3)
DBI(3)
