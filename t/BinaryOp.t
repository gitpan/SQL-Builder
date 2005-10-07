use Test::More tests => 12;

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
$o->set(qw(funky me you));

is($o->op, "funky", "op set correctly");
ok(@{$o->args} == 2, "args set correctly");
#use Data::Dumper; die Dumper $o;
is($o->sql, "me funky you", "returns correct sql");

$o->options(parens => 1);
is($o->sql(), "(me funky you)", "returns correct sql w/ parens");
$o->options(parens => 0);

## test quick stuff

my $struct = SQL::Builder::BinaryOp->quick(
	["this", "OR", "that"]
);

is($struct->sql, "this OR that", "quick aref works");

$struct = SQL::Builder::BinaryOp->quick(
	[
		["foo", "AND", "bar"],
		"OR",
		"that"
	]
);

is($struct->sql, "foo AND bar OR that", "quick nested exprs work");

$struct = SQL::Builder::BinaryOp->quick(
	{
		foo => 1,
		bar => 2
	}
);

ok(
	$struct->sql eq "(bar = 2 AND foo = 1)"
	|| $struct->sql eq "(foo = 1 AND bar = 2)",
	"quick hash simple works"
);

$struct = SQL::Builder::BinaryOp->quick(
	{
		foo => [11,12],
		bar => {
			">" => 10,
			"<" => 12
		}
	}
);

ok(
	grep $struct->sql, (
		"((foo = 11 OR foo = 12) AND (bar > 10 AND bar < 12))",
		"((foo = 11 OR foo = 12) AND (bar < 12 AND bar > 10))",
		"((bar > 10 AND bar < 12) AND (foo = 11 OR foo = 12))",
		"((bar < 12 AND bar > 10) AND (bar > 10 AND bar < 12))"
	),
	"quick hash with aref and hash with ops"
);

my @struct = SQL::Builder::BinaryOp->quick(
	["this", "OR", "that"],
	{
		foo => 12
	}
);

is($struct[0]->sql, "this OR that", "quick list aref");
is($struct[1]->sql, "(foo = 12)", "quick list hashref");



#use Data::Dumper; die Dumper $struct->sql;
