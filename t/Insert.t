use Test::More tests => 5;
use strict;
use warnings;

BEGIN { use_ok('SQL::Builder::Insert') };
BEGIN { use_ok('SQL::Builder::Function') };


	my $insert = SQL::Builder::Insert->new;

	$insert->table('foo');

	$insert->insert(
		bar => 15,
		baz  => 30,
		bang => SQL::Builder::Function->new(
			name => 'CURRENT_TIME',
			parens => 0
		)
	);

	# INSERT INTO foo (bar, baz, bang) VALUES (15, 30, CURRENT_TIME)
	is(
		$insert->sql,
		"INSERT INTO foo (bar, baz, bang) VALUES (15, 30, CURRENT_TIME)",
		"basic insert"
	);

	$insert->use_column_list(0);

	# INSERT INTO foo VALUES (15, 30, CURRENT_TIME)
	is($insert->sql, "INSERT INTO foo VALUES (15, 30, CURRENT_TIME)", "no col list");


	$insert->is_select(1);
	$insert->values("SELECT abc, def, ghi FROM other_table");

	# INSERT INTO foo SELECT abc, def, ghi FROM other_table
	is($insert->sql, "INSERT INTO foo SELECT abc, def, ghi FROM other_table", "INSERT SELECT works")

