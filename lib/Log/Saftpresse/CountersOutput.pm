package Log::Saftpresse::CountersOutput;

use strict;
use warnings;

# ABSTRACT: base class for output of counters
# VERSION

sub new {
	my $class = shift;
	my $self = { @_ };
	return bless($self, $class);
}

sub output {
	my ( $self, $counters ) = @_;
	die('not implemented');
}

sub init { return; }

1;

