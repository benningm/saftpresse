package Log::Saftpresse::CounterOutputs;

use Moose;

# ABSTRACT: class to manage saftpresse counter output
# VERSION

extends 'Log::Saftpresse::PluginContainer';

has 'plugin_prefix' => ( is => 'ro', isa => 'Str',
	default => 'Log::Saftpresse::CountersOutput::',
);

sub output {
	my ( $self, @events ) = @_;

	foreach my $plugin ( @{$self->plugins} ) {
		$plugin->output( @events );
	}

	return;
}

1;

