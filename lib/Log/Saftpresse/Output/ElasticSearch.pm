package Log::Saftpresse::Output::ElasticSearch;

use strict;
use warnings;

# ABSTRACT: plugin to write events to elasticsearch
# VERSION

use base 'Log::Saftpresse::Output';

sub elasticsearch {
	my $self = shift;
	if( ! defined $self->{_elasticsearch} ) {
		#$self->{_elasticsearch} = 
	}
	return $self->{_elasticsearch};
}

sub output {
	my ( $self, @events ) = @_;

	foreach my $event (@events) { 
	}

	return;
}

1;

