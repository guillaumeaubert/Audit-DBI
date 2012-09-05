#!perl -T

use Test::More tests => 1;

BEGIN
{
	use_ok( 'Audit::DBI::TT2' );
}

diag( "Testing Audit::DBI::TT2 $Audit::DBI::Utils::VERSION, Perl $], $^X" );
