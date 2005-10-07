#!/usr/bin/perl

package SQL::Builder::Select;

use warnings;
use strict;

use Carp qw(confess);


use SQL::Builder::Distinct;
use SQL::Builder::FromList;
use SQL::Builder::Where;
use SQL::Builder::GroupBy;
use SQL::Builder::Having;
use SQL::Builder::OrderBy;
use SQL::Builder::Limit;


use SQL::Builder::Base;

use base qw(SQL::Builder::Base);

sub set	{
	#dummy, not implemented, placed to avoid errors
}

=pod
	SELECT [ ALL | DISTINCT [ ON ( expression [, ...] ) ] ]
	    * | expression [ AS output_name ] [, ...]
	    [ FROM from_item [, ...] ]
	    [ WHERE condition ]
	    [ GROUP BY expression [, ...] ]
	    [ HAVING condition [, ...] ]
	    [ { UNION | INTERSECT | EXCEPT } [ ALL ] select ]
	    [ ORDER BY expression [ ASC | DESC | USING operator ] [, ...] ]
	    [ LIMIT { count | ALL } ]
	    [ OFFSET start ]
	    [ FOR UPDATE [ OF table_name [, ...] ] ]

	where from_item can be one of:

	    [ ONLY ] table_name [ * ] [ [ AS ] alias [ ( column_alias [, ...] ) ] ]
	    ( select ) [ AS ] alias [ ( column_alias [, ...] ) ]
	    function_name ( [ argument [, ...] ] ) [ AS ] alias [ ( column_alias [, ...] | column_definition [, ...] ) ]
	    function_name ( [ argument [, ...] ] ) AS ( column_definition [, ...] )
	    from_item [ NATURAL ] join_type from_item [ ON join_condition | USING ( join_column [, ...] ) ]

=cut


sub init	{
	my $self = shift;

	$self->SUPER::init;

	my $distinct = SQL::Builder::Distinct->new;
		$distinct->options(distinct => 0);
		$self->_distinct($distinct);
	
	my $from = SQL::Builder::FromList->new;
		$self->tables($from);
	
	my $where = SQL::Builder::Where->new;
		$self->where($where);

	my $group = SQL::Builder::GroupBy->new;
		$self->groupby($group);

	my $having = SQL::Builder::Having->new;
		$self->_having($having);

	my $orderby = SQL::Builder::OrderBy->new;
		$self->orderby($orderby);

	my $limit = SQL::Builder::Limit->new;
		$self->_limit($limit);
	
	return $self
}

# get the list obj containing select cols
sub cols	{
	return shift->_distinct->cols(@_)
}

# get the distinct_on list
sub distinct_on	{
	return shift->_distinct->on(@_)
}

# the internal distinct object
sub _distinct	{
	return shift->_set('distinct', @_)
}

# turn on/off distinct
sub distinct	{
	my $self = shift;
	
	if(@_)	{
		return $self->_distinct->options(distinct => shift)
	}
	else	{
		return $self->_distinct->options('distinct')
	}
}

# list obj of tables
sub tables	{
	return shift->_set('fromlist', @_)
}

# list obj of joins
sub joins	{
	return shift->tables->joins(@_)
}

# list obj of AND for exprs
sub where	{
	return shift->_set('where', @_)
}

# list obj of groups
sub groupby	{
	return shift->_set('groupby', @_)
}

# obj of having
sub _having	{
	return shift->_set('having', @_)
}

# list obj of binary op AND
sub having	{
	return shift->_having->expr
}

# list obj of order by
sub orderby	{
	return shift->_set('orderby', @_)
}

# limit obj
sub _limit	{
	return shift->_set('limit', @_)
}

# limit val
sub limit	{
	return shift->_limit->limit(@_)
}

# offset val
sub offset	{
	return shift->_limit->offset(@_)
}

sub sql	{
	my $self = shift;
	
	# just one thing
	my $sql = "SELECT" ;

	#distinct
	$sql .= " " . $self->cansql($self->_distinct);

	#tables -- make sure we have some or throw an error
	$sql .= "\n" . $self->cansql($self->tables);

	confess "Expecting at least one table in SELECT"
		unless length($self->cansql($self->tables)) && defined $self->cansql($self->tables);

	# where clause
	$sql .= "\n" . $self->cansql($self->where);

	#groupby
	$sql .= "\n" . $self->cansql($self->groupby);

	#having
	$sql .= "\n" . $self->cansql($self->_having);

	#order
	$sql .= "\n" . $self->cansql($self->orderby);

	#limit
	$sql .= "\n" . $self->cansql($self->_limit);
	
	return $sql
}

1;
