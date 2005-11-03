use Test::More tests => 2;
use strict;
use warnings;

BEGIN { use_ok('SQL::Builder::OrderBy') };

my $list = SQL::Builder::OrderBy->new();

$list->set(list => [qw(foo bar baz)]);

is($list->sql, "ORDER BY foo, bar, baz");
