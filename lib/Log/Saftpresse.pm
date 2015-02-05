package Log::Saftpresse;

use strict;
use warnings;

use Log::Saftpresse::Analyzer;
use Log::Saftpresse::Slurp;
use Log::Saftpresse::Log4perl;
use Log::Saftpresse::Config;

sub new {
	my $class = shift;
	my $self = {
		'_config' => Log::Saftpresse::Config->new,
		'_slurp' => Log::Saftpresse::Slurp->new,
		'_analyzer' => Log::Saftpresse::Analyzer->new,
		# TODO: outputs
		#'_counteroutputs' => Log::Saftpresse::Outputs->new,
		#'_outputs' => Log::Saftpresse::Outputs->new,
		@_,
	};
	bless( $self, $class );
	return( $self );
}

sub load_config {
	my $self = shift;
	$self->{'_config'}->load_config(@_);
	return;
}

sub init {
	my $self = shift;
	my $config = $self->{_config};
	
	Log::Saftpresse::Log4perl->init(
		$config->get('logging', 'level'),
		$config->get('logging', 'file'),
	);

	$self->{_slurp}->load_config( $config->get_node('Inputs') );
	$self->{_analyzer}->load_config( $config->get_node('Plugins') );
	# TODO: outputs

	return;
}

sub run {
	my $self = shift;
	my $slurp = $self->{_slurp};

	$log->debug('entering main loop');
	for(;;) { # main loop
		if( $slurp->can_read(1) ) {
			my $events = $slurp->read_events;
			foreach my $event ( @$events ) {
				$self->{_analyzer}->process_event( $event );

				# TODO: output
				use Data::Dumper;
				print Dumper( $event );
			}
		}
		# TODO: flush counters?
	}

	return;
}

1;

