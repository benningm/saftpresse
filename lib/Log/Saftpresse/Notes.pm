package Log::Saftpresse::Notes;

use strict;
use warnings;

# ABSTRACT: object to hold informations across log events
# VERSION

sub new {
	my $class = shift;
	my $self = {
		_data => {},
		_ring => [],
		max_entries => 10000,
	};
	return bless( $self, $class );
}

sub max_entries {
	my $self = shift;
	return( $self->{'max_entries'} );
}

sub reset {
	my $self = shift;
	$self->{'_data'} = {};
	$self->{'_ring'} = [];
	return;
}

sub size {
	my $self = shift;
	return( scalar @{$self->{'_ring'}} );
}

sub data {
	my $self = shift;
	return( $self->{'_data'} );
}

sub get {
	my ( $self, $key ) = @_;
	return( $self->{'_data'}->{$key} );
}

sub set {
	my ( $self, $key, $value ) = @_;

	if( defined $self->{'_data'}->{$key} ) {
		$self->remove( $key );
	}

	push( @{$self->{'_ring'}}, $key );
	$self->{'_data'}->{$key} = $value;

	$self->expire;

	return;
}

sub remove {
	my ( $self, $key ) = @_;

	if( ! defined $self->{'_data'}->{$key} ) {
		return;
	}
	delete $self->{'_data'}->{$key};

	# search the array for the key and remove it
	# iterating may be slow, but remove should be rare
	for( my $i = 0 ; $i < scalar(@{$self->{'_ring'}}) ; $i++ ) {
		if( $self->{'_ring'}->[$i] eq $key ) {
			splice(@{$self->{'_ring'}}, $i, 1);
			last;
		}
	}

	return;
}

sub is_full {
	my $self = shift;
	if( $self->size >= $self->{'max_entries'} ) {
		return 1;
	}
	return 0;
}

sub expire {
	my $self = shift;
	if( $self->size <= $self->{'max_entries'} ) {
		return;
	}
	my $num = $self->size - $self->{'max_entries'};
	foreach my $i ( 1..$num ) {
		my $key = shift @{$self->{'_ring'}};
		delete $self->{'_data'}->{$key};
	}
	return;
}

1;
