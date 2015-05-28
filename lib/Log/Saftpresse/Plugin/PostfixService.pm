package Log::Saftpresse::Plugin::PostfixService;

use Moose;

# ABSTRACT: plugin to parse postfix service from program
# VERSION

extends 'Log::Saftpresse::Plugin';

use Time::Piece;

sub process {
	my ( $self, $stash ) = @_;
	my $program = $stash->{'program'};

	if( ! defined $program || $program !~ /^postfix\// ) {
		return;
	}
	
	( $stash->{'service'} ) = $stash->{'program'} =~ /([^\/]+)$/;

	return;
}

1;

