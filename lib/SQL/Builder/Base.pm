#!/usr/bin/perl

package SQL::Builder::Base;

use warnings;
use strict;

use Carp qw(confess);
#use Scalar::Util qw(blessed weaken);
use Data::Dumper;
#use Clone;

#use overload '""' => \&stringify;
#sub stringify	{ return shift->sql }

use SQL::Builder::AnyObject;
use SQL::Builder::Iterator;

use base qw(SQL::Builder::AnyObject);

our %ID;

# the constructor
# pass set() arguments

sub new	{
	my $class = shift;
		$class = ref($class) || $class;

	my $self = $class->SUPER::new(@_);

	$self->id(1 + keys %ID);

	return $self;
}

sub id	{
	my $self = shift;
	
	if(@_)	{

		$ID{$_[0]} = $self;
	}

	return $self->_set('ID', @_)
}


# get the SQL representation of an object
# called with an option hashref of context

sub sql	{
	confess "sql() method not implemented"
}

# if an object can sql() the method is called and its result is returned
# otherwise, the var will be returned

sub cansql	{
	return UNIVERSAL::can($_[1], 'sql')
}


sub dosql	{
	my $class = shift;

	if($class->cansql($_[0], 'sql'))	{
		return $_[0]->sql
	}
	else	{
		return $_[0]
	}

}


# mark the child object's parent as the current object,
# call mark_

sub mark_parents	{
	my $self = shift;

	my $child_it = $self->children;

	return unless $child_it;

	while($child_it->pull)	{
		
		if($self->is_sb($child_it->current))	{
			
			$child_it->current->parent($self);
			$child_it->current->mark_parents;
		}
	}
}

# check to see if something is a SQL::Builder::Base
sub is_sb	{
	my $self = shift;
	return UNIVERSAL::isa(shift, __PACKAGE__)
}


# useful for certain implementations of an object type

sub make_instance	{
	my $class = shift;
	my @args = @_;

	return sub	{
		return $class->new(@args, @_)
	}
}

############ TREE NAVIGATION METHODS

# get/set the parent/current owner of the element if applicable

sub parent	{
	my $self = shift;
	
	confess "Cannot set parent to self"
		if $self->is_sb($_[0]) && $_[0]->id eq $self->id;
	
	return $self->_set('_parent', @_)
}


# return an iterator for all of the 

sub parents	{
	my $self = shift;
	my $obj = $self;
	
	# return unless we have at least one parent
	#return () unless defined $self->parent;

	return SQL::Builder::Iterator->new(sub{
		my $it = shift;
		
		# return an empty list if we're exhausted
		return () if $it->exhausted;
		
		$obj = $obj->parent;

		if(defined $obj)	{
			$it->set_current($obj);
			$it->hist_push($obj);
			return 1
		}
		else	{
			$it->set_exhausted(1);
			return ()
		}
	});
}


# make an iterator given a aref

sub _make_children_iterator	{
	my ($self, $list) = @_;
	my $i = 0;

	#return () unless @$list;

	return SQL::Builder::Iterator->new(sub	{
		my $it = shift;
		
		# exit if we're exhausted
		return () if $it->exhausted;
		
		# or if there aren't any elements or we've gone too far
		return () unless @$list && $i < @$list;
		
		# get the next item, tell the $it where we are
		$it->set_current($$list[$i]);
		
		# keep track of where we've been
		$it->hist_push($it->current);
		
		# don't iterate infinitely
		$i++;

		return 1;
	});
}


# get an iterator for the elements. returns empty list if none.
# should return a child iterator or list depending on context

sub children	{
	# empty
	return
}


# determine the class type of an object

sub type	{
	my ($self, $check) = @_;

	return UNIVERSAL::isa($self, $check) unless defined $check;

	return ref $self
}


# is this object exactly a type

sub is	{
	my ($self, $check) = @_;

	return defined($check) && ref($self) eq $check
}

# a child method
# should normally implement _has
# throws an exception
# sub has{}

