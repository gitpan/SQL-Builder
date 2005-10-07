use Test::More tests => 2;

BEGIN { use_ok('SQL::Builder::GroupBy') };

my $list = SQL::Builder::GroupBy->new();

$list->set([qw(foo bar baz)]);

is($list->sql, "GROUP BY foo, bar, baz");
