#!perl -T

use Test::More tests => 1;

BEGIN
{
	use_ok( 'Audit::DBI::Utils' );
}

diag( "Testing Audit::DBI::Utils $Audit::DBI::Utils::VERSION, Perl $], $^X" );
