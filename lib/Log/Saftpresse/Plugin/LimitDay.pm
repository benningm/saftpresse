package Log::Saftpresse::Plugin::LimitDay;

use strict;
use warnings;

# ABSTRACT: plugin to skip messages not from today or yesterday
# VERSION

use base 'Log::Saftpresse::Plugin';

use Time::Piece;
use Time::Seconds;

sub day {
	my $self = shift;
	return( $self->{'day'} );
}

sub now {
	my $self = shift;
	if( ! defined $self->{'_now'} ) {
		$self->{'_now'} = Time::Piece->new;
	}
	return( $self->{'_now'} );
}

sub yesterday {
	my $self = shift;
	if( ! defined $self->{'_yesterday'} ) {
		$self->{'_yesterday'} = ( Time::Piece->new - ONE_DAY );
	}
	return( $self->{'_yesterday'} );
}

sub is_yesterday {
	my ( $self, $time ) = @_;
	if( $self->yesterday->ymd eq $time->ymd ) {
		return( 1 );
	}
	return( 0 );
}

sub is_today {
	my ( $self, $time ) = @_;
	if( $self->now->ymd eq $time->ymd ) {
		return( 1 );
	}
	return( 0 );
}

sub process {
	my ( $self, $stash ) = @_;
	my $day = $self->day;
	my $time = $stash->{'time'};
	if( ! defined $time ) {
		return;
	}

	if( $day eq 'today' && ! $self->is_today($time) ) {
		return('next');
	} elsif( $day eq 'yesterday' && ! $self->is_yesterday($time) ) {
		return('next');
	}
	
	return;
}

1;

