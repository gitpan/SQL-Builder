use Test::More tests => 5;

BEGIN { use_ok('SQL::Builder::Having') };

my $h = SQL::Builder::Having->new();

is($h->sql, "", "none set, none returned");

$h->expr("foo!");

is($h->sql, "HAVING foo!", "sql works");

$h = $h->new();

$h->expr->list_push("COUNT(*) > 10");

is($h->sql, "HAVING COUNT(*) > 10", "list push");

$h = $h->quick(
	"some BINARY operation"
);

is($h->sql, "HAVING some BINARY operation", "quick works");
