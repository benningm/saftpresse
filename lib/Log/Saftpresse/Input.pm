package Log::Saftpresse::Input;

use Moose;

# ABSTRACT: base class for a log input
# VERSION

sub read_event {
	my ( $self, $counters ) = @_;
	die('not implemented');
}

sub init { return; }

1;

