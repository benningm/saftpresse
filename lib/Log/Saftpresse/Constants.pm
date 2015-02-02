package Log::Saftpresse::Constants;

use strict;
use warnings;

# ABSTRACT: class to hold the constants used in pflogsumm
# VERSION

our (@ISA, @EXPORT);

our ($divByOneKAt, $divByOneMegAt, $oneK, $oneMeg);
our (@monthNames, %monthNums, $thisMon, $thisYr);

BEGIN {
	require Exporter;

	# Some constants used by display routines.  I arbitrarily chose to
	# display in kilobytes and megabytes at the 512k and 512m boundaries,
	# respectively.  Season to taste.
	$divByOneKAt   = 524288;	# 512k
	$divByOneMegAt = 536870912;	# 512m
	$oneK          = 1024;		# 1k
	$oneMeg        = 1048576;	# 1m

	# Constants used throughout pflogsumm
	@monthNames = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	%monthNums = qw(
	    Jan  0 Feb  1 Mar  2 Apr  3 May  4 Jun  5
	    Jul  6 Aug  7 Sep  8 Oct  9 Nov 10 Dec 11);
	($thisMon, $thisYr) = (localtime(time()))[4,5];
	$thisYr += 1900;

	@ISA = qw(Exporter);
	@EXPORT = qw(
		$divByOneKAt $divByOneMegAt $oneK $oneMeg
		@monthNames %monthNums $thisMon $thisYr
	);
}


1;

