package Log::Saftpresse::Input::FileTail;

use Moose;

# ABSTRACT: log input for following a file
# VERSION

use IO::File;
use File::stat;

use Time::Piece;
use Sys::Hostname;

extends 'Log::Saftpresse::Input';

has 'path' => ( is => 'ro', isa => 'Str',
	default => sub {
		my $self = shift;
		return $self->name;
	},
);

has 'file' => ( is => 'rw', isa => 'IO::File', lazy => 1,
	default => sub {
		my $self = shift;
		return $self->_open_file;
	},
);

sub _open_file {
	my $self = shift;
	my $f = IO::File->new($self->path,"r");
	if( ! defined $f ) {
		die('could not open '.$self->path.' for input: '.$!);
	}
	$f->blocking(0);
	$f->seek(0,2); # seek to end of file
	return $f;
}

sub reopen_file {
	my $self = shift;
	$self->file->close;
	$self->file( $self->_open_file );
	return;
}

sub io_handles {
	my $self = shift;
	return;
}

sub read_events {
	my ( $self ) = @_;
	my @events;
	foreach my $line ( $self->file->getlines ) {
		chomp( $line );
		my $event = {
			'host' => hostname,
			'time' => Time::Piece->new,
			'message' => $line,
		};
		push( @events, $event );
	}
	$self->file->seek(0,1); # clear eof flag
	return @events;
}

sub eof {
	my $self = shift;
	if( stat($self->file)->nlink == 0 ) {
		# file has been deleted (logrotate?)
		$self->reopen_file;
	}
	return 0; # we dont signal eof, we're almost always eof.
}

sub can_read {
	my $self = shift;
	my $mypos = $self->file->tell;
	my $size = stat($self->file)->size;
	if( $size > $mypos ) {
		return 1;
	}
	return 0;
}


1;

