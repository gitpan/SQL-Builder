use Test::More tests => 15;

BEGIN { use_ok('SQL::Builder::Table') };

my $c = SQL::Builder::Table->new("table", "alias", "schema");

ok($c, "object created");

is($c->table, "table", "table storage works");

is(scalar(@{$c->other}), 1, "other storage works");

is($c->sql, "schema.table", "sql works");

$c->quoter( sub {return "`$_[0]`"});
$c->options(quote => 1);

is($c->sql, "`schema.table`", "quoter option works");

$c->quoter(undef);


$c->alias("funkytown");
is($c->alias, "funkytown", "alias storage works");

$c->alias(undef);

is($c->alias, undef, "alias unset works");

my $col = $c->col("foo");
is($col->sql, "schema.table.foo", "column works");

$c->col($col);
is($col->sql, "schema.table.foo", "column with obj works");

## quick methods

my @c = $c->quick(
	{
		table => "funky",
		alias => "town",
		other => "database"
	},
	[qw(table alias db)],
	"table",
	$col
);

is($c[0]->sql, "database.funky", "quick hash basic");
is($c[0]->alias, "town", "quick hash alias");
is($c[1]->sql, "db.table", "quick aref");
is($c[2]->sql, "table", "quick with scalar");
is($c[3]->sql, "schema.table.foo", "quick with obj");

