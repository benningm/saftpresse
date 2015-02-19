package Log::Saftpresse::CountersOutput::Html;

use strict;
use warnings;

# ABSTRACT: plugin to output counters in HTML report
# VERSION

use base 'Log::Saftpresse::CountersOutput';

use Log::Saftpresse::Utils qw( adj_int_units get_smh);

use Time::Piece;
use Template;

use Template::Stash;

$Template::Stash::LIST_OPS->{ type } = sub { return 'list'; };
$Template::Stash::SCALAR_OPS->{ type } = sub { return 'scalar'; };
$Template::Stash::HASH_OPS->{ type } = sub { return 'hash'; };

sub version {
	my $version;
        {
		no strict 'vars'; # is only declared in build
		$version = defined $VERSION ? $VERSION : '(git checkout)';
	}
	return( $version );
}

sub tt {
	my $self = shift;
	if( ! defined $self->{_tt} ) {
		my $tt = Template->new(
			ABSOLUTE => 1,
			EVAL_PERL => 1,
		);

 		my $code = $self->template_content;
		# create a parsed object of our main template
		my $doc = $tt->template( \$code );
		my $blocks = $doc->blocks();
		my $ctx = $tt->context;

		# copy all defined blocks over to the global context
		foreach my $block ( keys %$blocks ) {
			$ctx->define_block( $block, $blocks->{$block} );
		}

		$self->{_tt} = $tt;
	}
	return( $self->{_tt} );
}

sub template_content {
	my $self = shift;
	my $c = '';
	my $h;

	if( defined $self->{'_template_content'}) {
		return( $self->{'_template_content'} );
	}

	if( defined $self->{'template_file'} ) {
		$h = IO::File->new($self->{'template_file'}, 'r')
			or die('error opening output template: '.$!);
	} else {
		$h = IO::Handle->new_from_fd(*DATA,'r')
			or die('error reading default template from __DATA__: '.$!);
	}
	while ( my $line = $h->getline ) {
		$c .= $line;
	}
	$h->close;
	return( $self->{'_template_content'} = $c );
}

sub process {
	my ( $self, $block, %vars ) = @_;
	my $buf;
	$vars{'self'} = $self;
	my $tt = $self->tt;

	# create a wrapper script and execute it
	my $eval = "[% INCLUDE $block -%]\n";
	$tt->process( \$eval, \%vars, \$buf)
		or die( $tt->error );

	return $buf;
}

sub title {
	my $self = shift;
	return( "Postfix log summaries generated on ".Time::Piece->new->ymd );
}

sub output {
	my ( $self, $cnt ) = @_;

	print $self->process('header');
	
	$self->print_totals( $cnt );

	if( defined $cnt->{'PostfixSmtpdStats'} ) {
		$self->print_smtpd_stats( $cnt->{'PostfixSmtpdStats'} );
	}
	$self->print_problems_reports( $cnt );

	if( defined $cnt->{'TlsStatistics'} ) {
		$self->print_tls_stats( $cnt );
	}
	if( defined $cnt->{'PostfixGeoStats'} ) {
		$self->print_geo_stats( $cnt->{'PostfixGeoStats'} );
	}

	print $self->process('footer');

	return;
}

sub print_totals {
	my ( $self, $cnt ) = @_;
	my $reject_cnt = $cnt->{'PostfixRejects'};
	my $recieved_cnt = $cnt->{'PostfixRecieved'};
	my $delivered_cnt = $cnt->{'PostfixDelivered'};
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

	my $sendgUserCnt = $delivered_cnt->get_key_count('recieved', 'by_sender');
	my $sendgDomCnt = $delivered_cnt->get_key_count('recieved', 'by_domain'); 
	my $recipUserCnt =$delivered_cnt->get_key_count('sent', 'by_rcpt');
	my $recipDomCnt = $delivered_cnt->get_key_count('sent', 'by_domain');

	my $msgsTotal = $msgsDlvrd + $msgsRjctd + $msgsDscrdd;

	print $self->headline(1, 'Grand Totals');

	print $self->key_value_table( "Messages", [
		[ 'Received', $msgsRcvd ],
		[ 'Delivered', $msgsDlvrd ],
		[ 'Forwarded', $msgsFwdd ],
		[ 'Deferred', $msgsDfrd ],
	] );

	print $self->key_value_table( "Rejects", [
		[ 'Bounced', $msgsBncd ],
		[ 'Rejected', $msgsRjctd, 'count', $msgsTotal ],
		[ 'Rejected Warnings', $msgsWrnd ],
		[ 'Held', $msgsHld ],
		[ 'discarded', $msgsDscrdd, 'count', $msgsTotal ],
	] );

	print $self->key_value_table( "Traffic Volume", [
		[ 'Bytes recieved', $sizeRcvd, 'byte' ],
		[ 'Bytes delivered', $sizeDlvrd, 'byte' ],
		[ 'Senders', $sendgUserCnt ],
		[ 'Sending hosts/domains', $sendgDomCnt ],
		[ 'Recipients', $recipUserCnt ],
		[ 'Recipients hosts/domains', $recipDomCnt ],
	] );

	return;
}

