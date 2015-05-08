package Log::Saftpresse;

use strict;
use warnings;

# ABSTRACT: a modular logfile analyzer
# VERSION

use Log::Saftpresse::Log4perl;
use Log::Saftpresse::Config;

use Log::Saftpresse::Analyzer;
use Log::Saftpresse::Slurp;
use Log::Saftpresse::CounterOutputs;
use Log::Saftpresse::Outputs;

sub new {
	my $class = shift;
	my $self = {
		'_config' => Log::Saftpresse::Config->new,
		'_slurp' => Log::Saftpresse::Slurp->new,
		'_analyzer' => Log::Saftpresse::Analyzer->new,
		'_counter_outputs' => Log::Saftpresse::CounterOutputs->new,
		'_outputs' => Log::Saftpresse::Outputs->new,
		'_flush_interval' => undef,
		'_last_flush_counters' => time,
		@_,
	};
	bless( $self, $class );
	return( $self );
}

sub load_config {
	my $self = shift;

	$self->{'_config'}->load_config(@_);

	$self->{'_flush_interval'}
		= $self->{'_config'}->get('counters', 'flush_interval');

	return;
}

sub init {
	my $self = shift;
	my $config = $self->{_config};
	
	Log::Saftpresse::Log4perl->init(
		$config->get('logging', 'level'),
		$config->get('logging', 'file'),
	);

	$self->{_slurp}->load_config( $config->get_node('Input') );
	$self->{_analyzer}->load_config( $config->get_node('Plugin') );
	$self->{_counter_outputs}->load_config( $config->get_node('CounterOutput') );
	$self->{_outputs}->load_config( $config->get_node('Output') );

	return;
}

sub _need_flush_counters {
	my $self = shift;

	if( ! defined $self->{'_flush_interval'}
			|| $self->{'_flush_interval'} < 1 ) {
		return 0;
	}

	my $next_flush = $self->{'_last_flush_counters'}
		+ $self->{'_flush_interval'};
	if( time < $next_flush ) {
		return 0;
	}

	return 1;
}

sub _flushed_counters {
	my $self = shift;
	$self->{'_last_flush_counters'} = time;
	return;
}

sub run {
	my $self = shift;
	my $slurp = $self->{_slurp};
	my $last_flush = time;

	$log->debug('entering main loop');
	for(;;) { # main loop
		my $events;
		if( $slurp->can_read(1) ) {
			$events = $slurp->read_events;
			foreach my $event ( @$events ) {
				$self->{_analyzer}->process_event( $event );
			}
		}
		if( scalar @$events ) {
			$self->{_outputs}->output( @$events );
		}

		if( $self->_need_flush_counters ){
			$self->{'_counter_outputs'}->output(
				$self->{_analyzer}->get_all_counters );
			$self->_flushed_counters;
		}
	}

	return;
}

1;