sub _find_is_interesting	{

	my ($self, $node, $args) = @_;

	confess "\$args should be a hashref"
		unless ref($args) eq 'HASH';

	my $failed = 0;

	foreach my $attr (keys %$args)	{

		# skip special commands
		next if $attr =~ /^_[A-Z_]+/;

		my $check = $$args{$attr};
		
		# _class => 'SQL::Builder::BinaryOp'
		if($attr eq '_class')	{
			$failed = 1
				unless ref $node eq $check
		}

		# _isa => 'SQL::Builder'
		elsif($attr eq '_isa')	{
			$failed = 1
				unless UNIVERSAL::isa($node, $check)
		}
		
		# _re => qr/elashduie/
		elsif($attr eq '_re')	{
			$failed = 1
				unless defined($node) && $node =~ /$check/;
		}

		# _code => sub{}
		elsif($attr eq '_code')	{
			$failed = 1
				unless $check->($self, $node)
		}

		# * => sub {}
		elsif(ref $check eq 'CODE')	{
			$failed=1
				unless $check->($self, $node, $attr);
		}
		
		# just check that $node can $attr before we check anything else
		elsif(!UNIVERSAL::can($node, $attr))	{
			$failed = 1
		}
		
		# attr => undef
		elsif(!defined $check)	{
			$failed = 1
				unless defined $node->$attr
		}

		# attr => [qw(1 2 3)]
		elsif(ref $check eq 'ARRAY')	{
			$failed = 1
				unless $node->$attr(@$check)
		}

		# attr => qr/123/
		elsif(ref $check eq 'Regexp')	{
			my $val = $node->$attr;
			
			if(defined $val)	{
				$failed = 1
					unless $val =~ /$check/
			}
			else	{
				$failed = 1
			}
		}

		# attr => 324
		else	{
			my $val = $node->$attr;

			if(defined $val)	{
				$failed = 1
					unless $val eq $check
			}
			else	{
				$failed = 1
			}
		}

		last if $failed
	}

	return $failed ? 0 : 1
}


sub look_down	{
	my ($self, %args) = @_;

	if($args{_BREADTH})	{
		return $self->look_down_breadth(%args);
	}

	my @agenda = ($self);
	my @wanted;
	my $RETURN = [];

	my $walk = sub	{
		my $main_it = shift;

		AGENDA:
		while(@agenda)	{
			my $node = pop @agenda;

			if($RETURN eq $node)	{
				$main_it->set_current(pop @wanted);
				$main_it->hist_push($main_it->current);
				return 1;
			}
			
			my $is_wanted = $self->_find_is_interesting($node, \%args);
			
			# determine if we want this node

			if($is_wanted)	{
				push @wanted, $node;

				if(!$args{_TOP_DOWN})	{
					push @agenda, $RETURN;
				}
			}
			
			# get the nodes children
			if($self->is_sb($node))	{
				my $children_it = $node->children;

				if($children_it)	{
					my @kids;

					while($children_it->pull)	{
						push @kids, $children_it->current
					}
					
					
					if(@kids)	{
						# keep walking the tree
						# since we're popping the agenda, reverse this to keep order
						
						push @agenda, reverse @kids;

						if($args{_TOP_DOWN} && $is_wanted)	{
							push @agenda, $RETURN
						}
					}
				}
			}
		}
		
		$main_it->set_exhausted(1);

		return ()
	};
	
	return SQL::Builder::Iterator->new($walk);
}


sub look_down_breadth	{
	my ($self, %args) = @_;

	my @agenda = ([$self]);
	my $RETURN = [];

	return SQL::Builder::Iterator->new(sub	{
		my $it = shift;

		while(@agenda)	{
			my $item = pop @agenda;

			if(ref $item eq 'ARRAY')	{
				my @wanted;
				my @kids;# children of the current level, in order

				foreach my $node (@$item)	{
					if($self->_find_is_interesting($node, \%args))	{
						push @wanted, $node
					}

					next unless $self->is_sb($node);

					my $children = $node->children;

					if($children)	{

						while($children->pull)	{
							push @kids, $children->current
						}
					}
				}

				push @agenda, [@kids] if @kids;

				# add the iteresting items to return
				push @agenda, reverse @wanted;
			}
			else	{
				$it->set_current($item);
				$it->hist_push($item);
				return 1;
			}
		}

		$it->set_exhausted(1);
		return ()
	})
}


