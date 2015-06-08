package Log::Saftpresse::Output;

use Moose;

# ABSTRACT: base class for outputs
# VERSION

has 'name' => ( is => 'ro', isa => 'Str', required => 1 );

sub output {
	my ( $self, $event ) = @_;
	die('not implemented');
}

sub init { return; }

1;

