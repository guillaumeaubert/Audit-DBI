#!perl -T

use strict;
use warnings;

use Audit::DBI::Utils;
use Data::Dumper;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;


can_ok(
	'Audit::DBI::Utils',
	'diff_structures',
);

compare(
	Audit::DBI::Utils::diff_structures(
		'A',
		'A',
		comparison_function => \&comparison_function,
	),
	undef,
	'diff() on matching scalars with the same case.',
);

compare(
	Audit::DBI::Utils::diff_structures(
		'a',
		'A',
		comparison_function => \&comparison_function,
	),
	undef,
	'diff() on matching scalars with a different case.',
);

compare(
	Audit::DBI::Utils::diff_structures(
		'A',
		'B',
		comparison_function => \&comparison_function,
	),
	{
		old => 'A',
		new => 'B',
	},
	'diff() on different scalars.',
);


sub comparison_function
{
	my ( $variable_1, $variable_2 ) = @_;
	
	return lc( $variable_1 ) eq lc( $variable_2 );
}

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

