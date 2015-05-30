package Log::Saftpresse::Plugin::Postfix::Recieved;

use Moose::Role;

# ABSTRACT: plugin to gather postfix recieved messages statistics
# VERSION

use Log::Saftpresse::Utils qw( postfix_remote );

sub process_recieved {
	my ( $self, $stash, $notes ) = @_;
	my $service = $stash->{'service'};
	my $message = $stash->{'message'};
	my $qid = $stash->{'queue_id'};

	if( $service eq 'smtpd' &&
			$message =~ /client=(.+?)(,|$)/ ) {
		my ( $host, $addr ) = postfix_remote( $1 );
		$stash->{'client_host'} = $host;
		$stash->{'client_ip'} = $addr;
		$self->cnt->incr_one('total');
		if( $self->saftsumm_mode ) {
			$self->incr_per_time_one( $stash->{'time'} );
		}
		$notes->set('client-'.$qid => $host);
	} elsif( $service eq 'pickup' &&
			$message =~ /(sender|uid)=/ ) {
		$self->cnt->incr_one('total');
		if( $self->saftsumm_mode ) {
			$self->incr_per_time_one( $stash->{'time'} );
		}
		$notes->set('client-'.$qid => 'pickup');
	}

	return;
}

sub incr_per_time_one {
	my ( $self, $time ) = @_;
	$self->cnt->incr_one( 'per_hr', $time->hour );
	$self->cnt->incr_one( 'per_mday', $time->mday );
	$self->cnt->incr_one( 'per_wday', $time->wday );
	$self->cnt->incr_one( 'per_day', $time->ymd );
	return;
}

1;

