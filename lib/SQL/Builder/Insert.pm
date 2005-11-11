#!/usr/bin/perl

package SQL::Builder::Insert;

use warnings;
use strict;

use Carp qw(confess);

use SQL::Builder::Base;
use base qw(SQL::Builder::Base);

use SQL::Builder::List;


sub init	{
	my $self = shift;

	$self->SUPER::init;
	
	$self->columns(SQL::Builder::List->new);
	$self->values(SQL::Builder::List->new);
	$self->use_column_list(1);

	return $self;
}


sub table	{
	return shift->_set('table', @_)
}

sub columns	{
	return shift->_set('columns', @_)
}

sub values	{
	return shift->_set('values', @_)
}

sub is_select	{
	return shift->options('is_select', @_)
}

sub use_column_list	{
	return shift->options('use_column_list', @_)
}

sub insert	{
	my ($self, @data) = @_;

	confess "Expecting even-numbered list"
		if scalar(@data) % 2;

	while(@data)	{
		my $col = shift @data;
		my $val = shift @data;

		$self->columns->list_push($col);
		$self->values->list_push($val)
	}

	return $self
}

sub sql	{
	my $self = shift;

	my ($table, $cols, $values) = map {$self->dosql($_)}
					($self->table, $self->columns, $self->values);

	my $sql = "INSERT INTO $table";

	if(defined($cols) && length($cols) && $self->use_column_list)	{
		
		$sql .= " ($cols)"
	}

	if($self->is_select)	{
		
		$sql .= " $values";
	}
	else	{
		
		$sql .= " VALUES ($values)"
	}

	return $sql;
}

1;

=head1 NAME

SQL::Builder::Insert - Represent a SQL INSERT statement

=head1 SYNOPSIS

This class can build an INSERT using the 'VALUES' keyword or insert values based
on the result of a SELECT clause, if the DBMS in use supports it.

The typical INSERT:

	my $insert = SQL::Builder::Insert->new;

	$insert->table('foo');

	$insert->insert(
		bar => 15,
		baz  => 30,
		bang => SQL::Builder::Function->new(
			name => 'CURRENT_TIME',
			parens => 0
		)
	);

	# INSERT INTO foo (bar, baz, bang) VALUES (15, 30, CURRENT_TIME)
	print $insert->sql;

It's possible to omit the column list like so:

	$insert->use_column_list(0);

	# INSERT INTO foo VALUES (15, 30, CURRENT_TIME)
	print $insert->sql;

And to use a query for the INSERT values:

	$insert->is_select(1);
	$insert->values("SELECT abc, def, ghi FROM other_table");

	# INSERT INTO foo SELECT abc, def, ghi FROM other_table
	print $insert->sql;

=head1 DESCRIPTION

This class inherits from SQL::Builder::Base

columns() and values() maintain SQL::Builder::List(3) objects by default, so
it's possible to easily populate either of them manually; insert() is only a
convenience method

=head1 METHODS

=head2 columns([$list])

Get/set the value of the column list used in the statement. BY default this is
populated with a SQL:::Buider::List object. Pass a new value to change it and
return the current object; no arguments returns the current value

=head2 init()

Calls ini() on the parent class, sets default values for columns(), values(),
and use_column_alias()

=head2 insert($col, $val, ...)

This is a convenience method which appends the given items to the list
maintained by columns() and values(), respectively. One could just as easily do:

	$insert->columns->list_push("baz");
	$insert->values->list_push(50);

=head2 is_select([1|0])

This controls the behavior of the SQL serialization. When this is turned on, the
'VALUES' keyword is not used in the INSERT statement, and the value of this
method, after processed through SQL::Builder::Base::dosql(), will be used
instead. Pass 1/0 to turn it on/off, no arguments to return the current value

=head2 sql()

Return the SQL serialization. See the SYNOPSIS for examples of its behavior. If
the value of columns() filtered through SQL::Builder::Base::dosql() returns a
value with a length and use_column_list() returns true, then a column list is
used in the SQL statement. If is_select() returns true, the value of values()
filtered through SQL::Builder::Base::dosql() is used without the 'VALUES'
keyword and parenthesis; otherwise the value is wrapped in them and preceded by
the keyword.

=head2 table([$table])

Get/set the table on which the INSERT statement will be executed. Pass a table
to set it and return the current object; no arguments will return the current
value.

=head2 use_column_list([1|0])

Get/set the option to use the column list in the SQL INSERT statement. Turned on
by default. Pass arguments to turn it on/off and return the current value,
no arguments will return the current value

=head2 values([$values])

By default this method will return a SQL::Builder::List(3) object. To change
this pass arguments which will set it and return the current object, no
arguments will return the current value. This value is used by sql() to generate
the list of values (think VALUES) in the INSERT statement

=head1 SEE ALSO

SQL::BUilder::Select(3)
SQL::BUilder::Delete(3)
SQL::BUilder::Update(3)
SQL::BUilder::Base(3)
