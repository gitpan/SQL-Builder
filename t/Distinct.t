use Test::More tests => 12;

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

$d->cols->list([]);
$d->cols->options(default_select => '');

is($d->sql, "DISTINCT ON (foo, bar)", "empty columns with ON works");

$d->cols->options(default_select => undef);

## test the quick methods

$d = SQL::Builder::Distinct->quick({
	on => [qw(foo bar baz)]
});

is($d->sql, "DISTINCT ON (foo, bar, baz) *", "hashref with on");

$d = SQL::Builder::Distinct->quick({
	cols => [qw(foo bar baz)]
});

is($d->sql, "DISTINCT foo, bar, baz", "hashref with cols");

$d = SQL::Builder::Distinct->quick({
	cols => [qw(foo bar baz quux)],
	on => [qw(foo bar baz)]
});

is($d->sql, "DISTINCT ON (foo, bar, baz) foo, bar, baz, quux", "hashref with cols and on");

eval{$d->quick()};

ok($@, "died as expected with quick");

$d->options(distinct => 0);

is($d->sql, "foo, bar, baz, quux", "distinct => 0");
