#!perl -T

use Test::More tests => 2;
use Test::NoWarnings;


BEGIN
{
	use_ok( 'Audit::DBI::Utils' );
}

diag( "Testing Audit::DBI::Utils $Audit::DBI::Utils::VERSION, Perl $], $^X" );
