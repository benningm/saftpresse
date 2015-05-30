package Log::Saftpresse::Input::Server;

use Moose;

# ABSTRACT: udp/tcp network server input plugin for saftpresse
# VERSION

extends 'Log::Saftpresse::Input';

use IO::Socket::INET;
use IO::Select;

has 'port' => ( is => 'ro', isa => 'Int', default => 514 );
has 'proto' => ( is => 'ro', isa => 'Str', default => 'tcp' );
has 'listen' => ( is => 'ro', isa => 'Str', default => '127.0.0.1' );

has 'connection_queue_size' => ( is => 'ro', isa => 'Int', default => 10 );

has 'listener' => (
	is => 'ro', isa => 'IO::Socket::INET', lazy => 1,
	default => sub {
		my $self = shift;
		my $l = IO::Socket::INET->new(
			Listen => $self->connection_queue_size,
			LocalAddr => $self->listen,
			LocalPort => $self->port,
			Proto => $self->proto,
			Blocking => 0,
		) or die("error creating network listener socket: ".$@);
		return $l;
	},
);

has 'listener_select' => (
	is => 'ro', isa => 'IO::Select', lazy => 1,
	default => sub {
		my $self = shift;
		my $s = IO::Select->new();
		$s->add( $self->listener );
		return $s;
	},
);

sub accept_new_connections {
	my $self = shift;
	while( $self->listener_select->can_read(0) ) {
		my $conn = $self->listener->accept;
		$conn->blocking(0);
		$self->io_select->add( $conn );
		$self->handle_new_connection( $conn );
	}
	return;
}

sub handle_new_connection {
	my ( $self, $conn ) = @_;
	return;
}

sub io_handles {
	my $self = shift;
	return( $self->listener, $self->io_select->handles );
}

has 'io_select' => (
	is => 'ro', isa => 'IO::Select', lazy => 1,
	default => sub {
		my $self = shift;
		my $s = IO::Select->new();
		return $s;
	},
);


sub read_events {
	my ( $self ) = @_;
	my @events;

	$self->accept_new_connections;

	my @ready = $self->io_select->can_read(0);
	foreach my $conn ( @ready )  {
		if( $conn->eof ) {
			$self->handle_cleanup_connection( $conn );
			$self->io_select->remove( $conn );
			$conn->close;
		}
		push( @events, $self->handle_data($conn) );
	}
	return @events;
}

sub handle_cleanup_connection {
	my ( $self, $conn ) = @_;
	return;
}

sub handle_data {
	my ( $self, $conn ) = @_;
	my @events;
	while( defined( my $line = $conn->getline ) ) {
		$line =~ s/[\r\n]*$//;
		my $event = {
			'message' => $line,
		};
		push( @events, $event );
	}
	return @events;
}

sub can_read {
	my ( $self ) = @_;
	my @can_read = (
	       $self->io_select->can_read(0),
	       $self->listener_select->can_read(0),
	);
	return( scalar @can_read );
}

sub eof {
	return 0; # we're never at EOF
}

1;

