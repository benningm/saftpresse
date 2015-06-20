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
	@EXPORT_OK = qw( &adj_int_units &adj_time_units &get_smh );
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

1;

