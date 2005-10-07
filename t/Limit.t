use Test::More tests => 11;

BEGIN { use_ok('SQL::Builder::Limit') };

my $limit = SQL::Builder::Limit->new(5, 10);

is($limit->limit, 5, "limit storage works");
is($limit->offset, 10, "offset storage works");

is($limit->sql, "LIMIT 5 OFFSET 10", "sql is good");

$limit->offset(undef);

is($limit->sql, "LIMIT 5", "just limit sql is good");

$limit->limit(undef);

is($limit->sql, "", "empty args good");

my $l = $limit->quick({limit => 10});

is($l->sql, "LIMIT 10", "quick with limit hash");

$l = $limit->quick({limit => 10, offset => 15});

is($l->sql, "LIMIT 10 OFFSET 15", "quick with two  key hash");

eval{$limit->quick({})};

ok($@, "hash with no args");

$l = $limit->quick(10, 15);

is($l->sql, "LIMIT 10 OFFSET 15", "quick with list");

eval{$limit->quick()};

ok($@, "quick with no args");

