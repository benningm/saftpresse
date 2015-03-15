package Log::Saftpresse::Output::JSON;

use strict;
use warnings;

# ABSTRACT: plugin to dump events to in JSON to stdout
# VERSION

use base 'Log::Saftpresse::Output';

use Data::Dumper;

use JSON;

sub json {
	my $self = shift;
	if( ! defined $self->{_json} ) {
		$self->{_json} = JSON->new;
		$self->{_json}->utf8(1);
		$self->{_json}->pretty(1);
		$self->{_json}->allow_blessed(1);
	}
	return $self->{_json};
}

sub output {
	my ( $self, @events ) = @_;

	foreach my $event (@events) { 
		my %output = %$event;
		if( defined $output{'time'} &&
				ref($output{'time'}) eq 'Time::Piece' ) {
			$output{'@timestamp'} = $output{'time'}->datetime;
			delete $output{'time'};
		}
		print $self->json->encode( \%output );
	}

	return;
}

1;

