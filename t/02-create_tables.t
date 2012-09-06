#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 7;

use DBI;
use Audit::DBI;


ok(
	my $dbh = DBI->connect(
		'dbi:SQLite:dbname=t/test_database',
		'',
		'',
		{
			RaiseError => 1,
		}
	),
	'Create connection to a SQLite database.',
);

dies_ok(
	sub
	{
		# Disable printing errors out since we expect the test to fail.
		local $dbh->{'PrintError'} = 0;
		
		$dbh->selectrow_array( q| SELECT * FROM audit_events | );
	},
	'The audit_events table does not exist yet.',
);

dies_ok(
	sub
	{
		# Disable printing errors out since we expect the test to fail.
		local $dbh->{'PrintError'} = 0;
		
		$dbh->selectrow_array( q| SELECT * FROM audit_search | );
	},
	'The audit_search table does not exist yet.',
);

ok(
	defined(
		my $audit = Audit::DBI->new(
			database_handle => $dbh,
		)
	),
	'Create a new Audit::DBI object.',
);

lives_ok(
	sub
	{
		$audit->create_tables(
			drop_if_exist => 1,
		);
	},
	'Create tables.',
);

lives_ok(
	sub
	{
		$dbh->selectrow_array( q| SELECT * FROM audit_events | );
	},
	'The audit_events table exists.',
);

lives_ok(
	sub
	{
		$dbh->selectrow_array( q| SELECT * FROM audit_search | );
	},
	'The audit_search table exists.',
);

