#!/usr/bin/perl

package SQL::Builder::BinaryOp;

use warnings;
use strict;

use SQL::Builder::List;

use base qw(SQL::Builder::List);

sub init	{
	my $self = shift;

	$self->SUPER::init();

	$self->options('join_padding' => ' ');
	return $self;
}

sub op	{
	return shift->joiner(@_)
}

sub opers	{
	return shift->list(@_)
}

sub lhs	{
	return shift->element(0, @_)
}

sub rhs	{
	return shift->element(1, @_)
}

1;

=head1 NAME

SQL::Builder::BinaryOp - Represent binary expressions (two or more operands)

=head1 SYNOPSIS

This will produce

	anything OP anything [OP anything [...]]

The constructor accepts arguments in RPN, so we pass the operator first:

	my $op = SQL::Builder::BinaryOp->new(
		op => '+',
		opers => [[15, 10]]
	);

	# 15 + 10
	print $op->sql;

	$op->list_push(34,56);

	# 15 + 10 + 34 + 59
	print $op->sql;
	
	{
		my $multi = SQL::Builder::BinaryOp->new(
			op => "*",
			opers => [qw(5 10)]
		);
			
		# just in case we need to force precedence
		$multi->parens(1);

		$op->list_push($multi);

		# 15 + 10 + 34 + 59 + (5 * 10)
		print $op->sql;
	}

	# change the operator
	$op->op('PLUS');

	# 15 PLUS 10 PLUS 34 PLUS 59 PLUS (5 * 10)
	print $op->sql;

	# we can also do
	$op = SQL::Builder::BinaryOp->new(
		op => "+",
		lhs => 10,
		rhs => 15
	);

=head1 DESCRIPTION

This is a subclass of SQL::Builder::List(3). List items (the operands, which are
set via opers() and managed through the inherited SQL::Builder::List(3)
functions) are joined with the operator (set via op()) upon serialization. This
class can maintain more than two (fewer, too, but it's not as useful in those
cases) operands, which are joined with op() when sql() is called. This "feature"
makes it useful to do things like represent:

	1 OR 2 OR 3 OR 4

The code required for representing a binary operation might seem a bit
cumbersome, but of course the benefit is state. Suppose you have a date column
($col) and have moved to a different database vendor which doesn't support date
math. All the SQL you might have written (via SQL::Builder(3)) can be still be
used, you just need to write handlers to modify all mathematical operations on
$col before execution. It might look something like this:
	
	# get all the children of $sql that have an 'op' method which returns a
	# + or -
	my $it = $sql->look_down(
		op => qr/^[+-]$/
	);
	
	# walk the results
	while($it->pull)	{

		my $op = $it->current;

		my $children = $op->children;
		my $has_date;
		
		# examine the children of the current result

		while($children->pull)	{

			if(is_a_col_we_want($children->current))	{
				$has_date = 1;
				last;
			}
		}
		
		if($has_date)	{
			# transform the operator and its operands to suit your
			# database vendor needs
			# ...
		}
	}

But of course, logic like this can cause a lot of problems in code manageability
down the line, so we should avoid doing these things outside of "oh, crap"
situations where it's necessary. If one's goal is to design portable SQL,
preventing this situation would be more intelligently done by subclassing
SQL::Builder::Column(3) and SQL::Builder::BinaryOp(3) to create your own
DateColumn and DateOp classes. Once this is done, we can easily identify date
columns and operations on date columns. Deciding how the SQL should be written
can be done in the sql() methods, and the overhead of the tree search can be
avoided.

=head1 METHODS

See the parent class: SQL::Builder::List(3)

=head2 new()

See SQL::Builder::Base::set() for documentation on this. It's okay not to pass
any arguments here

=head2 init()

This calls SQL::Builder::List::init() and sets join_padding option to " ". This
method probably shouldn't be called manually

=head2 lhs()

This is convenience method which assumes there are only two operands in the
list. It wouldn't make much sense to use it in other cases. It returns the first
item in the list which equates to the "left-hand side" of the operator. Can also
be used to set the value if an argument is passed

=head2 op()

=head2 op($operator)

Called with no arguments it returns the value of the current operator. If called
with an argument, it sets the operator and returns the current object (useful
for chained calls). This is a wrapper call to SQL::Builder::List::joiner()

=head2 opers()

This is a wrapper method to SQL::Builder::List::list(). See it for complete
documentation. Passed with arguments it sets the list and returns the current
object, called with no arguments, it returns an array reference of list items

=head2 rhs()

Like lhs(), but returns the right-hand side of the operator (second operand).
Call rhs($arg) to set the value of the RHS. It can be used to set the value
if passed an argument. See lhs(), too

=head2 sql()

This is not implemented in this class, but inherited from SQL::Builder::List(3)

	oper1 OP oper2 [OP oper3 ...]

=head1 SEE ALSO

SQL::Builder::List(3)
SQL::Builder::Base(3)
SQL::Builder::PrefixOp(3)
SQL::Builder::PostfixOp(3)

=cut