sub look_up	{
	my ($self, %args) = @_;

	my $parents = $self->parents;

	return () unless $parents;

	return SQL::Builder::Iterator->new(sub	{
		my $it = shift;

		while($parents->pull)	{
			my $parent = $parents->current;

			if($parent && $self->_find_is_interesting($parent, \%args))	{
				$it->set_current($parent);
				$it->hist_push($parent);
				return 1;
			}
		}

		$it->set_exhausted(1);

		return ()
	})
}


sub descend_on	{
	my ($self, %args) = @_;
	
	my @agenda;
	my $RETURN = [];
	my $parents = $self->parents;

	return () unless $parents;

	while($parents->pull)	{
		push @agenda, $parents->current
	}

	return SQL::Builder::Iterator->new(sub	{
		my $it = shift;

		while(@agenda)	{
			my $node = pop @agenda;

			if($self->_find_is_interesting($node, \%args))	{
				$it->set_current($node);
				$it->hist_push($node);

				return 1;
			}
		}

		$it->set_exhausted(1);
		return ();
	})
}

# return the placeholders in this object and those of the children/recursively

sub placeholders	{
	my $self = shift;

	my $children = $self->children;

	return () unless $children;

	my @placeholders;

	while($children->pull)	{
		
		if(UNIVERSAL::isa($children->current, 'SQL::Builder::Placeholder'))	{
			
			push @placeholders, $children->current
		}
		elsif($self->is_sb($children->current))	{
			
			push @placeholders, $children->current->placeholders
		}
	}

	return @placeholders
}

sub ph_order	{
	my $self = shift;
	my %params = @_;
	my @return;

	foreach my $ph ($self->placeholders)	{

		if(defined($ph->tag))	{

			if(exists $params{$ph->tag})	{

				push @return, $params{$ph->tag}
			}
			else	{
				
				my $tag = $ph->tag;

				confess "tag '$tag' returned by placholders() but not provided in arguments"
			}
		}
		else	{
			
			confess "Placeholder object has undefined tag() value"
		}
	}

	return @return
}


sub dbh	{
	return shift->_set('dbh', @_)
}


sub run	{
	my $self = shift;

	confess "No dbh set"
		unless $self->dbh;
	my $sql = $self->sql;

	my $sth = $self->dbh->prepare($sql);

	$sth->execute(@_)
		or confess "Unable to run query: $DBI::errstr: ($sql)";

	return $sth
}


1;

=head1 NAME

SQL::Builder::Base - The base class for SQL::Builder objects

=head1 SYNOPSIS

This is a base class that should be implemented by all SQL::Builder/SQL objects.
SQL::Builder::Base will hopefully provide useful
mechanisms and common interfaces to use and author SQL::Builder objects
quickly and easily.

=head2 USAGE SUMMARY

Basically, all objects share a common constructor, get/set method behavior, and
have similar sql() behavior:

- They keys in the paired list sent to the constructor of an object are resolved as
method calls on the current object:

	new(foo => 1, 'baz->quux' => 1)

is the same as

	$foo = ...new;
	$foo->foo(1);
	$foo->baz->quux(1);

- Methods used to get/set attributes should behave the same. When arguments are
passed, a 'set' action is assumed, and the current object is returned. That is,
foo(1) should set whatever foo() represents to a value of 1, and return the
current object ($self). By returning the object, one can easily chain calls:

	$foo->foo(1)->baz(50);
	
	# same as

	$foo->foo(1);
	$foo->baz(50);

If foo() is called without arguments, the current value
of whatever foo() represents should be returned.

