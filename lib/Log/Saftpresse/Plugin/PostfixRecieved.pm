package Log::Saftpresse::Plugin::PostfixRecieved;

use Moose;

# ABSTRACT: plugin to gather postfix recieved messages statistics
# VERSION

extends 'Log::Saftpresse::Plugin';

use Log::Saftpresse::Utils qw( postfix_remote );

sub process {
	my ( $self, $stash, $notes ) = @_;
	if( $stash->{'program'} !~ /^postfix/ ) { return; }
	my $service = $stash->{'service'};
	my $message = $stash->{'message'};
	my $qid = $stash->{'queue_id'};

	if( $service eq 'smtpd' &&
			$message =~ /client=(.+?)(,|$)/ ) {
		my ( $host, $addr ) = postfix_remote( $1 );
		$stash->{'client_host'} = $host;
		$stash->{'client_ip'} = $addr;
		$self->cnt->incr_one('total');
		$self->incr_per_time_one( $stash->{'time'} );
		$notes->set('client-'.$qid => $host);
	} elsif( $service eq 'pickup' &&
			$message =~ /(sender|uid)=/ ) {
		$self->cnt->incr_one('total');
		$self->incr_per_time_one( $stash->{'time'} );
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

