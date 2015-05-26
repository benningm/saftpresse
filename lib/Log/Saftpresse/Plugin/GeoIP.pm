package Log::Saftpresse::Plugin::GeoIP;

use Moose;

# ABSTRACT: plugin to lookup geoip database
# VERSION

extends 'Log::Saftpresse::Plugin';

use Geo::IP;

sub process {
	my ( $self, $stash ) = @_;
	my $ip = $stash->{'client_ip'};

	if( defined $ip ) {
		my $cc = $self->_geoip->country_code_by_addr( $ip );
		if( defined $cc ) {
			$stash->{'geoip_cc'} = $cc;
		} else {
			$stash->{'geoip_cc'} = 'unknown';
		}
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

