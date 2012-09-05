package Audit::DBI::Utils;

use strict;
use warnings;


=head1 NAME

Audit::DBI::Utils - Utilities for the Audit::DBI distribution.


=head1 VERSION

Version 1.4.0

=cut

our $VERSION = '1.4.0';


=head1 SYNOPSIS

	use Audit::DBI::Utils;
	
	my $ip_address = Audit::DBI::Utils::integer_to_ipv4( $integer );
	
	my $integer = Audit::DBI::Utils::ipv4_to_integer( $ip_address );
	
	my $differences = Audit::DBI::Utils::diff_structures(
		$data_structure_1,
		$data_structure_2,
		comparison_function => sub { my ( $a, $b ) = @_; $a eq $b; }, #optional
	);


=head1 FUNCTIONS

=head2 integer_to_ipv4()

Convert a 32-bits integer representing an IP address into its IPv4 form.

	my $ip_address = Audit::DBI::Utils::integer_to_ipv4( $integer );

=cut

sub integer_to_ipv4
{
	my ( $integer ) = @_;
	
	return undef
		if !defined( $integer ) || $integer !~ m/^\d+$/;
	
	return join( '.', map { ( $integer >> 8 * ( 3 - $_ ) ) % 256 } 0..3 );
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

    perldoc Audit::DBI::Utils


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
