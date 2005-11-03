use Test::More tests => 6;
use strict;
use warnings;
BEGIN { use_ok('SQL::Builder::Order') };

#empty object creation
my $o = SQL::Builder::Order->new();

$o->set(expr => 'e', order => SQL::Builder::Order::ASC);
is($o->sql, "e ASC", "asc works");

$o->set(expr => 'e', order => SQL::Builder::Order::DESC);
is($o->sql, "e DESC", "desc works");

$o->set(expr => 'e', using => ">");
is($o->sql, "e DESC", "asc/desc precedence works");

$o->order(undef);
is($o->sql, "e USING >");

$o = SQL::Builder::Order->new(expr => "col");

is($o->sql, "col");
