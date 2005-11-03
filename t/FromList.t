use Test::More tests => 14;

BEGIN { use_ok('SQL::Builder::FromList') };
BEGIN { use_ok('SQL::Builder::Table') };
BEGIN { use_ok('SQL::Builder::FromTable') };
BEGIN { use_ok('SQL::Builder::Join') };

use warnings;
use strict;

## make sure we can do the most basic instantiation

my $list = SQL::Builder::FromList->new('tables->list_push' => [qw(t1 t2)]);

is($list->sql, "FROM t1, t2", "instantiate with two string tables");

## make table objects for play

my $t1 = SQL::Builder::Table->new(table => "table1", 'other->list_push' => "schm");
my $t2 = SQL::Builder::Table->new(table => "table2", alias => "t2", 'other->list_push' => "schm");

ok($t1, "t1 created");
ok($t2, "t2 created");


$list->tables->list_clear;
$list->tables->list_push($t1, $t2);

my $FROM = "FROM schm.table1, schm.table2 AS t2";

is($list->sql, $FROM, "sql works when passing sql objects");

## test add table

$list->add_table(table => "table3", alias => "t3", 'col_container->list_push' => [qw(one two three)]);

$FROM = "$FROM, table3 AS t3 (one, two, three)";

is($list->sql, $FROM, "add_table with alias and alias cols");

### test it with no alias, no alias cols

$list->add_table(table => "table4");

$FROM = "$FROM, table4";

is($list->sql, $FROM, "add table with no alias or cols");

### test with table, no alias, cols
# against sql standard, but not my problem

$list->add_table(table => "table5", 'col_container->list_push' => [qw(a b c)]);

$FROM = "$FROM, table5 (a, b, c)";

is($list->sql, $FROM, "add_table() with no alias, but with alias cols");

## test joins

my $j = SQL::Builder::Join->new(table => "jtable1", type => "LEFT", 'on->list_push' => "j = 10");

$FROM = "$FROM\nLEFT JOIN jtable1 ON j = 10";

$list->joins->list_push($j);

is($list->sql, $FROM, "adding join manually");

### test with add_join

$list->add_join(table => "jtable2", 'on->list_push', "b = 50");

$FROM = "$FROM\nJOIN jtable2 ON b = 50";

is($list->sql, $FROM, "add_join shortcut");

# now make sure it returns nothing when it's supposed to

$list = SQL::Builder::FromList->new();

is($list->sql, "", "empty returns empty");
