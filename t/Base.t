use Test::More tests => 8;

BEGIN {
	use_ok('SQL::Builder::Base');
	use_ok('SQL::Builder::Function');
};

use warnings;
use strict;


###### QUICK ARG TESTS

{
	my $func = SQL::Builder::Function->new(func => "COUNT", "args->list_push" => "*");

	is($func->sql, "COUNT(*)", "passing hash");
	
	$func = SQL::Builder::Function->new(
		{func => "COUNT"},
	);

	is($func->sql, "COUNT()", "single hash ref arg");


	$func = SQL::Builder::Function->new(
		{func => "COUNT"},
		{parens => 1}
	);

	is($func->sql, "COUNT()", "passing two args to handler");

	is($func->options('parens'), 1, "option setting to arg handler");

	### throws error when necessary

	eval {
		$func = SQL::Builder::Function->new(undef);
	};

	ok($@, "single invalid arg");

	eval {
		$func = SQL::Builder::Function->new(bar => "crap");
	};

	ok($@, "invalid hash")
}