- sql() is for SQL serialization. When called, the object should call sql() on all variables involved
in SQL serialization so that it propagates as necessary. Variables that do not
have a sql() method will be used as-is in serialization. This is the method to
use for converting an object to SQL

=head1 OBJECT CONSTRUCTION

Currently, all SQL::Builder objects share the same constructor which is
inherited from this class. Overwriting the
SQL::Builder::Base::new() function shouldn't be done unless one is prepared to
take the risks involved. Object construction, as far as SQL::Builder goes, is
composed of the following parts:

	- bless()ing
	- Base.pm initialization
	- User-defined initialization
	- Base.pm argument handling or user-defined argument handling

By breaking down the constructor into these pieces, the API becomes more
flexible and the SQL::Builder object author is able to focus on the
relevant logic more easiliy. When new() is called, it dispatches calls to
init(), which is optionally defined in the subclass, and then passes any
arguments to set(), which is also optionally defined in the subclass.
The set() method defined by SQL::Builder::Base passes its arguments to
the nifty argument handler named _quick_arg_handler(). The magic behind
_quick_arg_handler() is simple. It converts paired arguments into method calls:

	SQL::Builder::Foo->new(foo => 1, bar => 2, 'baz->quux' => 3)

into

	$self->foo(1);
	$self->bar(2);
	$self->baz->quux(3);

and

	SQL::Builder::Foo->new(foo => [1,2], foo => [7], bar => [2,3], 'baz->quux' => [3,4])

into

	$self->foo(1, 2);
	$self->foo(7);
	$self->bar(2, 3);
	$self->baz->quux(3, 4);

Don't worry, it doesn't use eval.

Cuurrently, this construction convention can be used on all SQL::Builder objects, and
is recommended for future objects. It greatly cuts back on the complexity and
work required to provide complete control over an object via the constructor.
_quick_arg_handler() provides more complex functionality, but see
it for more documentation.

Another behavior common to all SQL::Builder objects is the ability to chain
method calls easily. The bevahior is simply defined:

	Whenever a value is set, the current object is returned. Otherwise, the
	current value is returned

This basically means that

	my $foo  = SQL::Builder::Foo->new(
		foo         => [1,2], foo  => [7], bar => [2,3],
		'baz->quux' => [3,4], bang => 'fuzz'
	)

is equivalent to

	my $foo = SQL::Builder::Foo->new;

	$foo->foo(1,2)->foo(7)->bar(2,3);
	$foo->baz->quux(3,4);
	$foo->bang('fuzz');

but

	$foo->foo->bar

is invalid because foo() returns the current value of whatever foo() represents,
not the current object.

=head1 SQL SERILIZATION AND sql() FUNCTIONS

Currently, every SQL::Builder object provides a method to return a SQL
serialization of an object -- this is done via sql(). In order to be useful, a
sql() method must propagate sql() calls to all of the variables used for
serialization. This basically means that

	my $b1 = SQL::Builder::BinaryOp->new(op => "AND", opers => [10, 15]);
	my $b2 = SQL::Builder::BinaryOp->new(op => "OR", opers => [$b1, 123]);

should result in

	print $b2->sql;

	# prints: 10 AND 15 OR 123

Most places in the documentation don't use nested objects for examples, but substitution of
text with a SQL::Builder object should be possible unless noted otherwise.

Using similar methods, it should be relatively simple to implement other forms
of serialization. For example, producing DBIx::Abstract code or XML should be
relatively painless if all objects were capable of the required serialization

=head1 MACROS

A SQL::Builder object is essentially a tree and because objects that inherit
from a common base were used in its implementation (not vague or stateless
data structures, see SQL::Builder(3) propaganda), it should be relatively simple to traverse the tree
to examine and modify it. At one point this was somewhat working, but is
currently broken -- complete functionality will be on its way shortly.

The major benefit of this feature is the ability to detect and/or
change code at runtime. For example, one could modify broken MySQL
queries built with SQL::Builder to properly run under PostgreSQL.
For example, one could convert

	col = null

