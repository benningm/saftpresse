package Log::Saftpresse::App;

use Moose;

# ABSTRACT: commandline interface extension for Log::Saftpresse
# VERSION

extends 'Log::Saftpresse';

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

has 'options' => (
	is => 'rw', isa => 'HashRef',
	default => sub {
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

		return \%opts;
	},
);

sub init_with_options {
	my $self = shift;

	if( $self->options->{'config'} ) {
		$self->load_config( $self->options->{'config'} );
	}
	$self->init;
	if( defined $self->options->{'log_level'} ) {
		Log::Saftpresse::Log4perl->level( $self->options->{'log_level'} );
	}

	return;
}

1;

