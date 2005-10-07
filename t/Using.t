use Test::More tests => 8;
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
$l->set([qw(foo bar baz)]);
#use Data::Dumper; die Dumper $l->list;
ok(@{$l->list()} == 3, "storage/retrieval works");

#also test sql options
$l->options(parens => 1);
ok($l->sql() eq "USING(foo, bar, baz)", "sql with parens");

#test push
$l->list_push(qw(quux));
ok($l->sql eq "USING(foo, bar, baz, quux)", "push works");

#test pop
$l->list_pop;
ok($l->sql eq "USING(foo, bar, baz)", "pop works");

#shift
$l->list_shift;
ok($l->sql eq "USING(bar, baz)", "shift works");

#unshift
$l->list_unshift("dooky");
ok($l->sql eq "USING(dooky, bar, baz)", "unshift works");
