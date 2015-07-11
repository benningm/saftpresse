package Log::Saftpresse::Plugin;

use Moose;

# ABSTRACT: base class for saftpresse plugins
# VERSION

use Log::Saftpresse::Counters;

=head1 Description

This is the base class for saftpresse processing plugins.

All plugin classes must inherit from this class.

=head1 Synopsis

  package Log::Saftpresse::Plugin::MyPlugin;
  
  use Moose;
  
  extends 'Log::Saftpresse::Plugin';

  sub process {
    my ( $self, $event ) = @_;

    $event->{'example_text'} = 'this is an example';
    $self->incr_one('examples', 'count');

    return;
  }
  
  1;

=head1 Attributes

=head2 name( $str )

The name of plugin instance.

=head2 counters( L<Log::Saftpresse::Counters> )

Holds the counters of this plugin.

=cut

has 'name' => ( is => 'ro', isa => 'Str', required => 1 );

has 'counters' => (
	is => 'ro', isa => 'Log::Saftpresse::Counters', lazy => 1,
	default => sub {
		 Log::Saftpresse::Counters->new;
	},
	handles => [ 'incr', 'incr_one', 'incr_max' ],
);

=head1 Methods

=head2 process( $event, $notes )

This method must be implemented by every plugin.

Saftpresse will call it for every processed event and
pass $event and $notes.

=head2 init

This method is called after an instance of the plugin has been created.

A module could implement it to do initialization tasks.

=head2 incr, incr_one, incr_max

This methods are delegated to the counter object.

=cut

sub process {
	my ( $self, $stash, $notes ) = @_;
	die('not implemented');
}

sub init { return; }

1;

