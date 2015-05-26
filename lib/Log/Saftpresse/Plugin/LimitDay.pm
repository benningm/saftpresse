package Log::Saftpresse::Plugin::LimitDay;

use Moose;

# ABSTRACT: plugin to skip messages not from today or yesterday
# VERSION

extends 'Log::Saftpresse::Plugin';

use Time::Piece;
use Time::Seconds;

has 'day' => ( is => 'rw', isa => 'Maybe[Str]' );

has 'now' => ( is => 'rw', isa => 'Time::Piece', lazy => 1,
	default => sub { Time::Piece->new },
);

has 'yesterday' => ( is => 'rw', isa => 'Time::Piece', lazy => 1,
	default => sub {
		return Time::Piece->new - ONE_DAY;
	},
);

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

