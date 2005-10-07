#!/usr/bin/perl

package SQL::Builder::Column;

use warnings;
use strict;
use Carp;

use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

our $QUOTER = sub {
	my $var = shift;

	return "\"$var\""
};

sub quoter	{
	my $class = shift;

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
	#col, alias, [@other]

	$self->col(shift);

	$self->alias(shift);

	if(ref $_[0] eq 'ARRAY')	{
		$self->other(shift)
	}
	else	{
		$self->other([@_])
	}

	return $self;
}

sub col	{
	return shift->_set("col", @_)
}

sub other	{
	return shift->_set("other", @_)
}

sub alias	{
	return shift->_set('col_alias', @_)
}

sub sql	{
	my $self = shift;

	confess "No column set" unless $self->col;

	my $fqn = join ".", map {$self->cansql($_)} (reverse(@{$self->other}), $self->col);

	if($self->options('quote') && (my $quoter = $self->quoter))	{
		
		return $quoter->($fqn);
	}

	return $fqn;
}

#pass LIST of scalar|AREF
#return LIST of column objects
sub quick	{
	my $class = shift;

	my @return;

	foreach my $item (@_)	{
		if (ref $item eq 'ARRAY')	{
			push @return, $class->new(@$item)
		}
		elsif(ref $item eq 'HASH')	{
			my $new = $class->new;

			$new->col($$item{col} || $$item{name});
			
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
			push @return, $class->new($item)
		}
		else	{
			push @return, $item
		}
	}

	return wantarray ? @return : $return[0]
}


1;
