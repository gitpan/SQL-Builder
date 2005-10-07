#!/usr/bin/perl

package SQL::Builder::ColumnList;

use warnings;
use strict;

use SQL::Builder::List;

use base qw(SQL::Builder::List);

sub init	{
	my $self = shift;

	$self->SUPER::init();

	$self->joiner(", ");
	$self->options(parens => 0);

	return $self;
}


# convenience wrapper to PARENT::list()
sub cols	{
	return shift->list(@_)
}

sub sql	{
	my $self = shift;
	my $cols = $self->cols;
	
	if(@$cols)	{
		my $use_aliases = $self->options('use_column_alias');
			$use_aliases = $use_aliases || !defined $use_aliases;

		my $use_as      = $self->options('use_as');
			$use_as = $use_as || !defined $use_as;

		if($use_aliases)	{
			my @sql_cols;

			foreach my $col (@$cols)	{

				my $sql = $self->cansql($col);

				if(UNIVERSAL::can($col, 'alias') && defined $col->alias)	{

					if($use_as)	{

						push @sql_cols, "$sql AS " . $col->alias
					}
					else	{
						
						push @sql_cols, "$sql " . $col->alias
					}
				}
				else	{

					push @sql_cols, $sql
				}
			}
			
			# temporarily use the sql we built and let the parent
			# do the processing, then set the user columns back and return

			$self->cols(\@sql_cols);

			my $sql = $self->SUPER::sql;

			$self->cols($cols);

			return $sql
		}
		else	{
			return $self->SUPER::sql
		}
	}

	# if we don't have anything to return, use defaults
	
	my $default = $self->options('default_select');

	if(!defined($default))	{
		return "*"
	}
	elsif(length $default)	{
		return $default;
	}
	else	{
		return ""
	}
}

1;
