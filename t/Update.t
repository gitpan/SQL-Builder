use Test::More tests => 12;
use strict;
use warnings;

BEGIN { use_ok('SQL::Builder::Update') };
BEGIN { use_ok('SQL::Builder::Column') };


{

	my $upd = SQL::Builder::Update->new;

	is($upd->sql, "", "empty returns empty");

	$upd->table("tbl");

	is($upd->sql, "", "empty cols returns empty");

	$upd->columns->list_push("foo = 15");

	is($upd->sql, "UPDATE tbl SET foo = 15", "update with no WHERE or FROM");

	$upd->only(1);

	is($upd->sql, "UPDATE ONLY tbl SET foo = 15", "update with no WHERE or FROM with ONLY");

	$upd->only(0);

	$upd->where->list_push("primary_id = 50");

	is($upd->sql, "UPDATE tbl SET foo = 15\nWHERE primary_id = 50", "update with no FROM");

	$upd->from->list_push("foo");

	is($upd->sql, "UPDATE tbl SET foo = 15 FROM foo\nWHERE primary_id = 50", "update with no FROM");


	$upd->add_join(
			table => "bar",
			on    => "bar.id = foo.id"
		      );

	is($upd->sql, "UPDATE tbl SET foo = 15 FROM foo\nJOIN bar ON bar.id = foo.id\nWHERE primary_id = 50", "update with no FROM");

	$upd->update(
			baz => 50
		    );

	is($upd->sql, "UPDATE tbl SET foo = 15, baz = 50 FROM foo\nJOIN bar ON bar.id = foo.id\nWHERE primary_id = 50", "update with no FROM");

}

{
	my $col = SQL::Builder::Column->new(name => "foo", 'other->list_push' => 'schema');
	my $upd = SQL::Builder::Update->new();

	$upd->table("bar");

	$upd->update($col => 15);

	is($upd->sql, "UPDATE bar SET foo = 15", "column obj update using use_names");
}

{
	my $col = SQL::Builder::Column->new(name => "foo", 'other->list_push' => 'schema');
	my $upd = SQL::Builder::Update->new();

	$upd->table("bar");
	$upd->use_names(0);

	$upd->update($col => 15);

	is($upd->sql, "UPDATE bar SET schema.foo = 15", "column obj update using use_names");

}
