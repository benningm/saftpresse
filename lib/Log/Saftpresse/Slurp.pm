package Log::Saftpresse::Slurp;

use strict;
use warnings;

# ABSTRACT: class to read log file inputs
# VERSION

use IO::Select;
use Time::HiRes qw( sleep gettimeofday tv_interval );

sub new {
	my $class = shift;
	my $self = {
		prefix => 'Log::Saftpresse::Input::',
		plugins => [],
		select => IO::Select->new,
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
	$self->{'select'}->add( $plugin->io_handles );
	return;
}

sub can_read {
	my ( $self, $timeout ) = @_;

	# do we known when we did run last time?
	my $sleep;
	if( defined $self->{'_last_run'} ) {
		my $next = [ @{$self->{'_last_run'}} ]; $next->[0] += $timeout;
		$sleep = tv_interval( [gettimeofday], $next );
	} else {
		# just sleep for timeout
		$sleep = $timeout;
	}

	# use select() when possible
	if( $self->{'select'}->count ) {
		$self->{'select'}->can_read( $sleep );
	} else {
		sleep( $sleep );
	}

	$self->{'_last_run'} = [gettimeofday];
	return( 1 ); # always signal read
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

sub read_events {
	my $self = shift;
	my @events;
	my $eof = 1;

	foreach my $plugin ( @{$self->{'plugins'}} ) {
		if( $plugin->eof ) {
			next;
		}
		$eof = 0;
		if( $plugin->can_read ) {
			push( @events, $plugin->read_events );
		}
	}

	if( $eof ) {
		die('all inputs at EOF');
	}
	if( scalar @events ) { return \@events; }
	return;
}

1;

