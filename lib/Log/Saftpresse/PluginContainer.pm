package Log::Saftpresse::PluginContainer;

use Moose;

# ABSTRACT: base class for classes holding plugins
# VERSION

use Log::Saftpresse::Log4perl;

has 'plugin_prefix' => (
	is => 'rw', isa => 'Str',
	default => 'Log::Saftpresse::Plugin::',
);

has 'plugins' => (
	is => 'rw', isa => 'ArrayRef', lazy => 1,
	default => sub { [] },
	traits => [ 'Array' ],
	handles => {
		'add_plugin' => 'push',
	},
);

sub load_plugin {
	my ( $self, $name, %params )= @_;
	if( ! defined $params{'module'} ) {
		die("Parameter module is not defined for Input $name!");
	}
	my $plugin_class = $self->plugin_prefix.$params{'module'};
	my $plugin;

  $log->info('loading plugin '.$name.' ('.$plugin_class.')...');
	my $code = "require ".$plugin_class.";";
	eval $code; ## no critic (ProhibitStringyEval)
	if($@) {
		die('could not load plugin '.$plugin_class.': '.$@);
	}
	eval {
		$plugin = $plugin_class->new(
			name => $name,
			%params
		);
		$plugin->init();
	};
	if($@) {
		die('could not initialize plugin '.$plugin_class.': '.$@);
	}
	$self->add_plugin($plugin);
	return;
}

sub load_config {
	my ( $self, $config ) = @_;

	$self->plugins( [] );

	foreach my $plugin ( keys %$config ) {
		$self->load_plugin( $plugin, %{$config->{$plugin}} );
	}

	return;
}

sub get_plugin {
	my ( $self, $name ) = @_;
	my ( $plugin ) = grep { $_->name eq $name } @{$self->plugins};
	return( $plugin );
}

1;

