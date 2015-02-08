package Log::Saftpresse::CountersOutput::Pflogsumm;

use strict;
use warnings;

# ABSTRACT: plugin to output counters in pflogsumm style output
# VERSION

use base 'Log::Saftpresse::CountersOutput';

use Log::Saftpresse::Utils qw( adj_int_units get_smh);

use Time::Piece;

sub output {
	my ( $self, $cnt ) = @_;

	$self->print_totals(
		$cnt->{'PostfixRejects'},
		$cnt->{'PostfixRecieved'},
		$cnt->{'PostfixDelivered'},
	);

	if( defined $cnt->{'PostfixSmtpdStats'} ) {
		$self->print_smtpd_stats( $cnt->{'PostfixSmtpdStats'} );
	}
	if( defined $self->{'problems_first'} ) {
		$self->print_problems_reports( $cnt );
	}

	print_subsect_title( 'Per-Day Traffic Summary' );
	$self->print_table_from_hashes( 'date', 'string', 15, 10,
		[ 'recieved', $cnt->{'PostfixRecieved'}->get_node('per_day') ],
		[ 'delivered', $cnt->{'PostfixDelivered'}->get_node('sent', 'per_day') ],
		[ 'deffered', $cnt->{'PostfixDelivered'}->get_node('deferred', 'per_day'), ],
		[ 'bounced', $cnt->{'PostfixDelivered'}->get_node('bounced', 'per_day'), ],
		[ 'rejected', $cnt->{'PostfixRejects'}->get_node('per_day') ],
	);

	$self->print_table_from_hashes( 'hour', 'decimal', 15, 10,
		[ 'recieved', $cnt->{'PostfixRecieved'}->get_node('per_hr') ],
		[ 'delivered', $cnt->{'PostfixDelivered'}->get_node('sent', 'per_hr') ],
		[ 'deffered', $cnt->{'PostfixDelivered'}->get_node('deferred', 'per_hr'), ],
		[ 'bounced', $cnt->{'PostfixDelivered'}->get_node('bounced', 'per_hr'), ],
		[ 'rejected', $cnt->{'PostfixRejects'}->get_node('per_hr') ],
	);

#	print_recip_domain_summary(\%recipDom, $opts{'h'});
#	print_sending_domain_summary(\%sendgDom, $opts{'h'});

	if( my $smtpd_stats = $cnt->{'PostfixSmtpdStats'} ) {
    		print_subsect_title("Per-Day SMTPD Connection Summary");
		$self->print_table_from_hashes( 'date', 'string', 15, 10,
			[ 'connections', $smtpd_stats->get_node('per_day') ],
			[ 'time conn.', $smtpd_stats->get_node('busy', 'per_day') ],
			[ 'avg./conn.', $self->hash_calc_avg( 2,
					$smtpd_stats->get_node('busy', 'per_day'),
					$smtpd_stats->get_node('per_day'),
				), ],
			[ 'max. time', $smtpd_stats->get_node('busy', 'max_per_day'), ],
		);

    		print_subsect_title("Per-Hour SMTPD Connection Summary");
		$self->print_table_from_hashes( 'hour', 'decimal', 15, 10,
			[ 'connections', $smtpd_stats->get_node('per_hr') ],
			[ 'time conn.', $smtpd_stats->get_node('busy', 'per_hr') ],
			[ 'avg./conn.', $self->hash_calc_avg( 2,
					$smtpd_stats->get_node('busy', 'per_hr'),
					$smtpd_stats->get_node('per_hr'),
				), ],
			[ 'max. time', $smtpd_stats->get_node('busy', 'max_per_hr'), ],
		);

    		print_subsect_title("Per-Domain SMTPD Connection Summary");
		$self->print_table_from_hashes( 'domain', [ 'connections', 'decimal', 20 ] , 25, 10,
			[ 'connections', $smtpd_stats->get_node('per_domain') ],
			[ 'time conn.', $smtpd_stats->get_node('busy', 'per_domain') ],
			[ 'avg./conn.', $self->hash_calc_avg( 2,
					$smtpd_stats->get_node('busy', 'per_domain'),
					$smtpd_stats->get_node('per_domain'),
				), ],
			[ 'max. time', $smtpd_stats->get_node('busy', 'max_per_domain'), ],
		);
	}
#
#	print_user_data(\%sendgUser, "Senders by message count", $msgCntI, $opts{'u'}, $opts{'q'});
#	print_user_data(\%recipUser, "Recipients by message count", $msgCntI, $opts{'u'}, $opts{'q'});
#	print_user_data(\%sendgUser, "Senders by message size", $msgSizeI, $opts{'u'}, $opts{'q'});
#	print_user_data(\%recipUser, "Recipients by message size", $msgSizeI, $opts{'u'}, $opts{'q'});
#
#	print_hash_by_key(\%noMsgSize, "Messages with no size data", 0, 1);
#
	if( ! defined $self->{'problems_first'} ) {
		$self->print_problems_reports( $cnt );
	}

#	print_detailed_msg_data(\%msgDetail, "Message detail", $opts{'q'}) if($opts{'e'});
#
	if( defined $cnt->{'TlsStatistics'} ) {
		$self->print_tls_stats( $cnt );
	}
	if( defined $cnt->{'PostfixGeoStats'} ) {
		$self->print_geo_stats( $cnt->{'PostfixGeoStats'} );
	}

	return;
}

