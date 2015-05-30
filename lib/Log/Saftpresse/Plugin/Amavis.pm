package Log::Saftpresse::Plugin::Amavis;

use Moose;

# ABSTRACT: plugin to parse amavisd-new logs
# VERSION

extends 'Log::Saftpresse::Plugin';

use JSON;

has 'json' => (
	is => 'ro', isa => 'JSON', lazy => 1,
	default => sub { JSON->new; },
);

sub process {
	my ( $self, $stash ) = @_;
	my $program = $stash->{'program'};
	if( ! defined $program || $program ne 'amavis' ) {
		return;
	}

	if ( my ( $log_id, $msg ) = $stash->{'message'} =~ /^\(([^\)]+)\) (.+)$/ ) {
		$stash->{'log_id'} = $log_id;
		$stash->{'message'} = $msg;
	}

	# if JSON logging is configured decode JSON
	if( $stash->{'message'} =~ /^{/ ) {
		my $json_data;
		eval {
			$json_data = $self->json->decode( $stash->{'message'} );
		};
		if( $@ ) { return; }
		if( ref($json_data) ne 'HASH' ) {
			return;
		}
		@$stash{keys %$json_data} = values %$json_data;
	}

	return;
}

1;

