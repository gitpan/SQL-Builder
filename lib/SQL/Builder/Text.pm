#!/usr/bin/perl

package SQL::Builder::Text;

use warnings;
use strict;

use SQL::Builder::Base;
use base qw(SQL::Builder::Base);

our $QUOTER = sub {
	my $var = shift;

	return "NULL" unless defined $var;
	
	$var =~ s/'/\\'/g;
	
	return "'$var'"
};

sub quoter	{
	shift;#get rid of object

	if(@_)	{
		$QUOTER = shift;
	}

	return $QUOTER
}

sub text	{
	return shift->_set('text', @_)
}

sub children	{
	my $self = shift;

	return $self->_make_children_iterator([
		$self->text
	])
}

sub sql	{
	my $self = shift;
	my $text = $self->dosql($self->text);

	return $self->quoter->($text)
}

1;

=head1 NAME

SQL::Builder::Text - represent values to be quoted in SQL

=head1 SYNOPSIS

This hasn't had much work done to it yet and will change significantly next
release.

	my $text = SQL::Builder::Text->new(text => "a simple string");

	# 'a string'
	print $text->sql

Hopefully this will act more like SQL::Builder::Table(3) and
SQL::Builder::Column(3) in terms of quoting mechanisms and support

=head1 DESCRIPTION

This inherits from SQL::Builder::Base(3)

=head1 METHODS

=head2 sql()

Returns the SQL serialization. Filters the value of text() through
SQL::Builder::Base::dosql() then quotes it.

=head2 text([$item])

Get/set the value to be quoted. If arguments are passed then the value is set
and current object returned. If no arguments present the current value is
returned.

=head2 children()

Return a SQL::Builder::Iterator(3) object to iterate over the value of text()

=head1 SEE ALSO

SQL::Builder::Placeholder(3)
SQL::Builder::Base(3)
SQL::Builder(3)
