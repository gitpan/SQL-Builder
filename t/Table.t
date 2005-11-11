use Test::More tests => 11;
use strict;
use warnings;

BEGIN { use_ok('SQL::Builder::Table') };

my $c = SQL::Builder::Table->new(table => "table", alias => "alias", 'other->list_push' => "schema");

ok($c, "object created");

is($c->table, "table", "table storage works");

is($c->other->sql, "schema", "other storage works");

is($c->sql, "schema.table", "sql works");

$c->quoter( sub {return "`$_[1]`"});
$c->options(quote => 1);

is($c->sql, "`schema`.`table`", "quoter option works");

$c->quoter(undef);


$c->alias("funkytown");
is($c->alias, "funkytown", "alias storage works");

$c->alias(undef);

is($c->alias, undef, "alias unset works");

my $col = $c->col(name => "foo");
is($col->sql, "schema.table.foo", "column works");


{
	my $table = SQL::Builder::Table->new(
		name => "foo",
		schema => "bar",
		db => "baz"
	);

	is($table->sql, "baz.bar.foo", "schema(), db()");

	$table->schema_elem(1);
	$table->schema("bar");

	$table->db_elem(0);
	$table->db("baz");


	is($table->sql, "bar.baz.foo", "schema(), db() element mod");
}
