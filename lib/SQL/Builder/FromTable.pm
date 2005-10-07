#!/usr/bin/perl

package SQL::Builder::FromTable;
# <table> [as] [alias] [(column aliases)]

use warnings;
use strict;

use SQL::Builder::List;
use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub init	{
	my $self = shift;

	$self->SUPER::init();
	
	{
		my $list = SQL::Builder::List->new;
		$list->options(parens => 1);
		$self->col_container($list);
	}

	return $self
}

sub set	{
	my ($self, $table, $table_alias, @col_aliases) = @_;

	$self->table($table)		 if $table;

	$self->alias($table_alias) if defined $table_alias;

	$self->cols(@col_aliases)	 if @col_aliases;

	return $self
}

sub alias	{
	return shift->_set('table_alias', @_)
}

sub table	{
	return shift->_set('table', @_)
}

sub cols	{
	return shift->col_container->list(@_)
}

sub col_container	{
	return shift->_set('cols', @_)
}

sub only	{
	return shift->_set('from_only', @_)
}

sub use_as	{
	return shift->_set('use_as', @_)
}

sub sql	{
	my $self  = shift;
	my $table = $self->cansql($self->table);
	my $cols  = $self->cansql($self->col_container->sql);
	my $template;

		if(defined $table)	{
			$template = $self->only ? "ONLY $table" : "$table";
		}

	my $has_tbl_alias = UNIVERSAL::can($self->table, 'alias')
				&& defined $self->table->alias;
	my $use_tbl_alias = !defined($self->options('use_table_alias'))
				|| $self->options('use_table_alias');
	my $alias;

	return "" unless defined $table;
	
	# determine the alias
	if ($use_tbl_alias && $has_tbl_alias)	{
		$alias = $self->table->alias
	}
	elsif (defined $self->alias)	{
		$alias = $self->alias
	}
	
	# set the alias if we can
	if(defined $alias)	{

		my $use_as = $self->use_as;
		
		if($use_as || !defined $use_as)	{
			$template .= " AS $alias"
		}
		else	{
			$template .= " $alias"
		}
	}
	
	# add column aliases if needed
	if (length($cols) && defined $cols)	{
		return "$template $cols"
	}
	else	{
		return $template
	}
}


1;
