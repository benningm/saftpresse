package Log::Saftpresse::Input::Stdin;

use Moose;

# ABSTRACT: log input for reading STDIN
# VERSION

use IO::Handle;
use IO::Select;

use Sys::Hostname;
use Time::Piece;

extends 'Log::Saftpresse::Input';

has 'max_chunk_lines' => ( is => 'rw', isa => 'Int', default => 1024 );

sub io_handles {
	my $self = shift;
	if( ! defined $self->{'stdin'} ) {
		die('stdin handle has not been initialized!');
	}
	return( $self->{'stdin'} );
}

sub read_events {
	my ( $self ) = @_;
	my @events;
	my $cnt = 0;
	while( defined( my $line = $self->{'stdin'}->getline ) ) {
		chomp( $line );
		my $event = {
			'host' => hostname,
			'time' => Time::Piece->new,
			'message' => $line,
		};
		push( @events, $event );
		$cnt++;
		if( $cnt > $self->max_chunk_lines ) {
			last;
		}
	}
	return @events;
}

sub can_read {
	my ( $self ) = @_;
	my @can_read = $self->{'select'}->can_read(0);
	return( scalar @can_read );
}

sub eof {
	my $self = shift;
	return $self->{'stdin'}->eof;
}

sub init {
	my $self = shift;
	$self->{'stdin'} = IO::Handle->new_from_fd(fileno(STDIN),"r");
	$self->{'stdin'}->blocking(0);
	$self->{'select'} = IO::Select->new();
	$self->{'select'}->add( $self->{'stdin'} );
	return;
}

1;

