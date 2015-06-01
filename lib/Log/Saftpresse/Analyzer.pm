package Log::Saftpresse::Analyzer;

use Moose;

# ABSTRACT: class to analyze log messages
# VERSION

use Log::Saftpresse::Notes;
use Log::Saftpresse::Counters;

extends 'Log::Saftpresse::PluginContainer';

has 'notes' => (
	is => 'ro', isa => 'Log::Saftpresse::Notes', lazy => 1,
	default => sub { Log::Saftpresse::Notes->new; },
);

has 'stats' => (
	is => 'ro', isa => 'Log::Saftpresse::Counters', lazy => 1,
	default => sub { Log::Saftpresse::Counters->new; },
);

sub process_message {
	my ( $self, $msg ) = @_;
	my $stash = {
		'message' => $msg,
	};
	$self->process_event( $stash );
	return;
}

sub process_event {
	my ( $self, $stash ) = @_;
	
	foreach my $plugin ( @{$self->plugins} ) {
		my $ret = $plugin->process(
			$stash, $self->notes );
		if( defined $ret && $ret eq 'next') {
			last;
		}
	}
	$self->stats->incr_one('events');

	return;
}

sub get_counters {
	my ( $self, $name ) = @_;
	my $plugin = $self->get_plugin( $name );
	if( defined $plugin ) {
		return( $plugin->counters );
	}
	return;
}

sub get_all_counters {
	my $self = shift;
	my %values;

	%values = map {
		$_->name => $_->counters
	} @{$self->plugins};

	return \%values;
}

1;

