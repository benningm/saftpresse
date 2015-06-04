package Log::Saftpresse::Plugin::Apache;

use Moose;

# ABSTRACT: plugin to parse apache logs
# VERSION

extends 'Log::Saftpresse::Plugin';

with 'Log::Saftpresse::Plugin::Role::CounterUtils';

has 'format' => ( is => 'rw', isa => 'Str', default => 'vhost_combined');

sub process {
	my ( $self, $stash ) = @_;
	my $program = $stash->{'program'};
	if( ! defined $program || $program ne 'apache' ) {
		return;
	}

	if( $self->format eq 'vhost_combined' ) {
		$self->parse_vhost_combined( $stash );
	} elsif( $self->format eq 'combined' ) {
		$self->parse_combined( $stash );
	} else {
		return;
	}

	$self->incr_host_one($stash, 'total' );
	$self->count_fields_occur( $stash, 'vhost', 'code' );
	$self->count_fields_value( $stash, 'size' );

	return;
}

sub parse_vhost_combined {
	my ( $self, $stash, $msg ) = @_;
	if( ! defined $msg ) {
		$msg = $stash->{'message'};
	}
	my ( $vhost, $port, $combined ) = 
		$msg =~ /^([^:]+):(\d+) (.*)$/;
	if( ! defined $vhost ) {
		return;
	}
	$stash->{'vhost'} = $vhost;
	$stash->{'port'} = $port;

	$self->parse_combined( $stash, $combined );

	return;
}

sub parse_combined {
	my ( $self, $stash, $msg ) = @_;
	if( ! defined $msg ) {
		$msg = $stash->{'message'};
	}

	my ( $ip, $ident, $user, $ts, $request, $code, $size, $referer, $agent ) = 
		$msg =~ /^(\S+) (\S+) (\S+) \[([^\]]+)\] "([^"]+)" (\d+) (\d+) "([^"]+)" "([^"]+)"$/;
	if( ! defined $ip ) {
		return;
	}
	my $time;
	eval { $time = Time::Piece->strptime($ts, "%d/%b/%Y:%H:%M:%S %z"); };
	my ( $method, $uri, $proto ) = split(' ', $request );

	@$stash{'client_ip', 'ident', 'user', 'time', 'method', 'uri', 'proto', 'code', 'size', 'referer', 'agent'}
		= ( $ip, $ident, $user, $time, $method, $uri, $proto, $code, $size, $referer, $agent);

	return;
}

1;