sub hash_calc_avg {
	my ( $self, $precision, $total, $count ) = @_;
	my %avg;
	my %uniq = map { $_ => 1 } ( keys %$total, keys %$count );
	my @keys = keys %uniq;
	foreach my $key ( @keys ) {
		my $value = 0;
		if( defined $total->{$key} && $total->{$key} > 0
				&& defined $count->{$key} && $count->{$key} > 0 ) { 
			$value = $total->{$key} / $count->{$key};
		}
		$avg{$key} = sprintf('%.'.$precision.'f', $value);
	}
	return \%avg;
}

sub print_table_from_hashes {
	my ( $self, $legend, $sort, $lw, $cw, @rows ) = @_;
	my @headers = map { $_->[0] } @rows;
	my @hashes = map { $_->[1] } @rows;
	my @yaxis;

	$self->print_table_header( $legend, $lw, $cw, @headers );

	if( ref($sort) eq 'ARRAY' ) { # sort by a column value
		my ( $sortby, $alg, $limit ) = @$sort;
		my ( $row ) = grep { $_->[0] eq $sortby } @rows;
		$row = $row->[1];
		if( ! defined $row ) { die('cant find row '.$sortby.' for sorting'); }
		if( $alg eq 'decimal' ) {
			@yaxis = sort { $row->{$b} <=> $row->{$a} } keys %$row;
		} else { # string
			@yaxis = sort { $row->{$b} cmp $row->{$a} } keys %$row;
		}
		if( $limit > 0 && scalar @yaxis > $limit ) { @yaxis = @yaxis[0 .. ($limit-1) ] };
	} else { # simple sort by key
		my @all_keys = map { keys %$_ } @hashes;
		my %uniq = map { $_ => 1 } @all_keys;
		if( $sort eq 'decimal' ) {
			@yaxis = sort { $a <=> $b } keys %uniq;
		} else { # string
			@yaxis = sort { $a cmp $b } keys %uniq;
		}
	}

	foreach my $row ( @yaxis ) {
		$self->print_table_row( $row, $lw, $cw,
			map { $_->{$row} } @hashes );
	}
	print "\n";

	return;
}

sub print_table_row {
	my ( $self, $ylabel, $lw, $cw, @values ) = @_;

	printf("%".$lw."s", $ylabel);
	foreach my $value ( @values ) {
		if( ! defined $value ) { $value = '-'; }
		printf(" %".$cw."s", $value);
	}
	print "\n";

	return;
}

sub print_table_header {
	my ( $self, $legend, $lw, $cw, @headers ) = @_;

	$self->print_table_row( $legend, $lw, $cw, @headers);

	my $width = $lw + (( $cw + 1 ) * scalar @headers);
	print( ("-" x $width)."\n");

	return;
}

