package Log::Saftpresse::Plugin::Postfix;

use Moose;

# ABSTRACT: plugin to parse analyse postfix logging
# VERSION

extends 'Log::Saftpresse::Plugin';

has 'saftsumm_mode' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'message_detail' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'smtpd_warn_detail' => ( is => 'rw', isa => 'Maybe[Int]' );

has 'reject_detail' => ( is => 'rw', isa => 'Maybe[Int]' );
has 'bounce_detail' => ( is => 'rw', isa => 'Maybe[Int]' );
has 'deferred_detail' => ( is => 'rw', isa => 'Maybe[Int]' );

has 'ignore_case' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'rej_add_from' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'extended' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'uucp_mung' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'verp_mung' => ( is => 'rw', isa => 'Maybe[Int]' );

with 'Log::Saftpresse::Plugin::Role::PerHostCounters';

with 'Log::Saftpresse::Plugin::Postfix::Service';
with 'Log::Saftpresse::Plugin::Postfix::QueueID';
with 'Log::Saftpresse::Plugin::Postfix::Messages';
with 'Log::Saftpresse::Plugin::Postfix::Rejects';
with 'Log::Saftpresse::Plugin::Postfix::Recieved';
with 'Log::Saftpresse::Plugin::Postfix::Delivered';
with 'Log::Saftpresse::Plugin::Postfix::Smtp';
with 'Log::Saftpresse::Plugin::Postfix::Smtpd';
with 'Log::Saftpresse::Plugin::Postfix::Tls';

use Time::Piece;

sub process {
	my ( $self, $stash, $notes ) = @_;
	my $program = $stash->{'program'};

	if( ! defined $program || $program !~ /^postfix\// ) {
		return;
	}
	$self->process_service( $stash );
	if( ! defined $stash->{'service'} ) {
		return;
	}
	$self->process_queueid( $stash );

	$self->process_messages( $stash );
	$self->process_rejects( $stash );
	$self->process_recieved( $stash, $notes );
	$self->process_delivered( $stash, $notes );
	$self->process_smtp( $stash );
	$self->process_smtpd( $stash, $notes );
	$self->process_tls( $stash, $notes );

	return;
}

1;

