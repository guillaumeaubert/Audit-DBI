#!perl -T

use strict;
use warnings;

use Test::More tests => 3;
use Audit::DBI::Utils;


# 'expected_relative' is the expected return value with absolute=0.
# 'expected_absolute' is the expected return value with absolute=1.
my $tests =
[
	{
		name              => 'Test empty diff.',
		diff              => undef,
		expected_relative => 0,
		expected_absolute => 0,
	},
	{
		name     => 'Test string.',
		diff     =>
		{
			old => 'Test',
			new => '12',
		},
		expected_relative => -2,
		expected_absolute => 6,
	},
	{
		name              => 'Test arrayref.',
		diff              =>
		[
			{
				'index' => 1,
				'new'   => 42,
				'old'   => 3,
			},
		],
		expected_relative => 1,
		expected_absolute => 3,
	},
	{
		name              => 'Test hashref.',
		diff              =>
		{
			'key2' =>
			{
				'new' => 3,
				'old' => 24,
			},
		},
		expected_relative => -1,
		expected_absolute => 3,
	},
];

can_ok(
	'Audit::DBI::Utils',
	'get_diff_string_bytes',
);

subtest(
	'Test absolute diffs.',
	sub
	{
		plan( tests => scalar( @$tests ) );
		
		foreach my $test ( @$tests )
		{
			is(
				Audit::DBI::Utils::get_diff_string_bytes( $test->{'diff'} ),
				$test->{'expected_relative'},
				$test->{'name'},
			);
		}
	},
);

subtest(
	'Test absolute diffs.',
	sub
	{
		plan( tests => scalar( @$tests ) );
		
		foreach my $test ( @$tests )
		{
			is(
				Audit::DBI::Utils::get_diff_string_bytes(
					$test->{'diff'},
					absolute => 1,
				),
				$test->{'expected_absolute'},
				$test->{'name'},
			);
		}
	},
);
