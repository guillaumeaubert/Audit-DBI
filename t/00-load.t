#!perl -T

use Test::More tests => 2;
use Test::NoWarnings;


BEGIN
{
	use_ok( 'Audit::DBI' );
}

diag( "Testing Audit::DBI $Audit::DBI::VERSION, Perl $], $^X" );
