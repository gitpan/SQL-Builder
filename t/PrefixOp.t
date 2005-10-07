use Test::More tests => 6;
BEGIN { use_ok('SQL::Builder::PrefixOp') };

#make sure an object was created
my $p = SQL::Builder::PrefixOp->new();
if($p)	{
	ok("empty object created");
}
else	{
	fail("empty object created")
}

#make sure it stringifies and sets correctly
$p->set("!","col");
ok($p->sql eq "!col");

#retrieval methods
is($p->op, "!", "op retrieval");

is($p->arg, "col", "arg retrieval");

$p = $p->quick("!", "bar");

is($p->sql, "!bar", "quick method");
