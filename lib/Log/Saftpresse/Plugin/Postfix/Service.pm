package Log::Saftpresse::Plugin::Postfix::Service;

use Moose::Role;

# ABSTRACT: plugin to parse postfix service
# VERSION

sub process_service {
	my ( $self, $stash ) = @_;
	my $program = $stash->{'program'};

	( $stash->{'service'} ) = $stash->{'program'} =~ /([^\/]+)$/;

	return;
}

1;

