use Test::More tests => 2;
use Data::Dumper;

BEGIN {
	use_ok('SQL::Builder::Base');
	use_ok('SQL::Builder::BinaryOp');
};

use warnings;
use strict;

my $op = op(
	'OR',
	op(
		'AND',
		op("=", col => 10),
		op(">", foo => 40)
	),
	op(
		'AND',
		op(
			">",
			op("+", baz => 50),
			"bang"
		),
		op(
			"||",
			'first_name',
			'last_name',
		)
	)
);

print Dumper $op;

sub op	{
	return SQL::Builder::BinaryOp->new(@_)
}
