#!/usr/bin/perl

use Test::More tests => 12;

use strict;
use warnings;

BEGIN {
	use_ok('SQL::Builder::TableExpression');
	use_ok('SQL::Builder::Table');
};


my $table = SQL::Builder::Table->new(name => "table", alias => "alias");
my $expr = SQL::Builder::TableExpression->new(expr => $table);

$expr->use_expr_alias(1);

is($expr->sql, "table AS alias", "uses expr alias");


$expr->parens(1);
is($expr->sql, "(table) AS alias", "with parens");
$expr->parens(0);


$expr->use_expr_alias(0);
is($expr->sql, "table", "no expr alias");

$expr->alias("alias2");

is($expr->sql, "table AS alias2", "uses own alias");

$expr->use_as(0);

is($expr->sql, "table alias2", "uses own alias, no AS");


$expr->use_own_alias(0);

is($expr->sql, "table", "no own alias, no AS");


$expr = SQL::Builder::TableExpression->new(expr => $table);
$expr->use_expr_alias(1);

$expr->only(1);

is($expr->sql, "ONLY table AS alias", "ONLY keyword works");


$expr->cols(qw(a1 b1 c1));

is($expr->sql, "ONLY table AS alias (a1, b1, c1)", "column aliases");

$expr->use_expr_alias(0);

# prolly invalid sql
is($expr->sql, "ONLY table (a1, b1, c1)", "column aliases, no expr alias");

$expr->use_own_alias(1);
$expr->alias("haha");

is($expr->sql, "ONLY table AS haha (a1, b1, c1)", "column aliases, using own alias");
