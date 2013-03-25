#!perl -T

use Test::More tests => 2;
use Test::NoWarnings;


BEGIN
{
	use_ok( 'Audit::DBI::TT2' );
}

diag( "Testing Audit::DBI::TT2 $Audit::DBI::TT2::VERSION, Perl $], $^X" );
