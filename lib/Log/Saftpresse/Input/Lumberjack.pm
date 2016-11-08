package Log::Saftpresse::Input::Lumberjack;

use Moose;

use Log::Saftpresse::Log4perl;

# ABSTRACT: lumberjack server input plugin for saftpresse
# VERSION

extends 'Log::Saftpresse::Input::Server';

use Net::Lumberjack::Reader;

has 'readers' => (
  is => 'ro', isa => 'HashRef[Net::Lumberjack::Reader]',
  default => sub { {} },
);

sub handle_cleanup_connection {
  my ( $self, $conn ) = @_;
  delete $self->readers->{"$conn"};
  return;
}

sub _get_reader {
  my ( $self, $conn ) = @_;
  if( ! defined $self->readers->{"$conn"} ) {
    $self->readers->{"$conn"} = Net::Lumberjack::Reader->new(
      handle => $conn,
    );
  }
  return $self->readers->{"$conn"};
}

sub handle_data {
	my ( $self, $conn ) = @_;
  my @events;
  my $reader = $self->_get_reader( $conn );
  while( my @data = $reader->read_data ) {
    push( @events, @data );
  }
  $reader->send_ack;
	return @events;
}

1;

