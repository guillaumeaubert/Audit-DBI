package Audit::DBI::TT2;

use strict;
use warnings;

use base 'Template::Plugin';

use Template::Stash;
use Data::Dumper;
use HTML::Entities qw();


=head1 NAME

Audit::DBI::TT2 - A Template Toolkit plugin to display audit events.


=head1 VERSION

Version 1.4.1

=cut

our $VERSION = '1.4.1';


=head1 SYNOPSIS

	use Audit::DBI::TT2;


=head1 FUNCTIONS

=head2 new()

Create a new Audit::DBI::TT2 object.

=cut

sub new
{
	my ( $class, $context ) = @_;
	
	my $self = bless(
		{
			_CONTEXT => $context,
		},
		$class,
	);
	
	return $self;
}


=head2 format_results()

Format the following fields for display as HTML:

=over 4

=item * diff

(accessible as diff_formatted)

=item * information

(accessible as information_formatted)

=item * event_time

(accessible as event_time_formatted)

=back

	[% FOREACH result IN audit.format_results( results ) %]
		<div>
			Formatted information: [% result.information_formatted %]<br/>
			Formatted diff: [% result.diff_formatted %]<br/>
			Formatted event time: [% result.event_time_formatted %]
		</div>
	[% END %]

=cut

sub format_results
{
	my ( $self ) = @_;
	my $results = $self->{'_CONTEXT'}->{'STASH'}->{'results'} || [];
	
	local $Class::Date::DATE_FORMAT="%Y-%m-%d %H:%M:%S";
	
	foreach my $result ( @$results )
	{
		$result->{information_formatted} = html_dumper( $result->get_information() );
		$result->{diff_formatted} = html_dumper( $result->get_diff() );
		my $event_date = Class::Date::date( $result->{event_time} );
		$result->{event_time_formatted} = $event_date->string()
			if defined( $event_date );
	}
	
	return $results;
}


=head2 html_dumper()

Format a data structure for display as HTML.

	my $formatted_data = Audit::DBI::TT2::html_dumper( $data );

=cut

sub html_dumper
{
	my ( $data ) = @_;
	return undef
		if !defined( $data );
	
	my $string;
	{
		# Skip "$VAR1 = ".
		local $Data::Dumper::Terse = 1;
		# Don't quote hash keys.
		local $Data::Dumper::Quotekeys = 0;
		$string = Dumper( $data );
	}
	
	$string =~ s/\$VAR1 = //;
	$string = HTML::Entities::encode_entities( $string );
	$string =~ s/ /&nbsp;/g;
	$string =~ s/\n/<br\/>/g;
	
	return $string;
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

    perldoc Audit::DBI::TT2


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
