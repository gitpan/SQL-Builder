use Test::More tests => 12;

BEGIN { use_ok('SQL::Builder::Function') };

my $f = SQL::Builder::Function->new("CURRENT_TIME");

#no parens if no args
is($f->sql, "CURRENT_TIME()", "function storage");

$f->args('1234');

#default with parens
is($f->sql, "CURRENT_TIME(1234)", "arg storage");

$f->options(parens => 1);

is($f->sql, "CURRENT_TIME(1234)", "parens work");

$f->options(parens => 0);

is($f->sql, "CURRENT_TIME 1234", "no-parens works");

use_ok('SQL::Builder::List');

$f->args(SQL::Builder::List->new([qw(foo bar baz)]));

is($f->sql, "CURRENT_TIME foo, bar, baz", "calls args sql method");

my $func = SQL::Builder::Function->quick(
{ func => "HELLO", args => [qw(foo bar baz)] }
);

is($func->sql, "HELLO(foo, bar, baz)", "quick with hashref works");

$func = SQL::Builder::Function->quick(
	["FUNC", "foo", "bar", "baz"]
);

is($func->sql, "FUNC(foo, bar, baz)", "quick with aref");

$func = SQL::Builder::Function->quick(
	"FOO",
	"BAR",
	"BAZ"
);

is($func->sql, "FOO(BAR, BAZ)", "quick with list");

$func->options(auto_parens => 1);

is($func->sql, "FOO(BAR, BAZ)", "autoparens with list");

$func->args->list([]);

is($func->sql, "FOO", "autoparens without list");