sub print_smtpd_stats {
	my ( $self, $cnt ) = @_;
	my $connections = $cnt->get_value_or_zero('total');
	my $hosts_domains = int(keys %{$cnt->get_node('per_domain')});
	my $avg_conn_time = $connections > 0 ?
		($cnt->get_value_or_zero('busy', 'total')
			/ $connections ) + .5 : 0;
	my $total_conn_time = $cnt->get_value_or_zero('busy', 'total');

	print $self->headline(1, 'Smtpd Statistics');

	print $self->key_value_table( "Connections", [
		[ 'Connections', $connections ],
		[ 'Hosts/domains', $hosts_domains ],
		[ 'Avg. connect time', $avg_conn_time ],
		[ 'total connect time', $total_conn_time, 'interval' ],
	] );
	return;
}

sub print_geo_stats {
	my ( $self, $cnt ) = @_;
	my $client = $cnt->get_node('client');
	if( defined $client ) {
    		print $self->hash_top_values(
			$client,
			title => 'Client Countries',
			count => 0,
			legend => 'Country',
		);
	}
	return;
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

	print $self->headline(1, "TLS Statistics");

	print $self->key_value_table( "Total", [
		[ 'Incoming TLS connections',
			$tls_cnt->get('smtpd', 'connections', 'total'),
			'count', $smtpdConnCnt ],
		[ 'Incoming TLS messages',
			$tls_cnt->get('smtpd', 'messages', 'total'),
			'count', $msgs_rcvd ],
		[ 'Outgoing TLS connections',
			$tls_cnt->get('smtp', 'connections', 'total'),
			'count', $smtpdConnCnt ],
		[ 'Outgoing TLS messages',
			$tls_cnt->get('smtp', 'messages', 'total'),
			'count', $msgs_sent ],
	] );

	my @tls_statistics = (
		[ "Incoming TLS trust-level" => 'trust-level',
			$smtpdConnCnt, 'smtpd', 'connections', 'level' ],
		[ "Outgoing TLS trust-level" => 'trust-level',
			0, 'smtp', 'connections', 'level' ],
		[ "Incoming TLS Protocol Version" => 'protocol version',
			$smtpdConnCnt, 'smtpd', 'connections', 'protocol' ],
		[ "Outgoing TLS Protocol Version" => 'protocol version',
			0, 'smtp', 'connections', 'protocol' ],
		[ "Incoming TLS key length" => 'key length',
			$smtpdConnCnt, 'smtpd', 'connections', 'keylen' ],
		[ "Outgoing TLS key length" => 'key length',
			0, 'smtp', 'connections', 'keylen' ],
		[ "Incoming TLS Ciphers" => 'cipher',
			$smtpdConnCnt, 'smtpd', 'connections', 'cipher' ],
		[ "Outgoing TLS Ciphers" => 'cipher',
			0, 'smtp', 'connections', 'cipher' ],
	);

	foreach my $tls_stat ( @tls_statistics ) {
		my ( $title, $legend, $total, @node ) = @$tls_stat;
		my $values = $tls_cnt->get_node(@node);
		if( ! defined $values ) { next; }
		print $self->hash_top_values( $values,
			title => $title,
			total => $total,
			legend => $legend,
		);
	}
}

