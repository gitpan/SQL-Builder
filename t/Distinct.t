use Test::More tests => 7;
use strict;
use warnings;

BEGIN { use_ok('SQL::Builder::Distinct') };

my $d = SQL::Builder::Distinct->new();

is($d->sql, "DISTINCT *", "returns empty by default");

$d->options(always_return => 1);

is($d->sql, "DISTINCT *", "returns keyword when option is set and empty list");

$d->options(always_return => 0);

$d->cols->list_push("crapola");

is($d->sql, "DISTINCT crapola", "column push works");

$d->cols->list_push("bar");

is($d->sql, "DISTINCT crapola, bar", "two items in columns works");

$d->on->list_push("foo", "bar");

is($d->sql, "DISTINCT ON (foo, bar) crapola, bar", "on and list works");

$d->cols->list_clear();
$d->cols->options(default_select => '');

is($d->sql, "DISTINCT ON (foo, bar)", "empty columns with ON works");

$d->cols->options(default_select => undef);
