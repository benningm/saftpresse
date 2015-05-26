package Log::Saftpresse::Plugin::PostfixMessages;

use Moose;

# ABSTRACT: plugin to gather postfix warning|fatal|panic messages
# VERSION

extends 'Log::Saftpresse::Plugin';

use Log::Saftpresse::Utils qw( string_trimmer );

sub process {
	my ( $self, $stash ) = @_;
	my $service = $stash->{'service'};
	my $message_detail = $self->{'message_detail'};
	my $smtpd_warn_detail = $self->{'smtpd_warn_detail'};

	if( $service eq 'master' ) { # gather all master messages
		$self->cnt->incr_one('master', $stash->{'message'});
		return;
	}

	if( my ($level, $msg) = $stash->{'message'} =~ /^(warning|fatal|panic): (.*)$/ )  {
		$msg = string_trimmer($msg, 66, $message_detail);
		if( $level eq 'warning' && $service eq 'smtpd' &&
	       			$smtpd_warn_detail == 0 ) {
			return;
		}
		$self->cnt->incr_one($level, $service, $msg);
		$stash->{'postfix_level'} = $level;
	} 

	return;
}

1;

