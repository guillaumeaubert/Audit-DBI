package Audit::DBI;

use strict;
use warnings;

use Carp;
use Data::Validate::Type;
use Storable;
use Try::Tiny;

use Audit::DBI::Event;
use Audit::DBI::Utils;


=head1 NAME

Audit::DBI - Audit data changes in your code and store searchable log records in a database.


=head1 VERSION

Version 1.4.0

=cut

our $VERSION = '1.4.0';


=head1 SYNOPSIS

	use Audit::DBI;
	
	# Create the audit object.
	my $audit = Audit::DBI->new(
		database_handle => $dbh,
	);
	
	# Create the necessary tables.
	$audit->create_tables();
	
	$audit->record(
		event               => $event,
		subject_type        => $subject_type,
		subject_id          => $subject_id,
		event_time          => $event_time,
		diff                => [ $old_structure, $new_structure ],
		search_data         => \%search_data,
		information         => \%information,
		affected_account_id => $account_id,
		file                => $file,
		line                => $line,
	);
	
	$audit->review(
		[ search criteria ]
	);


=head1 METHODS

=head2 new()

Create a new Audit::DBI object.

	my $audit = Audit::DBI->new(
		database_handle => $dbh,
	);

Parameters:

=over 4

=item * 'database handle'

Mandatory, a DBI object.

=item * 'memcache'

Optional, a Cache::Memcached or Cache::Memcached::Fast object to use for
rate limiting. If not specified, rate-limiting functions will not be available.

=back

=cut

sub new
{
	my ( $class, %args ) = @_;
	my $dbh = delete( $args{'database_handle'} );
	my $memcache = delete( $args{'memcache'} );

	# Check parameters.
	croak "Argument 'database_handle' is mandatory and must be a DBI object"
		if !Data::Validate::Type::is_instance( $dbh, class => 'DBI::db' );

	my $self = bless(
		{
			'database_handle' => $dbh,
			'memcache'        => $memcache,
		},
		$class
	);

	return $self;
}


=head1 AUTHOR

Guillaume Aubert, C<< <aubertg at cpan.org> >>.


=head1 BUGS

Please report any bugs or feature requests to C<bug-audit-dbi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Audit-DBI>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Audit::DBI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Audit-DBI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Audit-DBI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Audit-DBI>

=item * Search CPAN

L<http://search.cpan.org/dist/Audit-DBI/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to ThinkGeek (L<http://www.thinkgeek.com/>) and its corporate overlords
at Geeknet (L<http://www.geek.net/>), for footing the bill while I write code
for them!


=head1 COPYRIGHT & LICENSE

Copyright 2012 Guillaume Aubert.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
