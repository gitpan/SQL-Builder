use Test::More tests => 13;
use strict;
use warnings;

BEGIN { use_ok('SQL::Builder::Select') };
BEGIN { use_ok('SQL::Builder::Table') };
BEGIN { use_ok('SQL::Builder::Column') };
BEGIN { use_ok('SQL::Builder::BinaryOp') };


## POD EXAMPLE 1
{
	# new select object

	my $sel = SQL::Builder::Select->new;

	# add a table

	$sel->tables->add_table(table => "users", alias => "u");

	# SELECT * FROM users AS u
	ok($sel->sql =~ /SELECT \*\nFROM users AS u\s*/, "doc example 1");
	


	## POD EXAMPLE 2
	$sel->tables->add_table(table => "salaries", alias => "sals");

	ok($sel->sql =~ /SELECT \*\nFROM users AS u, salaries AS sals\s*/, "doc example 2");


	## POD EXAMPLE 3
	$sel->where->list_push("u.salary_id = sals.salary_id");
	
	ok($sel->sql =~ /SELECT \*\nFROM users AS u, salaries AS sals\s*\nWHERE u.salary_id = sals.salary_id/, "doc example 3");
}

## POD EXAMPLE 4

{

	my $sel = SQL::Builder::Select->new();

	$sel->tables->add_table(table => "users", alias => "u");

	$sel->tables->add_join(
		table => "salaries",
		'using->list_push' => "salary_id"
	);

	# SELECT * FROM users AS u JOIN salaries USING (salary_id)

	ok($sel->sql =~ /FROM users AS u\n+JOIN salaries\s+USING\(salary_id\)/, "doc example 4");
}


{
	# define a users table
	our $tbl_users    = SQL::Builder::Table->new(
				name => "users",
				alias => "u"
			);
	
	# define the salaries table
	our $tbl_salaries = SQL::Builder::Table->new(
				name => "salaries",
				alias => "sals"
			);


	sub get_user_pay	{
		
		# declare a new SELECT object
		my $sel = SQL::Builder::Select->new();
		
		
		# add the users table to the SELECT list
		$sel->tables->list_push($tbl_users);
		
		# join against the salaries table
		$sel->tables->joins->list_push(
			SQL::Builder::Join->new(
				table => $tbl_salaries,
				'on->list_push' => SQL::Builder::BinaryOp->new(
					op  => "=",
					lhs => $tbl_salaries->col(name => 'salary_id'),
					rhs => $tbl_users->col(name => 'salary_id')
				)
			)
		);
		
		return $sel
	}

	my $query = get_user_pay();

	# suppose we only want the user_id and salary_amount columns returned

	$query->cols->list_push(
	    $tbl_users->col(name => 'user_id'),
	    $tbl_salaries->col(name => 'salary_amount')
	);

	# SELECT u.user_id, sals.salary_amount
	# FROM users AS u
	# JOIN salaries AS sal ON sal.salary_id = u.salary_id

	ok($query->sql =~ /SELECT u.user_id, sals.salary_amount\nFROM users AS u\n+JOIN salaries AS sals ON sals.salary_id = u.salary_id/, "with select cols");

	$query->where->list_push(
		SQL::Builder::BinaryOp->new(
			op  => ">",
			lhs => $tbl_salaries->col(name => 'salary_amount'),
			rhs => 20_000
		)
	);

	ok($query->sql =~ /SELECT u.user_id, sals.salary_amount\nFROM users AS u\n+JOIN salaries AS sals ON sals.salary_id = u.salary_id\nWHERE sals.salary_amount > 20000/, "with WHERE");

	# SELECT u.user_id, sals.salary_amount
	# FROM users AS u
	# JOIN salaries AS sal ON sal.salary_id = u.salary_id
	# WHERE u.salary_amount > 20000


	my $iterator = $query->where->look_down(
		op => ">"
	);

	while($iterator->pull)	{
		my $binary_op = $iterator->current;
		
		# flip the sign
		$binary_op->op("<");
	}

	ok($query->sql =~ /SELECT u.user_id, sals.salary_amount\nFROM users AS u\n+JOIN salaries AS sals ON sals.salary_id = u.salary_id\nWHERE sals.salary_amount < 20000/, "with WHERE");

	# SELECT u.user_id, sals.salary_amount
	# FROM users AS u
	# JOIN salaries AS sal ON sal.salary_id = u.salary_id
	# WHERE u.salary_amount < 20000


	$query->limit(10);

	ok($query->sql =~ /SELECT u.user_id, sals.salary_amount\nFROM users AS u\n+JOIN salaries AS sals ON sals.salary_id = u.salary_id\nWHERE sals.salary_amount < 20000\n+LIMIT 10/, "with WHERE");


	# SELECT u.user_id, sals.salary_amount
	# FROM users AS u
	# JOIN salaries AS sal ON sal.salary_id = u.salary_id
	# WHERE u.salary_amount > 20000
	# LIMIT 10


	$query->offset(10);

	ok($query->sql =~ /SELECT u.user_id, sals.salary_amount\nFROM users AS u\n+JOIN salaries AS sals ON sals.salary_id = u.salary_id\nWHERE sals.salary_amount < 20000\n+LIMIT 10 OFFSET 10/, "with WHERE");

	# SELECT u.user_id, sals.salary_amount
	# FROM users AS u
	# JOIN salaries AS sal ON sal.salary_id = u.salary_id
	# WHERE u.salary_amount > 20000
	# LIMIT 10 OFFSET 10
}
