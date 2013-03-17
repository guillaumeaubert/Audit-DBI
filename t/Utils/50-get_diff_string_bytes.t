#!perl -T

use strict;
use warnings;

use Test::More;
use Audit::DBI::Utils;


my $tests =
[
	{
		name     => 'Test empty diff.',
		diff     => undef,
		expected => 0,
	},
	{
		name     => 'Test string.',
		diff     =>
		{
			old => 'Test',
			new => '12',
		},
		expected => -2,
	},
	{
		name     => 'Test arrayref.',
		diff     =>
		[
			{
				'index' => 1,
				'new'   => 42,
				'old'   => 2,
			},
		],
		expected => 1,
	},
	{
		name     => 'Test hashref.',
		diff     =>
		{
			'key2' =>
			{
				'new' => 3,
				'old' => 24,
			},
		},
		expected => -1,
	},
];

plan( tests => 1 + scalar( @$tests ) );

can_ok(
	'Audit::DBI::Utils',
	'get_diff_string_bytes',
);

foreach my $test ( @$tests )
{
	is(
		Audit::DBI::Utils::get_diff_string_bytes( $test->{'diff'} ),
		$test->{'expected'},
		$test->{'name'},
	);
}

