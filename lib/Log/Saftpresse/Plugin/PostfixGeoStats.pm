package Log::Saftpresse::Plugin::PostfixGeoStats;

use Moose;

# ABSTRACT: plugin to build postfix statistics from geoip info
# VERSION

extends 'Log::Saftpresse::Plugin';

sub process {
	my ( $self, $stash ) = @_;
	my $cc = $stash->{'geoip_cc'};
	my $service = $stash->{'service'};
	my $message = $stash->{'message'};

	if( defined $cc && $stash->{'service'} eq 'smtpd' &&
			$message =~ /client=/ ) {
		$self->cnt->incr_one('client', $cc);
	}

	return;
}

1;

