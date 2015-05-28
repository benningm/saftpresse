package Log::Saftpresse::Plugin::SyslogProgram;

use Moose;

# ABSTRACT: plugin to parse syslog program prefix
# VERSION

extends 'Log::Saftpresse::Plugin';

use Time::Piece;

sub process {
	my ( $self, $stash ) = @_;
	
	if( my ( $host, $program, $pid, $msg ) = $stash->{'message'} =~
			/^(\S+) ([^[]+)\[([^\]]+)\]: (.+)$/) {
		$stash->{'host'} = $host;
		$self->cnt->incr_one('by_host', $host);
		$stash->{'program'} = $program;
		$self->cnt->incr_one('by_program', $program);
		$stash->{'pid'} = $pid;
		$stash->{'message'} = $msg;
		return;
	}

	return('next');
}

1;

