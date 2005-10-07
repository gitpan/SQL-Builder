#!/usr/bin/perl

package SQL::Builder::Table;

use warnings;
use strict;
use Carp;

use SQL::Builder::Column;
use SQL::Builder::Base;

use base qw(SQL::Builder::Base);


our $QUOTER = sub {
	my $var = shift;

	return sprintf '"%s"', $var
};

sub quoter	{
	my $class = shift;#get rid of object

	if(@_)	{
		$QUOTER = shift;
		return $class
	}

	return $QUOTER
}


sub init	{
	my $self = shift;

	$$self{other} = [];

	return $self;
}

sub set	{
	my $self = shift;
	#table, alias, [@other]

	$self->table(shift);
	$self->alias(shift);

	if(ref $_[0] eq 'ARRAY')	{
		$self->other(shift)
	}
	else	{
		$self->other([@_])
	}

	return $self
}

sub table	{
	my $self = shift;
	return $self->_set("table", @_)
}

sub other	{
	my $self = shift;
	return $self->_set("other", @_)
}

sub alias	{
	return shift->_set('table_alias', @_)
}


sub sql	{
	my $self = shift;

	confess "No table set" unless defined $self->table;

	my $fqn = join ".", map {$self->cansql($_)} (reverse(@{$self->other}), $self->table);

	if($self->options('quote') && (my $quoter = $self->quoter))	{
		
		return $quoter->($fqn);
	}

	return $fqn;
}

sub col	{
	my $self = shift;

	my $column = shift;
	my $alias = shift;

	if(UNIVERSAL::can($column, 'table'))	{
		$column->table($self)
	}
	else	{
		$column = SQL::Builder::Column->new($column, $alias, $self)
	}

	return $column
}

sub quick	{
	my $self = shift;

	my @return;

	foreach my $item (@_)	{
		if(ref $item eq 'ARRAY')	{
			push @return, $self->new(@$item)
		}
		elsif(ref $item eq 'HASH')	{
			my $new = $self->new;

			$new->table($$item{table} || $$item{name});

			if($$item{other})	{
				if(ref $$item{other} eq 'ARRAY')	{
					$new->other($$item{other})
				}
				else	{
					$new->other([$$item{other}])
				}
			}

			if($$item{alias})	{
				$new->alias($$item{alias})
			}

			push @return, $new
		}
		elsif(!ref $item)	{
			push @return, $self->new($item)
		}
		else	{
			push @return, $item
		}
	}

	return wantarray ? @return : $return[0]
}

1;
