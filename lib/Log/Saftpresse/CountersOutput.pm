package Log::Saftpresse::CountersOutput;

use Moose;

# ABSTRACT: base class for output of counters
# VERSION

sub output {
	my ( $self, $counters ) = @_;
	die('not implemented');
}

sub init { return; }

1;

