use Test::More tests => 4;
use strict;
use warnings;

BEGIN { use_ok('SQL::Builder::Having') };

my $h = SQL::Builder::Having->new();

is($h->sql, "", "none set, none returned");

$h->expr("foo!");

is($h->sql, "HAVING foo!", "sql works");

$h = $h->new();

$h->expr->list_push("COUNT(*) > 10");

is($h->sql, "HAVING COUNT(*) > 10", "list push");
