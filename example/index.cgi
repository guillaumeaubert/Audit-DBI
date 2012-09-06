#!/usr/bin/perl

=head1 NAME

index.cgi - Example of audit search interface using Audit::DBI.


=head1 DESCRIPTION

Caveat: I tried to avoid having this example rely on fancy modules, in order
to allow it to run on most machines. The drawback of cours is that it isn't
fancy (for example, it uses the CGI module).

=cut

use strict;
use warnings;

use lib '../lib';

use Audit::DBI::TT2;
use Audit::DBI;
use CGI qw();
use Class::Date;
use DBI;
use Data::Dumper;
use Template;


=head1 MAIN CODE

=cut

my $cgi = CGI->new();
print $cgi->header();

my $dbh = DBI->connect(
	'dbi:SQLite:dbname=test_database',
	'',
	'',
	{
		RaiseError => 1,
	}
);

my $template = Template->new(
	{
		INCLUDE_PATH => 'templates/',
		EVAL_PERL    => 1,
		PLUGINS      =>
		{
			audit => 'Audit::DBI::TT2',
		},
	}
) || die $Template::ERROR;

# Actions
my $action = $cgi->param('action') || '';
{
	search();
}


=head1 FUNCTIONS


=head2 search()

Displays a search interface to query audit data.

=cut

sub search
{
	# Output the template.
	$template->process(
		'search.tt2',
		{},
	) || die $template->error();
	
	return;
}


=head1 COPYRIGHT & LICENSE

Copyright 2012 Guillaume Aubert.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
