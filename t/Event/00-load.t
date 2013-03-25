#!perl -T

use Test::More tests => 2;
use Test::NoWarnings;


BEGIN
{
	use_ok( 'Audit::DBI::Event' );
}

diag( "Testing Audit::DBI::Event $Audit::DBI::Event::VERSION, Perl $], $^X" );
