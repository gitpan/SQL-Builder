use Test::More tests => 3;
use strict;
use warnings;

BEGIN { use_ok('SQL::Builder::AggregateFunction') };

my $func = SQL::Builder::AggregateFunction->new(
	'func'           => "COUNT", 
	'args-list_push' => "*"
);

is($func->sql, "COUNT(*)", "good aggregate sql");

$func = SQL::Builder::AggregateFunction->new({
	'func'           => "COUNT", 
	'args-list_push' => "*"
});

is($func->sql, "COUNT(*)", "good aggregate sql");
