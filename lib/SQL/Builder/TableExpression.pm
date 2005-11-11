#!/usr/bin/perl

package SQL::Builder::TableExpression;

use warnings;
use strict;

use SQL::Builder::List;

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub init	{
	my $self = shift;

	$self->SUPER::init;

	$self->use_expr_alias(0);
	$self->use_own_alias(1);
	$self->use_as(1);

	$self->col_container(
		SQL::Builder::List->new
	);

	return $self
}

sub expr	{
	return shift->_set('expr', @_)
}

sub use_expr_alias	{
	return shift->options('use_expr_alias', @_)
}

sub use_own_alias	{
	return shift->options('use_own_alias', @_)
}

sub alias	{
	return shift->_set('alias', @_)
}

sub parens	{
	return shift->options('parens', @_)
}

sub use_as	{
	return shift->options('use_as', @_)
}

sub sql	{
	my $self = shift;
	my $expr = $self->dosql($self->expr);

	my $cols = $self->dosql($self->col_container);

	my ($sql, $alias);
	
	return "" unless defined($expr) && length $expr;


	if($self->use_own_alias)	{
		my $own_alias = $self->dosql($self->alias);
		
		if(defined($own_alias) && length $own_alias)	{
		
			$alias = $own_alias
		}
	}

	if($self->use_expr_alias && !defined $alias)	{
		
		if(UNIVERSAL::can($self->expr, 'alias'))	{
			
			my $expr_alias = $self->dosql($self->expr->alias);

			if(defined($expr_alias) && length($expr_alias))	{
				
				$alias = $expr_alias;
			}
		}
	}



	if($self->parens)	{
		
		$expr = "($expr)"
	}


	if(defined $alias)	{
		
		if($self->use_as)	{
	
			$sql = "$expr AS $alias"
		}
		else	{
			
			$sql = "$expr $alias"
		}
	}
	else	{
		
		$sql = $expr
	}

	if(defined($cols) && length $cols)	{

		$sql .= " ($cols)"
	}


	if($self->only)	{
		
		$sql = "ONLY $sql"
	}

	return $sql
}

sub children	{
	my $self = shift;
	my $list = [$self->expr];

	if($self->use_own_alias)	{
		
		push @$list, $self->alias
	}

	push @$list, $self->col_container;
	
	return $self->_make_children_itertor($list)
}

sub cols	{
	return shift->col_container->list(@_)
}

sub col_container	{
	return shift->_set('cols', @_)
}

sub only	{
	return shift->options('only', @_)
}

1;

=head1 NAME

SQL::Builder::TableExpression - represent SQL table expressions

=head1 SYNOPSIS
	
	# construct your objects
	my $table = SQL::Builder::Table->new(name => "table", alias => "tblalias");
	my $expr  = SQL::Builder::TableExpression->new(
		expr => $table,
		alias => "alias"
	);

	# table AS alias
	print $expr->sql;

	
	# useful for certain expressions
	$expr->parens(1);

	# (table) AS alias
	print $expr->sql;

	$expr->parens(0);

	# previously the alias being used was provided by the current object,
	# it's possible to change this behavior

	$expr->use_own_alias(0);

	# table AS tblalias
	print $expr->sql;
	
	# the AS keyword can be turned off
	$expr->use_as(0);

	# table tblalias
	print $expr->sql;

	# it's also possible to ignore all aliases
	$expr->use_expr_alias(0);

	# table
	print $expr->sql;

There is also support for column aliasing:

	my $expr  = SQL::Builder::TableExpression->new(expr => $table, alias => "alias");
	$expr->cols(qw(a1 b2 c3));

	# table AS alias (a1, b2, c3)
	print $expr->sql;
	
One can also manipulate the list of column aliases using

	$expr->col_container
	
For databases support table inheritence/ONLY, the keyword can be toggled:

	$expr->only(1)
	
	# ONLY table AS alias (a1, b2, c2)
	print $expr->sql

=head1 DESCRIPTION

This module is not to be confused with SQL::Builder::Table(3). TableExpression
is typically used to respresent table expressions in the FROM list of a query,
while objects like Table are typically used to refer to the table in other parts
of the query, such as other() in Column list or to a function. In particular,
SQL::Builder::TableExpression will be used for single table references, grouped
joins, and sub-queries

This is a SQL::Builder::Base(3) subclass

=head1 METHODS

=head2 alias([$alias])

Get/set the alias of the object. See use_expr_alias() and use_own_alias() to see
how and when it gets used. See use_as(), too

=head2 children()

Return a SQL::Builder::Iterator(3) object to iterate over the values of expr(),
col_container(), and alias(). If use_own_alias() returns false, then alias()
is not included in the iterator

=head2 expr([$expr])

Get/set the table expression. It can be a SQL::Builder object or a string and is
used for serialization in sql()

=head2 init()

Calls init() on the parent class and sets some defaults: use_as(),
use_expr_alias(), and use_own_alias() are all set to 1 or "on"

=head2 parens([1|0])

Turn on/off usage of parenthesis to wrap the SQL::Builder::Base::dosql() result
of expr() in sql()

=head2 sql()

Return the SQL serialization. If parens() returns true, parenthesis are used to
wrap the value of expr(). If use_as() returns true and a usable alias is found,
the 'AS' SQL keyword is used to connect the expression to the alias. To
determine if there is a usable alias, use_own_alias() is checked for a true
value; when it returns true and the dosql() value of alias() has a length, then
it is used. If alias() does not return a usable value, use_expr_alias() is
checked for a true value; when it returns true and the value of expr() has an
alias() method, then that method is called and checked for a length. When there
is a length, that alias will be used. See the SYNOPSIS for examples.

If only() returns true, the returned SQL is prepended with "ONLY".

If the value of col_container() passed through dosql() has a length, then column
aliases are provided for the statement. Basically:

	$expr->cols(qw(a1 b1 c1));

	# table AS alias (a1, b1, c1)
	print $expr->sql

=head2 use_as([1|0])

Turn on/off the usage of the 'AS' SQL keyword to connect expr() to its alias

=head2 use_expr_alias([1|0])

Turn on/off usage of the alias() provided by expr() -- see sql()

=head2 use_own_alias([1|0])

Turn on/off usage of the alias() method and use it in the SQL serialization when
alias() returns a value with a length. See sql()

=head2 only([1|0])

Turn on/off the ONLY keyword in the SQL serialization.

=head2 col_container()

Get/set the SQL::Builder::List(3) object used for maintaining the list of column
aliases. This object can be overwritten with a non-object or another object, but
if a list() method is not provided, cols() will fail.

=head2 cols([@cols])

Get/set the list of items maintained in the list by col_container(). This is just
a wrapper that passes its arguments to SQL::Builder::List::list()

=head1 SEE ALSO

SQL::Builder::Table(3)
SQL::Builder::Base(3)
SQL::Builder::List(3)
SQL::Builder(3)
SQL::Builder::Select(3)
SQL::Builder::Update(3)
SQL::Builder::Delete(3)
SQL::Builder::Insert(3)