to

	col IS NULL

One could even convert MySQL's CONCAT function to ||. ie,

	CONCAT(foo, bar)

to

	foo || bar

Or perhaps it'd be nice to automatically join against a set of tables if a
specific column is used in a SELECT query -- this could be easily done.

=head1 METHODS

=head2 cansql($obj)

Returns true/the code ref. if the provided argument has a sql() method

=head2 children()

This method returns an empty list. Subclasses should overwrite it and return
SQL::Builder::Iterator(3) objects to iterate over the children of an object. The
term 'child' may be a bit confusing; it might help to think of this function as something
like get_leaves_or_branches(), since SQL::Builder objects represent trees of
some sort. "children" typically refer to any object/variable maintained by a
SQL::Builder object used for serialization. For example, the children of a
SQL::Builder::List object are the elements in the list.

In general, the child of an object should be returned in some logical order,
typically the order in which they will be seen in a serialization.

This method will come in handy for using macros

=head2 dbh([$dbh])

This method is used to get/set a DBI object. When an argument is passed the
value is set and current object returned, otherwise the current value is
returned.

When sql() is called, the value of dbh() is made available to children objects.

=head2 descend_on(@args)

This is a macro method which gathers the parents of the current object and
returns a SQL::Builder::Iterator(3) object which can be used to "descend" to the
current object. That is, the iterator might return the great grandparent,
grandparent, and parent. The current object is not included. If no parents are
found, an empty list is returned immediately

Arguments passed here are passed to _find_is_interesting(). If the mechanisms
provided by _find_is_interesting() are too limiting, one can easily add the
control/search mechanisms to the loop used on the returned iterator.

=head2 dosql($var)

Given a scalar argument, dosql() checks if the passed variable has sql() method
attached to it by using cansql(), and if it does, $argument->sql() is called and
returned. If cansql() returns false, the passed variable is returned.

This is the standard operation for conditionally calling sql() on a variable.
The way this method works is likely to change, so in order to maintain any sort
of compatability, it must be used everywhere possible.

=head2 init()

This method is called by new() before set() is called. Its typical role is to
configure an object for usage. A common role is to set defaults

=head2 is($obj)

This method checks to see if the current object is the same type (ref($self) eq
ref($obj)) as $obj and returns true if it is. False otherwise

=head2 is_sb($var)

Returns true if $var inherits from SQL::Builder::Base, false otherwise

=head2 look_down(@args)

This is a macro method which left-recursively inspects the children (think
children()) of the current object. A SQL::Builder::Iterator(3) object is
returned, which uses _find_is_interesting(@args) to determine whether or not a
node should be mentioned.

look_down() accepts a special boolean (1 or 0) argument named "_BREADTH" to control the flow of
the search. By default, it searches depth-first and finds the "deepest" match to
return first. If _BREADTH is true, the search is converted to a breadth search
and gets handled by look_down_breadth()

=head2 look_down_breadth(@args)

This method acts like look_down(), except it searches the tree breadth-first.

=head2 look_up(@args)

This method returns a SQL::Builder::Iterator(3) object which helps the user
"upward recursively" iterate through all the parents of an object. This is the
opposite of descend_on(). If no parents are found, an empty list is returned.
@args is passed to _find_is_interesting() to determine whether or not a node is
interating

=head2 make_instance([@args])

This method is a function factory generator. Since no object can be
used twice within a given SQL::Builder tree, one should be able to easily
generate duplicates of a given object. This method returns a subroutine
reference:
	
	# $foo is a SQL::Builder::Foo
	my $factory = $foo->make_instance(foo => 1);

now that we have a factory, we can do:

	my $new_foo = $factory->(bar => 2);

which basically translates into

	my $new_foo = SQL::Builder::Foo->new(foo => 1, bar => 2)

One can set as many "defaults" as necessary via make_instance().

This method is mostly for convenience and should be used lightly. It should not
be used when a subclass with a well-defined init() method can be used instead.
Subclassing will often offer much more flexibility in the long run

