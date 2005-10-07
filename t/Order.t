use Test::More tests => 10;
BEGIN { use_ok('SQL::Builder::Order') };

#empty object creation
my $o = SQL::Builder::Order->new();

$o->set('e', SQL::Builder::Order::ASC);
is($o->sql, "e ASC", "asc works");

$o->set('e', SQL::Builder::Order::DESC);
is($o->sql, "e DESC", "desc works");

$o->set('e', using => ">");
is($o->sql, "e DESC", "asc/desc precedence works");

$o->order(undef);
is($o->sql, "e USING >");

$o = SQL::Builder::Order->new("col");

is($o->sql, "col");

my @o = $o->quick(
	{expr => "expr", order => "ASC"},
	{expr => "expr", using => "+"},
	["expr", "DESC"],
	"foo"
);

is($o[0]->sql, "expr ASC", "quick hash simple");
is($o[1]->sql, "expr USING +", "quick hash using");
is($o[2]->sql, "expr DESC", "quick aref");
is($o[3], "foo", "quick other");
