package Log::Saftpresse::Plugin::PostfixRejects;

use strict;
use warnings;

# ABSTRACT: plugin to gather postfix reject statistics
# VERSION

use base 'Log::Saftpresse::Plugin';

use Log::Saftpresse::Utils qw(gimme_domain verp_mung string_trimmer );

sub process {
	my ( $self, $stash ) = @_;
	if( $stash->{'program'} !~ /^postfix/ ) { return; }
	my $service = $stash->{'service'};
	my $message = $stash->{'message'};

	if( $service eq 'cleanup' &&
			( my($rejSubTyp, $rejReas, $rejRmdr) = $message =~
			/.*?\b(reject|warning|hold|discard): (header|body) (.*)$/ ) ) {

		$stash->{'reject_type'} = $rejSubTyp;
		$stash->{'reject_reason'} = $rejReas;

		$rejRmdr =~ s/( from \S+?)?; from=<.*$//
			unless($self->{'message_detail'});
		$rejRmdr = string_trimmer($rejRmdr, 64, $self->{'message_detail'});
		
		if( $self->{'reject_detail'} != 0 ) {
			$self->cnt->incr_one($rejSubTyp, $service, $rejReas, $rejRmdr);
		}
		$self->cnt->incr_one( $rejSubTyp );
		$self->incr_per_time_one( $stash->{'time'} );
	}

	if( my ($type, $reject_message) = $message
			=~ /^(reject|reject_warning|proxy-reject|hold|discard): (.*)$/ ) {
		$stash->{'reject_type'} = $type;
		$self->proc_smtpd_reject($stash, $type, $reject_message);
	}

	return;
}

sub incr_per_time_one {
	my ( $self, $time ) = @_;
	$self->cnt->incr_one( 'per_hr', $time->hour );
	$self->cnt->incr_one( 'per_mday', $time->mday );
	$self->cnt->incr_one( 'per_wday', $time->wday );
	$self->cnt->incr_one( 'per_day', $time->ymd );
	return;
}

sub proc_smtpd_reject {
    my ( $self, $stash, $type, $message ) = @_;
    #my ($logLine, $rejects, $msgsRjctd, $rejPerHr, $msgsPerDay) = @_;
    my ($rejTyp, $rejFrom, $rejRmdr, $rejReas);
    my ($from, $to);
    my $rejAddFrom = 0;

    $self->cnt->incr_one( 'total', $type );
    $self->incr_per_time_one( $stash->{'time'} );

    # Hate the sub-calling overhead if we're not doing reject details
    # anyway, but this is the only place we can do this.
    return if( $self->{'reject_detail'} == 0);

    # This could get real ugly!

    # First: get everything following the "reject: ", etc. token
    # Was an IPv6 problem here
    ($rejTyp, $rejFrom, $rejRmdr) = $message =~ /^(\S+) from (\S+?): (.*)$/;

    # Next: get the reject "reason"
    $rejReas = $rejRmdr;
    unless(defined( $self->{'message_detail'} )) {
	if($rejTyp eq "RCPT" || $rejTyp eq "DATA" || $rejTyp eq "CONNECT") {	# special treatment :-(
	    # If there are "<>"s immediately following the reject code, that's
	    # an email address or HELO string.  There can be *anything* in
	    # those--incl. stuff that'll screw up subsequent parsing.  So just
	    # get rid of it right off.
	    $rejReas =~ s/^(\d{3} <).*?(>:)/$1$2/;
	    $rejReas =~ s/^(?:.*?[:;] )(?:\[[^\]]+\] )?([^;,]+)[;,].*$/$1/;
	    $rejReas =~ s/^((?:Sender|Recipient) address rejected: [^:]+):.*$/$1/;
	    $rejReas =~ s/(Client host|Sender address) .+? blocked/blocked/;
	} elsif($rejTyp eq "MAIL") {	# *more* special treatment :-( grrrr...
	    $rejReas =~ s/^\d{3} (?:<.+>: )?([^;:]+)[;:]?.*$/$1/;
	} else {
	    $rejReas =~ s/^(?:.*[:;] )?([^,]+).*$/$1/;
	}
    }

    # Snag recipient address
    # Second expression is for unknown recipient--where there is no
    # "to=<mumble>" field, third for pathological case where recipient
    # field is unterminated, forth when all else fails.
    (($to) = $rejRmdr =~ /to=<([^>]+)>/) ||
	(($to) = $rejRmdr =~ /\d{3} <([^>]+)>: User unknown /) ||
	(($to) = $rejRmdr =~ /to=<(.*?)(?:[, ]|$)/) ||
	($to = "<>");
    $to = lc($to) if($self->{'ignore_case'});

    # Snag sender address
    (($from) = $rejRmdr =~ /from=<([^>]+)>/) || ($from = "<>");

    if(defined($from)) {
	$rejAddFrom = $self->{'rej_add_from'};
        $from = verp_mung( $self->{'verp_mung'}, $from);
	$from = lc($from) if($self->{'ignore_case'});
    }

    # stash in "triple-subscripted-array"
    if($rejReas =~ m/^Sender address rejected:/) {
	# Sender address rejected: Domain not found
	# Sender address rejected: need fully-qualified address
        $self->cnt->incr_one($type, $rejTyp, $rejReas, $from);
    } elsif($rejReas =~ m/^(Recipient address rejected:|User unknown( |$))/) {
	# Recipient address rejected: Domain not found
	# Recipient address rejected: need fully-qualified address
	# User unknown (in local/relay recipient table)
	#++$rejects->{$rejTyp}{$rejReas}{$to};
	my $rejData = $to;
	if($rejAddFrom) {
	    $rejData .= "  (" . ($from? $from : gimme_domain($rejFrom)) . ")";
	}
        $self->cnt->incr_one($type, $rejTyp, $rejReas, $rejData);
    } elsif($rejReas =~ s/^.*?\d{3} (Improper use of SMTP command pipelining);.*$/$1/) {
	# Was an IPv6 problem here
	my ($src) = $message =~ /^.+? from (\S+?):.*$/;
        $self->cnt->incr_one($type, $rejTyp, $rejReas, $src);
    } elsif($rejReas =~ s/^.*?\d{3} (Message size exceeds fixed limit);.*$/$1/) {
	my $rejData = gimme_domain($rejFrom);
	$rejData .= "  ($from)" if($rejAddFrom);
        $self->cnt->incr_one($type, $rejTyp, $rejReas, $rejData);
    } elsif($rejReas =~ s/^.*?\d{3} (Server configuration (?:error|problem));.*$/(Local) $1/) {
	my $rejData = gimme_domain($rejFrom);
	$rejData .= "  ($from)" if($rejAddFrom);
        $self->cnt->incr_one($type, $rejTyp, $rejReas, $rejData);
    } else {
#	print STDERR "dbg: unknown reject reason $rejReas !\n\n";
	my $rejData = gimme_domain($rejFrom);
	$rejData .= "  ($from)" if($rejAddFrom);
        $self->cnt->incr_one($type, $rejTyp, $rejReas, $rejData);
    }
}

1;

