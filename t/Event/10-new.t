#!perl -T

use strict;
use warnings;

use Audit::DBI::Event;
use Test::More tests => 1;


can_ok(
	'Audit::DBI::Event',
	'new',
);
