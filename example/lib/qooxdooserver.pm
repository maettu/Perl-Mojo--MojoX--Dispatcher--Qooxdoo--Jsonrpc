package qooxdooserver;

use strict;
use warnings;

use RpcService::Test;

use base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;
    
    my $services= {
        Test => new RpcService::Test(),
        # more services here
    };
    
    # tell Mojo about your services:
    my $r = $self->routes;
    
    # this sends all requests for "/qooxdoo" in your Mojo server to our little dispatcher
    # change this at your own taste.
    $r->route('/qooxdoo')->to('
        jsonrpc#handle_request', 
        services => $services, 
        namespace => 'MojoX::Dispatcher::Qooxdoo'
    );
    
}

1;
