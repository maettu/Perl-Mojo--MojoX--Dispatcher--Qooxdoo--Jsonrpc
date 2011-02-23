package MojoX::Dispatcher::Qooxdoo::Jsonrpc;

use strict;
use warnings;

use Mojo::JSON;
use base 'Mojolicious::Controller';

our $VERSION = '0.56';

sub dispatch {
    my $self = shift;
    
    my ($id, $cross_domain, $data, $reply, $error);
    
    my $debug = $self->stash('debug');

    # instantiate a JSON encoder - decoder object.
    my $json = Mojo::JSON->new;
    
    # We have to differentiate between POST and GET requests, because
    # the data is not sent in the same place..
    
    # non cross domain POST calls. 
    if ($self->req->method eq 'POST'){
        # Data comes as JSON object, so fetch a reference to it
        $data           = $json->decode($self->req->body);
        $id             = $data->{id};
        $cross_domain   = 0;
    }
    
    # cross-domain GET requests
    elsif ($self->req->method eq 'GET'){
        $data= $json->decode(
            $self->param('_ScriptTransport_data')
        );
        $id = $self->param('_ScriptTransport_id') ;
        $cross_domain   = 1;
    }
    else{
        print "wrong request method: ".$self->req->method."\n" if $debug;
        
        # I don't know any method to send a reply to qooxdoo if it doesn't 
        # send POST or GET 
        # return will simply generate a 
        # "Transport error 0: Unknown status code" in qooxdoo
        return;
    }
        
    if (not defined $id){
        $self->app->log->fatal("This is not a JsonRPC request.");
        return;
    }

    # Getting available services from stash
    my $services = $self->stash('services');

    # Check if desired service is available
    my $package = $data->{service};

    # Check if method is not private (marked with a leading underscore)
    my $method = $data->{method};
    
    my @params  = @{$data->{params}}; # is a reference, so "unpack" it
        
    # invocation of method in class according to request 
    eval{
        # make sure there are not foreign signal handlers
        # messing with our problems
        local $SIG{__DIE__};
        my $svc = $services->{$package};

        die {
            origin => 1,
            message => "service $package not available",
            code=> 3
        } if not ref $svc;

        die {
             origin => 1, 
             message => "your rpc service object (".ref($svc).") must provide an allow_rpc_access method", 
             code=> 2
        } unless $svc->can('allow_rpc_access');

        
        if ($svc->can('mojo_session')){
            # initialize session if it does not exists yet
            my $session = $self->stash->{'mojo.session'} ||= {};
            $svc->mojo_session($session);
        }

        if ($svc->can('mojo_stash')){
            # initialize session if it does not exists yet
            $svc->mojo_stash($self->stash);
        }

        die {
             origin => 1, 
             message => "rpc access to method $method denied", 
             code=> 2
        } unless $svc->allow_rpc_access($method);

        die {
             origin => 1, 
             message => "method $method does not exist.", 
             code=> 2
        } if not $svc->can($method);

        no strict 'refs';
        $reply = $svc->$method(@params);
    };
       
    if ($@){ 
        my $error;
        for (ref $@){
            /HASH/ && $@->{message} && do {
                $error = {
                     origin => $@->{origin} || 2, 
                     message => $@->{message}, 
                     code=>$@->{code}
                };
                last;
            };
            /.+/ && $@->can('message') && $@->can('code') && do {
                $error = {
                      origin => 2, 
                      message => $@->message(), 
                      code=>$@->code()
                };
                last;
            };
            $error = {
                origin => 2, 
                message => "error while processing ${package}::$method: $@", 
                code=> '9999'
            };
        }
        $reply = $json->encode({ id => $id, error => $error });
        $self->app->log->fatal("JsonRPC Error $error->{code}: $error->{message}");
    }
    else {
        $reply = $json->encode({ id => $id, result => $reply });
    }

    if ($cross_domain){
        # for GET requests, qooxdoo expects us to send a javascript method
        # and to wrap our json a litte bit more
        $self->res->headers->content_type('application/javascript');
        $reply = "qx.io.remote.transport.Script._requestFinished( $id, " . $reply . ");";
    }    
    $self->render(text => $reply);
}

1;



=head1 NAME

MojoX::Dispatcher::Qooxdoo::Jsonrpc - Dispatcher for Qooxdoo Json Rpc Calls

