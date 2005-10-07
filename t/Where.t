use Test::More tests => 6;

#does it load
BEGIN { use_ok('SQL::Builder::Where') };

my $w = SQL::Builder::Where->new();

$w->set(qw(foo bar));

is($w->sql, 'WHERE foo AND bar', "basics work");

$w->list_push("crapola");

is($w->sql, "WHERE foo AND bar AND crapola", "push works");

$w->and('moo');

is($w->sql, "WHERE foo AND bar AND crapola AND moo", "and works");

$w->set([]);

is($w->sql, "", "empty works");

$w = $w->quick({foo => 1}, {bar => 2});

is($w->sql, "WHERE (foo = 1) AND (bar = 2)", "quick");