=head2 mark_parents()

This looks at the children (children()) of the current object, marks their
parent (parent()) as the current object ($self), and calls mark_parents() on the
child object. For performance reasons and design simplicity, this must be called before
using macros that require parent() or parents(). This may change.

=head2 new([@args])

This constructor *should* be used on all SQL::Builder objects and not be
overwritten. The more consistent the interface is, the better. new() takes care
of the object creation (bless()ing) and makes calls to init() and set() (set()
is only called with arguments are passed); if all
goes well, a new object is returned. Ideally, arguments are all optional.

=head2 options([$name [=> $value] [...]])

This method works much like _set() does, except uses a different "namespace" for
storing data. The major difference between them is that _set() should be used
for storing user-defined data, which will typically be passed through dosql().
options() is designed to store control options. For example, options() should be
used to store user preferences about whether or not the 'AS' keyword should be
used in an alias, or what the default selection column(s) should be in a SELECT
query.

When no arguments are passed, the hash reference which contains all of the
current options is returned. If a single argument is passed, the value of the
option is returned. If 2 or more options are passed, we assume it's an
even-numbered list of (key => value), which will be used to set option values,
and have the current object returned
	
	# set foo to 1
	options(foo => 1);

	# set foo to 1, and bar to 2
	options(foo => 1, bar => 2);
	
	# view all currently set options
	print Dumper $obj->options()

	# view foo
	print $obj->options('foo')

In a subclass, it would be wise to wrap options() calls to add opaqueness.
Typically, one would want something like:

	sub use_as_keyword	{
		return shift->options('use_as_keyword', @_)
	}

which basically encapsulates all of functionality described above and adds a
structured interface.

=head2 parent([$parent])

Get/set the parent of the object. It might be easier to think of the parent as
the branch to which a leaf belongs. If called with an argument, the parent is
set and the current object returned. Without arguments, the current parent is
returned.

=head2 ph_order(%params)

Given a list of tag_name=>value pairs (a hash, really), this method returns the
ordered list of values based on their occurance/order provided by the list
returned by placeholders(). That is, one doesn't need to keep track of the order
of placeholders in a query, just the tag names (see SQL::Builder::Placeholder(3)
for tag()), and this method will put them in order

	# age = ? AND name = ?

	my @values $sql->ph_order(name => "sqlbuilder", age => "50");

	# prints: 50
	# prints: sqlbuilder
	print @values

The return of this method would typically be passed to DBI::execute(). To access
the list which controls the order of placeholder values for this function, see
placeholders()

	$sth->execute($sql->ph_order(
		age => 20,
		name => "foozle"
	))

=head2 parents()

This method is similar to look_up(), except returns an iterator which
unconditionally returns every parent of the current object in order of closeness
to the current object. ie, parent, grandparent, great grandparent, etc

=head2 placeholders()

This will walk the iterator provided by children() and look for
SQL::Builder::Placeholder objects, which get pushed onto the list that is
returned, and for all children that are SQL::Builder objects (is_sb()), their
placeholders (placeholders()) is called and pushed onto the return. Basically
the placeholder objects for the current object and all of its children
(recursively) are returned as a list.

This might change. At some point there will be an easier way to pass
placeholder values to queries.

=head2 run()

If dbh() returns a value, the current sql() value is passed through
DBI::prepare(), and executed via execute(). If an error occurs, an exception is
thrown which includes the SQL and the error fetched from $DBI::errstr

=head2 set()

This is the argument handler called from new(). Currently it's nothing more than
a wrapper which passes its arguments to _quick_arg_handler(). This can be
overwritten in a subclass, but it's not recommended. A consistent interface is a
good thing.

=head2 sql()

Return the SQL serialization of an object. Child classes can decide what to do
if this is not possible. Most return an empty string, but this may not be
suitable for all cases.

sql() methods must pass user-defined data through dosql() so that the SQL
serialization gets fully built. If it's possible and makes sense in a useful
sort of way, these methods should return empty strings when generating SQL isn't
logically possible

