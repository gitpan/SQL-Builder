#!/usr/bin/perl

package SQL::Builder::List;

use warnings;
use strict;
use Carp qw(confess);

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

#always pass an arrayref
sub list	{
	my $self = shift;

	if(@_)	{
		
		$self->list_clear;
		return $self->list_push(@_)
	}
	else	{
		return $self->_list
	}
}

sub _list	{
	return shift->_set('list', @_)
}

sub list_push	{
	my $self = shift;

	push @{$self->list}, @_;

	return $self;
}

sub list_pop	{
	my $self = shift;
	confess "Trying to pop empty list"
		unless @{$self->list};
	
	return pop @{$self->list}
}

sub list_shift	{
	my $self = shift;
	confess "Trying to shift empty list"
		unless @{$self->list};
	return shift @{$self->list}
}

sub list_unshift	{
	my $self = shift;
	unshift @{$self->list}, @_
}

sub list_clear	{
	my $self = shift;

	# maintain the current a ref
	splice @{$self->list}, 0, @{$self->list};
}

sub init	{
	my $self = shift;

	$self->joiner(', ');
	$self->join_padding('');

	$self->_list([]);

	return $self
}

sub join_padding	{
	return shift->options('join_padding', @_)
}

sub joiner	{
	shift->_set('joiner', @_)
}

sub element	{
	my $self = shift;
	my $element = shift;

	confess "array index should be defined"
		unless defined $element;
	
	if(@_)	{

		$self->list->[$element] = shift;

		return $self
	}
	else	{
		return $self->list->[$element]
	}
}

sub use_aliases	{
	return shift->options('use_aliases', @_)
}

#options: parens, join_padding
sub sql	{
	my $self = shift;
	
	return "" unless $self->list && @{$self->list};

	my $joiner = $self->dosql($self->joiner);
	my $join_pad = $self->dosql($self->join_padding);

	if(defined $join_pad)	{
		my $pad = $join_pad;

		$joiner = $pad.$joiner.$pad;
	}

	return "" unless defined $self->list;

	my $sql = join(
		$joiner,
		map {

			my $item = $_;
			my ($dosql, $ret);

			if($self->use_aliases && UNIVERSAL::can($item, 'alias_sql'))	{

				my $alias = $item->alias;

				if(defined($alias) && length $alias)	{
					
					$ret = $item->alias_sql;
				}
				else	{

					$dosql = 1
				}
			}
			else	{
				
				$dosql = 1
			}

			if($dosql)	{
				my $val = $self->dosql($_);
				$ret = defined $val ? $val : ""
			}

			$ret
		} (ref $self->list eq 'ARRAY' ? @{$self->list} : $self->list)
	);

	if($self->parens)	{
		$sql = "($sql)"
	}

	return $sql
}

sub children	{
	my $self = shift;
	return $self->_make_children_iterator($self->list)
}

sub parens	{
	return shift->options('parens', @_)
}

1;

=head1 NAME

SQL::Builder::List - An object interface for various SQL lists

=head1 SYNOPSIS

	my $list = SQL::Builder::List->new;

	$list->list_push(qw(1 2 3));

	# 1, 2, 3
	print $list->sql;

	$list->parens(1);

	# (1, 2, 3)
	print $list->sql;

	$list->element(1, 5);

	# (1, 5, 3)
	print $list->sql;
	
	# 3
	print $list->list_pop;
	
	# (1, 5)
	print $list->sql;

	# modify the join string
	$list->joiner("!");
	
	# (1!5)
	print $list->sql;

	# add padding to the join string
	$list->join_padding(" ");

	# (1 ! 5)
	print $list->sql

=head1 DESCRIPTION

Many SQL constructs employ some form of list. Be it arguments to a function,
joins in a table, etc. This class is designed to provide a common interface
for manipulating and accessing these constructs. Many SQL::Builder modules
inherit from this class so it'd be wise to learn it. Currently it's a very basic
set of methods and a thin layer around a Perl array.

=head1 METHODS

=head2 _list([$aref])

This is mostly an internal method used to set the value of the internal
representation of the list. By default, it's an array reference. Most of the
methods in this class rely on that fact. This should probably only be set when
its value needs to be changed; otherwise, one should probably use list().

This class attempts to maintain the array reference created when an object is
instantiated, this means that after calling list_clear() or list(@elems), the
reference to the maintained array does not change, just the elements in that
array. It might be useful at some point to change the reference to another. eg,

	$list->_list([1..15])

=head2 children()

Returns an iterator to walk the children (items in the list)

=head2 element($elem [, $value])

This can be used to get/set the value of an element in the list. It is
zero-indexed. If only $elem is passed, its value of $arr[$elem] is returned. If $value is
passed, $arr[$elem] will be set to $value and the current object will be
returned.

=head2 init()

Sets joiner() to ", ", join_padding() to "", and _list() to []. Also calls the
parent init() method

=head2 joiner([$str])

Used to get/set the value of the string used to join elements of the list with
on SQL serialization. Called with an argument, the value is set and current
object returned; otherwise, the current value is returned

=head2 join_padding([$str])

Used to get/set the value of the string used to surround the value of joiner()
on SQL serialization. Called with an argument, the value is set and current
object returned; otherwise, the current value is returned

=head2 list([@list])

Get/set the elements in the maintained array. If called with arguments, the list
is set and the current object is returned. Without arguments, a reference to the
maintained array is returned. See _list() as well

=head2 parens([1|0])

Toggle parenthesis on the list, effective on serialization. When arguments are
passed, the value is set and current object returned; otherwise the current
value is returned.

=head2 sql()

Return the SQL serialization or a blank string if there are no elements in the
list. Each element in the list, joiner(), and join_padding() are passed through
SQL::Builder::Base::dosql() before being used. The serialization basically looks
like:

	elem1 $join_padding$joiner$join_padding elem2 [...]

If there is only one element in the list, join_padding() and joiner() aren't
used

=head2 use_aliases([1|0])

If this option is set, the items processed in sql() are checked for the
alias_sql() method. If an item has the method and its alias() method returns a
value that is defined and has a length, then the value of alias_sql() is used in
the list.

=head2 LIST MANIPULATION METHODS

	list_clear, list_pop, list_push, list_shift, list_unshift

These are all thin wrappers to the corresponding Perl function. I prefixed them
with "list_" so that we don't run into any problems with classes inherited these
methods that have more useful uses of methods named "push" (for example)
