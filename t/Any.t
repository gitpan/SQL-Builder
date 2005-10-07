use Test::More tests => 4;

BEGIN { use_ok('SQL::Builder::Any') };

my $any = SQL::Builder::Any->new;

is($any->sql, "", "empty works");

$any->set([qw(foo bar baz)]);

is($any->sql, "foo bar baz", "set works, sql works");

## test the quick thing

my @bar = $any->quick(qw(foo bar baz));

is($bar[0]->sql, "foo bar baz");
