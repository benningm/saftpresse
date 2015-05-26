package Log::Saftpresse::Output;

use Moose;

# ABSTRACT: base class for outputs
# VERSION

sub output {
	my ( $self, $event ) = @_;
	die('not implemented');
}

sub init { return; }

1;

