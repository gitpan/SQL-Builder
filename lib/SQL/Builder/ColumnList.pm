#!/usr/bin/perl

package SQL::Builder::ColumnList;

use warnings;
use strict;

use SQL::Builder::List;

use base qw(SQL::Builder::List);

sub init	{
	my $self = shift;

	$self->SUPER::init();

	$self->joiner(", ");
	$self->options(parens => 0);

	$self->use_as(1);
	$self->use_aliases(1);

	return $self;
}


# convenience wrapper to PARENT::list()
sub cols	{
	return shift->list(@_)
}

sub use_aliases	{
	return shift->options('use_aliases', @_)
}

sub use_as	{
	return shift->options('use_as', @_)
}

sub children	{
	my $self = shift;

	my $own_children = $self->list;

	if($own_children && @$own_children)	{
		
		return $self->SUPER::children
	}
	else	{
		my $default_sel = $self->default_select;

		if(defined $default_sel)	{
			
			return $self->_make_children_iterator([$default_sel]);
		}
		else	{
			
			return ()
		}
	}
}

sub sql	{
	my $self = shift;
	my $cols = $self->cols;

	
	if(@$cols)	{
		my $use_aliases = $self->use_aliases;

		my $use_as      = $self->options('use_as');

			my @sql_cols;

			foreach my $col (@$cols)	{

				if($use_aliases)	{

					if(UNIVERSAL::isa($col, 'SQL::Builder::Column'))	{

						if(defined($col->alias) && length $col->alias)	{

							my $full_name = $self->dosql($col->full_name);

							my $alias     = $self->dosql($col->alias);

							if($use_as)	{
								push @sql_cols, "$full_name AS $alias"
							}
							else	{
								push @sql_cols, "$full_name $alias"
							}
						}
						else	{
							push @sql_cols, $col->full_name
						}
					}
					else	{

						my $sql = $self->dosql($col);

						if(UNIVERSAL::can($col, 'alias') && defined $col->alias)	{

							if($use_as)	{

								push @sql_cols, "$sql AS " . $col->alias
							}
							else	{
								
								push @sql_cols, "$sql " . $col->alias
							}
						}
						else	{

							push @sql_cols, $sql
						}
					}
				}
				else	{

					if(UNIVERSAL::isa($col, 'SQL::Builder::Column'))	{

						push @sql_cols, $self->dosql($col->full_name)
					}
					else	{

						push @sql_cols, $self->dosql($col)
					}
				}
			}
			
			# temporarily use the sql we built and let the parent
			# do the processing, then set the user columns back and return

			$self->_list(\@sql_cols);

			my $sql = $self->SUPER::sql;

			$self->_list($cols);

			return $sql
	}
	else	{

		# if we don't have anything to return, use defaults
		
		my $default = $self->options('default_select');

		if(!defined($default))	{
			return "*"
		}
		elsif(length $default)	{
			return $self->dosql($default);
		}
		else	{
			return ""
		}
	}
}

sub default_select	{
	return shift->options('default_select', @_)
}

1;

=head1 NAME

SQL::Builder::ColumnList - generate a list of expressions to be used in a SELECT
statement's column list

=head1 SYNOPSIS

	( anything [ [AS] [alias]] [, ...] ) | *

This class is little more than a SQL::Builder::List(3) with some useful checks
built into sql()
	
	# generate list of columns/expressions to be used
	my $col1 = SQL::Builder::Column->new(
		col => "foozle",
		alias => col1"
	);

	my $col2 = SQL::Builder::Column->new(col => "bang");

	my $col3 = "fosheezy";

	my $expr = SQL::Builder::BinaryOp->new(
		op => "+",
		opers => ["15", $col3]
	);

	my $list = SQL::Builder::ColumnList->new(
		cols => [$col1, $col2, $col3, $expr]
	);

	# foozle AS col1, bang, fosheezy, 15 + fosheezy
	print $list->sql;

	# turn of the 'AS' keyword
	$list->use_as(0);

	# foozle col1, bang, fosheezy, 15 + fosheezy
	print $list->sql;

	# turn off aliases completely
	$list->use_aliases(0);
	
	# foozle, bang, fosheezy, 15 + fosheezy
	print $list->sql;

	# Let's get all columns
	$list->list_clear();

	# *
	print $list->sql;

	# set $col3 as our default column
	$list->default_select($col3);

	# fosheezy
	print $list->sql;

