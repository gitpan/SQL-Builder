use Test::More tests => 9;
use strict;
use warnings;

BEGIN { use_ok('SQL::Builder::Table') };

my $c = SQL::Builder::Table->new(table => "table", alias => "alias", 'other->list_push' => "schema");

ok($c, "object created");

is($c->table, "table", "table storage works");

is($c->other->sql, "schema", "other storage works");

is($c->sql, "schema.table", "sql works");

$c->quoter( sub {return "`$_[1]`"});
$c->options(quote => 1);

is($c->sql, "`schema`.`table`", "quoter option works");

$c->quoter(undef);


$c->alias("funkytown");
is($c->alias, "funkytown", "alias storage works");

$c->alias(undef);

is($c->alias, undef, "alias unset works");

my $col = $c->col(name => "foo");
is($col->sql, "schema.table.foo", "column works");

