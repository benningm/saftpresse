package Log::Saftpresse::Plugin::Postfix::Smtp;

use Moose::Role;

# ABSTRACT: plugin to gather postfix smtp client statistics
# VERSION

sub process_smtp {
	my ( $self, $stash ) = @_;
	my $service = $stash->{'service'};
	if( $service ne 'smtp' ) { return; }

	# Was an IPv6 problem here
	if($stash->{'message'} =~ /^connect to (\S+?): ([^;]+); address \S+ port.*$/) {
		$self->incr_host_one( $stash, 'messages', lc($2), $1);
	} elsif($stash->{'message'} =~ /^connect to ([^[]+)\[\S+?\]: (.+?) \(port \d+\)$/) {
		$self->incr_host_one( $stash, 'messages', lc($2), $1);
	}

	# TODO: is it possible to count connections?
	#$self->incr_host_one( $stash, 'connections');

	return;
}

1;

