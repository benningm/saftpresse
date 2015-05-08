package Log::Saftpresse::Analyzer;

use strict;
use warnings;

# ABSTRACT: class to analyze log messages
# VERSION

use Log::Saftpresse::Notes;
use Log::Saftpresse::Counters;

sub new {
	my $class = shift;
	my $self = {
		prefix => 'Log::Saftpresse::Plugin::',
		plugins => [],
		_notes => Log::Saftpresse::Notes->new,
		_stats => Log::Saftpresse::Counters->new,
	};
	bless( $self, $class );
	return $self;
}

sub prefix {
	my $self = shift;
	return( $self->{'prefix'} );
}

sub add_plugin {
	my ( $self, $plugin ) = @_;
	push( @{$self->{'plugins'}}, $plugin );
	return;
}

sub load_plugin {
	my ( $self, $name, %params )= @_;
	if( ! defined $params{'module'} ) {
		die("Parameter module is not defined for Input $name!");
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
	
	foreach my $plugin ( @{$self->{'plugins'}} ) {
		my $ret = $plugin->process(
			$stash, $self->{_notes} );
		if( defined $ret && $ret eq 'next') {
			last;
		}
	}
	$self->{_stats}->incr_one('events');

	return;
}

sub get_plugin {
	my ( $self, $name ) = @_;
	my ( $plugin ) = grep { $_->{'name'} eq $name } @{$self->{'plugins'}};
	return( $plugin );
}

sub get_counters {
	my ( $self, $name ) = @_;
	my $plugin = $self->get_plugin( $name );
	if( defined $plugin ) {
		return( $plugin->cnt );
	}
	return;
}

sub get_all_counters {
	my $self = shift;
	my %values;

	%values = map {
		$_->{'name'} => $_->cnt
	} @{$self->{'plugins'}};

	return \%values;
}

1;

