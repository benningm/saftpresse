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

=head1 Description

This is the central class of the saftpresse log analyzer.

=head1 Synopsis

  use Log::Saftpresse;

  my $saft = Log:::Saftpresse->new;

  $saft->load_config( $path );
  $saft->init;

  # start main loop
  $saft->run;

=head1 Attributes

=head2 config( L<Log::Saftpresse::Config>)

Holds the configuration.

=head2 slurp( L<Log::Saftpresse::Slurp> )

Holds the slurp class implementing the input.

=head2 analyzer( L<Log::Saftpresse::Analyzer> )

Holds the analyzer object which controls the processing plugins.

=head2 counter_outputs( L<Log::Saftpresse::CounterOutputs> )

Holds the counter output object which controls output of metrics.

=head2 outputs( L<Log::Saftpresse::Outputs> )

Holds the Outputs plugin which controls the event output.

=head2 flush_interval( $seconds )

How often to flush metrics to CounterOutputs.

=cut

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

has 'flush_interval' => ( is => 'rw', isa => 'Maybe[Int]' );

has '_last_flush_counters' => (
	is => 'rw', isa => 'Int',
	default => sub { time },
);

=head1 Methods

=head2 init

Initialize saftpresse as configured in config file.

Will load slurp, analyzer, counter_outputs, outputs and flush_interval
from configuration.

=cut

sub init {
	my $self = shift;
	my $config = $self->config;
	
	Log::Saftpresse::Log4perl->init(
		$config->get('logging', 'level'),
		$config->get('logging', 'file'),
	);
	$self->flush_interval( $config->get('counters', 'flush_interval') );
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

=head2 run

Run the main loop of saftpresse.

=cut

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

=head1 See also

=over

=item L<Log::Saftpresse::App> 

Commandline glue for this class.

=item bin/saftpresse

Commandline interface of saftpresse with end-user docs.

=back

=cut

1;

