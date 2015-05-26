package Log::Saftpresse::Input::FileTail;

use strict;
use warnings;

# ABSTRACT: log input for following a file
# VERSION

use IO::File;
use File::stat;

use Time::Piece;
use Sys::Hostname;

sub new {
	my $class = shift;
	my $self = { @_ };
	return bless($self, $class);
}

sub path {
	my $self = shift;
	if( defined $self->{'path'} ) {
		return $self->{'path'};
	}
	return $self->{'name'};
}

sub io_handles {
	my $self = shift;
	return;
}

sub read_events {
	my ( $self ) = @_;
	my @events;
	foreach my $line ( $self->{'file'}->getlines ) {
		chomp( $line );
		my $event = {
			'host' => hostname,
			'time' => Time::Piece->new,
			'message' => $line,
		};
		push( @events, $event );
	}
	$self->{'file'}->seek(0,1); # clear eof flag
	return @events;
}

sub eof {
	my $self = shift;
	if( stat($self->{'file'})->nlink == 0 ) {
		# file has been deleted (logrotate?)
		
		# reopen file
		$self->{'file'}->close;
		$self->init;
	}
	return 0; # we dont signal eof, we're almost always eof.
}

sub can_read {
	my $self = shift;
	my $mypos = $self->{'file'}->tell;
	my $size = stat($self->{'file'})->size;
	if( $size > $mypos ) {
		return 1;
	}
	return 0;
}

sub init {
	my $self = shift;
	$self->{'file'} = IO::File->new($self->path,"r");
	if( ! defined $self->{'file'} ) {
		die('could not open '.$self->path.' for input: '.$!);
	}
	$self->{'file'}->blocking(0);
	$self->{'file'}->seek(0,2); # seek to end of file
	return;
}

1;

