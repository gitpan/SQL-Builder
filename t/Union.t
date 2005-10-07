use Test::More tests => 4;
BEGIN { use_ok('SQL::Builder::Union') };

my $u = SQL::Builder::Union->new();

is($u->sql, "", "empty works right");

$u->list_push("foo");
$u->list_push("bar");

is($u->sql, "foo UNION bar", "sql is good");

$u->all(1);

is($u->sql, "foo UNION ALL bar", "all sql is good");
