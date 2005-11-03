#!/usr/bin/perl

package SQL::Builder::Order;

use warnings;
use strict;
use Carp qw(confess);

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub ASC {"ASC"}
sub DESC{"DESC"}

sub expr	{
	return shift->_set('expr', @_)
}

sub order	{
	return shift->options('order', @_)
}

sub desc	{
	return shift->order(DESC())
}

sub asc	{
	return shift->order(ASC())
}

sub using	{
	return shift->options('using', @_)
}

sub sql	{
	my $self  = shift;
	my $order = $self->dosql($self->order);
	my $using = $self->dosql($self->using);
	my $expr  = $self->dosql($self->expr);

	return "" unless defined $expr;

	if(defined($order) && length($order))	{
		return "$expr $order"
	}
	elsif(defined($using) && length($using))	{
		return "$expr USING $using"
	}
	else	{
		return $expr
	}
}

sub children	{
	my $self = shift;

	return $self->_make_children_iterator([
		$self->expr,
		$self->order,
		$self->using
	])
}

1;

=head1 NAME

SQL::Builder::Order - Represent an expression in SQL ORDER BY clauses

=head1 SYNOPSIS

This class can represent the following SQL:

	anything [ASC|DESC|USING anything|anything]

which basically turns into

	foo ASC
	foo DESC
	foo USING >
	foo USING <
	foo bar

Here's how to use it:

	my $expr = SQL::Builder::Order->new(expr => "foo - bar");

	$expr->asc;
	
	# foo - bar ASC
	print $expr->sql;

	$expr->desc;

	# foo - bar DESC
	print $expr->sql;

	$expr->order(undef);

	# foo - bar
	print $expr->sql;

	$expr->using(">");

	# foo - bar USING >
	print $expr->sql;

	$expr->order("ASC");

	# foo - bar ASC
	print $expr->sql;


=head1 DESCRIPTION

This class inherits from SQL::Builder::Base(3)

=head1 METHODS

=head2 ASC()

Returns the string "ASC"

=head2 DESC()

Rerturns the string "DESC"

=head2 asc()

Passes the value of ASC() to order()

=head2 desc()

Passes the value of DESC() to order()

=head2 expr([$expr])

Called with an argument sets the expression and returns the current object.
Otherwise it returns the current value. This is the expression that is to be
ordered in the ORDER BY clause

=head2 order([$by])

Called with an argument sets the value and returns the current object. Otherwise
it returns the current value. This is the value that is typically used to
specify sort order. For example, order("ASC") will result in sql() returning
something like "foo ASC"

=head2 sql()

Returns the SQL serialization of the object. The values of expr(), order(), and
using() are all passed through SQL::Builder::Base::dosql() before being
processed. An empty string is returned if $expr is undefined. If $order is
defined and has a length, "$expr $order" is returned. Otherwise, if $using is
defined and has a length, "$expr USING $using" is returned. All other cases will
return $expr

=head2 using([$using])

Called with arguments, the value is set and the current object is returned.
Otherwise, the current value is returned. This method gets/sets the value to be
used with USING, if your DBMS supports it. using(">") will result in sql()
returning something like "foo USING >"

=head2 children()

Return a SQL::Builder::Iterator to iterate over the values of expr(), order(),
and using()

=head1 SEE ALSO

SQL::Builder::GroupBy(3)
SQL::Builder::Base(3)
SQL::Builder(3)
