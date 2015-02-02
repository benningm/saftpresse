package Log::Saftpresse::Plugin;

use strict;
use warnings;

# ABSTRACT: base class for pflogsumm plugins
# VERSION

use Log::Saftpresse::Counters;

sub new {
	my $class = shift;
	my $self = {
		'counters' => Log::Saftpresse::Counters->new,
		@_,
	};

	return bless($self, $class);
}

sub counters {
	my $self = shift;
	return( $self->{'counters'} );
}
*cnt = \&counters;

sub process {
	my ( $self, $stash, $notes ) = @_;
	die('not implemented');
}

sub init { return; }

1;

