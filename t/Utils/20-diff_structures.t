#!perl -T

use strict;
use warnings;

use Audit::DBI::Utils;
use Data::Dumper;
use Test::FailWarnings -allow_deps => 1;
use Test::More;


my $tests =
[
	{
		name     => 'diff() on matching scalars.',
		old      => 'A',
		new      => 'A',
		expected => undef,
	},
	{
		name     => 'diff() on scalars.',
		old      => 'A',
		new      => 'B',
		expected =>
		{
			old => 'A',
			new => 'B',
		},
	},
	{
		name     => 'diff() on arrayrefs.',
		old      =>
		[
			1,
			2,
			3,
		],
		new      =>
		[
			1,
			4,
			3,
		],
		expected =>
		[
			{
				'index' => 1,
				'new'   => 4,
				'old'   => 2
			},
		],
	},
	{
		name     => 'diff() on hashrefs.',
		old      =>
		{
			'key1' => 1,
			'key2' => 2,
		},
		new      =>
		{
			'key1' => 1,
			'key2' => 3,
		},
		expected =>
		{
			'key2' =>
			{
				'new' => 3,
				'old' => 2
			},
		},
	},
	{
		name     => 'diff() numbers with a different format.',
		old      => '1',
		new      => '1.00',
		expected => undef,
	},
];

plan( tests => scalar( @$tests ) + 1 );

can_ok(
	'Audit::DBI::Utils',
	'diff_structures',
);

foreach my $test ( @$tests )
{
	is_deeply(
		Audit::DBI::Utils::diff_structures(
			$test->{'old'},
			$test->{'new'},
		),
		$test->{'expected'},
		$test->{'name'},
	) || diag(
		'Old structure: ' . Dumper( $test->{'old'} ) . "\n" .
		'New structure: ' . Dumper( $test->{'new'} ) . "\n" .
		'Expected: ' . Dumper( $test->{'expected'} )
	);
}
