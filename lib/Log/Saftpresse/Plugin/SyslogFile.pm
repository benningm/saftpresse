package Log::Saftpresse::Plugin::SyslogFile;

use Moose;

# ABSTRACT: plugin to parse syslog logfile format
# VERSION

extends 'Log::Saftpresse::Plugin';

use Time::Piece;

sub process {
	my ( $self, $stash ) = @_;
	
	if( my ( $date_str, $msg ) = $stash->{'message'} =~
			/^(... {1,2}\d{1,2} \d{2}:\d{2}:\d{2}) (.+)$/) {
		my $time = Time::Piece->strptime($date_str, "%b %e %H:%M:%S");
		my $now = Time::Piece->new;

		# guess year
		if( $time->mon > $now->mon ) {
			# Time::Piece->year is ro :-/
			$time->[5] = $now->[5] - 1;
		} else {
			$time->[5] = $now->[5];
		}

		$stash->{'time'} = $time;
		$stash->{'message'} = $msg;
	}

	if( my ( $date_str, $msg ) = $stash->{'message'} =~
			/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:[\+\-](?:\d{2}):(?:\d{2})|Z) (.+)$/) {
		$stash->{'time'} = Time::Piece->strptime($date_str, "%Y-%m-%dT%H:%M:%S%z");
		$stash->{'message'} = $msg;
	}

	if( my ( $host, $program, $pid, $msg ) = $stash->{'message'} =~
			/^(\S+) ([^[]+)\[([^\]]+)\]: (.+)$/) {
		$stash->{'host'} = $host;
		$self->incr_one('by_host', $host);
		$stash->{'program'} = $program;
		$self->incr_one('by_program', $program);
		$stash->{'pid'} = $pid;
		$stash->{'message'} = $msg;
	}

	return;
}

1;

