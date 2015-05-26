package Log::Saftpresse::Plugin::LimitProgram;

use Moose;

# ABSTRACT: plugin to limit messages by syslog program name
# VERSION

extends 'Log::Saftpresse::Plugin';

has 'regex' => ( is => 'rw', isa => 'Str', required => 1 );

sub process {
	my ( $self, $stash ) = @_;
	my $regex = $self->regex;

	if( ! defined $stash->{'program'} ) {
		return;
	}
	if( $stash->{'program'} !~ /$regex/ ) {
		return('next');
	}
	
	return;
}

1;

