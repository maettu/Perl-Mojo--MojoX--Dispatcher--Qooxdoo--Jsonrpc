package JsonRpcService;
use strict;
use Mojo::Base -base;

=head1 NAME

JsonRpcService - RPC services for Qooxdoo

=head1 SYNOPSIS

This module gets instanciated by L<ep::MojoApp> and provides backend functionality for your qooxdoo app

=head1 DESCRIPTION

All methods on this class can get called remotely as long as their name does not start with an underscore.

=head2 new()

Create a service object.

=cut 

sub new {
    my $self = shift->SUPER::new(@_);
    # do some other interesting initialization work
    return $self;
}

=head2 allow_rpc_access

check it this method may be called

=cut

our %allow_access =  (
    echo => 1
);

sub allow_rpc_access {
    my $self = shift;
    my $method = shift;
    return $allow_access{$method};
}

=head2 echo(var)

return the string we input

=cut  

sub echo {
    my $self = shift;
    my $arg = shift;
    return $arg;
}

1;
__END__
=head1 COPYRIGHT

Public Domain

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY 

 2011-01-25 to Initial

=cut
  
1;

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4 et
