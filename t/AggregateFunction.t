use Test::More tests => 2;

BEGIN { use_ok('SQL::Builder::AggregateFunction') };

my $func = SQL::Builder::AggregateFunction->new("COUNT", "*");

is($func->sql, "COUNT(*)", "good aggregate sql");