sub print_problems_reports {
	my ( $self, $cnt ) = @_;

	my $delivered_cnt = $cnt->{'PostfixDelivered'};
	my $reject_cnt = $cnt->{'PostfixRejects'};

	if($self->{'deferral_detail'} != 0) {
		print $self->nested_top_values(
			$delivered_cnt->get_node('deferred'),
			title => "message deferral detail",
			count => $self->{'deferral_detail'} );
	}
	if($self->{'bounce_detail'} != 0) {
		print $self->nested_top_values(
			$delivered_cnt->get_node('bounced'),
			title => "message bounce detail (by relay)",
			count => $self->{'bounce_detail'} );
	}
	if($self->{'reject_detail'} != 0) {
		foreach my $key ( 'reject', 'warning', 'hold', 'discard') {
			print $self->nested_top_values(
				$reject_cnt->get_node($key),
				title => "message $key detail",
				count => $self->{'reject_detail'} );
		}
	}

	if( my $smtp_cnt = $cnt->{'PostfixSmtp'} ) {
		my $messages = $smtp_cnt->get_node('messages');
		if( defined $messages ) {
			print $self->nested_top_values($messages,
				title => "smtp delivery failures",
				count => $self->{'smtp_detail'} );
		}
	}
	if( my $msg_cnt =  $cnt->{'PostfixMessages'} ) {
		if($self->{'smtpd_warn_detail'} != 0) {
			print $self->nested_top_values(
				$msg_cnt->get_node('warning'),
				title => "Warnings",
				count => $self->{'smtpd_warn_detail'} );
		}
		print $self->nested_top_values(
			$msg_cnt->get_node('fatal'),
			title => "Fatal Errors" );
		print $self->nested_top_values(
			$msg_cnt->get_node('panic'),
			title => "Panics" );
		print $self->hash_top_values($msg_cnt->get_node('master'),
			title => "Master daemon messages",
			legend => 'Message',
		);
	}
}

sub get_element_id {
	my $self = shift;
	if( ! defined $self->{_cur_element_id} ) {
		$self->{_cur_element_id} = 1;
	}
	return $self->{_cur_element_id}++;
}

sub headline {
	my ( $self, $level, $title ) = @_;
	if( ! defined $self->{'_headlines'} ) {
		$self->{'_headlines'} = [];
	}
	my $cur = $self->{'_headlines'};
	my $cur_level = 1;
	my $id = 'title-'.$self->get_element_id;
	while( $cur_level < $level ) {
		if( scalar(@$cur) == 0 || ref($cur->[-1]) ne 'ARRAY' ) {
			push(@$cur, []);
		}
		$cur = $cur->[-1];
		$cur_level++;
	}
	my %headline = (
		title => $title,
		id => $id,
		level => $level,
	);
	push(@$cur, \%headline );
	return $self->process('headline', %headline );
}

sub navigation {
	my ( $self, $depth ) = @_;
	return $self->process('navigation',
		nav => $self->{_headlines},
		depth => $depth,
	);
	return;
}

sub nested_top_values {
	my ( $self, $hash ) = ( shift, shift );
	my %args = (
		'count' => 0,
		'unit' => 'count',
		'legend' => '',
		@_,
	);
	if( ! defined $hash) { return ''; }
	
	return $self->process('nested_values_table',
		%args,
		'data' => $hash,
	);
}

sub hash_top_values {
	my ( $self, $hash ) = ( shift, shift );
	my %args = (
		'count' => 0,
		'unit' => 'count',
		'legend' => '',
		'total' => 0,
		@_,
	);
	if( ! defined $hash) { return ''; }

	my @data = sort { $b->[0] <=> $a->[0] || $b->[1] cmp $a->[1] }
		map { [ $hash->{$_} => $_ ] } keys %$hash;

	return $self->process('top_values_table',
		%args,
		'data' => \@data,
	);
}

sub key_value_table {
	my ( $self, $name, $data ) = @_;
	return $self->process('key_value_table',
		'name' => $name,
		'data' => $data,
	);
}


1;

