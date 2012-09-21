#!perl -T

use strict;
use warnings;

use Test::More tests => 4;
use Audit::DBI::Utils;
use Data::Dumper;


can_ok(
	'Audit::DBI::Utils',
	'diff_structures',
);

compare(
	Audit::DBI::Utils::diff_structures(
		'A',
		'A',
		comparison_function => 'eq',
	),
	undef,
	'diff() on matching scalars.',
);

compare(
	Audit::DBI::Utils::diff_structures(
		'A',
		'B',
		comparison_function => 'eq',
	),
	{
		old => 'A',
		new => 'B',
	},
	'diff() on scalars.',
);

compare(
	Audit::DBI::Utils::diff_structures(
		'1',
		'1.00',
		comparison_function => 'eq',
	),
	{
		old => '1',
		new => '1.00',
	},
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

