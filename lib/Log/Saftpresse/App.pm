package Log::Saftpresse::App;

use strict;
use warnings;

# ABSTRACT: commandline interface extension for Log::Saftpresse
# VERSION

use base 'Log::Saftpresse';

use Getopt::Long;

use Log::Saftpresse::Log4perl;

sub print_usage {
	my $self = shift;
	print " usage: $0
	[--config|-c <file>]
	[--log-level|-l <level>]
	[--help|-h]
\n";
	exit 0;
}

sub get_options {
	my $self = shift;
	my %opts;

	GetOptions(
		"help|h" => \$opts{'help'},
		"config|c=s"   => \$opts{'config'},
		"log-level|l=i"   => \$opts{'log_level'},
	) or $self->print_usage;
	if( $opts{'help'} ) {
		$self->print_usage;
	}

	$self->{'_options'} = \%opts;
	return;
}

sub init_with_options {
	my $self = shift;

	$self->get_options;
	if( $self->{_options}->{'config'} ) {
		$self->load_config( $self->{_options}->{'config'} );
	}
	$self->init;
	if( defined $self->{_options}->{'log_level'} ) {
		Log::Saftpresse::Log4perl->level( $self->{_options}->{'log_level'} );
	}

	return;
}

1;

