package Log::Saftpresse::CountersOutput::Graphite;

use Moose;

# ABSTRACT: plugin to write counters to carbon line reciever
# VERSION

extends 'Log::Saftpresse::CountersOutput';

use Net::Domain qw( hostfqdn );
use IO::Socket::INET;

sub output {
	my ( $self, $counters ) = @_;
	my %data = map {
		$_ => $counters->{$_}->counters,
	} keys %$counters;

	$self->_output_graphit( \%data );

	return;
}

has 'graphit_prefix' => ( is => 'rw', isa => 'Str', lazy => 1,
	default => sub {
		$prefix = hostfqdn;
		$prefix =~ s/\./_/g;
		return $prefix;
	},
);

has '_handle' => (
	is => 'rw', isa => 'IO::Socket::INET', lazy => 1,
	default => sub {
		my $self = shift;
		my $handle = IO::Socket::INET->new(
			PeerAddr => $self->{'host'} || '127.0.0.1',
			PeerPort => $self->{'port'} || '2003',
			Proto => 'tcp',
		) or die('error opening connection to graphite line reciever: '.$@);
		return $handle;
	},
);

sub _proc_hash {
	my ( $self, $path, $now, $hash ) = @_;
	foreach my $key ( keys %$hash ) {
		my $value = $hash->{$key};
		my $type = ref $value;
		my $graphit_key = $key;
		$graphit_key =~ s/\./_/g;
		my $this_path = $path.'.'.$graphit_key;
		if( ! defined $value ) {
			# noop
		} elsif( $type eq 'HASH' ) {
			$self->_proc_hash($this_path, $now, $value);
		} elsif( $type eq '' ) {
			$self->_handle->print($this_path.' '.$value.' '.$now."\n");
		} else {
			die('unhandled data structure!');
		}
	}
	return;
}

sub _output_graphit { 
	my ( $self, $data ) = @_;
	my $now = time;
	
	$self->_proc_hash($self->graphit_prefix, $now , $data);

	return;
}

1;

