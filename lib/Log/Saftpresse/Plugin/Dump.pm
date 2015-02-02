package Log::Saftpresse::Plugin::Dump;

use strict;
use warnings;

# ABSTRACT: plugin to dump current message $stash
# VERSION

use base 'Log::Saftpresse::Plugin';

use Data::Dumper;

sub process {
	my ( $self, $stash ) = @_;
	print Dumper( $stash );	
	return;
}

1;

