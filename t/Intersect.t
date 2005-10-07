use Test::More tests => 4;
BEGIN { use_ok('SQL::Builder::Intersect') };

my $u = SQL::Builder::Intersect->new();

is($u->sql, "", "empty works right");

$u->list_push("foo");
$u->list_push("bar");

is($u->sql, "foo INTERSECT bar", "sql is good");

$u->all(1);

is($u->sql, "foo INTERSECT ALL bar", "all sql is good");
