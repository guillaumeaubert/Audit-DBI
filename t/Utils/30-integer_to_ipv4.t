#!perl -T

use strict;
use warnings;

use Test::More;
use Audit::DBI::Utils;


my $tests = [];
foreach my $line ( <DATA> )
{
	chomp( $line );
	next if !defined( $line ) || $line !~ /\w+/ || substr( $line, 0, 1 ) eq '#';
	push( @$tests, $line );
}

plan( tests => 1 + scalar( @$tests ) );

can_ok(
	'Audit::DBI::Utils',
	'integer_to_ipv4',
);

# Run the tests defined in the DATA section below.
foreach my $test ( @$tests )
{
	my ( $integer, $ipv4 ) = split( /\t+/, $test );
	
	is(
		Audit::DBI::Utils::integer_to_ipv4(
			$integer,
		),
		$ipv4,
		"Convert $integer to dotted format.",
	);
}


__DATA__
# Integer	IPv4
3232235521	192.168.0.1
1		0.0.0.1
4294967295	255.255.255.255
167772167	10.0.0.7
