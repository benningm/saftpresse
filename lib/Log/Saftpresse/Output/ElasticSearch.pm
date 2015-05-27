package Log::Saftpresse::Output::ElasticSearch;

use Moose;

# ABSTRACT: plugin to write events to elasticsearch
# VERSION

extends 'Log::Saftpresse::Output';

sub output {
	my ( $self, @events ) = @_;

	foreach my $event (@events) { 
	}

	return;
}

1;

