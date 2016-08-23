package Log::Saftpresse::Output::Redis;

use Moose;

# ABSTRACT: plugin to write events to a redis server
# VERSION

extends 'Log::Saftpresse::Output';

use Redis;
use JSON qw(encode_json);

=head1 Description

Write events to a queue on a redis server.

=head1 Synopsis

  <Input myapp>
    module = "Redis"
    server = "127.0.0.1:6379"
    # sock = "/path/to/socket"
    db = 0
    queue = "logs"
  </Input>

=head1 Format

The plugin will write entries in JSON format.

=cut

has 'server' => ( is => 'ro', isa => 'Str',
  default => '127.0.0.1:6379'
);
has 'sock' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'db' => ( is => 'ro', isa => 'Int', default => 0 );

has '_redis' => ( is => 'rw', isa => 'Redis', lazy => 1,
  default => sub {
    my $self = shift;
    return $self->_connect_redis;
  },
);

has 'queue' => ( is => 'ro', isa => 'Str', default => 'logs' );

sub _connect_redis {
  my $self = shift;
  my $r = Redis->new(
    defined $self->sock ? (
      sock => $self->sock,
    ) : (
      server => $self->server,
    ),
  );
  $r->select( $self->db );
  return $r;
}

sub output {
	my ( $self, @events ) = @_;

	my @blobs = map {
		my %output = %$_;
		if( defined $output{'time'} &&
				ref($output{'time'}) eq 'Time::Piece' ) {
			$output{'@timestamp'} = $output{'time'}->datetime;
			delete $output{'time'};
    }
    encode_json(\%output)
  } @events;
	$self->_redis->lpush($self->queue, @blobs);

	return;
}

1;

