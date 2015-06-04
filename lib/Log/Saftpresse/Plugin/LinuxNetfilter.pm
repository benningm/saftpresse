package Log::Saftpresse::Plugin::LinuxNetfilter;

use Moose;

# ABSTRACT: plugin to parse network packets logged by linux/netfilter
# VERSION

extends 'Log::Saftpresse::Plugin';

with 'Log::Saftpresse::Plugin::Role::CounterUtils';

sub process {
	my ( $self, $stash ) = @_;
	my $program = $stash->{'program'};
	if( ! defined $program || $program ne 'kernel' ) {
		return;
	}

	my ( $prefix, $msg ) =
		$stash->{'message'} =~ /^\[\d+\.\d+\] ([^:]+): (IN=\S* OUT=\S* .+) ?$/;

	if( ! defined $prefix ) {
		return;
	}

	my %values = map {
		my ( $key, $value ) = split('=', $_, 2);
		defined $value && $value ne '' ? ( lc($key) => $value ) : ();
	} split(' ', $msg);

	$stash->{'prefix'} = $prefix;
	@$stash{ keys %values } = values %values;

	$self->count_fields_value( $stash, 'prefix' );

	return;
}

1;

