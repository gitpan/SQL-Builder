use Test::More tests => 2;
use strict;
use warnings;

BEGIN { use_ok('SQL::Builder::In') };

my $in = SQL::Builder::In->new();

$in->lhs("col1");
$in->rhs->list_push(qw(foo bar baz quux));

is($in->sql, "col1 IN (foo, bar, baz, quux)");
