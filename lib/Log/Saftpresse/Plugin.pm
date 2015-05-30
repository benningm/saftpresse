package Log::Saftpresse::Plugin;

use Moose;

# ABSTRACT: base class for saftpresse plugins
# VERSION

use Log::Saftpresse::Counters;

has 'name' => ( is => 'ro', isa => 'Str', required => 1 );

has 'counters' => (
	is => 'ro', isa => 'Log::Saftpresse::Counters', lazy => 1,
	default => sub {
		 Log::Saftpresse::Counters->new;
	},
);
*cnt = \&counters;

sub process {
	my ( $self, $stash, $notes ) = @_;
	die('not implemented');
}

sub init { return; }

1;

