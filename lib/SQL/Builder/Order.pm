#!/usr/bin/perl

package SQL::Builder::Order;

use warnings;
use strict;
use Carp qw(confess);

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub ASC(){"ASC"}
sub DESC(){"DESC"}
sub USING(){"USING"}

sub set	{
	my $self = shift;

	if(@_ == 1)	{
		#expr
		$self->expr(@_)
	}
	elsif(@_ == 2)	{
		#expr DESC|ASC
		$self->expr($_[0]);
		$self->order($_[1]);
	}
	elsif(@_ == 3)	{
		#expr USING foo
		$self->expr($_[0]);
		$self->using($_[2]);
	}
	else	{
		confess "Expecting 1, 2, or 3 args"
	}

	return $self
}

sub expr	{
	return shift->_set('expr', @_)
}

sub order	{
	return shift->options('order', @_)
}

sub desc	{
	return shift->order(DESC)
}

sub asc	{
	return shift->order(ASC)
}

sub using	{
	return shift->options('using', @_)
}

sub sql	{
	my $self  = shift;
	my $order = $self->cansql($self->order);
	my $using = $self->cansql($self->using);
	my $expr  = $self->cansql($self->expr);

	return "" unless $expr;

	if($order)	{
		return "$expr $order"
	}
	elsif($using)	{
		return "$expr USING $using"
	}
	else	{
		return $expr
	}
}

sub quick	{
	my $class = shift;
	my @return;

	foreach my $item (@_)	{
		if(ref $item eq 'ARRAY')	{
			push @return, $class->new(@$item)
			
		}
		elsif(ref $item eq 'HASH')	{
			my $new = $class->new;

			if($$item{using})	{
				$new->using($$item{using})
			}
			elsif($$item{order})	{
				$new->order($$item{order})
			}

			$new->expr($$item{expr});

			push @return, $new
		}
		else	{
			push @return, $item
		}
	}

	return wantarray ? @return : $return[0];
}

1;
