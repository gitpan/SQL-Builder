use Test::More tests => 2;

BEGIN { use_ok('SQL::Builder::In') };

#uses base class List, should already be working

my $in = SQL::Builder::In->new();
$in->set([qw(foo bar baz quux)]);

is($in->sql, "IN (foo, bar, baz, quux)");
