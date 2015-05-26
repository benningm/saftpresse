package Log::Saftpresse::CounterOutputs;

use strict;
use warnings;

# ABSTRACT: class to manage saftpresse counter output
# VERSION

sub new {
	my $class = shift;
	my $self = {
		prefix => 'Log::Saftpresse::CountersOutput::',
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
	if( ! defined $params{'module'} ) {
		die("Parameter module is not defined for CounterOutput $name!");
	}
	my $plugin_class = $self->prefix.$params{'module'};
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

sub output {
	my ( $self, @events ) = @_;

	foreach my $plugin ( @{$self->{'plugins'}} ) {
		$plugin->output( @events );
	}

	return;
}

1;

