package Log::Saftpresse::Plugin::Dump;

use Moose;

# ABSTRACT: plugin to dump current message $stash
# VERSION

extends 'Log::Saftpresse::Plugin';

use Data::Dumper;

sub process {
	my ( $self, $stash ) = @_;
	print Dumper( $stash );	
	return;
}

1;

