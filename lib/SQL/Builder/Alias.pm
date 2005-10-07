#!/usr/bin/perl

package SQL::Builder::Alias;

use warnings;
use strict;
use Carp qw(confess);

use SQL::Builder::AliasName;
use SQL::Builder::AliasSelect;

use SQL::Builder::BaseProxy;

use base qw(SQL::Builder::BaseProxy);

sub init	{
	my $self = shift;

	$self->SUPER::init();

	return $self
}

sub set	{
	my $self = shift;
	$self = $self->_base_or_child;

	$self->expr(shift);
	$self->alias(shift);

	return $self;
}

sub expr	{
	my $self = shift;
	$self    = $self->_base_or_child;

	return $self->_set('expr', @_);
}

sub alias	{
	my $self = shift;
	$self    = $self->_base_or_child;

	return $self->_set('alias', @_)
}

sub fallback_alias	{
	my $self = shift;
	$self    = $self->_base_or_child;

	my $fallback = @_ ? shift : 1;

	my $alias = $self->alias;

	if($alias)	{
		return $alias
	}
	else	{
		if($fallback)	{
			return $self->expr
		}
		else	{
			return undef
		}
	}
}

sub sql	{
	my $self = shift;

	return "" unless defined $self->expr && length $self->expr;
	
	return $self->expr;
}

sub quick	{
	my $class = shift;#just get rid of it
		$class = __PACKAGE__;#overwrite it
	my @return;

	foreach my $item (@_)	{
		if(ref $item eq 'ARRAY')	{
			push @return, $class->new(@$item)
		}
		elsif(ref $item eq 'HASH')	{
			foreach my $key (keys %$item)	{
				push @return, $class->new($key, $$item{$key})
			}
		}
		else	{
			push @return, $item
		}
	}

	return @return
}

sub select	{
	my $self = shift;
	$self    = $self->_base_or_child;

	return $self if(UNIVERSAL::isa($self, 'SQL::Builder::AliasSelect'));
	
	if(!$$self{alias_select})	{
		$$self{alias_select} = SQL::Builder::AliasSelect->new();
		$$self{alias_select}->_base($self);
	}
	
	return $$self{alias_select};
}

sub reference	{
	my $self = shift;
	$self    = $self->_base_or_child;

	return $self if(UNIVERSAL::isa($self, 'SQL::Builder::AliasName'));

	if(!$$self{alias_ref})	{
		$$self{alias_ref} = SQL::Builder::AliasName->new();
		$$self{alias_ref}->_base($self);
	}
	
	return $$self{alias_ref};
}

1;
