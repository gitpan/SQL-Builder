use Test::More tests => 12;

BEGIN { use_ok('SQL::Builder::FromTable') };
BEGIN { use_ok('SQL::Builder::Table') };

## test empty object
{
	my $from = SQL::Builder::FromTable->new();
	is($from->sql, "", "empty returns empty");
}

## test with raw sql strings. some of these tests are done in FromList.t!!!
{
	my $from = SQL::Builder::FromTable->new("table1", "t1", qw(one two three));

	is($from->sql, "table1 AS t1 (one, two, three)", "gen from strings");
}

## test with raw sql strings. no alias, but cols
{
	my $from = SQL::Builder::FromTable->new("table1", undef, qw(one two three));

	is($from->sql, "table1 (one, two, three)", "gen from strings, no alias");
}

## test using a table object with its own alias, with col aliases
{
	my $table = SQL::Builder::Table->new("table1", "t1", "schema");
	my $from  = SQL::Builder::FromTable->new($table, undef, qw(one two three));

	is($from->sql, "schema.table1 AS t1 (one, two, three)", "table object with alias and alias cols");
	
	# set an alias to prove it won't be used if the table has an alias
	$from->alias("wontmatter");

	is($from->sql, "schema.table1 AS t1 (one, two, three)", "table object with aslias and no alias cols, with table_alias set in from obj");

	### test column accessor
	$from->col_container->list_clear;

	is($from->sql, "schema.table1 AS t1");
	
	### test ONLY option

	$from->only(1);

	is($from->only, 1, "ONLY storage");

	is($from->sql, "ONLY schema.table1 AS t1", "only serialize works");

	### test "AS" usage option

	$from->use_as(0);

	is($from->use_as, 0, "use_as storage");

	is($from->sql, "ONLY schema.table1 t1", "no use_as serialize");
}
