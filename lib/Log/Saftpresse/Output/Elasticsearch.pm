package Log::Saftpresse::Output::Elasticsearch;

use Moose;

# ABSTRACT: plugin to write events to elasticsearch
# VERSION

extends 'Log::Saftpresse::Output';

use Time::Piece;
use Search::Elasticsearch;

has 'nodes' => ( is => 'rw', isa => 'Str', default => 'localhost:9200' );
has 'cxn_pool' => ( is => 'rw', isa => 'Str', default => 'Static' );
has 'type' => ( is => 'rw', isa => 'Str', default => 'log' );

has 'indicies_template' => (
	is => 'rw', isa => 'Str', default => 'saftpresse-%Y-%m-%d' );

sub current_index {
	my $self = shift;
	return( Time::Piece->new->strftime( $self->indicies_template ) );
}

has 'es' => ( is => 'ro', lazy => 1,
	default => sub {
		my $self = shift;
		return Search::Elasticsearch->new(
			nodes => [ split(/\s*,\s*/, $self->nodes) ],
			cxn_pool => $self->cxn_pool,
		);
	},
);

sub index_event {
	my ( $self, $e ) = @_;

	if( defined $e->{'time'} &&
			ref($e->{'time'}) eq 'Time::Piece' ) {
		$e->{'@timestamp'} = $e->{'time'}->datetime;
		delete $e->{'time'};
	}
	$self->es->index(
	    index   => $self->current_index,
	    type    => $self->type,
	    body    => $e,
	);

	return;
}

sub output {
	my ( $self, @events ) = @_;

	foreach my $event (@events) { 
		if( defined $event->{'type'} && $event->{'type'} ne $self->type ) {
			next;
		}
		$self->index_event( $event );
	}

	return;
}


1;

