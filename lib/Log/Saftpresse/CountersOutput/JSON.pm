package Log::Saftpresse::CountersOutput::JSON;

use strict;
use warnings;

# ABSTRACT: plugin to dump counters in JSON format
# VERSION

use base 'Log::Saftpresse::CountersOutput';

use JSON;

sub output {
	my ( $self, $counters ) = @_;
	my $json = JSON->new;
	$json->pretty(1);
	my %data = map {
		$_ => $counters->{$_}->counters,
	} keys %$counters;
	print $json->encode( \%data );	
	return;
}

1;