=head2 type([$class])

Called without arguments, this returns ref($self) -- the name of the current
class. If $class is passed/defined and the current object is the same type as $class,
true is returned. False otherwise

=head2 _find_is_interesting($node, $pattern)

This method typically accepts arguments passed by search methods (descend_on(),
look_down(), look_up()) and given an object/node in the tree, determines whether
or not it is "interesting" and should be mentioned by an iterator. This method
returns true if the given node is interesting -- false otherwise

$node can be of any type. $pattern needs to be a hashref, which shouldn't be
confused with a RE pattern. $pattern allows the user to automate/abstract checks
against a node to see whether or not it is interesting. If $pattern is empty,
all nodes will be interesting because there were no tests provided that would
cause a match to fail.

Here is an example pattern (keys are referred to as 'attribute names' and their
counterparts/values are referred to as 'attribute values'):

	$pattern = {

		# This is a callback. Given a node and current object, the
		# callback should determine whether or not the node is
		# interesting. If the node is interesting, the callback needs to
		# return true, otherwise the node will be skipped/not mentioned
		# by the iterator

		_code => sub {
			# check to see if the given node has a certain method

			my ($self, $node) = @_;
			return UNIVERSAL::can($node, "dsidi3j93932")
		},
		
		# This pattern checks if the current node's ref($node) returns a
		# value equal to the given value. In this case, the check would
		# be if(ref($node) eq 'SQL::Builder::Foo'). If the node is not
		# of the given type, it will be skipped

		_class => 'SQL::Builder::Foo',
		
		# Checks to see if the given node inherits from the given class.
		# The node is skipped if the test fails

		_isa => 'SQL::Builder::Base',
		
		# This pattern checks to see if the given node matches a regular
		# expression

		_re => qr/\d+/,

		# This pattern is sort of a fall-through callback. If none of
		# the aforementioned patterns matched, and the given pattern is
		# a subroutine reference, the subroutine is called with the
		# current object, node, and attribute name (hash key). The
		# callback must return true for the node to be mentioned. I'm
		# not exactly sure if this will be useful or not, but it only
		# took three lines of code to implement so we'll see.

		anything_can_go_here => sub 	{
			my ($self, $node, $attribute_name) = @_;

			# in this example, $attribute_name is
			# "anything_can_go_here"

			return 1 if $attribute_name eq 1000
		}

		# If no fall-through callback is found, the remaining attribute
		# names are assumed to be names of functions that the given node
		# might have. The attribute value is then compared against the
		# result of the method call, if the comparison returns true,
		# then the node is marked as interesting. The following example
		# attribute names are all the names of functions that will be
		# checked for

		sql => "foo",          # see if $node->sql() eq "foo"
		alias => undef,        # see if $node->alias() is undefined
		other => qr/user/,     # see if $node->other() =~ /user/
		foozle => [1,5]        # see if $node->foozle(1, 5) returns true
	}

There are some things to watch out for:

- Capital pattern keys prefixed with an underscore are skipped unless mentioned
otherwise; _CODE is an example of this

=head2 _make_children_iterator(@children)

Most if not all objects will know all of their immediate children without doing
any processing, so writing a custom iterator is usually
waste of time. This method, given a list of children, returns a
SQL::Builder::Iterator(3) object to traverse the list.

A child class may optionally implement a children() which returns
an iterator for all of the children. It's usually useful to do something like:

	sub children	{
		my $self = shift;

		return $self->_make_children_iterator([$self->foo, $self->bar])
	}

=head2 _quick_arg_handler(@config)

_quick_arg_handler() is called by set() when arguments are passed by the
constructor (by default, anyway. This behavior may change in subclassses, which
is bad). It accepts paired list of commands, or 3 hash refs. If a list of paired
commands is not passed, the following arguments are expected:

	_quick_arg_handler($methods, $options, $control)

=head3 $methods

