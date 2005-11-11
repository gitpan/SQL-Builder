use Test::More tests => 10;
use strict;
use warnings;
BEGIN { use_ok('SQL::Builder::Using') };

#empty object creation
my $l = SQL::Builder::Using->new();

if($l)	{
	pass("empty object creation");
}
else	{
	fail("empty object creation");
}


#storage test. will test set() and list()
$l->expr->list(qw(foo bar baz));

#use Data::Dumper; die Dumper $l->list;
ok(@{$l->expr->list()} == 3, "storage/retrieval works");

#also test sql options
ok($l->sql() eq "USING(foo, bar, baz)", "sql with parens");

#test push
$l->expr->list_push(qw(quux));
ok($l->sql eq "USING(foo, bar, baz, quux)", "push works");

#test pop
$l->expr->list_pop;
ok($l->sql eq "USING(foo, bar, baz)", "pop works");

#shift
$l->expr->list_shift;
ok($l->sql eq "USING(bar, baz)", "shift works");

#unshift
$l->expr->list_unshift("dooky");
ok($l->sql eq "USING(dooky, bar, baz)", "unshift works");

$l->expr("custom");

is($l->sql, "USING(custom)", "custom expression");

$l->expr("");

is($l->sql, "", "empty expr");
