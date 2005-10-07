#!/usr/bin/perl

package SQL::Builder::BinaryOp;

use warnings;
use strict;

use SQL::Builder::List;

use base qw(SQL::Builder::List);

sub init	{
	my $self = shift;
	$self->options('join_padding' => ' ');
	return $self;
}

sub set	{
	my $self = shift;

	$self->op(shift);
	$self->list(@_);

	return $self;
}

sub op	{
	return shift->joiner(@_)
}

sub args	{
	return shift->list(@_)
}

sub opers	{
	return shift->list(@_)
}


sub lhs	{
	return shift->list->[0]
}

sub rhs	{
	return shift->list->[1]
}

sub quick	{
	my $class = shift;
	my @return;

	#[lhs op rhs] -- should be treated recursively if LHS or RHS is an AREF to build nested logic
	#{bar => val} yields AND
		# if val is AREF assume key = bar or key = foo or key = ...
		# if val is HASHREF {op => other} assume "key OP val"
			# if other is AREF assume key op val or key op foo  ..
	#scalar has no special treatment

	foreach my $item (@_)	{
		if(ref $item eq 'ARRAY')	{
			my $op = $class->new();

			$op->op(splice @$item, 1, 1);

			my @tmp;

			foreach my $operand (@$item)	{
				if(ref $operand eq 'ARRAY')	{
					push @tmp, $class->quick($operand)
				}
				else	{
					push @tmp, $operand
				}
			}

			$op->args(\@tmp);

			push @return, $op
		}
		elsif(ref $item eq 'HASH')	{

			my $parent = $class->new();
			$parent->op('AND');
			$parent->options(parens => 1);

			foreach my $column (keys %$item)	{

				if(ref $$item{$column} eq 'ARRAY')	{
					my $or = $class->new();

					$or->op('OR');
					$or->options(parens => 1);

					foreach my $tmp (@{$$item{$column}})	{
						my $op = $class->new('=', $column, $tmp);

						$or->list_push($op)
					}
					
					$parent->list_push($or);
				}
				elsif(ref $$item{$column} eq 'HASH')	{

					my $child = $class->new();
					$child->op('AND');
					$child->options(parens => 1);
					
					foreach my $operator (keys %{$$item{$column}})	{
						$child->list_push(
							$class->new($operator, $column, $$item{$column}{$operator})
						)
					}

					$parent->list_push($child);
				}
				else	{
					$parent->list_push($class->quick([$column, '=', $$item{$column}]));
				}
			}

			push @return, $parent
		}
		else	{
			push @return, $item
		}
	}
		
	return wantarray ? @return : $return[0]
}


1;
