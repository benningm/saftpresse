package Log::Saftpresse::Plugin::GeoIP;

use strict;
use warnings;

# ABSTRACT: plugin to lookup geoip database
# VERSION

use base 'Log::Saftpresse::Plugin';

use Geo::IP;

sub process {
	my ( $self, $stash ) = @_;
	my $ip = $stash->{'client_ip'};

	if( defined $ip ) {
		my $cc = $self->{'_geoip'}->country_code_by_addr( $ip );
		if( defined $cc ) {
			$stash->{'geoip_cc'} = $cc;
		} else {
			$stash->{'geoip_cc'} = 'unknown';
		}
	}

	return;
}

sub init {
	my $self = shift;
	my $db = $self->{'database'};
	if( ! defined $db ) {
		$db = '/usr/share/GeoIP/GeoIP.dat';
	}
	$self->{'_geoip'} = Geo::IP->open( $db, GEOIP_STANDARD );
	return;
}

1;

