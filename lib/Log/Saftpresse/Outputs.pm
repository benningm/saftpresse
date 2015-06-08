package Log::Saftpresse::Outputs;

use Moose;

# ABSTRACT: class to manage saftpresse outputs
# VERSION

extends 'Log::Saftpresse::PluginContainer';

has 'plugin_prefix' => ( is => 'ro', isa => 'Str',
	default => 'Log::Saftpresse::Output::',
);

use Log::Saftpresse::Log4perl;

sub output {
	my ( $self, @events ) = @_;

	foreach my $plugin ( @{$self->plugins} ) {
		eval { $plugin->output( @events ) };
		if( $@ ) {
			$log->error('error writing event to plugin '.$plugin->name.': '.$@);
		}
	}

	return;
}

1;

