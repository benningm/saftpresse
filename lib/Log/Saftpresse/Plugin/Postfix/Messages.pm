package Log::Saftpresse::Plugin::Postfix::Messages;

use Moose::Role;

# ABSTRACT: plugin to gather postfix warning|fatal|panic messages
# VERSION

use Log::Saftpresse::Utils qw( string_trimmer );

requires 'message_detail';
requires 'smtpd_warn_detail';

sub process_messages {
	my ( $self, $stash ) = @_;
	my $service = $stash->{'service'};
	my $message_detail = $self->message_detail;
	my $smtpd_warn_detail = $self->smtpd_warn_detail;

	if( $service eq 'master' ) { # gather all master messages
		$self->incr_host_one( $stash, 'master', $stash->{'message'});
		return;
	}

	if( my ($level, $msg) = $stash->{'message'} =~ /^(warning|fatal|panic): (.*)$/ )  {
		$msg = string_trimmer($msg, 66, $message_detail);
		if( $level eq 'warning' && $service eq 'smtpd' &&
	       			$smtpd_warn_detail == 0 ) {
			return;
		}
		$self->incr_host_one( $stash, $level, $service, $msg);
		$stash->{'postfix_level'} = $level;
	} 

	return;
}

1;

