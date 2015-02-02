package Log::Saftpresse::CountersOutput::Dump;

use strict;
use warnings;

# ABSTRACT: plugin to dump counters to stdout
# VERSION

use base 'Log::Saftpresse::CountersOutput';

use Data::Dumper;

sub output {
	my ( $self, $counters ) = @_;
	my %data = map {
		$_ => $counters->{$_}->counters,
	} keys %$counters;
	print Dumper( \%data );	
	return;
}

1;

