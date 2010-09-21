package qooxdooserver;

use strict;
use warnings;

 use RpcService::Test;
 
 sub startup {
    my $self = shift;
    
    # instantiate all services
    my $services= {
        Test => new RpcService::Test(),
        
    };
    
    
    # add a route to the Qooxdoo dispatcher and route to it
    my $r = $self->routes;
    $r->route('/qooxdoo') ->
            to('
                Jsonrpc#handle_request', 
                services => $services, 
                namespace => 'MojoX::Dispatcher::Qooxdoo'
            );
        
 }

1;