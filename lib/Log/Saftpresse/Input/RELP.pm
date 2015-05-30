package Log::Saftpresse::Input::RELP;

use Moose;

# ABSTRACT: RELP server input plugin for saftpresse
# VERSION

extends 'Log::Saftpresse::Input::Server';

use Log::Saftpresse::Input::RELP::Frame;
use Log::Saftpresse::Input::RELP::RSP;
use Time::Piece;

sub handle_data {
	my ( $self, $conn ) = @_;
	my @events;
	while( defined( my $frame = $self->_read_frame($conn) ) ) {
		if( $frame->command eq 'open' ) {
			$self->cmd_open( $conn, $frame );
		} elsif( $frame->command eq 'close' ) {
			$self->cmd_close( $conn, $frame );
		} elsif( $frame->command eq 'syslog' ) {
			my $data = $self->cmd_syslog( $conn, $frame );
			if( defined $data ) {
				push( @events, { message => $data } );
			}
		}
	}
	return @events;
}

sub cmd_open {
	my ( $self, $conn, $frame ) = @_;
	my $resp;

	if( $frame->data =~ /^relp_version=0/ ) {
		$resp = Log::Saftpresse::Input::RELP::Frame->new_next_frame(
			$frame,
			command => 'rsp',
			data => Log::Saftpresse::Input::RELP::RSP->new(
				code => 200,
				message => 'OK',
				data => "relp_version=0\nrelp_software=saftpresse\ncommands=open,close,syslog",
			)->as_string,
		);
	} else {
		$resp = Log::Saftpresse::Input::RELP::Frame->new_next_frame(
			$frame,
			command => 'rsp',
			data => Log::Saftpresse::Input::RELP::RSP->new(
				code => 500,
				message => 'unsupported protocol version',
			)->as_string,
		);
	}

	$conn->print( $resp->as_string );

	return;
}

sub cmd_close {
	my ( $self, $conn, $frame ) = @_;
	my $resp;

	$resp = Log::Saftpresse::Input::RELP::Frame->new_next_frame(
		$frame,
		command => 'rsp',
		data => Log::Saftpresse::Input::RELP::RSP->new(
			code => 200,
			message => 'OK',
		)->as_string,
	);
	$conn->print( $resp->as_string );
	$conn->close;

	return;
}

sub cmd_syslog {
	my ( $self, $conn, $frame ) = @_;
	my $resp;

	$resp = Log::Saftpresse::Input::RELP::Frame->new_next_frame(
		$frame,
		command => 'rsp',
		data => Log::Saftpresse::Input::RELP::RSP->new(
			code => 200,
			message => 'OK',
		)->as_string,
	);
	$conn->print( $resp->as_string );

	return $frame->data;
}

sub _read_frame {
	my ( $self, $conn ) = @_;
	my $frame;
	
	eval {
		$frame = Log::Saftpresse::Input::RELP::Frame->new_from_fh($conn);
	};

	return( $frame );
}

1;

