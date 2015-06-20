package Log::Saftpresse::Plugin::GraphitLineFormat;

use Moose;

# ABSTRACT: read metric values from logs and export them as counters
# VERSION

extends 'Log::Saftpresse::Plugin';

with 'Log::Saftpresse::Plugin::Role::CounterUtils';

=head1 Description

This plugin parses the graphit line format.

=head1 Synopsis

  <Plugin graphit>
    module = "GraphitLineFormat"
  </Plugin>

=head1 Input Format

The plugin expects a events with

  'program' => 'metric'

and a 'message' field in graphit plaintext format:

  'message' => '<metric path> <metric value> <metric timestamp>'

=head1 Output

This plugin will add the following fields:

=over

=item type

The value: 'metric'.

=item path

The metric path.

=item value

The metric value.

=item timestamp

The metric timestamp.

=back

=cut

sub process {
	my ( $self, $event ) = @_;
	my $program = $event->{'program'};
	if( ! defined $program || $program ne 'metric' ) {
		return;
	}

	my ( $path, $value, $ts ) = split(/\s+/, $event->{'message'});

	if( ! defined $path || $path !~ /^[a-zA-Z0-9\-_\.]+$/ ) {
		return;
	}
	if( ! defined $value || $value !~ /^[+\-]?[0-9,\.]+$/ ) {
		return;
	}
	if( ! defined $ts || $ts !~ /^\d+$/ ) {
		return;
	}

	@$event{'type', 'path', 'value', 'timestamp'} =
		( 'metric', $path, $value, $ts );

	return;
}

1;

