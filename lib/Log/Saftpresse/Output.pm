package Log::Saftpresse::Output;

use strict;
use warnings;

# ABSTRACT: base class for outputs
# VERSION

sub new {
	my $class = shift;
	my $self = { @_ };
	return bless($self, $class);
}

sub output {
	my ( $self, $event ) = @_;
	die('not implemented');
}

sub init { return; }

1;

