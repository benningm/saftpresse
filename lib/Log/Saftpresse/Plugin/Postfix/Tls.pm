package Log::Saftpresse::Plugin::Postfix::Tls;

use Moose::Role;

# ABSTRACT: plugin to gather TLS statistics
# VERSION

sub process_tls {
	my ( $self, $stash, $notes ) = @_;
	my $service = $stash->{'service'};
	my $pid = $stash->{'pid'};
	my $message = $stash->{'message'};
	my $queue_id = $stash->{'queue_id'};

	if( $service ne 'smtp' && $service ne 'smtpd' ) {
		return;
	}

	my $tls_params = $notes->get($service.'-tls-'.$pid);
	if( defined $tls_params ) {
		if( $service eq 'smtpd' &&
		       		$message =~ /^(lost connection|disconnect|connect from)/ ) {
			$notes->remove($service.'-tls-'.$pid);
			return;
		}
		@$stash{keys %$tls_params} = values %$tls_params;
		if( $service eq 'smtpd' && $message =~ /^client=/ ) {
			$self->incr_tls_stats( $stash, $tls_params, 'tls_msg', $service);
		} elsif( $service eq 'smtp' &&
		       		$message =~ /status=(sent|bounced|deferred)/ ) {
			$self->incr_tls_stats( $stash, $tls_params, 'tls_msg', $service);
			$notes->remove($service.'-tls-'.$pid);
			# postfix/smtp closes the TLS connection after each delivery
			# see postfix-users maillist (2015-02-05)
			# but there may be more than one recipients so remember
			# TLS parameters for this queue_id
			if( defined $queue_id ) {
				$notes->set($service.'-tls-'.$queue_id, $tls_params);
			}
		}
		return;
	} elsif( defined $queue_id &&
			defined($tls_params = $notes->get($service.'-tls-'.$queue_id))
			) {
		@$stash{keys %$tls_params} = values %$tls_params;
		$self->incr_tls_stats( $stash, $tls_params, 'tls_msg', $service);
	}

	if( my ($tlsLevel,$tlsHost, $tlsAddr, $tlsProto, $tlsCipher, $tlsKeylen) =
		$message =~ /^(\S+) TLS connection established (?:from|to) ([^\[]+)\[([^\]]+)\]:(?:\d+:)? (\S+) with cipher (\S+) \((\d+)\/(\d+) bits\)/ ) {
		my $tls_params = {
			'tls_level' => $tlsLevel,
			'tls_proto' => $tlsProto,
			'tls_chipher' => $tlsCipher,
			'tls_keylen' => $tlsKeylen,
		};
		$self->incr_tls_stats( $stash, $tls_params, 'tls_conn', $service);
		@$stash{keys %$tls_params} = values %$tls_params;
		$notes->set($service.'-tls-'.$pid, $tls_params);
	}

	return;
}

sub incr_tls_stats {
	my ( $self, $stash, $tls_params, @path ) = @_;

	$self->incr_host_one( $stash, @path, 'total');
	$self->incr_host_one( $stash, @path, 'level', $tls_params->{'tls_level'});
	$self->incr_host_one( $stash, @path, 'proto', $tls_params->{'tls_proto'});
	$self->incr_host_one( $stash, @path, 'cipher', $tls_params->{'tls_chipher'});
	$self->incr_host_one( $stash, @path, 'keylen', $tls_params->{'tls_keylen'});

	return;
}

1;

