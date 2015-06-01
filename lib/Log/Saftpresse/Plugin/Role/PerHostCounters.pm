package Log::Saftpresse::Plugin::Role::PerHostCounters;

use Moose::Role;

# ABSTRACT: role for plugins to gather statistics/counters
# VERSION

has 'per_host_counters' => ( is => 'rw', isa => 'Bool', default => 1 );

sub _get_event_host {
	my ( $self, $event ) = @_;
	if( ! $self->per_host_counters ) {
		return;
	}
	if( defined $event->{'host'} ) {
		return( $event->{'host'});
	}
	return 'empty';
}

sub incr_host {
	my ( $self, $event, @params ) = @_;
	return $self->incr( $self->_get_event_host($event), @params );
}

sub incr_host_one {
	my ( $self, $event, @params ) = @_;
	return $self->incr_one( $self->_get_event_host($event), @params );
}

sub incr_host_max {
	my ( $self, $event, @params ) = @_;
	return $self->incr_max( $self->_get_event_host($event), @params );
}

1;

