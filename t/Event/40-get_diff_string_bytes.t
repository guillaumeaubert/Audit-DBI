#!perl -T

use strict;
use warnings;

use Audit::DBI::Event;
use Test::More tests => 2;
use Test::NoWarnings;


can_ok(
	'Audit::DBI::Event',
	'get_diff_string_bytes',
);
