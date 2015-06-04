package Log::Saftpresse::Plugin::Amavis;

use Moose;

# ABSTRACT: plugin to parse amavisd-new logs
# VERSION

extends 'Log::Saftpresse::Plugin';

with 'Log::Saftpresse::Plugin::Role::CounterUtils';

use JSON;

has 'json' => (
	is => 'ro', isa => 'JSON', lazy => 1,
	default => sub { JSON->new; },
);

has 'test_stats' => ( is => 'ro', isa => 'Bool', default => 1 );

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

	if( ! defined $stash->{'action'} ) {
		return;
	}

	$self->incr_host_one($stash, 'total' );
	$self->count_fields_occur( $stash, 'content_type' );
	$self->count_array_field_values( $stash, 'action' );
	$self->count_fields_value( $stash, 'size', 'score' );

	if( $self->test_stats ) {
		$self->count_array_field_values( $stash, 'tests' );
	}

	return;
}

1;

