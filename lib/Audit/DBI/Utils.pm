package Audit::DBI::Utils;

use strict;
use warnings;

use Carp;
use Data::Validate::Type;


=head1 NAME

Audit::DBI::Utils - Utilities for the Audit::DBI distribution.


=head1 VERSION

Version 1.5.3

=cut

our $VERSION = '1.5.3';


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

=head2 stringify_data_structure()

	my $string = Audit::DBI::Utils::stringify_data_structure(
		data_structure             => $data_structure,
		object_stringification_map =>
		{
			'Math::Currency' => 'as_float',
		},
	);

=cut

sub stringify_data_structure
{
	my ( %args ) = @_;
	my $data_structure = delete( $args{'data_structure'} );
	my $object_stringification_map = delete( $args{'object_stringification_map'} );
	croak 'The following arguments are not valid: ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;
	
	return _stringify_data_structure( $data_structure, $object_stringification_map );
}

sub _stringify_data_structure
{
	my ( $data_structure, $object_stringification_map ) = @_;
	
	if ( Data::Validate::Type::is_arrayref( $data_structure ) )
	{
		# If we have an array, try to stringify each of the elements.
		return
		[
			map { _stringify_data_structure( $_, $object_stringification_map ) } @$data_structure
		];
	}
	elsif ( Data::Validate::Type::is_hashref( $data_structure ) )
	{
		# First, we try to stringify this object.
		foreach my $class ( keys %$object_stringification_map )
		{
			next if !Data::Validate::Type::is_instance( $data_structure, class => $class );
			my $stringification_method = $object_stringification_map->{ $class };
			next if !$data_structure->can( $stringification_method );
			return $data_structure->$stringification_method();
		}
		
		# If we haven't found it in our list of stringifiable objects,
		# then we need to investigate the individual keys.
		return
		{
			map
				{ $_ => _stringify_data_structure( $data_structure->{ $_ }, $object_stringification_map ) }
				keys %$data_structure
		};
	}
	else
	{
		return $data_structure;
	}
}


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


=head2 ipv4_to_integer()

Convert an IPv4 address to a 32-bit integer.

	my $integer = Audit::DBI::Utils::ipv4_to_integer( $ip_address );

=cut

sub ipv4_to_integer
{
	my ( $ip_address ) = @_;
	
	return undef
		if !defined( $ip_address );
	
	if ( my ( @bytes ) = $ip_address =~ m/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/x )
	{
		if ( ! grep { $_ > 255 } @bytes )
		{
			@bytes = reverse( @bytes );
			my $integer = 0;
			foreach my $exponent ( 0..3 )
			{
				$integer += $bytes[ $exponent ] * 256**$exponent;
			}
			return $integer;
		}
	}
	
	# Invalid input.
	return undef;
}


=head2 diff_structures()

Return the differences between the two data structures passed as parameter.

By default, if leaf nodes are compared with '==' if they are both numeric, and
with 'eq' otherwise.

An optional I<comparison_function> parameter can be used to specify a different
comparison function.

	my $differences = Audit::DBI::Utils::diff_structures(
		$data_structure_1,
		$data_structure_2,
	);
	
	# Alternative built-in comparison function.
	# Leaf nodes are compared using 'eq'.
	my $diff = Audit::DBI::Utils::diff_structures(
		$data_structure_1,
		$data_structure_2,
		comparison_function => 'eq',
	);
	
	# Alternative custom comparison function.
	my $diff = Audit::DBI::Utils::diff_structures(
		$data_structure_1,
		$data_structure_2,
		comparison_function => sub
		{
			my ( $variable_1, $variable2 ) = @_;
			# [...]
			return $is_equal;
		}
	);

=cut

sub diff_structures
{
	my ( @args ) = @_;
	return _diff_structures(
		{},
		@args
	);
}

sub _diff_structures_comparison_eq
{
	my ( $variable_1, $variable_2 ) = @_;
	
	return $variable_1 eq $variable_2;
}

sub _diff_structures_comparison_default
{
	my ( $variable_1, $variable_2 ) = @_;
	
	# For numbers, return numerical comparison.
	return $variable_1 == $variable_2
		if Scalar::Util::looks_like_number( $variable_1 ) && Scalar::Util::looks_like_number( $variable_2 );
	
	# Otherwise, use exact string match.
	return $variable_1 eq $variable_2;
}

sub _diff_structures
{
	my ( $cache, $structure1, $structure2, %args ) = @_;
	my $comparison_function = $args{'comparison_function'};
	
	# make sure the provided equality function is really a coderef
	if ( !Data::Validate::Type::is_coderef( $comparison_function ) )
	{
		if ( defined( $comparison_function ) && ( $comparison_function eq 'eq' ) )
		{
			$comparison_function = \&_diff_structures_comparison_eq;
		}
		else
		{
			$comparison_function = \&_diff_structures_comparison_default;
		}
	}
	
	# If one of the structure is undef, return
	if ( !defined( $structure1 ) || !defined( $structure2 ) )
	{
		if ( !defined( $structure1 ) && !defined( $structure2 ) )
		{
			return undef;
		}
		else
		{
			return
			{
				old => $structure1,
				new => $structure2
			};
		}
	}
	
	# Cache memory addresses to make sure we don't get into an infinite loop.
	# The idea comes from Test::Deep's code.
	return undef
		if exists( $cache->{ "$structure1" }->{ "$structure2" } );
	$cache->{ "$structure1" }->{ "$structure2" } = undef;
	
	# Hashes (including hashes blessed as objects)
	if ( Data::Validate::Type::is_hashref( $structure1 ) && Data::Validate::Type::is_hashref( $structure2 ) )
	{
		my %union_keys = map { $_ => undef } ( keys %$structure1, keys %$structure2 );
		
		my %tmp = ();
		foreach ( keys %union_keys )
		{
			my $diff = _diff_structures(
				$cache,
				$structure1->{$_},
				$structure2->{$_},
				%args,
			);
			$tmp{$_} = $diff
				if defined( $diff );
		}
		
		return ( scalar( keys %tmp ) != 0 ? \%tmp : undef );
	}
	
	# If the structures have different references, since we've ruled out blessed
	# hashes (objects) above (that could have a different blessing with the same
	# actual content), return the elements
	if ( ref( $structure1 ) ne ref( $structure2 ) )
	{
		return
		{
			old => $structure1,
			new => $structure2
		};
	}
	
	# Simple scalars, compare and return
	if ( ref( $structure1 ) eq '' )
	{
		return $comparison_function->( $structure1, $structure2 )
			? undef
			: {
				old => $structure1,
				new => $structure2
			};
	}
	
	# Arrays
	if ( Data::Validate::Type::is_arrayref( $structure1 ) )
	{
		my @tmp = ();
		my $max_length = ( sort { $a <=> $b } ( scalar( @$structure1 ), scalar( @$structure2 ) ) )[1];
		for my $i ( 0..$max_length-1 )
		{
			my $diff = _diff_structures(
				$cache,
				$structure1->[$i],
				$structure2->[$i],
				%args,
			);
			next unless defined( $diff );
			
			$diff->{'index'} = $i;
			push(
				@tmp,
				$diff
			);
		}
		
		return ( scalar( @tmp ) != 0 ? \@tmp : undef );
	}
	
	# We don't track other types for audit purposes
	return undef;
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

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see http://www.gnu.org/licenses/

=cut

1;
