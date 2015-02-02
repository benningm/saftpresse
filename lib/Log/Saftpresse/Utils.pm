package Log::Saftpresse::Utils;

use strict;
use warnings;

# ABSTRACT: class with collection of some utility functions
# VERSION

use Log::Saftpresse::Constants;

our (@ISA, @EXPORT_OK);

BEGIN {
	require Exporter;

	@ISA = qw(Exporter);
	@EXPORT_OK = qw(
		&string_trimmer &said_string_trimmer
		&adj_int_units &adj_time_units &get_smh
		&gimme_domain &postfix_remote &msg_warn &verp_mung
	);
}

# Trim a "said:" string, if necessary.  Add elipses to show it.
# FIXME: This sometimes elides The Wrong Bits, yielding
#        summaries that are less useful than they could be.
sub said_string_trimmer {
    my($trimmedString, $maxLen) = @_;

    while(length($trimmedString) > $maxLen) {
        if($trimmedString =~ /^.* said: /) {
            $trimmedString =~ s/^.* said: //;
        } elsif($trimmedString =~ /^.*: */) {
            $trimmedString =~ s/^.*?: *//;
        } else {
            $trimmedString = substr($trimmedString, 0, $maxLen - 3) . "...";
            last;
        }
    }

    return $trimmedString;
}

# Trim a string, if necessary.  Add elipses to show it.
sub string_trimmer {
    my($trimmedString, $maxLen, $doNotTrim) = @_;

    $trimmedString = substr($trimmedString, 0, $maxLen - 3) . "..."
        if(! $doNotTrim && (length($trimmedString) > $maxLen));
    return $trimmedString;
}

# Return (value, units) for integer
sub adj_int_units {
    my $value = $_[0];
    my $units = ' ';
    $value = 0 unless($value);
    if($value > $divByOneMegAt) {
        $value /= $oneMeg;
        $units = 'm'
    } elsif($value > $divByOneKAt) {
        $value /= $oneK;
        $units = 'k'
    }
    return($value, $units);
}

# Return (value, units) for time
sub adj_time_units {
    my $value = $_[0];
    my $units = 's';
    $value = 0 unless($value);
    if($value > 3600) {
        $value /= 3600;
        $units = 'h'
    } elsif($value > 60) {
        $value /= 60;
        $units = 'm'
    }
    return($value, $units);
}

# Get seconds, minutes and hours from seconds
sub get_smh {
    my $sec = shift @_;
    my $hr = int($sec / 3600);
    $sec -= $hr * 3600;
    my $min = int($sec / 60);
    $sec -= $min * 60;
    return($sec, $min, $hr);
}

# if there's a real domain: uses that.  Otherwise uses the IP addr.
# Lower-cases returned domain name.
#
# Optional bit of code elides the last octet of an IPv4 address.
# (In case one wants to assume an IPv4 addr. is a dialup or other
# dynamic IP address in a /24.)
# Does nothing interesting with IPv6 addresses.
# FIXME: I think the IPv6 address parsing may be weak

sub postfix_remote {
    $_ = $_[0];
    my($domain, $ipAddr);

    # split domain/ipaddr into separates
    # newer versions of Postfix have them "dom.ain[i.p.add.ress]"
    # older versions of Postfix have them "dom.ain/i.p.add.ress"
    unless((($domain, $ipAddr) = /^([^\[]+)\[((?:\d{1,3}\.){3}\d{1,3})\]/) == 2 ||
           (($domain, $ipAddr) = /^([^\/]+)\/([0-9a-f.:]+)/i) == 2) {
        # more exhaustive method
        ($domain, $ipAddr) = /^([^\[\(\/]+)[\[\(\/]([^\]\)]+)[\]\)]?:?\s*$/;
    }

    # "mach.host.dom"/"mach.host.do.co" to "host.dom"/"host.do.co"
    if($domain eq 'unknown') {
        $domain = $ipAddr;
        # For identifying the host part on a Class C network (commonly
        # seen with dial-ups) the following is handy.
        # $domain =~ s/\.\d+$//;
    } else {
        $domain =~
            s/^(.*)\.([^\.]+)\.([^\.]{3}|[^\.]{2,3}\.[^\.]{2})$/\L$2.$3/;
    }

    return($domain, $ipAddr);
}
*gimme_domain = \&postfix_remote;

# Emit warning message to stderr (unused?)
sub msg_warn {
	warn "warning: $0: $_[0]\n";
}

# Hack for VERP (?) - convert address from somthing like
# "list-return-36-someuser=someplace.com@lists.domain.com"
# to "list-return-ID-someuser=someplace.com@lists.domain.com"
# to prevent per-user listing "pollution."  More aggressive
# munging converts to something like
# "list-return@lists.domain.com"  (Instead of "return," there
# may be numeric list name/id, "warn", "error", etc.?)
sub verp_mung {
    my ( $level, $addr )= @_;

    if( $level ) {
	    $addr =~ s/((?:bounce[ds]?|no(?:list|reply|response)|return|sentto|\d+).*?)(?:[\+_\.\*-]\d+\b)+/$1-ID/i;
	    if($level > 1) {
		$addr =~ s/[\*-](\d+[\*-])?[^=\*-]+[=\*][^\@]+\@/\@/;
	    }
    }

    return $addr;
}

1;

