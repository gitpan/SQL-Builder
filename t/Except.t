use Test::More tests => 4;
BEGIN { use_ok('SQL::Builder::Except') };

my $u = SQL::Builder::Except->new();

is($u->sql, "", "empty works right");

$u->list_push("foo");
$u->list_push("bar");

is($u->sql, "foo EXCEPT bar", "sql is good");

$u->all(1);

is($u->sql, "foo EXCEPT ALL bar", "all sql is good");
