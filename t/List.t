use Test::More tests => 12;
BEGIN { use_ok('SQL::Builder::List') };

#empty object creation
my $l = SQL::Builder::List->new();

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

#test sql
ok($l->sql eq "foo, bar, baz", "sql wo parens");

#also test sql options
$l->options(parens => 1);
ok($l->sql() eq "(foo, bar, baz)", "sql w/ parens");

#test push
$l->list_push(qw(quux));
ok($l->sql eq "(foo, bar, baz, quux)", "push works");

#test pop
$l->list_pop;
ok($l->sql eq "(foo, bar, baz)", "pop works");

#shift
$l->list_shift;
ok($l->sql eq "(bar, baz)", "shift works");

#unshift
$l->list_unshift("dooky");
ok($l->sql eq "(dooky, bar, baz)", "unshift works");


$l->list([qw(foo)]);
is($l->sql, "(foo)", "set with aref");

$l->list(qw(foo bar));
is($l->sql, "(foo, bar)", "set with list");

$l->list_clear();
is($l->sql, "", "clear list");
