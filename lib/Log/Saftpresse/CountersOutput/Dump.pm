package Log::Saftpresse::CountersOutput::Dump;

use strict;
use warnings;

# ABSTRACT: plugin to dump counters to stdout
# VERSION

use base 'Log::Saftpresse::CountersOutput';

use JSON;
use Data::Dumper;
use Sys::Hostname;

sub output {
	my ( $self, $counters ) = @_;
	my %data = map {
		$_ => $counters->{$_}->counters,
	} keys %$counters;

	if( ! defined $self->{'format'}
       			|| lc $self->{'format'} eq 'graphit' ) {
		$self->_output_graphit( \%data );
	} elsif ( lc $self->{'format'} eq 'json' ) {
		$self->_output_json( \%data );
	} elsif ( lc $self->{'format'} eq 'perl' ) {
		$self->_output_perl( \%data );
	}

	return;
}

sub graphit_prefix {
	my $self = shift;
	if( ! defined $self->{'graphit_prefix'} ) {
		$self->{'graphit_prefix'} = 'server.'.hostname;
	}
	return $self->{'graphit_prefix'};
}

sub _output_graphit { 
	my ( $self, $data ) = @_;
	our $now = time;
	
	sub _proc_hash {
		my ( $path, $hash ) = @_;
		foreach my $key ( keys %$hash ) {
			my $value = $hash->{$key};
			my $type = ref $value;
			my $graphit_key = $key;
			$graphit_key =~ s/\./_/g;
			my $this_path = $path.'.'.$graphit_key;
			if( ! defined $value ) {
				# noop
			} elsif( $type eq 'HASH' ) {
				_proc_hash($this_path, $value);
			} elsif( $type eq '' ) {
				print $this_path.' '.$value.' '.$now."\n";
			} else {
				die('unhandled data structure!');
			}
		}
		return;
	}
	_proc_hash($self->graphit_prefix, $data);

	return;
}

sub _output_perl { 
	my ( $self, $data ) = @_;
	print Dumper( $data );	
	return;
}
sub _output_json { 
	my ( $self, $data ) = @_;
	my $json = JSON->new;
	$json->pretty(1);
	print $json->encode( $data );	
	return;
}

1;

