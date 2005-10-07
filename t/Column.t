use Test::More tests => 13;

BEGIN { use_ok('SQL::Builder::Column') };

my $c = SQL::Builder::Column->new("col", "alias", "table", "schema");

ok($c, "object created");

is($c->col, "col", "col storage works");

is(scalar(@{$c->other}), 2, "other storage works");

is($c->sql, "schema.table.col", "sql works");

$c->quoter( sub {return "`$_[0]`"});
$c->options(quote => 1);

is($c->sql, "`schema.table.col`", "quoter option works");

$c->quoter(undef);

$c->alias("funkytown");
is($c->alias, "funkytown", "alias storage works");

$c->alias(undef);

is($c->alias, undef, "alias unset works");

$c->col("foo");
$c->alias("bar");


## test expression handling

my @list = SQL::Builder::Column->quick(
	['refcol', 'alias', "table"],
	$c,
	"scalarcol",
	{
		col => "col",
		other => "table",
		alias => "bar"
	}
);


is($list[0]->sql, "table.refcol", "ref expr works");
is($list[1]->sql, "schema.table.foo", 'obj expr works');
is($list[2]->sql, "scalarcol", "string expr works");
is($list[3]->sql, "table.col", "quick hash");
is($list[3]->alias, "bar", "quick hash alias");
