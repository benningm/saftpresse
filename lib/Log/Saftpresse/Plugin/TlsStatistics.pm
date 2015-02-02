package Log::Saftpresse::Plugin::TlsStatistics;

use strict;
use warnings;

# ABSTRACT: plugin to gather TLS statistics
# VERSION

use base 'Log::Saftpresse::Plugin';

sub process {
	my ( $self, $stash, $notes ) = @_;
	my $service = $stash->{'service'};
	my $pid = $stash->{'pid'};
	my $message = $stash->{'message'};

	if( $service ne 'smtp' && $service ne 'smtpd' ) {
		return;
	}

	my $tls_params = $notes->get($service.'-tls-'.$pid);
	if( defined $tls_params ) {
		if( $message =~ /^(lost connection|disconnect|connect from)/ ) {
			$notes->remove($service.'-tls-'.$pid);
			return;
		}
		@$stash{keys %$tls_params} = values %$tls_params;
		if( $message =~ /^client=/ ) {
			$self->incr_tls_stats($service, 'messages', $tls_params);
		}
	}

	if( my ($tlsLevel,$tlsHost, $tlsAddr, $tlsProto, $tlsCipher, $tlsKeylen) =
		$message =~ /^(\S+) TLS connection established (?:from|to) ([^\[]+)\[([^\]]+)\]:(?:\d+:)? (\S+) with cipher (\S+) \((\d+)\/(\d+) bits\)/ ) {
		my $tls_params = {
			'tls_level' => $tlsLevel,
			'tls_proto' => $tlsProto,
			'tls_chipher' => $tlsCipher,
			'tls_keylen' => $tlsKeylen,
		};
		$self->incr_tls_stats($service, 'connections', $tls_params);
		@$stash{keys %$tls_params} = values %$tls_params;
		$notes->set($service.'-tls-'.$pid, $tls_params);
	}

	return;
}

sub incr_tls_stats {
	my $self = shift;
	my $cnt = $self->cnt;
	my $tls_params = pop;
	my @path = @_;

	$self->cnt->incr_one(@path, 'total');
	$self->cnt->incr_one(@path, 'level', $tls_params->{'tls_level'});
	$self->cnt->incr_one(@path, 'protocol', $tls_params->{'tls_proto'});
	$self->cnt->incr_one(@path, 'cipher', $tls_params->{'tls_chipher'});
	$self->cnt->incr_one(@path, 'keylen', $tls_params->{'tls_keylen'});

	return;
}

1;

