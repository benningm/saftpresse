package Log::Saftpresse::Outputs;

use Moose;

# ABSTRACT: class to manage saftpresse outputs
# VERSION

extends 'Log::Saftpresse::PluginContainer';

has 'plugin_prefix' => ( is => 'ro', isa => 'Str',
	default => 'Log::Saftpresse::Output::',
);

sub output {
	my ( $self, @events ) = @_;

	foreach my $plugin ( @{$self->plugins} ) {
		$plugin->output( @events );
	}

	return;
}

1;

