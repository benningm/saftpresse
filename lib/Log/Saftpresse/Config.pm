package Log::Saftpresse::Config;

use strict;
use warnings;

# ABSTRACT: configuration option parser for Log::Saftpresse
# VERSION

use Tie::IxHash;
use Config::General qw(ParseConfig);

sub ordered_hash_ref {
	tie my %hash, 'Tie::IxHash', @_;
	return \%hash;
}

tie our %defaults, "Tie::IxHash";
%defaults = (
	'counters' => {
		'flush_interval' => '300',
	},
	'logging' => {
		level => 'INFO',
		file => undef, # log to syslog
	},
	Input => ordered_hash_ref(
		Stdin => {},
	),
	Plugin => ordered_hash_ref(
		SyslogTimestamp => {},
		SyslogProgram => {},
	),
	CounterOutput => ordered_hash_ref (
		Dump => {},
	),
	Output => ordered_hash_ref (
		JSON => {},
	),
);

sub new {
	my $class = shift;
	my $self = {
		_config => undef,
		_defaults => \%defaults,
		@_,
	};
	bless( $self, $class );
	return($self);
}

sub load_config {
	my ( $self, $file ) = @_;
	if( ! -f $file ) {
		die('configuration file '.$file.' does not exist!');
	}

	tie my %config_hash, "Tie::IxHash";
	%config_hash = ParseConfig(
		-AllowMultiOptions => 'no',
		-ConfigFile => $file,
		-Tie => "Tie::IxHash"
	);
	$self->{_config} = \%config_hash;

	return;
}

sub defaults {
	my $self = shift;
	return( $self->{'_defaults'});
}

sub config {
	my $self = shift;
	return( $self->{_config} );
}	

sub _get_hash_node {
	my $hash = shift;
	my @path = @_;
	my $cur = $hash;

	if( ! defined $hash ) { return; }

	while( my $element = shift @path ) {
		if( defined $cur->{$element}
	       			&& ref $cur->{$element} eq 'HASH' ) {
			$cur = $cur->{$element};
		} else { return; }
	}

	return $cur;
}

sub _get_hash_value {
	my $hash = shift;
	my $key = pop;
	my @path = @_;

	my $cur = _get_hash_node( $hash, @path );

	if( defined $cur
			&& defined $cur->{$key}
			&& ! ref($cur->{$key}) ) {
		return $cur->{$key};
	}
	return;
}

sub get_node {
	my $self = shift;
	my $node;
	if( $node = _get_hash_node( $self->{_config}, @_ ) ) {
		return $node;
	}
	if( $node = _get_hash_node( $self->{_defaults}, @_ ) ) {
		return $node;
	}
	return;
}

sub get {
	my $self = shift;
	my $value;

	if( $value = _get_hash_value( $self->{_config}, @_ ) ) {
		return $value;
	}
	if( $value = _get_hash_value( $self->{_defaults}, @_ ) ) {
		return $value;
	}
	return;
}

1;

