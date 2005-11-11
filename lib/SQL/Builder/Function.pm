#!/usr/bin/perl

package SQL::Builder::Function;

use warnings;
use strict;

use Carp qw(confess);

use SQL::Builder::Base;
use SQL::Builder::List;

use base qw(SQL::Builder::Base);

sub init	{
	my $self = shift;

	$self->SUPER::init();

	my $list = SQL::Builder::List->new();

	$self->args($list);

	$self->parens(1);
	
	return $self
}

sub children	{
	my $self = shift;
	return $self->_make_children_iterator([
		$self->func,
		$self->args
	])
}

sub func	{
	return shift->_set('func', @_);
}

*name = *func;

sub args	{
	return shift->_set('args', @_);
}

sub parens	{
	return shift->options('parens', @_)
}

sub auto_parens	{
	return shift->options('auto_parens', @_)
}

sub sql	{
	my $self = shift;

	no warnings 'uninitialized';

	my $func = $self->dosql($self->func);
	my $args = $self->dosql($self->args);

	if($self->auto_parens)	{

		if($args)	{
			return "$func($args)"
		}
		else	{
			return "$func"
		}
	}
	else	{
		if ($self->parens)	{

			return sprintf "%s(%s)",
				$func,
				$args
		}
		else	{
			my $tpl = defined($args) && length $args ? "%s %s" : "%s";

			return sprintf $tpl,
				$func,
				$args
		}
	}
}

1;

=head1 NAME

SQL::Builder::Function - represent a SQL function

=head1 SYNOPSIS

	FUNCTION(anything [, ...])

This object maintains a SQL::Builder::List(3) list object available through
args() and a function name available through func()

	my $func = SQL::Builder::Function->new(
		func => "CONCAT",
		'args->list_push' => ["sql", "builder"]
	);
	
	# CONCAT(sql, builder)
	print $func->sql;

	$func->func('HELLO');
	
	# HELLO(sql, builder);
	print $func->sql;

	# add an argument
	$func->args->list_push("rocks");

	# HELLO(sql, builder, rocks)
	print $func->sql;

=head1 DESCRIPTION

This is a subclass of SQL::Builder::Base(3)

Although it would be wise to subclass this class, one could use the convenient
SQL::Builder::Base::make_instance() method to create a function that returns a
SQL::Builder::Function object instantiated with certain arguments. The following
is an example of how to create a SQL "CONCAT" function

	my $concat_factory = SQL::Builder::Function->make_instance(func => "CONCAT");

	...

	my $concat = $concat_factory->('args->list_push' => [1234, "zxcv"]);

	# CONCAT(1234, zxcv)
	print $concat->sql;

=head1 METHODS

=head2 new()

This method is inherited from SQL::Builder::Base(3) - See its documentation for
new(), set(), and _quick_arg_handler()

=head2 args()

By default this returns a SQL::Builder::List(3) object which is used for
maintaining the list of arguments of the current SQL function. Called with no
arguments, this method returns whatever value args() has been set to. See
SQL::Builder::List(3) for complete documentation on its usage. This is
implemented with SQL::Builder::Base::_set(); its functionality should be
expected

=head2 args($anything)

This will set the args() value and return the current object. Typically, one
shouldn't need to call args() with an argument unless for a good reason

=head2 auto_parens([0|1])

When turned on, this option will return only the function name (eg, "CURRENT_TIMESTAMP")
if there are no arguments. 0 is off, 1 is on. This option takes
precedence over parens(). This is a wrapper call to SQL::Builder::Base::options()
so you can call $func->options(auto_parens => 1|0) if you must. This is turned off
by default

=head2 func()

Returns the value of the current function (typically a string, but could be any
scalar). Implemented with SQL::Builder::Base::_set()

=head2 func($anything)

Called with an argument, func() sets the name of the SQL function and returns
the current object

=head2 name()

An alias for func()

=head2 init()

An overwritten method from SQL::Builder::Base(3) which instantiates the args()
value to a SQL::Builder::List(3) object. This probably shouldn't be called
manually. Returns the current object

=head2 parens(1|0)

This controls whether or not the SQL serialization should have parenthesis
surrounding the argument list. It is turned on (1) by default. This is a wrapper
call to $func->options() (inherited from SQL::Builder::Base(3)) so you can
call $func->options(parens => 1)

=head2 set()

This is the argument handler for the constructor (new()), inherited from
SQL::Builder::Base. See it for docs.

=head2 sql()

Returns the current SQL serialization

	FUNCTION(anything [, anything ...])

See parens() and auto_parens() for control options

=head2 children()

Return a SQL::Builder::Iterator to iterate over the return values of name() and
args()

=head1 SEE ALSO

SQL::Builder(3)
SQL::Builder::Base(3)
SQL::Builder::List(3)
SQL::Builder::AggregateFunction(3)

=cut