=head1 SYNOPSIS

 # lib/your-application.pm

 use base 'Mojolicious';
 
 use RpcService;

 sub startup {
    my $self = shift;
    
    # instantiate all services
    my $services= {
        Test => RpcService->new(),
        
    };
    
    
    # add a route to the Qooxdoo dispatcher and route to it
    my $r = $self->routes;
    $r->route('/qooxdoo') -> to(
                'Jsonrpc#dispatch', 
                services    => $services, 
                debug       => 0,
                namespace   => 'MojoX::Dispatcher::Qooxdoo'
            );
        
 }

    

=head1 DESCRIPTION

L<MojoX::Dispatcher::Qooxdoo::Jsonrpc> dispatches incoming
rpc requests from a qooxdoo application to your services and renders
a (hopefully) valid json reply.


=head1 EXAMPLE 

This example exposes a service named "Test" in a folder "RpcService".
The Mojo application is named "QooxdooServer". The scripts are in
the 'example' directory.
First create this application using 
"mojolicious generate app QooxdooServer".

Then, lets write the service:

Change to the root directory "qooxdoo_server" of your fresh 
Mojo-Application and make a dir named 'qooxdoo-services' 
for the services you want to expose.

Our "Test"-service could look like:

 package RpcService;

 use Mojo::Base -base;

 # if this attribute is created it will hold the mojo cookie session hash
 # it is a hash pointer use it to store little bits of session information
 # the session is signed and written into a browser cookie.
 has 'mojo_session';

 # if this attribute exists it will provide access to the mojo stash
 # the mojo stash holds all sorts of information on the actual request
 has 'mojo_stash';
 
 # MANDADROY access check method. The method is called right before the actual
 # method call, after assigning mojo_session and mojo_stash properties are set.
 # These can be used for providing dynamic access control

 our %access = (
    add => 1,
 );

 sub allow_rpc_access {
    my $self = shift;
    my $method = shift;          
    # check if we can access
    return $access{$method};
 }

 sub add{
    my $self = shift;
    my @params = @_;
    
    # Debug message on Mojo-server console (or log)
    print "Debug: $params[0] + $params[1]\n";
    
    # uncomment if you want to die without further handling
    # die;
    
    # uncomment if you want to die with a message in a hash
    # die {code => 20, message => "Test died on purpose :-)"};
    
    
    # uncomment if you want to die with your homemade error object 
    # (simple example see below)
   
    # use Error;
    # my $error = new Error('stupid error message', '56457');
    # die $error;
    
    my $result =  $params[0] + $params[1]
    return $result;    
 }

 1;
 
 
 # Example of simple Error object class:
 
 package Error;

 sub new{
    my $class = shift;
    
    my $error = {
        message => shift;
        code    => shift;
    };
    
    bless $error, $class;
    return $error;
 }

 sub message{
    my $self = shift;
    return $self->{message};
 }

 sub code{
    my $self = shift;
    return $self->{code};
 }

1;

Please create a constructor (like "new" here) which instantiates
an object because we are going to use this in
our 'lib/QooxdooServer.pm' below.

Notice the exception handling: You can die without or with a message 
(see example above). 
MojoX::Dispatcher::Qooxdoo::Jsonrpc will catch the "die" like an 
exception an send a message to the client.
Happy dying! :-)


Now, lets write our application.
Almost everything should have been prepared by Mojo when you invoked 
"mojolicious generate app QooxdooServer" (see above).

Change to "lib/" and open "QooxdooServer.pm" in your favourite editor.
Then add some lines to make it look like this:

 package QooxdooServer;

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
    
    # this sends all requests for "/qooxdoo" in your Mojo server 
    # to our little dispatcher.
    # change this at your own taste.
    $r->route('/qooxdoo')->to('
        jsonrpc#dispatch', 
        services    => $services, 
        debug       => 0,
        namespace   => 'MojoX::Dispatcher::Qooxdoo'
    );
    
 }

 1;

Now start your Mojo Server by issuing 'script/QooxdooServer daemon'. 
If you want to change any options, type 'script/QooxdooServer help'. 

=head2 Security

MojoX::Dispatcher::Qooxdoo::Jsonrpc calls the allow_rpc_access
method to check if rpc access should be allowed. The result of this
request is NOT cached, so you can use this method to provide dynamic access control
or even do initialization tasks that are required before handling each request.

=head1 AUTHOR

S<Matthias Bloch, E<lt>matthias@puffin.chE<gt>>,
S<Tobias Oetiker, E<lt>tobi@oetiker.chE<gt>>.

This Module is sponsored by OETIKER+PARTNER AG

=head1 COPYRIGHT

Copyright (C) 2010 by :m)

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
