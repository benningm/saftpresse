package Log::Saftpresse::Outputs;

use strict;
use warnings;

# ABSTRACT: class to manage saftpresse outputs
# VERSION

sub new {
	my $class = shift;
	my $self = {
		prefix => 'Log::Saftpresse::Output::',
		plugins => [],
	};
	bless( $self, $class );
	return $self;
}

sub prefix {
	my $self = shift;
	return $self->{'prefix'};
}

sub add_plugin {
	my ( $self, $plugin ) = @_;
	push( @{$self->{'plugins'}}, $plugin );
	return;
}

sub load_plugin {
	my ( $self, $name, %params )= @_;
	my $plugin_class = $self->prefix.$name;
	my $plugin;

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

	$self->{'plugins'} = [];

	foreach my $plugin ( keys %$config ) {
		$self->load_plugin( $plugin, %{$config->{$plugin}} );
	}

	return;
}

sub output_events {
	my ( $self, @events ) = @_;

	foreach my $plugin ( @{$self->{'plugins'}} ) {
		$plugin->output( @events );
	}

	return;
}

1;

