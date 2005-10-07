use Test::More tests => 3;

BEGIN { use_ok('SQL::Builder::OrderBy') };

my $list = SQL::Builder::OrderBy->new();

$list->set([qw(foo bar baz)]);

is($list->sql, "ORDER BY foo, bar, baz");

my $t = $list->quick(
	{expr => "expr", order => "ASC"},
	{expr => "expr", using => "+"},
	["expr", "DESC"],
	"foo"
);

is($t->sql, "ORDER BY expr ASC, expr USING +, expr DESC, foo", "quick order");
