package Log::Saftpresse::Plugin::LimitProgram;

use strict;
use warnings;

# ABSTRACT: plugin to limit messages by syslog program name
# VERSION

use base 'Log::Saftpresse::Plugin';

sub process {
	my ( $self, $stash ) = @_;
	my $regex = $self->{'regex'};

	if( ! defined $stash->{'program'} || ! defined $regex ) {
		return;
	}
	if( $stash->{'program'} !~ /$regex/ ) {
		return('next');
	}
	
	return;
}

1;

