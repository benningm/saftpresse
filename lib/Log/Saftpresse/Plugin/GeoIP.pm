package Log::Saftpresse::Plugin::GeoIP;

use Moose;

# ABSTRACT: plugin to lookup geoip database
# VERSION

extends 'Log::Saftpresse::Plugin';

has 'address_fields' => ( is => 'ro', isa => 'Str', default => 'client_ip' );

has '_address_fields' => ( is => 'ro', isa => 'ArrayRef', lazy => 1,
	default => sub {
		my $self = shift;
		return( [ split(/\s*,\s*/, $self->address_fields) ] );
	},
);

use Geo::IP;

sub process {
	my ( $self, $stash ) = @_;
	my $addr;

	foreach my $field ( @{$self->_address_fields} ) {
		if( defined $stash->{$field} ) {
			$addr = $stash->{'client_ip'};
		}
	}

	if( ! defined $addr ) {
		return;
	}

	my $cc = $self->_geoip->country_code_by_addr( $addr );
	if( defined $cc ) {
		$stash->{'geoip_cc'} = $cc;
	} else {
		$stash->{'geoip_cc'} = 'unknown';
	}

	return;
}

has 'database' => ( is => 'ro', isa => 'Str', default => '/usr/share/GeoIP/GeoIP.dat' );

has '_geoip' => (
	is => 'ro', isa => 'Geo::IP', lazy => 1,
	default => sub {
		my $self = shift;
		return Geo::IP->open( $self->database, GEOIP_STANDARD );
	},
);

1;

