use Test::More tests => 6;
use strict;
use warnings;

#does it load
BEGIN { use_ok('SQL::Builder::BinaryOp') };

#empty object constructor
my $o = SQL::Builder::BinaryOp->new();
if($o)	{
	pass("empty object creation");
}
else	{
	fail("empty object creation");
}

#set the data
$o->set(op => 'funky', 'list_push' => [qw(me you)]);

is($o->op, "funky", "op set correctly");
ok(@{$o->opers} == 2, "args set correctly");
#use Data::Dumper; die Dumper $o;
is($o->sql, "me funky you", "returns correct sql");

$o->options(parens => 1);
is($o->sql(), "(me funky you)", "returns correct sql w/ parens");
$o->options(parens => 0);
