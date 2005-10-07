#!/usr/bin/perl

package SQL::Builder::Join;

use warnings;
use strict;
use Carp qw(confess);

use SQL::Builder::BinaryOp;
use SQL::Builder::Using;
use SQL::Builder::Table;

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub init	{
	my $self = shift;

	$self->SUPER::init();
	
	my $on = SQL::Builder::BinaryOp->new("AND");
	$on->options(parens => 0);
	$self->on($on);

	my $using = SQL::Builder::Using->new();
	$self->using($using);

	my $table = SQL::Builder::Table->new();
	$self->table($table);

	return $self;
}

sub set	{
	my $self = shift;
	
	# set the table
	if(defined $_[0])	{
		my $table = shift;

		if(UNIVERSAL::isa($table, 'SQL::Builder::Table'))	{
			$self->table($table);
		}
		else	{
			$self->table->table($table);
		}
	}
	
	# set other options if present

	defined $_[0] ? $self->type(shift) : shift;
	defined $_[0] ? $self->on->list_push(shift) : shift;
	defined $_[0] ? $self->using->list_push(shift) : shift;

	return $self;
}

sub on	{
	return shift->_set('on', @_)
}

sub table	{
	return shift->_set('table', @_)
}

sub left_table	{
	return shift->_set('left_table', @_)
}

sub type	{
	return shift->_set('type', @_)
}

sub using	{
	return shift->_set('using', @_);
}

sub natural	{
	return shift->options('natural', @_)
}

#[ INNER ] JOIN, LEFT [ OUTER ] JOIN, RIGHT [ OUTER ] JOIN, FULL [ OUTER ] JOIN

sub inner	{ return "INNER" }
sub left	{ return "LEFT" }
sub left_outer	{ return "LEFT OUTER" }
sub right	{ return "RIGHT" }
sub right_outer	{ return "RIGHT OUTER" }
sub full	{ return "FULL" }
sub full_outer	{ return "FULL OUTER" }
sub cross	{ return "CROSS" }

sub set_inner		{ shift->type(inner()) }
sub set_left		{ shift->type(left()) }
sub set_left_outer	{ shift->type(left_outer()) }
sub set_right		{ shift->type(right()) }
sub set_right_outer	{ shift->type(right_outer()) }
sub set_full		{ shift->type(full()) }
sub set_full_outer	{ shift->type(full_outer()) }
sub set_cross		{ shift->type(cross()) }

sub sql	{
	my $self  = shift;
	
	my $table = $self->cansql($self->table);
	my $type  = $self->cansql($self->type);
	my $on    = $self->cansql($self->on);
	my $using = $self->cansql($self->using);
	my $natural = $self->natural;
	
	my $tpl   = $type ? "$type JOIN $table" : "JOIN $table";

	$tpl = "NATURAL $tpl" if $natural;

	if(!$natural && $on)	{
		return "$tpl ON $on"
	}
	elsif(!$natural && $using)	{
		return "$tpl $using"
	}
	else	{
		return $tpl;
	}
}

sub quick	{
	my $class = shift;
		$class = ref($class) || $class;

	my @return;

	foreach my $join (@_)	{
		if(ref $join eq 'HASH')	{
			my $new = $class->new();

			# what type of join
			if(defined $$join{type})	{
				$new->type($$join{type})
			}
			
			# table is required
			if(defined $$join{table})	{
				my $t = $$join{table};

				if(UNIVERSAL::isa($t, 'SQL::Builder::Table'))	{
					$new->table($t)
				}
				else	{
					$new->table->table($t)
				}
			}

			# on?
			if(defined $$join{on})	{
				my $binop = SQL::Builder::BinaryOp->quick($$join{on});

				$new->on->list_push($binop);
			}

			# using?
			if(defined $$join{using})	{
				$new->using->list_push($$join{using});
			}

			push @return, $new
		}
		elsif (ref $join eq 'ARRAY')	{
			# expect arg order of the constructor

			my $new = $class->new(@$join);

			push @return, $new
		}
		else	{
			push @return, $join
		}
	}

	return wantarray ? @return : $return[0];
}

1;
