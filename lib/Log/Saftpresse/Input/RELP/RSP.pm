package Log::Saftpresse::Input::RELP::RSP;

use Moose;

# VERSION
# ABSTRACT: class for building RELP RSP records

has 'code' => ( is => 'rw', isa => 'Int', required => 1 );
has 'message' => ( is => 'rw', isa => 'Str', required => 1 );
has 'data' => ( is => 'rw', isa => 'Str', default => '' );

sub as_string {
	my $self = shift;
	return join(' ', $self->code, $self->message)."\n".$self->data;
}

1;

