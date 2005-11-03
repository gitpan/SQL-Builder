use Test::More tests => 11;
use strict;
use warnings;

BEGIN { use_ok('SQL::Builder::Function') };

my $f = SQL::Builder::Function->new(func => "CURRENT_TIME");

#no parens if no args
is($f->sql, "CURRENT_TIME()", "function storage");

$f->args('1234');

#default with parens
is($f->sql, "CURRENT_TIME(1234)", "arg storage");

$f->parens(1);

is($f->sql, "CURRENT_TIME(1234)", "parens work");

$f->parens(0);

is($f->sql, "CURRENT_TIME 1234", "no-parens works");

use_ok('SQL::Builder::List');

$f->args(SQL::Builder::List->new(list_push => [qw(foo bar baz)]));

is($f->sql, "CURRENT_TIME foo, bar, baz", "calls args sql method");

my $func = SQL::Builder::Function->new(
	func => "FOO",
	'args->list_push' => ["BAR", "BAZ"]
);

is($func->sql, "FOO(BAR, BAZ)", "quick with list");

$func->auto_parens(1);

is($func->sql, "FOO(BAR, BAZ)", "autoparens with list");

$func->args->list_clear;

is($func->sql, "FOO", "autoparens without list");

#### new object

$func = $func->new();

{
	my $concat_factory = $func->make_instance(func => 'CONCAT');

	my $concat = $concat_factory->("args->list_push" => [1,2]);

	is($concat->sql, "CONCAT(1, 2)", "function factory works");
}
