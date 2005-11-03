use Test::More tests => 5;
use strict;
use warnings;

#does it load
BEGIN { use_ok('SQL::Builder::Where') };

my $w = SQL::Builder::Where->new();

$w->set(list => [qw(foo bar)]);

is($w->sql, 'WHERE foo AND bar', "basics work");

$w->list_push("crapola");

is($w->sql, "WHERE foo AND bar AND crapola", "push works");

$w->and('moo');

is($w->sql, "WHERE foo AND bar AND crapola AND moo", "and works");

$w->list_clear();

is($w->sql, "", "empty works");
