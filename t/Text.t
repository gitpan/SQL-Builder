use Test::More tests => 5;
use strict;
use warnings;
BEGIN { use_ok('SQL::Builder::Text') };

#empty object creation
my $t = SQL::Builder::Text->new();

is($t->sql, "NULL", "null works");

$t->set(text => "foozle");
is($t->sql, "'foozle'", "defulat quote works");

$t->set(text => "foo'z'l\"e");
is($t->sql, "'foo\\'z\\'l\"e'", "escaper works");

$t->quoter(sub {return "bling"});
is($t->sql, "bling", "set quoter works");
