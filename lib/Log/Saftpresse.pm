package Log::Saftpresse;

use Moose;

# ABSTRACT: a modular logfile analyzer
# VERSION

use Log::Saftpresse::Log4perl;
use Log::Saftpresse::Config;

use Log::Saftpresse::Analyzer;
use Log::Saftpresse::Slurp;
use Log::Saftpresse::CounterOutputs;
use Log::Saftpresse::Outputs;

has 'config' => (
	is => 'ro', isa => 'Log::Saftpresse::Config', lazy => 1,
	default => sub { Log::Saftpresse::Config->new },
	handles => [ 'load_config' ],
);

has 'slurp' => (
	is => 'ro', isa => 'Log::Saftpresse::Slurp', lazy => 1,
	default => sub { Log::Saftpresse::Slurp->new },
);

has 'analyzer' => (
	is => 'ro', isa => 'Log::Saftpresse::Analyzer', lazy => 1,
	default => sub { Log::Saftpresse::Analyzer->new },
);

has 'counter_outputs' => (
	is => 'ro', isa => 'Log::Saftpresse::CounterOutputs', lazy => 1,
	default => sub { Log::Saftpresse::CounterOutputs->new },
);

has 'outputs' => (
	is => 'ro', isa => 'Log::Saftpresse::Outputs', lazy => 1,
	default => sub { Log::Saftpresse::Outputs->new },
);

has 'flush_interval' => (
	is => 'rw', isa => 'Maybe[Int]',
	default => sub {
		my $self = shift;
		return $self->config->get('counters', 'flush_interval');
	},
);

has '_last_flush_counters' => (
	is => 'rw', isa => 'Int',
	default => sub { time },
);


sub init {
	my $self = shift;
	my $config = $self->config;
	
	Log::Saftpresse::Log4perl->init(
		$config->get('logging', 'level'),
		$config->get('logging', 'file'),
	);

	$self->slurp->load_config( $config->get_node('Input') );
	$self->analyzer->load_config( $config->get_node('Plugin') );
	$self->counter_outputs->load_config( $config->get_node('CounterOutput') );
	$self->outputs->load_config( $config->get_node('Output') );

	return;
}

sub _need_flush_counters {
	my $self = shift;

	if( ! defined $self->flush_interval
			|| $self->flush_interval < 1 ) {
		return 0;
	}

	my $next_flush = $self->_last_flush_counters + $self->flush_interval;
	if( time < $next_flush ) {
		return 0;
	}

	return 1;
}

sub _flushed_counters {
	my $self = shift;
	$self->_last_flush_counters( time );
	return;
}

sub run {
	my $self = shift;
	my $slurp = $self->slurp;
	my $last_flush = time;

	$log->debug('entering main loop');
	for(;;) { # main loop
		my $events;
		if( $slurp->can_read(1) ) {
			$events = $slurp->read_events;
			foreach my $event ( @$events ) {
				$self->analyzer->process_event( $event );
			}
		}
		if( scalar @$events ) {
			$self->outputs->output( @$events );
		}

		if( $self->_need_flush_counters ){
			$self->counter_outputs->output(
				$self->analyzer->get_all_counters );
			$self->_flushed_counters;
		}
	}

	return;
}

1;

