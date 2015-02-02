package Log::Saftpresse::Input::Stdin;

use strict;
use warnings;

# ABSTRACT: log input for reading STDIN
# VERSION

use IO::Handle;
use IO::Select;

sub new {
	my $class = shift;
	my $self = { @_ };
	return bless($self, $class);
}

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
	foreach my $line ( $self->{'stdin'}->getlines ) {
		chomp( $line );
		my $event = { message => $line };
		push( @events, $event );
	}
	return @events;
}

sub can_read {
	my ( $self ) = @_;
	return( $self->{'select'}->can_read(0) );
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

