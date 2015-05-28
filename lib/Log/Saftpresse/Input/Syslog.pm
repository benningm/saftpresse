package Log::Saftpresse::Input::Syslog;

use Moose;

# ABSTRACT: syslog server input plugin for saftpresse
# VERSION

extends 'Log::Saftpresse::Input::Server';

has 'syslog_format' => ( is => 'rw', isa => 'Str', default => 'rfc3164' );

use Time::Piece;

sub handle_data {
	my ( $self, $conn ) = @_;
	my @events;
	while( defined( my $line = $conn->getline ) ) {
		$line =~ s/[\r\n]*$//;
		my $event = $self->parse_rfc3164_line( $line );
		if( defined $event ) {
			push( @events, $event );
		}
	}
	return @events;
}

has priorities => (
	is => 'ro', isa => 'ArrayRef', lazy => 1,
	default => sub { [
		'emerg',
		'alert',
		'crit',
		'error',
		'warn',
		'notice',
		'info',
		'debug',
	] },
);

has facilities => (
	is => 'ro', isa => 'ArrayRef', lazy => 1,
	default => sub { [
		'kernel',
		'user',
		'mail',
		'daemon',
		'auth',
		'syslog',
		'printer',
		'news',
		'uucp',
		'cron',
		'authpriv',
		'ftp',
		'ntp',
		'audit',
		'alert',
		'clock',
		'local0',
		'local1',
		'local2',
		'local3',
		'local4',
		'local5',
		'local6',
		'local7',
	] },
);

sub parse_rfc3164_line {
	my ( $self, $line ) = @_;
	my ( $d, $time_str, $host, $proc, $pid, $message ) =
		$line =~ m/^<(\d+)>([A-Z][a-z]{2} [\d ]\d \d\d:\d\d:\d\d) ([^ ]+) ([^\[]+)(?:\[(\d+)\])?: (.*)$/;
	if( ! defined $d || ! defined $time_str || ! defined $host || ! defined $proc || ! defined $message ) {
		return;
	}
	my $priority = $self->priorities->[ $d & 7 ];
	my $facility = $self->facilities->[ $d >> 3 ];
	my $time = Time::Piece->strptime($time_str, "%b %e %H:%M:%S");
	my $now = Time::Piece->new;                                              
	# guess year
	if( $time->mon > $now->mon ) {
		# Time::Piece->year is ro :-/
		$time->[5] = $now->[5] - 1;
	} else {
		$time->[5] = $now->[5];
	}

	return {
		defined $priority ? (priority => $priority) : (),
		defined $facility ? (facility => $facility) : (),
		time => $time,
		host => $host,
		program => $proc,
		defined $pid ? ( pid => $pid ) : (),
		message => $message,
	};
}

1;

