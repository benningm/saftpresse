package Log::Saftpresse::Plugin::PostfixSmtp;

use strict;
use warnings;

# ABSTRACT: plugin to gather postfix smtp client statistics
# VERSION

use base 'Log::Saftpresse::Plugin';

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

