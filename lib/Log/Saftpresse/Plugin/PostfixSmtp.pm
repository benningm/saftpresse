package Log::Saftpresse::Plugin::PostfixSmtp;

use Moose;

# ABSTRACT: plugin to gather postfix smtp client statistics
# VERSION

extends 'Log::Saftpresse::Plugin';

sub process {
	my ( $self, $stash ) = @_;
	my $service = $stash->{'service'};
	if( $service ne 'smtp' ) { return; }

	# Was an IPv6 problem here
	if($stash->{'message'} =~ /^connect to (\S+?): ([^;]+); address \S+ port.*$/) {
		$self->cnt->incr_one('messages', lc($2), $1);
	} elsif($stash->{'message'} =~ /^connect to ([^[]+)\[\S+?\]: (.+?) \(port \d+\)$/) {
		$self->cnt->incr_one('messages', lc($2), $1);
	}

	# TODO: is it possible to count connections?
	#$self->cnt->incr_one('connections');

	return;
}

1;

