package Log::Saftpresse::Plugin::Postfix::QueueID;

use Moose::Role;

# ABSTRACT: plugin to parse the postfix queue ID
# VERSION

sub process_queueid {
	my ( $self, $stash, $notes ) = @_;
	
	if( my ( $queue_id, $msg ) = $stash->{'message'} =~
			/^([A-Z0-9]{8,12}|[b-zB-Z0-9]{15}|NOQUEUE): (.+)$/) {
		$stash->{'queue_id'} = $queue_id;
		$stash->{'message'} = $msg;
    $self->get_tracking_id('queue_id', $stash, $notes);
	}

	return;
}

1;

