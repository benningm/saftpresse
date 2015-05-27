package Log::Saftpresse::Slurp;

use Moose;

# ABSTRACT: class to read log file inputs
# VERSION

extends 'Log::Saftpresse::PluginContainer';

use IO::Select;
use Time::HiRes qw( sleep gettimeofday tv_interval );

has 'plugin_prefix' => ( is => 'ro', isa => 'Str',
	default => 'Log::Saftpresse::Input::',
);

has 'io_select' => (
	is => 'ro', isa => 'IO::Select', lazy => 1,
	default => sub { IO::Select->new; },
);

after 'add_plugin' => sub {
	my ( $self, @plugins ) = @_;
	foreach my $plugin ( @plugins ) {
		$self->io_select->add( $plugin->io_handles );
	}
	return;
};

has '_last_run' => ( is => 'rw', isa => 'Maybe[ArrayRef]' );

sub can_read {
	my ( $self, $timeout ) = @_;

	# do we known when we did run last time?
	my $sleep;
	if( defined $self->_last_run ) {
		my $next = [ @{$self->_last_run} ]; $next->[0] += $timeout;
		$sleep = tv_interval( [gettimeofday], $next );
	} else {
		# just sleep for timeout
		$sleep = $timeout;
	}

	# use select() when possible
	if( $self->io_select->count ) {
		$self->io_select->can_read( $sleep );
	} elsif( $sleep > 0 ) { # may be negative if clock is drifting
		sleep( $sleep );
	}

	$self->_last_run( [gettimeofday] );
	return( 1 ); # always signal read
}

sub read_events {
	my $self = shift;
	my @events;
	my $eof = 1;

	foreach my $plugin ( @{$self->plugins} ) {
		if( $plugin->can_read ) {
			if( $plugin->eof ) { next; }
			push( @events, $plugin->read_events );
		}
		$eof = 0;
	}

	if( $eof ) {
		die('all inputs at EOF');
	}
	if( scalar @events ) { return \@events; }
	return;
}

1;