sub print_totals {
	my ( $self, $reject_cnt, $recieved_cnt, $delivered_cnt ) = @_;
	my $smtpdConnCnt = 0;

	# PostfixRejects
	my $msgsRjctd = $reject_cnt->get_value_or_zero('total', 'reject');
	my $msgsDscrdd = $reject_cnt->get_value_or_zero('total', 'discard');
	my $msgsWrnd = $reject_cnt->get_value_or_zero('total', 'warning');
	my $msgsHld = $reject_cnt->get_value_or_zero('total', 'hold');

	# PostfixRecieved
	my $msgsRcvd = $recieved_cnt->get_value_or_zero('total');

	my $msgsDlvrd = $delivered_cnt->get_value_or_zero('sent', 'total');
	my $msgsDfrd = $delivered_cnt->get_value_or_zero('deferred', 'total');
	my $msgsFwdd = $delivered_cnt->get_value_or_zero('forwarded');
	my $msgsBncd = $delivered_cnt->get_value_or_zero('bounced', 'total');

	my $sizeRcvd = $delivered_cnt->get_value_or_zero('recieved', 'size', 'total');
	my $sizeDlvrd = $delivered_cnt->get_value_or_zero('sent', 'size', 'total');

	my $sendgUserCnt = $delivered_cnt->get_key_count('sent', 'by_rcpt');
	my $sendgDomCnt = $delivered_cnt->get_key_count('sent', 'by_domain'); 
	my $recipUserCnt =$delivered_cnt->get_key_count('recieved', 'by_sender');
	my $recipDomCnt = $delivered_cnt->get_key_count('recieved', 'by_domain');

	# Calculate percentage of messages rejected and discarded
	my $msgsRjctdPct = 0;
	my $msgsDscrddPct = 0;
	if(my $msgsTotal = $msgsDlvrd + $msgsRjctd + $msgsDscrdd) {
	    $msgsRjctdPct = int(($msgsRjctd/$msgsTotal) * 100);
	    $msgsDscrddPct = int(($msgsDscrdd/$msgsTotal) * 100);
	}

	print "Postfix log summaries generated on ".Time::Piece->new->ymd."\n";

	print_subsect_title("Grand Totals");
	print "messages\n\n";
	printf " %6d%s  received\n", adj_int_units($msgsRcvd);
	printf " %6d%s  delivered\n", adj_int_units($msgsDlvrd);
	printf " %6d%s  forwarded\n", adj_int_units($msgsFwdd);
	printf " %6d%s  deferred", adj_int_units($msgsDfrd);
	#printf "  (%d%s deferrals)", adj_int_units($msgsDfrdCnt) if($msgsDfrdCnt);
	print "\n";
	printf " %6d%s  bounced\n", adj_int_units($msgsBncd);
	printf " %6d%s  rejected (%d%%)\n", adj_int_units($msgsRjctd), $msgsRjctdPct;
	printf " %6d%s  reject warnings\n", adj_int_units($msgsWrnd);
	printf " %6d%s  held\n", adj_int_units($msgsHld);
	printf " %6d%s  discarded (%d%%)\n", adj_int_units($msgsDscrdd), $msgsDscrddPct;
	print "\n";
	printf " %6d%s  bytes received\n", adj_int_units($sizeRcvd);
	printf " %6d%s  bytes delivered\n", adj_int_units($sizeDlvrd);
	printf " %6d%s  senders\n", adj_int_units($sendgUserCnt);
	printf " %6d%s  sending hosts/domains\n", adj_int_units($sendgDomCnt);
	printf " %6d%s  recipients\n", adj_int_units($recipUserCnt);
	printf " %6d%s  recipient hosts/domains\n", adj_int_units($recipDomCnt);
	print "\n";

	return;
}

sub print_smtpd_stats {
	my ( $self, $cnt ) = @_;
	my $smtpdConnCnt = $cnt->get_value_or_zero('total');
	print "\nsmtpd\n\n";
	printf "  %6d%s  connections\n",
	adj_int_units($smtpdConnCnt);
	printf "  %6d%s  hosts/domains\n",
	adj_int_units(int(keys %{$cnt->get_node('per_domain')}));
	printf "  %6d   avg. connect time (seconds)\n",
		$smtpdConnCnt > 0 ?
		($cnt->get_value_or_zero('busy', 'total')
			/ $smtpdConnCnt ) + .5
		: 0;
	{
		my ($sec, $min, $hr) = get_smh($cnt->get_value_or_zero('busy', 'total'));
		printf " %2d:%02d:%02d  total connect time\n",
		$hr, $min, $sec;
	}
	return;
}

