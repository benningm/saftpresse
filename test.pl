#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Log::Saftpresse::Slurp;

my $slurp = Log::Saftpresse::Slurp->new;
$slurp->load_plugin('FileTail', path => '/var/log/mail.log');
#$slurp->load_plugin('FileTail', path => '/var/log/syslog');
#$slurp->load_plugin('FileTail', path => '/var/log/kern.log');
$slurp->load_plugin('Stdin');

for(;;) {
        if( $slurp->can_read(1) ) {
                my $events = $slurp->read_events;
		if( defined $events ) {
			print Dumper( $events );
		}
        }
}

