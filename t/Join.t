use Test::More tests => 9;
use strict;
use warnings;

BEGIN { use_ok('SQL::Builder::Join') };

my $j = SQL::Builder::Join->new('table->table' => "table", type => "FUNKY", 'on->list_push' => "funky = bar");

ok($j, "object created");

is($j->table->table, "table", "table storage");
is($j->type, "FUNKY", "type storage");
is($j->on->sql, "funky = bar", "on storage");

$j->using("foo bar baz");
is($j->using(), "foo bar baz", "using storage");

is($j->sql, "FUNKY JOIN table ON funky = bar", "ON sql works");

$j->on('');
is($j->sql, "FUNKY JOIN table foo bar baz", "USING sql works");

$j->natural(1);

is($j->sql, "NATURAL FUNKY JOIN table", "natural works");
