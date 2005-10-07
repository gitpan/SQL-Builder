use Test::More tests => 12;

BEGIN { use_ok('SQL::Builder::Alias') };

my $a = SQL::Builder::Alias->new;

is($a->sql, "", "empty expr returns empty");

$a->expr("foo");

is($a->expr, "foo", "single expr works");

is($a->fallback_alias, "foo", "fallback works");

is($a->fallback_alias(0), undef, "fallback config works");

$a->alias("bar");

is($a->fallback_alias, "bar", "fallback works with alias");

is($a->select->sql, "foo AS bar", "complete works");

$a->set("bar", "foo");

is($a->select->sql, "bar AS foo", "set works");

is($a->sql, "bar", "sql returns expr");


## test the expression business

my @list = SQL::Builder::Alias->quick(
	['col', 'alias'],
	{foo => 'bar'},
	"string"
);

is($list[0]->select->sql, 'col AS alias', "aref expr works");
is($list[1]->select->sql, 'foo AS bar', 'hashref expr 2 works');
is($list[2], 'string', 'string expr works');
