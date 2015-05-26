package Log::Saftpresse::Output::JSON;

use strict;
use warnings;

# ABSTRACT: plugin to dump events to in JSON to stdout
# VERSION

use base 'Log::Saftpresse::Output';

sub json {
	my $self = shift;
	if( ! defined $self->{_json} ) {
		$self->{_json} = JSON->new;
		$self->{_json}->utf8(1);
		$self->{_json}->pretty(1);
		$self->{_json}->allow_blessed(1);
	}
	return $self->{_json};
}

sub output {
	my ( $self, @events ) = @_;

	foreach my $event (@events) { 
		my %output = %$event;
		if( defined $output{'time'} &&
				ref($output{'time'}) eq 'Time::Piece' ) {
			$output{'@timestamp'} = $output{'time'}->datetime;
			delete $output{'time'};
		}
		$self->dump_json_data( \%output );
	}

	return;
}

sub _backend {
	my $self = shift;
	if( defined $self->{'_backend'} ) {
		return $self->{'_backend'} ;
	}
	foreach my $module ( 'JSON::Color', 'JSON') {
		my $require = "require $module;";
		eval $require;
		if( ! $@ ) {
			return $module;
		}
	}
	die('could not find supported JSON output module. Install JSON::Color or JSON.');
}

sub dump_json_data {
	my ( $self, $data ) = @_;

	my $backend = $self->_backend;

	if( $backend eq 'JSON::Color' ) {
		print JSON::Color::encode_json( $data, { pretty => 1 } )."\n";
	} elsif( $backend eq 'JSON' ) {
		print $self->json->encode( $data );
	} else {
		die("unknown JSON backend module or not defined?!");
	}
	return;
}

1;

