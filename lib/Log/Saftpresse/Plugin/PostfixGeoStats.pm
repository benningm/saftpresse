package Log::Saftpresse::Plugin::PostfixGeoStats;

use strict;
use warnings;

# ABSTRACT: plugin to build postfix statistics from geoip info
# VERSION

use base 'Log::Saftpresse::Plugin';

sub process {
	my ( $self, $stash ) = @_;
	my $cc = $stash->{'geoip_cc'};
	my $service = $stash->{'service'};
	my $message = $stash->{'message'};

	if( defined $cc && $service eq 'smtpd' &&
			$message =~ /client=/ ) {
		$self->cnt->incr_one('client', $cc);
	}

	return;
}

1;

