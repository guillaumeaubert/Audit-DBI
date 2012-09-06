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


=head2 record()

Record an audit event along with information on the context and data changed.

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

Required:

=over 4

=item * event

The type of action performed (48 characters maximum).

=item * subject_type

Normally, the singular form of the name of a table, such as "object" or
"account" or "order".

=item * subject_id

If subject_type is a table, the corresponding record ID.

=back

Optional:

=over 4

=item * diff

This automatically calculates the differences between the two data structures
passed as values for this parameter, and makes a new structure recording those
differences.

=item * search_data

A hashref of all the key/value pairs that we may want to be able search on later
to find this type of event. You may pass either a scalar or an arrayref of
multiple values for each key.

=item * information

Any other useful information (such as user input) to understand the context of
this change.

=item * account_affected

The ID of the account to which the data affected during that event where linked
to, if applicable.

=item * event_time

Unix timestamp of the time that the event occurred, the default being the
current time.

=item * file and line

The filename and line number where the event occurred, the default being the
immediate caller of Audit::DBI->record().

=back

Note: if you want to delay the insertion of audit events (to group them, for
performance), subclass C<Audit::DBI> and add a custom C<_insert_event method()>.

=cut

sub record ## no critic (NamingConventions::ProhibitAmbiguousNames)
{
	my( $self, %args ) = @_;
	my $limit_rate_timespan = delete( $args{'limit_rate_timespan'} );
	my $limit_rate_unique_key = delete( $args{'limit_rate_unique_key'} );
	my $dbh = $self->get_database_handle();
	
	# Check required parameters.
	foreach my $arg ( qw( event subject_type subject_id ) )
	{
		next if defined( $args{ $arg } ) && $args{ $arg } ne '';
		croak "The argument $arg must be specified.";
	}
	croak('The argument "limit_rate_timespan" must be a strictly positive integer.')
		if defined $limit_rate_timespan && ( $limit_rate_timespan !~ /^\d+$/ || $limit_rate_timespan == 0 );
	croak('The argument "limit_rate_unique_key" must be a string with length greater than zero.')
		if defined $limit_rate_unique_key && length $limit_rate_unique_key == 0;
	croak('Both "limit_rate_timespan" and "limit_rate_unique_key" must be defined.')
		if defined $limit_rate_timespan != defined $limit_rate_unique_key;
	
	# Rate limiting.
	if ( defined( $limit_rate_timespan ) )
	{
		if ( !defined( $self->_get_cache( key => $limit_rate_unique_key ) ) )
		{
			# Cache event.
			$self->_set_cache(
				key         => $limit_rate_unique_key,
				value       => 1,
				expire_time => time() + $limit_rate_timespan,
			);
		}
		else
		{
			# No need to log audit event.
			return 1;
		}
	}
	
	# Record the time (unless it was already passed in).
	$args{'event_time'} ||= time();
	
	# Store the file and line of the caller, unless they were passed in.
	if ( !defined( $args{'file'} ) || !defined( $args{'line'} ) )
	{
		my ( $file, $line ) = ( caller() )[1,2];
		$file =~ s|.*/||;
		$args{'file'} = $file
			if !defined( $args{'file'} );
		$args{'line'} = $line
			if !defined( $args{'line'} );
	}
	
	my $audit_event = $self->_insert_event( \%args );
	
	return defined( $audit_event )
		? 1
		: 0;
}


=head1 ACCESSORS

=head2 get_database_handle()

Return the database handle tied to the audit object.

	my $database_handle = $audit->_get_database_handle();

=cut

sub get_database_handle
{
	my ( $self ) = @_;

	return $self->{'database_handle'};
}


=head2 get_memcache()

Return the database handle tied to the audit object.

	my $memcache = $audit->get_memcache();

=cut

sub get_memcache
{
	my ( $self ) = @_;

	return $self->{'memcache'};
}


=head1 INTERNAL METHODS

=head2 _get_cache()

Get a value from the cache.

	my $value = $audit->get_cache( key => $key );

=cut

sub _get_cache
{
	my ( $self, %args ) = @_;
	my $key = delete( $args{'key'} );
	
	# Check parameters.
	croak 'The parameter "key" is mandatory'
		if !defined( $key ) || $key !~ /\w/;
	
	my $memcache = $self->get_memcache();
	return undef
		if !defined( $memcache );
	
	return $memcache->get( $key );
}


