package Log::Saftpresse::Input::Journald;

use Moose;

# ABSTRACT: log input for systemd-journald
# VERSION

=head1 Description

This input will read events from the systemd journal.

=head1 Synopsis

  <Input systemd>
    module = "Journald"
  </Input>

=head1 Parameters

=over

=item lowercase (default: 1)

Systemd fields will be transformed to lowercase.

=item remove_address_fields (default: 1)

Remove systemd journal address informations.

=item merge_trusted_fields (default: 1)

Will remove the "_" prefix of systemd trusted fields.

=back

=cut

use JSON;

extends 'Log::Saftpresse::Input::Command';

has 'command' => ( is => 'ro', isa => 'Str', default => 'journalctl -f -o json');

has 'lowercase' => ( is => 'ro', isa => 'Bool', default => 1 );
has 'remove_address_fields'  => ( is => 'ro', isa => 'Bool', default => 1 );
has 'merge_trusted_fields'  => ( is => 'ro', isa => 'Bool', default => 1 );

sub process_line {
  my ( $self, $line ) = @_;
  my $data = from_json( $line );
  if( $self->lowercase ) {
    my %new = map { lc $_ => $data->{$_} } keys %$data;
    $data = \%new;
  }
  foreach my $key ( keys %$data ) {
    if( $self->remove_address_fields && $key =~ /^__/ ) {
      delete( $data->{$key} );
    }
    if( $self->merge_trusted_fields && $key =~ /^_[^_]/ ) {
      my $newkey = $key;
      $newkey =~ s/^_//;
      $data->{$newkey} = $data->{$key};
      delete( $data->{$key} );
    }
  }
  return %$data;
}

1;