__DATA__
[% BLOCK header -%]
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="[% self.title %]">

    <title>[% self.title %]</title>

    <link rel="stylesheet" href="https://markusbenning.de/js/bootstrap.min.css" />
    <link rel="stylesheet" href="https://markusbenning.de/js/bootstrap-theme.min.css" />
    <script src="https://markusbenning.de/js/jquery.min.js"></script>
    <script src="https://markusbenning.de/js/bootstrap.min.js"></script>
    <script src="https://markusbenning.de/js/numeral.min.js"></script>
    <script>
    $( document ).ready(function() {
      $("span.unit-count").each( function( index ) {
      	$( this ).html( numeral( $(this).text() ).format('0,0') );
      });
      $("span.unit-byte").each(function( index ) {
      	$( this ).html( numeral( $(this).text() ).format('0 b') );
      });
      $("span.unit-percent").each(function( index ) {
      	$( this ).html( numeral( $(this).text() ).format('0.00%') );
      });
      $("span.unit-interval").each(function( index ) {
      	$( this ).html( numeral( $(this).text() ).format('00:00:00') );
      });
    });
    </script>
  </head>

  <body>

    <nav class="navbar navbar-inverse">
      <div class="container-fluid">
        <div class="navbar-header">
          <a class="navbar-brand" href="#">Postfix Statistics</a>
        </div>
        <div id="navbar" class="navbar-collapse collapse">
          <ul class="nav navbar-nav navbar-right">
            <li><a href="https://markusbenning.de/">saftpresse</a></li>
          </ul>
        </div>
      </div>
    </nav>

    <div class="container-fluid">
      <div class="row">
        <div class="col-md-10 col-md-push-2 main">
	  <h1>[% self.title %]</h1>
	  <p class="lead">generated by saftpresse [% self.version %] log file analyzer</p>
[% END -%]

[% BLOCK footer %]
        </div>
        [% self.navigation(2) %]
      </div>
    </div> <!-- /container -->


  </body>
</html>
[% END %]

[% BLOCK navigation %]
<div class="col-md-2 col-md-pull-10 sidebar">
  <ul class="nav nav-sidebar nav-stacked">
    [% INCLUDE nav_element nav=nav level=1 depth=depth %]
  </ul>
</div>
[% END %]

[% BLOCK nav_element %]
[% FOREACH element = nav -%]
[% IF element.type == 'list' -%]
    [% IF level < depth -%]
    <li><ul class="nav">
    [% INCLUDE nav_element nav=element level=level+1 depth=depth %]
    </ul></li>
    [% END %]
[% ELSE -%]
    <li><a href="#[% element.id %]">[% element.title %]</a></li>
[% END -%]
[% END -%]
[% END %]

[% BLOCK headline %]
<h[% level + 1 %] id="[% id %]">[% title %]</h[% level + 1 %]>
[% END %]

[% BLOCK key_value_table %]
[% self.headline( 2, name ) %]
<table class="table table-striped table-hover">
<thead>
  <tr>
    <th class="col-md-3">Key</th>
    <th>Value</th>
  </tr>
</thead>
<tbody>
[% FOREACH row = data -%]
  <tr>
    <td>[% row.shift %]</td>
    <td>[% INCLUDE format_unit format=row %]</td>
  </tr>
[% END -%]
</tbody>
</table>
[% END %]

[% BLOCK format_unit %]
[% value = format.0; type = format.1 -%]
[% IF ! type ; type = 'count' ; END -%]
[% IF format.2 -%]
[% total = format.2 ; percent = value / total; -%]
<span class="unit-[% type %]">[% value %]</span>
(<span class="unit-percent">[% percent %]</span> of <span class="unit-[% type %]">[% total %]</span>)
[% ELSE -%]
<span class="unit-[% type %]">[% value %]</span>
[% END -%]
[% END %]

[% BLOCK top_values_table %]
[% IF title ; self.headline( 2, title ) ; END -%]
<table class="table table-striped table-hover[% IF compact %] table-condensed[% END %]">
<thead>
  <tr>
    <th class="col-md-3">Count</th>
    <th>[% legend %]</th>
  </tr>
</thead>
<tbody>
[% FOREACH row = data -%]
  <tr>
    <td>[% INCLUDE format_unit format=[ row.0, unit, total ] %]</td>
    <td>[% row.1 %]</td>
  </tr>
[% END -%]
</tbody>
</table>
[% END %]

[% BLOCK nested_values_table %]
[% self.headline( 2, title ) %]
[% FOREACH section = data -%]
[% IF title ; self.headline( 3, section.key ) ; END %]
<div class="panel-group">
[% FOREACH panel = section.value -%]
<div class="panel panel-default">
<div class="panel-heading">[% panel.key %]</div>
<div class="panel-body">
[% IF panel.value.values.0.type == 'scalar' -%]
[% self.hash_top_values(panel.value, 'title', '', 'compact', 1) -%]
[% ELSE -%]
[% INCLUDE nested_values_table data=panel.value title=undef -%]
[% END -%]
</div>
</div>
[% END %]
</div>
[% END %]
[% END %]
