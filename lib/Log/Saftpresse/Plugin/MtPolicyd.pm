package Log::Saftpresse::Plugin::MtPolicyd;

use Moose;

use Log::Saftpresse::Log4perl;

# ABSTRACT: plugin to parse mtpolicyd logs
# VERSION

=head1 Description

This plugin parses mtpolicyd log files

=head1 Synopsis

  <Plugin mtpolicyd>
    module = "MtPolicyd"
  </Plugin>

=head1 Input

This plugin expects a log line with

  'program' => 'mtpolicyd'

and an message like

  'message' => 'reputation: instance=25d8.55f1aea2.3adb.0, type=smtpd_access_policy, t=2ms, result=dunno'

or with mtpolicyd > 0.20:

  'message' => 'reputation: instance=25d8.55f1aea2.3adb.0, type=smtpd_access_policy, t=2ms, plugin=whitelist, result=dunno'

=head1 Output

It will output the following fields:

  vhost
  instance
  elapsed
  action
  reason
  plugin (mtpolicyd version >= 0.20)

=head1 Counters

The plugin will create the following counters:

  <host>.total
  <host>.time
  <host>.vhost.<vhost>.count
  <host>.vhost.<vhost>.time
  <host>.vhost.<vhost>.<action>
  <host>.plugin.<plugin>.count
  <host>.plugin.<plugin>.time
  <host>.plugin.<plugin>.<action>

=cut

extends 'Log::Saftpresse::Plugin';

with 'Log::Saftpresse::Plugin::Role::CounterUtils';

sub process {
	my ( $self, $stash ) = @_;
	my $program = $stash->{'program'};
	if( ! defined $program || $program ne 'mtpolicyd' ) {
		return;
	}
  my ( $vhost, $instance, $time, $plugin, $result );

	if ( my ( @fields ) = $stash->{'message'} =~ /^([^:]+): instance=([^,]+), type=[^,]+, t=(\d+)ms,(?: plugin=([^,]+),)? result=(.*)$/ ) {
    ( $vhost, $instance, $time, $plugin, $result ) = @fields;
    @$stash{'vhost', 'instance', 'elapsed' } = @fields;
    if( $fields[3] ) {
      $stash->{'plugin'} = $fields[3];
    }
	} else {
    $log->debug('unhandled output format of mtpolicyd');
    return;
  }
  my ( $action, $reason );
  if( $result ne '' ) {
    ( $action, $reason ) = split(/\s+/, $result, 2);
    $stash->{'action'} = $action;
    if( defined $reason && $reason ne '' ) {
      $stash->{'reason'} = $reason;
    }
  }

	$self->incr_host_one($stash, 'total' );
	$self->incr_host($stash, 'time', $time );

  $self->incr_host_one($stash, 'vhost', $vhost, 'count' );
  $self->incr_host($stash, 'vhost', $vhost, 'time', $time );
  if( defined $action ) {
    $self->incr_host_one($stash, 'vhost', $vhost, lc($action) );
  }

  if( defined $plugin ) {
    $self->incr_host_one($stash, 'plugin', $plugin, 'count' );
    $self->incr_host($stash, 'plugin', $plugin, 'time', $time );
    if( defined $action ) {
      $self->incr_host_one($stash, 'plugin', $plugin, lc($action) );
    }
  }

	return;
}

1;