sub print_problems_reports {
	my ( $self, $cnt ) = @_;

	my $delivered_cnt = $cnt->{'PostfixDelivered'};
	my $reject_cnt = $cnt->{'PostfixRejects'};

	if($self->{'deferral_detail'} != 0) {
		$self->print_nested_hash( $delivered_cnt->get_node('deferred'),
			"message deferral detail",
			$self->{'deferral_detail'},
			$self->{'quiet'} );
	}
	if($self->{'bounce_detail'} != 0) {
		$self->print_nested_hash( $delivered_cnt->get_node('bounced'),
			"message bounce detail (by relay)",
			$self->{'bounce_detail'},
			$self->{'quiet'} );
	}
	if($self->{'reject_detail'} != 0) {
		foreach my $key ( 'reject', 'warning', 'hold', 'discard') {
			$self->print_nested_hash($reject_cnt->get_node($key),
				"message $key detail",
				$self->{'reject_detail'},
				$self->{'quite'});
		}
	}

	if( my $smtp_cnt = $cnt->{'PostfixSmtp'} ) {
		my $messages = $smtp_cnt->get_node('messages');
		if( defined $messages ) {
			$self->print_nested_hash($messages, "smtp delivery failures",
				$self->{'smtp_detail'},
				$self->{'quite'} );
		}
	}
	if( my $msg_cnt =  $cnt->{'PostfixMessages'} ) {
		if($self->{'smtpd_warn_detail'} != 0) {
			$self->print_nested_hash($msg_cnt->get_node('warning'),
				"Warnings",
				$self->{'smtpd_warn_detail'},
				$self->{'quite'});
		}
		$self->print_nested_hash($msg_cnt->get_node('fatal'),
			"Fatal Errors", 0,
			$self->{'quite'});
		$self->print_nested_hash($msg_cnt->get_node('panic'),
			"Panics", 0,
			$self->{'quite'});
		$self->print_hash_by_cnt_vals($msg_cnt->get_node('master'),
			"Master daemon messages", 0,
			$self->{'quite'});
	}
}

sub print_tls_stats {
	my ( $self, $cnt ) = @_;
	my $tls_cnt = $cnt->{'TlsStatistics'};
	my $smtpd_cnt = $cnt->{'PostfixSmtpdStats'};
	my $recieved_cnt = $cnt->{'PostfixRecieved'};
	my $delivered_cnt = $cnt->{'PostfixDelivered'};
	my $smtpdConnCnt;

	if( defined $smtpd_cnt ) {
		$smtpdConnCnt = $smtpd_cnt->get_value_or_zero('total');
	}
	my $msgs_rcvd = $recieved_cnt->get_value_or_zero('total');
	my $msgs_sent = $delivered_cnt->get_value_or_zero('sent', 'total');

	print_subsect_title("TLS Statistics");

	my @total_stats = (
		[ 'incoming tls connections' => $smtpdConnCnt,
			'smtpd', 'connections', 'total' ],
		[ 'incoming tls messages' => $msgs_rcvd,
			'smtpd', 'messages', 'total' ],
		[ 'outgoing tls connections' => $smtpdConnCnt,
			'smtp', 'connections', 'total' ],
		[ 'outgoing tls messages' => $msgs_sent,
			'smtp', 'messages', 'total' ],
	);

	foreach my $stat ( @total_stats ) {
		my ( $name, $total, @node ) = @$stat;
		my $value = $tls_cnt->get( @node );
		if( ! defined $value ) { next; }
		printf " %6d%s $name",
			adj_int_units($value);
		if( $total ) {
			print_in_percent($value, $total);
		} else { print "\n"; }
	}

	my @tls_statistics = (
		[ "Incoming TLS trust-level" =>
			$smtpdConnCnt, 'smtpd', 'connections', 'level' ],
		[ "Outgoing TLS trust-level" =>
			0, 'smtp', 'connections', 'level' ],
		[ "Incoming TLS Protocol Version" =>
			$smtpdConnCnt, 'smtpd', 'connections', 'protocol' ],
		[ "Outgoing TLS Protocol Version" =>
			0, 'smtp', 'connections', 'protocol' ],
		[ "Incoming TLS key length" =>
			$smtpdConnCnt, 'smtpd', 'connections', 'keylen' ],
		[ "Outgoing TLS key length" =>
			0, 'smtp', 'connections', 'keylen' ],
		[ "Incoming TLS Ciphers" =>
			$smtpdConnCnt, 'smtpd', 'connections', 'cipher' ],
		[ "Outgoing TLS Ciphers" =>
			0, 'smtp', 'connections', 'cipher' ],
	);

	foreach my $tls_stat ( @tls_statistics ) {
		my ( $title, $total, @node ) = @$tls_stat;
		my $values = $tls_cnt->get_node(@node);
		if( ! defined $values ) { next; }
		$values = hash_key_add_percent( $values, $total );
		$self->print_hash_by_cnt_vals( $values, $title, 0, 1 );
	}
}

