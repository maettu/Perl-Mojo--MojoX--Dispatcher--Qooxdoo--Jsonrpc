package Mojolicious::Plugin::QooxdooJsonrpc;
use Mojo::Base 'Mojolicious::Plugin';

# the dispatcher module gets autoloaded, we list it here to
# make sure it is available and compiles at startup time and not
# only on demand.
use MojoX::Dispatcher::Qooxdoo::Jsonrpc;

sub register {
    my ($self, $app, $conf) = @_;

    # Config
    $conf ||= {};
    my $services = $conf->{services};
    my $path = $conf->{path} || '/jsonrpc';
    my $qx_app_src = $conf->{qx_app_src} || $app->home->rel_dir('../frontend');
    my $r = $app->routes;

    if ($app->mode eq 'development'){
        $r->route('/source'.$path)->to(
            class       => 'Jsonrpc',
            method      => 'dispatch',
            namespace   => 'MojoX::Dispatcher::Qooxdoo',        
            # our own properties
            services    => $services,        
            debug       => 1,        
        );

        $r->get( '/source/' => sub { shift->redirect_to('/source/index.html') });

        # relative path

        my $rel_static = Mojolicious::Static->new();
        $rel_static->root($qx_app_src);
        my $rel_static_cb = sub {
                my $self = shift;
                return $rel_static->dispatch($self);
        };
        $r->route('/source/(*b)')->to( cb => $rel_static_cb );
        $r->route('/(.a)/framework/source/(*b)')->to( cb => $rel_static_cb );
        $r->route('/(.a)/downloads/(*b)/source/(*c)')->to( cb => $rel_static_cb );

        # absolute source path

        my $abs_static = Mojolicious::Static->new();
        $abs_static->root('/');
        my $abs_static_cb = sub {
            my $self = shift;
            return $abs_static->dispatch($self);
        };
        $r->route('/(.a)/(*b)/framework/source/(*c)')->to( cb => $abs_static_cb );
        $r->route('/(.a)/(*b)/downloads/(*b)/source/(*c)')->to( cb => $abs_static_cb );

    };
    $r->route($path)->to(
        class       => 'Jsonrpc',
        method      => 'dispatch',
        namespace   => 'MojoX::Dispatcher::Qooxdoo',        
        # our own properties
        services    => $services
    );

    $r->get( '/' => sub { shift->redirect_to('/index.html') });

}

1;

__END__

=head1 NAME

Mojolicious::Plugin::QooxdooJsonrpc - handle qooxdoo Jsonrpc requests

=head1 SYNOPSIS

 # lib/your-application.pm

 use base 'Mojolicious';
 use RpcService;
 
 sub startup {
    my $self = shift;
       
    $self->plugin('qooxdoo_json_rpc',{
        services => {
            Test => RpcService->new(),
        },
    });
 }


=head1 DESCRIPTION

This plugin installs the L<MojoX::Dispatcher::Qooxdoo::Jsonrpc> dispatcher into your application.
It has the ability to serve both a compiled as well the source version of the application.
See the documentation on L<MojoX::Dispatcher::Qooxdoo::Jsonrpc> for details on how to write
your service. The plugin understands the following parameters

=over

=item B<services> (mandatory)

A pointer to a hash of service instances. See L<MojoX::Dispatcher::Qooxdoo::Jsonrpc> for details on how
to write a service.

=item B<path> (default: /jsonrpc)

If your application expects the JsonRPC service to appear under a different url.

=item B<qx_app_root> (default: the F<../frontend>)

When the mojo application is running in development mode, provide access to the source version
of the qooxdoo application under the F</source> url. By default it is expected to reside in
a directory called F<frontend> sitting next to the mojo application directory.

=back

=head1 AUTHOR

S<Tobias Oetiker, E<lt>tobi@oetiker.chE<gt>>

=head1 COPYRIGHT

Copyright OETIKER+PARTNER AG 2010

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
