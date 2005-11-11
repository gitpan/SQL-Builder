use Test::More tests => 5;
use strict;
use warnings;

BEGIN { use_ok('SQL::Builder::Delete') };


# $table is a SQL::Builder::Table object or a string

my $del = SQL::Builder::Delete->new;

$del->table("table");

$del->where->list_push(
	# primary_key = 50
	SQL::Builder::BinaryOp->new(
		lhs => "primary_key",
		op  => "=",
		rhs => 50
	)
);

# DELETE FROM table WHERE primary_key = 50

is($del->sql, "DELETE FROM table WHERE primary_key = 50", "basic del with table and where");

$del->only(1);

# DELETE FROM ONLY table WHERE primary_key = 50
is($del->sql, "DELETE FROM ONLY table WHERE primary_key = 50", "basic del with table and where + ONLY");

$del->table("");

# ""
is($del->sql, "", "empty table returns ''");

$del->table("table");

$del->where->list_clear();

$del->only(0);

# DELETE FROM table
is($del->sql, "DELETE FROM table", "truncate");