sub print_geo_stats {
	my ( $self, $cnt ) = @_;
	my $client = $cnt->get_node('client');
	if( defined $client ) {
    		$self->print_hash_by_cnt_vals( $client, 'Client Countries', 0, 1 );
	}
}

sub print_in_percent {
	my ( $value, $total ) = @_;
	my $percent = $value / $total * 100;
	printf(" (%3.2f%% of %d)\n", $percent, $total );
	return;
}

sub hash_key_add_percent {
	my ( $hash, $base ) = @_;
	if( ! defined $base || $base == 0 ) {
		return( $hash );
	}
	my $out = {
		map {
			my $percent = sprintf("%.2f%%", $hash->{$_} / $base * 100 );
			$_.' ('.$percent.')' => $hash->{$_};
		} keys %$hash
	};
	return( $out );
}

# print "per-recipient-domain" traffic summary
# (done in a subroutine only to keep main-line code clean)
#sub print_recip_domain_summary {
#    use vars '$hashRef';
#    local($hashRef) = $_[0];
#    my($cnt) = $_[1];
#    return if($cnt == 0);
#    my $topCnt = $cnt > 0? "(top $cnt)" : "";
#    my $avgDly;
#
#    print_subsect_title("Host/Domain Summary: Message Delivery $topCnt");
#
#    print <<End_Of_Recip_Domain_Heading;
# sent cnt  bytes   defers   avg dly max dly host/domain
# -------- -------  -------  ------- ------- -----------
#End_Of_Recip_Domain_Heading
#
#    foreach (reverse sort by_count_then_size keys(%$hashRef)) {
#	# there are only delay values if anything was sent
#	if(${$hashRef->{$_}}[$msgCntI]) {
#	    $avgDly = (${$hashRef->{$_}}[$msgDlyAvgI] /
#		       ${$hashRef->{$_}}[$msgCntI]);
#	} else {
#	    $avgDly = 0;
#	}
#	printf " %6d%s  %6d%s  %6d%s  %5.1f %s  %5.1f %s  %s\n",
#	    adj_int_units(${$hashRef->{$_}}[$msgCntI]),
#	    adj_int_units(${$hashRef->{$_}}[$msgSizeI]),
#	    adj_int_units(${$hashRef->{$_}}[$msgDfrsI]),
#	    adj_time_units($avgDly),
#	    adj_time_units(${$hashRef->{$_}}[$msgDlyMaxI]),
#	    $_;
#	last if --$cnt == 0;
#    }
#}

# print "per-sender-domain" traffic summary
# (done in a subroutine only to keep main-line code clean)
#sub print_sending_domain_summary {
#    use vars '$hashRef';
#    local($hashRef) = $_[0];
#    my($cnt) = $_[1];
#    return if($cnt == 0);
#    my $topCnt = $cnt > 0? "(top $cnt)" : "";
#
#    print_subsect_title("Host/Domain Summary: Messages Received $topCnt");
#
#    print <<End_Of_Sender_Domain_Heading;
# msg cnt   bytes   host/domain
# -------- -------  -----------
#End_Of_Sender_Domain_Heading
#
#    foreach (reverse sort by_count_then_size keys(%$hashRef)) {
#	printf " %6d%s  %6d%s  %s\n",
#	    adj_int_units(${$hashRef->{$_}}[$msgCntI]),
#	    adj_int_units(${$hashRef->{$_}}[$msgSizeI]),
#	    $_;
#	last if --$cnt == 0;
#    }
#}

# print "per-user" data sorted in descending order
# order (i.e.: highest first)
sub print_user_data {
    my($hashRef, $title, $index, $cnt, $quiet) = @_;
    my $dottedLine;
    return if($cnt == 0);
    $title = sprintf "%s%s", $cnt > 0? "top $cnt " : "", $title;
    unless(%$hashRef) {
	return if($quiet);
	$dottedLine = ": none";
    } else {
	$dottedLine = "\n" . "-" x length($title);
    }
    printf "\n$title$dottedLine\n";
    foreach (map { $_->[0] }
	     sort { $b->[1] <=> $a->[1] || $a->[2] cmp $b->[2] }
	     map { [ $_, $hashRef->{$_}[$index], normalize_host($_) ] }
	     (keys(%$hashRef)))
    {
	printf " %6d%s  %s\n", adj_int_units(${$hashRef->{$_}}[$index]), $_;
	last if --$cnt == 0;
    }
}