$methods is expected to maintain the same data provided in the list of paired
commands.

	$self->_quick_arg_handler(foo => 1, bar => [2, 3], 'baz->quux' => 5)

is converted into

	$self->foo(1);
	$self->foo(2, 3);
	$self->baz->quux(2);

One can also pass

	$self->_quick_arg_handler({
		foo => 1, bar => [2, 3], 'baz->quux' => 5
	});

Which gets turned into the same thing. Argument calls are actually done through
_quick_arg_method_caller() which has options to control how the method is called
and how errors are handled

=head3 $options

$options is an optional hashref that sets the given option (key) to the given value. For example:

	_quick_arg_handler({}, {foo => 1})

Calls

	$self->options(foo => 1)

Hopefully the $options hash won't be used much because the options are hidden
away through wrappers, allowed them to be configured via $methods.

=head3 $control

This is an optionaly hashref that contains parameters that control the way the
methods are handled. When a method is to be executed, the reference, method name, and $control are passed
to _quick_arg_method_caller()

=head2 _quick_arg_method_caller($ref, $method, $args, $control)

This method is used by _quick_arg_handler() to call methods on references.
Basically, it does

	$ref->$method(@$args)

Which means it calls method $method on reference $ref with the elements in $args
as arguments.

$control is used for additional handling. Currently, one can

	$self->_quick_arg_handler($ref, $method, $args, {catch_errors => 1})

which traps the method call in an eval{}, and if an error occurs, the error
message is passed off to Carp::confess(). This might help debugging.

The return value of the method call is returned

=head2 _set()

This is a private method that should be used to automate the work of doing
get/set-variable operations. If 1 argument is passed, its current value is
returned. If two arguments are passede, the current value is set, and current
object is returned.

Child classes should implement this method for method behavior consistency and
max code reuse.

Typically, it'd be used like so:

	sub tableName	{
		return shift->_set('table_name', @_)
	}

Then the user can do something like:
	
	# get the table name
	my $table_name = $obj->tableName;

or

	# set the table name
	$obj->tableName("foozle");

and also

	# chain method calls since all methods act like _set()

	$obj->tableName("foozle")->foo(1)->bar(1)

which equates to

	$obj->tableName("foozle");
	$obj->foo(1);
	$obj->bar(1);

=head2 alias_sql()

This method is not defined in this class but may optionally be defined in child
classes. If this method is defined, alias() must be defined as well. It's
typically responsible for returning the SQL serialization representing the
aliased object. This can be seen in action in SQL::Builder::Table(3) and
basically generates:

	foo AS bar

or

	foo bar

It's generally a good idea to acompany alias() and alias_sql() with a
use_as()-like method to control the usage of the AS keyword and default this
behavior to "on"

=head1 SUBCLASSING

Subclassing should be quick and easy. In general, one just needs to inherit from
SQL::Builder::Base and provide a sql() method:

	package MySubClass;

	use SQL::Builder::Base;

	use base qw(SQL::Builder::Base);

	sub anything	{
		return shift->_set('anything', @_)
	}

	sub sql	{
		my $self = shift;

		my $anything = $self->dosql($self->anything);

		if(defined($anything) && length($anything))	{
			return "ANYTHING $anything"
		}
		else	{
			return ""
		}
	}

	sub children	{
		return shift->_make_children_iterator([$self->anything])
	}

	1;

At this point, we've packed in tons of functionality which eases this subclass
into SQL::Builder nicely. The constructor and all of its neat functionality have
been taken care of, behavioral modifications to antyhing() which gets/sets an
attribute have been taken care of, SQL serialization acts as it should, and this
module is ready for usage.

For a better understanding of what exactly is inherted, read this document and
consider reading the source for other SQL::Builder modules. The behavior
required from a SQL::Builder object is relatively simple and much of it has been
automated by inheriting SQL::Builder::Base.

Ideally SQL::Builder will be very granular and OO - see SQL::Builder(3) for
propaganda. It's important to keep this in mind when developing subclasses.

=head1 SEE ALSO

SQL::Builder - for propaganda
