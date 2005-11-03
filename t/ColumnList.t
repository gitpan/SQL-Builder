use Test::More tests => 9;
use strict;
use warnings;

BEGIN {
	use_ok('SQL::Builder::ColumnList');
	use_ok('SQL::Builder::Column');
};

my $l = SQL::Builder::ColumnList->new();

ok($l, "new object obtained");

is($l->sql, "*", "default as *");

$l->list_push(
	SQL::Builder::Column->new(col => 'col1', alias => 'alias1', 'other->list_push' => 'table1')
);

is($l->sql, "table1.col1 AS alias1", "use alias if avail on list items");

$l->use_as(0);

is($l->sql, "table1.col1 alias1", "use_as turned off");

$l->use_aliases(0);

is($l->sql, "table1.col1", "use col alias");

$l = SQL::Builder::ColumnList->new();

$l->list_push(SQL::Builder::Column->new(col => 'col1', 'other->list_push' => 'table1'));

is($l->sql, "table1.col1", "uses fqn when no alias");


$l->default_select("foozle");

$l->list_clear();

is($l->sql, "foozle", "default_select set works");