=head2 _set_cache()

Set a value into the cache.

	$audit->_set_cache(
		key         => $key,
		value       => $value,
		expire_time => $expire_time,
	);

=cut

sub _set_cache
{
	my ( $self, %args ) = @_;
	my $key = delete( $args{'key'} );
	my $value = delete( $args{'value'} );
	my $expire_time = delete( $args{'expire_time'} );
	
	# Check parameters.
	croak 'The parameter "key" is mandatory'
		if !defined( $key ) || $key !~ /\w/;
	
	my $memcache = $self->get_memcache();
	return
		if !defined( $memcache );
	
	$memcache->set( $key, $value, $expire_time )
		|| carp 'Failed to set cache with key >' . $key . '<';
	
	return;
}


=head2 _insert_event()

Insert an audit event in the database.

	my $audit_event = $audit->_insert_event( \%data );

Important: note that this is an internal function that record() calls. You should
be using record() instead. What you can do with this function is to subclass
it if you need to extend/change how events are inserted, for example:

=over 4

=item

if you want to stash it into a register_cleanup() when you're making the
all in Apache context (so that audit calls don't slow down the main request);

=item

if you want to insert extra information.

=back

=cut

sub _insert_event
{
	my ( $self, $data ) = @_;
	my $dbh = $self->get_database_handle();
	
	return try
	{
		# Make a diff if applicable based on the content of 'diff'
		if ( defined( $data->{'diff'} ) )
		{
			croak 'The "diff" argument must be an arrayref'
				if !Data::Validate::Type::is_arrayref( $data->{'diff'} );
			
			croak 'The "diff" argument cannot have more than two elements'
				if scalar( @{ $data->{'diff'} } ) > 2;
			
			$data->{'diff'} = MIME::Base64::encode_base64(
				Storable::freeze(
					Audit::DBI::Utils::diff_structures( @{ $data->{'diff'} } )
				)
			);
		}
		
		# Clean input.
		my $search_data = delete( $data->{'search_data'} );
		
		# Freeze the free-form data as soon as it is set on the object, in case it's
		# a complex data structure with references that may be updated before the
		# insert in the database.
		$data->{'information'} = MIME::Base64::encode_base64( Storable::freeze( $data->{'information'} ) )
			if defined( $data->{'information'} );
		
		# Set defaults.
		$data->{'created'} = time();
		$data->{'ipv4_address'} = Audit::DBI::Utils::ipv4_to_integer( $ENV{'REMOTE_ADDR'} );
		$data->{'event_time'} = time()
			if !defined( $data->{'event_time'} );
		
		# Insert.
		my @fields = ();
		my @values = ();
		foreach my $field ( keys %$data )
		{
			push( @fields, $dbh->quote( $field) );
			push( @values, $data->{ $field } );
		}
		my $insert = $dbh->do(
			sprintf(
				q|
					INSERT INTO audit_events( %s )
					VALUES ( %s )
				|,
				join( ', ', @fields ),
				join( ', ', ( '?' ) x scalar( @fields ) ),
			),
			{},
			@values,
		) || croak 'Cannot execute SQL: ' . $dbh->errstr();
		$data->{'audit_event_id'} = $dbh->last_insert_id(
			undef,
			undef,
			'audit_events',
			'audit_event_id',
		);
		
		# Create an object to return.
		my $audit_event = Audit::DBI::Event->new( data => $data );
		
		# Add the search data
		if ( defined( $search_data ) )
		{
			my $sth = $dbh->prepare(
				q|
					INSERT INTO audit_search( audit_event_id, name, value )
					VALUES( ?, ?, ? )
				|
			);
			
			foreach my $name ( keys %$search_data )
			{
				my $values = $search_data->{ $name };
				$values = [ $values ] # Force array
					if !Data::Validate::Type::is_arrayref( $values );
				
				foreach my $value ( @$values )
				{
					$sth->execute(
						$data->{'audit_event_id'},
						lc( $name ),
						lc( $value || '' ),
					) || carp 'Failed to insert search index key >' . $name . '< for audit event ID >' . $audit_event->id() . '<'; 
				}
			}
		}
		
		return $audit_event;
	}
	catch
	{
		carp $_;
		return undef;
	};
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