# print hash contents sorted by numeric values in descending
# order (i.e.: highest first)
sub print_hash_by_cnt_vals {
    my($self, $hashRef, $title, $cnt, $quiet) = @_;
    my $dottedLine;
    if( ! defined $hashRef) { return; }
    $title = sprintf "%s%s", $cnt? "top $cnt " : "", $title;
    unless(%$hashRef) {
	return if($quiet);
	$dottedLine = ": none";
    } else {
	$dottedLine = "\n" . "-" x length($title);
    }
    printf "\n$title$dottedLine\n";
    really_print_hash_by_cnt_vals($hashRef, $cnt, ' ');
}

# print hash contents sorted by key in ascending order
sub print_hash_by_key {
    my($hashRef, $title, $cnt, $quiet) = @_;
    my $dottedLine;
    $title = sprintf "%s%s", $cnt? "first $cnt " : "", $title;
    unless(%$hashRef) {
	return if($quiet);
	$dottedLine = ": none";
    } else {
	$dottedLine = "\n" . "-" x length($title);
    }
    printf "\n$title$dottedLine\n";
    foreach (sort keys(%$hashRef))
    {
	printf " %s  %s\n", $_, $hashRef->{$_};
	last if --$cnt == 0;
    }
}

# print "nested" hashes
sub print_nested_hash {
    my( $self, $hashRef, $title, $cnt, $quiet) = @_;
    my $dottedLine;
    if( ! defined $hashRef ) { return; }
    unless(%$hashRef) {
	return if($quiet);
	$dottedLine = ": none";
    } else {
	$dottedLine = "\n" . "-" x length($title);
    }
    printf "\n$title$dottedLine\n";
    walk_nested_hash($hashRef, $cnt, 0);
}

# "walk" a "nested" hash
sub walk_nested_hash {
	my ($hashRef, $cnt, $level) = @_;
	$level += 2;
	my $indents = ' ' x $level;
	my ($keyName, $hashVal) = each(%$hashRef);

	if( ref($hashRef) ne 'HASH' ) { return; }

	if(ref($hashVal) ne 'HASH') {
		really_print_hash_by_cnt_vals($hashRef, $cnt, $indents);
		return;
	}
	foreach (sort keys %$hashRef) {
	    if( ref $hashRef->{$_} ne 'HASH' ) { next; }
	    print "$indents$_";
	    # If the next hash is finally the data, total the
	    # counts for the report and print
	    my $hashVal2 = (each(%{$hashRef->{$_}}))[1];
	    keys(%{$hashRef->{$_}});	# "reset" hash iterator
	    unless(ref($hashVal2) eq 'HASH') {
		print " (top $cnt)" if($cnt > 0);
		my $rptCnt = 0;
		$rptCnt += $_ foreach (values %{$hashRef->{$_}});
		print " (total: $rptCnt)";
	    }
	    print "\n";
	    walk_nested_hash($hashRef->{$_}, $cnt, $level);
	}
}

# print per-message info in excruciating detail :-)
sub print_detailed_msg_data {
    use vars '$hashRef';
    local($hashRef) = $_[0];
    my($title, $quiet) = @_[1,2];
    my $dottedLine;
    unless(%$hashRef) {
	return if($quiet);
	$dottedLine = ": none";
    } else {
	$dottedLine = "\n" . "-" x length($title);
    }
    printf "\n$title$dottedLine\n";
    foreach (sort by_domain_then_user keys(%$hashRef))
    {
	printf " %s  %s\n", $_, shift(@{$hashRef->{$_}});
	foreach (@{$hashRef->{$_}}) {
	    print "   $_\n";
	}
	print "\n";
    }
}

