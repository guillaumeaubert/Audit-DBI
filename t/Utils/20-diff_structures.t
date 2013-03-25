#!perl -T

use strict;
use warnings;

use Audit::DBI::Utils;
use Data::Dumper;
use Test::More tests => 7;
use Test::NoWarnings;


can_ok(
	'Audit::DBI::Utils',
	'diff_structures',
);

compare(
	Audit::DBI::Utils::diff_structures(
		'A',
		'A',
	),
	undef,
	'diff() on matching scalars.',
);

compare(
	Audit::DBI::Utils::diff_structures(
		'A',
		'B',
	),
	{
		old => 'A',
		new => 'B',
	},
	'diff() on scalars.',
);

compare(
	Audit::DBI::Utils::diff_structures(
		[
			1,
			2,
			3,
		],
		[
			1,
			4,
			3,
		],
	),
	[
		{
			'index' => 1,
			'new'   => 4,
			'old'   => 2
		},
	],
	'diff() on arrayrefs.',
);

compare(
	Audit::DBI::Utils::diff_structures(
		{
			'key1' => 1,
			'key2' => 2,
		},
		{
			'key1' => 1,
			'key2' => 3,
		},
	),
	{
		'key2' =>
		{
			'new' => 3,
			'old' => 2
		},
	},
	'diff() on hashrefs.',
);

compare(
	Audit::DBI::Utils::diff_structures(
		'1',
		'1.00',
	),
	undef,
	'diff() numbers with a different format.',
);


sub compare
{
	my ( $got, $expected, $name ) = @_;
	
	is_deeply(
		$got,
		$expected,
		$name,
	) || diag(
		'Got: ' . Dumper( $got ) . "\n" .
		'Expected: ' . Dumper( $expected )
	);
	
	return;
}
