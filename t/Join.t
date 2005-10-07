use Test::More tests => 15;

BEGIN { use_ok('SQL::Builder::Join') };

my $j = SQL::Builder::Join->new("table", "FUNKY", "funky = bar");

ok($j, "object created");

is($j->table->table, "table", "table storage");
is($j->type, "FUNKY", "type storage");
is($j->on->sql, "funky = bar", "on storage");

$j->using("foo bar baz");
is($j->using(), "foo bar baz", "using storage");

is($j->sql, "FUNKY JOIN table ON funky = bar", "ON sql works");

$j->on('');
is($j->sql, "FUNKY JOIN table foo bar baz", "USING sql works");

$j->natural(1);

is($j->sql, "NATURAL FUNKY JOIN table", "natural works");

## test the quick method stuff

$j = $j->quick("foo");

is($j, "foo", "quick with scalar");

$j = SQL::Builder::Join->quick({
	table => "herro",
	on => "foo = bar"
});

is($j->sql, "JOIN herro ON foo = bar", "quick simple join");

$j = $j->quick({
	table => "foo",
	on => {j => 10, b => 50},
	type => "LEFT"
});

ok(
	$j->sql eq "LEFT JOIN foo ON (j = 10 AND b = 50)"
	 || $j->sql eq "LEFT JOIN foo ON (b = 50 AND j = 10)",
	"quick more complex"
);

$j = $j->quick({
	table => "foo",
	using => [qw(a b c)]
});

is($j->sql, "JOIN foo USING(a, b, c)", "quick with using");

$j = $j->quick({
	table => "foo",
	natural => 1,
	on => "j = 1"
});

is($j->sql, "JOIN foo ON j = 1", "quick natural less precedence than ON");

$j = $j->quick(["table"]);

is($j->sql, "JOIN table", "quick aref");
