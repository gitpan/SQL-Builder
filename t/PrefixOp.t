use strict;
use warnings;
use Test::More tests => 5;
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
$p->set(op => "!", oper => "col");
ok($p->sql eq "! col");

#retrieval methods
is($p->op, "!", "op retrieval");

is($p->arg, "col", "arg retrieval");
