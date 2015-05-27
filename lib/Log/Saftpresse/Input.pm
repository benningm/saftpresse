package Log::Saftpresse::Input;

use Moose;

# ABSTRACT: base class for a log input
# VERSION

has 'name' => ( is => 'ro', isa => 'Str', required => 1 );

sub io_handles {
	my $self = shift;
	die('not implemented');
	return;
}

sub can_read {
	my $self = shift;
	die('not implemented');
	return 0;
}

sub read_events {
	my ( $self, $counters ) = @_;
	die('not implemented');
	return( { message => 'hello world' } );
}

sub eof {
	my $self = shift;
	die('not implemented');
	return 0;
}

sub init { return; }

1;

