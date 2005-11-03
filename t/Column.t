use Test::More tests => 10;
use strict;
use warnings;

BEGIN { use_ok('SQL::Builder::Column') };
BEGIN { use_ok('SQL::Builder::Table') };

my $c = SQL::Builder::Column->new(
	col => 'col',
	alias => 'alias',
	'other->list_push' => [qw(table schema)]
);

ok($c, "object created");

is($c->col, "col", "col storage works");

is(scalar(@{$c->other->list}), 2, "other storage works");

is($c->full_name, "schema.table.col", "sql works");

$c->quoter( sub {return "'$_[1]'"});
$c->quote(1);

is($c->full_name, "'schema'.'table'.'col'", "quoter option");

$c->quoter(undef);

$c->alias("funkytown");
is($c->alias, "funkytown", "alias storage works");

$c->alias(undef);

is($c->alias, undef, "alias unset works");

$c->col("foo");
$c->alias("bar");


{
	my $users   = SQL::Builder::Table->new(name => "users", alias => "u");

	my $user_id = SQL::Builder::Column->new(
			name => "user_id",
			other => $users
		);

	# u.user_id
	is($user_id->sql, "u.user_id", "full_name uses other() when it has an alias");

}
