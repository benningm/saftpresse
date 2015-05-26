package Log::Saftpresse::Plugin::PostfixQueueID;

use Moose;

# ABSTRACT: plugin to parse the postfix queue ID
# VERSION

extends 'Log::Saftpresse::Plugin';

use Time::Piece;

sub process {
	my ( $self, $stash ) = @_;
	if( $stash->{'program'} !~ /^postfix/) { return; }
	
	if( my ( $queue_id, $msg ) = $stash->{'message'} =~
			/^([A-Z0-9]{11}|[b-zB-Z0-9]{15}|NOQUEUE): (.+)$/) {
		$stash->{'queue_id'} = $queue_id;
		$stash->{'message'} = $msg;
		return;
	}

	return;
}

1;

