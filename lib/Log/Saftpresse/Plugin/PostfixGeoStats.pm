package Log::Saftpresse::Plugin::PostfixGeoStats;

use Moose;

# ABSTRACT: plugin to build postfix statistics from geoip info
# VERSION

extends 'Log::Saftpresse::Plugin';
with 'Log::Saftpresse::Plugin::Role::CounterUtils';

sub process {
	my ( $self, $stash ) = @_;
	my $cc = $stash->{'geoip_cc'};;
	my $service = $stash->{'service'};
	my $message = $stash->{'message'};
	my $program = $stash->{'program'};

	if( ! defined $program || $program !~ /^postfix\// ) {
		return;
	}
	if( defined $cc && $stash->{'service'} eq 'smtpd' &&
			$message =~ /client=/ ) {
		$self->incr_host_one( $stash, 'client', $cc);
	}

	return;
}

1;

