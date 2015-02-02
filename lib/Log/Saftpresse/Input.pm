package Log::Saftpresse::Input;

use strict;
use warnings;

# ABSTRACT: base class for a log input
# VERSION

sub new {
	my $class = shift;
	my $self = { @_ };
	return bless($self, $class);
}

sub read_event {
	my ( $self, $counters ) = @_;
	die('not implemented');
}

sub init { return; }

1;

