package Log::Saftpresse::Output::Graphite;

use Moose;

# ABSTRACT: plugin to write events to carbon line reciever
# VERSION

extends 'Log::Saftpresse::Output';

use Time::Piece;
use IO::Socket::INET;

has 'prefix' => ( is => 'rw', isa => 'Str',
	default => 'saftpresse-metric',
);

has 'type' => ( is => 'rw', isa => 'Str',
	default => 'metric',
);

has '_handle' => (
	is => 'rw', isa => 'IO::Socket::INET', lazy => 1,
	default => sub {
		my $self = shift;
		my $handle = IO::Socket::INET->new(
			PeerAddr => $self->{'host'} || '127.0.0.1',
			PeerPort => $self->{'port'} || '2003',
			Proto => 'tcp',
		) or die('error opening connection to graphite line reciever: '.$@);
		return $handle;
	},
);

sub output {
	my ( $self, @events ) = @_;

	foreach my $event (@events) { 
		if( ! defined $event->{'type'} || $event->{'type'} ne $self->type ) {
			next;
		}
		$self->send_event( $event );
	}

	return;
}

sub send_event {
	my ( $self, $event ) = @_;
	if( ! defined $event->{'path'} || ! defined $event->{'value'} ) {
		return;
	}
	my $ts = $event->{'timestamp'};
	if( ! defined $ts ) {
		$ts = Time::Piece->new->epoch;
	}
	my $host = $event->{'host'};

	my $path = join('.',
		$self->prefix,
		defined $host ? ( 'host', $host ) : ( 'global' ),
		$event->{'path'}
	);

	$self->_handle->print( $path.' '.$event->{'value'}.' '.$ts."\n" );

	return;
}

1;