=head1 DESCRIPTION

This is a subclass of SQL::Builder::List(3). It will probably the most useful
when used for generating the column list returned from a SELECT statement. Any
object in the maintained list of expressions with an alias() method that returns
something defined() and with a length() will be used pending the current
options.

=head1 METHODS

=head2 new()

See SQL::Builder::Base::new() and SQL::Builder::Base::set() - as they are inherited

=head2 cols([@list])

Use this to get/set the list of expressions. This is really just a wrapper to
SQL::Builder::List::list(), see it for more documentation

=head2 default_select([$default_select])

This sets the default select expression which is used when list() or cols()
returns an empty list. If $default_select is passed, it sets the default select
expression and returns the current object. With no arguments, it returns the
current value

=head2 init()

This calls SQL::Builder::List::init() and sets some default options, including
use_as(1) and use_aliases(1)

=head2 sql()

To summarize, every expression (be it the column expression or its alias) is
passed through SQL::Builder::Base::dosql(). SQL::Builder::Column objects are
treated specially and SQL::Builder::Column::full_name() is used as the
expression. Aliases are only considered valid when they are defined and have a
length. When the list of expressions is empty, default_select() is checked; if
default_select()'s return value is not defined, "*" is returned by sql(). The
return value of default_select() is passed through dosql() as well. In the even
any usable alias is found, use_as() is checked: when it is true, the 'AS'
keyword is used between the expression and its alias.

If that wasn't enough, please read the following, more confusing and
wordy description of how this method behaves:

This method overwrites the inherited sql(). If list() returns an empty list,
then default_select() is checked. If default_select() is defined() and has a
length(), then the value of $self->dosql($self->default_select) is used. If the returned
value of default_select() is not defined, "*" is used as the default selection expression. If the value is
defined but has no length, en empty string is returned by sql().

If list() does have elements, then use_aliases() is checked. If use_aliases() is
true, then expressions in the list that inherit from SQL::Builder::Column(3) are
checked for aliases that are defined() and have a length(), in which case they
will be used; if the alias is not valid, SQL::Builder::Column::full_name() is
used -- in either case, the return of full_name() will be processed with dosql().

When an expression from list() is not a SQL::Builder::Column(3) object, it
is checked for an alias() method, and used if its return is defined and has a
length. The expression is always passed through SQL::Builder::Base::dosql().

When use_aliases() is turned off, all expressions are passed through
SQL::Builder::Base::dosql() with the exception of SQL::Builder::Column objects.
If these are encountered, SQL::Builder::Column::full_name() is passed through
SQL::Builder::Base::dosql()

=head2 use_aliases([1|0])

This method controls the option to use expression aliases when they're
available. When called with no arguments, the current value is returned. Pass a
true or false value to turn it on or off, respectively

=head2 use_as([1|0])

This method controls the option to use the 'AS' keyword between an expression
and its alias upon SQL serialization (sql()). Called with no arguments, this
method returns the current value. Pass a 1 or 0 to turn it on or off,
respectively. When passing a value, the current object is returned

=head2 children

If there are any items in list(), SQL::Builder::List::children() is returned. If
the list is empty and default_select() is defined, an iterator containing the
default_select() value is returned. Otherwise, an empty list is returned

=head1 SEE ALSO

SQL::Builder::Column(3)
SQL::Builder::List(3)
SQL::Builder::Base(3)
