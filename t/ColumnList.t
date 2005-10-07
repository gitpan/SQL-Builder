use Test::More tests => 2;
BEGIN { use_ok('SQL::Builder::ColumnList') };

my $l = SQL::Builder::ColumnList->new();

ok($l, "new object obtained");