# *really* print hash contents sorted by numeric values in descending
# order (i.e.: highest first), then by IP/addr, in ascending order.
sub really_print_hash_by_cnt_vals {
    my($hashRef, $cnt, $indents) = @_;

    foreach (map { $_->[0] }
	     sort { $b->[1] <=> $a->[1] || $a->[2] cmp $b->[2] }
	     map { [ $_, $hashRef->{$_}, normalize_host($_) ] }
	     (keys(%$hashRef)))
    {
        printf "$indents%6d%s  %s\n", adj_int_units($hashRef->{$_}), $_;
        last if --$cnt == 0;
    }
}

# Print a sub-section title with properly-sized underline
sub print_subsect_title {
    my $title = $_[0];
    print "\n$title\n" . "-" x length($title) . "\n";
}

# Normalize IP addr or hostname
# (Note: Makes no effort to normalize IPv6 addrs.  Just returns them
# as they're passed-in.)
sub normalize_host {
    # For IP addrs and hostnames: lop off possible " (user@dom.ain)" bit
    my $norm1 = (split(/\s/, $_[0]))[0];

    if((my @octets = ($norm1 =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)) == 4) {
	# Dotted-quad IP address
	return(pack('U4', @octets));
    } else {
	# Possibly hostname or user@dom.ain
	return(join( '', map { lc $_ } reverse split /[.@]/, $norm1 ));
    }
}

# subroutine to sort by domain, then user in domain, then by queue i.d.
# Note: mixing Internet-style domain names and UUCP-style bang-paths
# may confuse this thing.  An attempt is made to use the first host
# preceding the username in the bang-path as the "domain" if none is
# found otherwise.
sub by_domain_then_user {
    # first see if we can get "user@somedomain"
    my($userNameA, $domainA) = split(/\@/, ${$hashRef->{$a}}[0]);
    my($userNameB, $domainB) = split(/\@/, ${$hashRef->{$b}}[0]);

    # try "somedomain!user"?
    ($userNameA, $domainA) = (split(/!/, ${$hashRef->{$a}}[0]))[-1,-2]
	unless($domainA);
    ($userNameB, $domainB) = (split(/!/, ${$hashRef->{$b}}[0]))[-1,-2]
	unless($domainB);

    # now re-order "mach.host.dom"/"mach.host.do.co" to
    # "host.dom.mach"/"host.do.co.mach"
    $domainA =~ s/^(.*)\.([^\.]+)\.([^\.]{3}|[^\.]{2,3}\.[^\.]{2})$/$2.$3.$1/
	if($domainA);
    $domainB =~ s/^(.*)\.([^\.]+)\.([^\.]{3}|[^\.]{2,3}\.[^\.]{2})$/$2.$3.$1/
	if($domainB);

    # oddly enough, doing this here is marginally faster than doing
    # an "if-else", above.  go figure.
    $domainA = "" unless($domainA);
    $domainB = "" unless($domainB);

    if($domainA lt $domainB) {
	return -1;
    } elsif($domainA gt $domainB) {
	return 1;
    } else {
	# disregard leading bang-path
	$userNameA =~ s/^.*!//;
	$userNameB =~ s/^.*!//;
	if($userNameA lt $userNameB) {
	    return -1;
	} elsif($userNameA gt $userNameB) {
	    return 1;
	} else {
	    if($a lt $b) {
		return -1;
	    } elsif($a gt $b) {
		return 1;
	    }
	}
    }
    return 0;
}

# Subroutine used by host/domain reports to sort by count, then size.
# We "fix" un-initialized values here as well.  Very ugly and un-
# structured to do this here - but it's either that or the callers
# must run through the hashes twice :-(.
#sub by_count_then_size {
#    ${$hashRef->{$a}}[$msgCntI] = 0 unless(${$hashRef->{$a}}[$msgCntI]);
#    ${$hashRef->{$b}}[$msgCntI] = 0 unless(${$hashRef->{$b}}[$msgCntI]);
#    if(${$hashRef->{$a}}[$msgCntI] == ${$hashRef->{$b}}[$msgCntI]) {
#	${$hashRef->{$a}}[$msgSizeI] = 0 unless(${$hashRef->{$a}}[$msgSizeI]);
#	${$hashRef->{$b}}[$msgSizeI] = 0 unless(${$hashRef->{$b}}[$msgSizeI]);
#	return(${$hashRef->{$a}}[$msgSizeI] <=>
#	       ${$hashRef->{$b}}[$msgSizeI]);
#    } else {
#	return(${$hashRef->{$a}}[$msgCntI] <=>
#	       ${$hashRef->{$b}}[$msgCntI]);
#    }
#}

1;

