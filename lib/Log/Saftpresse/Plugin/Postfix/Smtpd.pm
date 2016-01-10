package Log::Saftpresse::Plugin::Postfix::Smtpd;

use Moose::Role;

# ABSTRACT: plugin to gather postfix/smtpd advanced statistics
# VERSION

use Log::Saftpresse::Plugin::Postfix::Utils qw( gimme_domain );

use Time::Piece;
use Time::Seconds;

sub process_smtpd {
	my ( $self, $stash, $notes ) = @_;
	my $service = $stash->{'service'};
	my $message = $stash->{'message'};
	my $qid = $stash->{'queue_id'};
	my $pid = $stash->{'pid'};
	my $time = $stash->{'time'};

	if( $service eq 'pickup' && $message =~ /^(sender|uid)=/) {
		$notes->set( 'client-'.$qid => 'pickup' );
	}

	if( $service ne 'smtpd' ) { return; }

	if( defined $qid && $message =~ /client=(.+?)(,|$)/ ) {
		$notes->set( 'client-'.$qid => gimme_domain($1) );
	} elsif ( defined $pid && $message =~ /^connect from / ) {
		$notes->set( 'pid-connect-'.$pid => $time );
    $self->new_tracking_id($stash, $notes);
	} elsif ( defined $pid &&
	       		( my ($host) = $message =~ /^disconnect from (.+)$/) ) {
		my $host = gimme_domain($host);
		my $conn_time = $notes->get( 'pid-connect-'.$pid );
		if( ! defined $conn_time ) { return; }
		my $elapsed = $time - $conn_time;
		my $sec = $elapsed->seconds;

		$stash->{'connection_time'} = $sec;
		$stash->{'client'} = $host;

		if( $self->saftsumm_mode ) {
			$self->incr_host_one( $stash, 'conn', 'per_hr', $time->hour);
			$self->incr_host_one( $stash, 'conn', 'per_day', $time->ymd);
			$self->incr_host( $stash, 'conn', 'busy', 'per_hr', $time->hour, $sec);
			$self->incr_host( $stash, 'conn', 'busy', 'per_day', $time->ymd, $sec);
			$self->incr_host_max( $stash, 'conn', 'busy', 'max_per_hr', $time->hour, $sec);
			$self->incr_host_max( $stash, 'conn', 'busy', 'max_per_day', $time->ymd, $sec);
			$self->incr_host_max( $stash, 'conn', 'busy', 'max_per_domain', $host, $sec);
		}
		$self->incr_host_one( $stash, 'conn', 'per_domain', $host);
		$self->incr_host( $stash, 'conn', 'busy', 'per_domain', $host, $sec);

		$self->incr_host_one( $stash, 'conn', 'total');
		$self->incr_host( $stash, 'conn', 'busy', 'total', $sec);

    $self->clear_tracking_id('pid', $stash, $notes);
	} 

	return;
}

1;

