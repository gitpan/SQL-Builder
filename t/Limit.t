use Test::More tests => 6;
use strict;
use warnings;

BEGIN { use_ok('SQL::Builder::Limit') };

my $limit = SQL::Builder::Limit->new(limit => 5, offset => 10);

is($limit->limit, 5, "limit storage works");
is($limit->offset, 10, "offset storage works");

is($limit->sql, "LIMIT 5 OFFSET 10", "sql is good");

$limit->offset(undef);

is($limit->sql, "LIMIT 5", "just limit sql is good");

$limit->limit(undef);

is($limit->sql, "", "empty args good");

