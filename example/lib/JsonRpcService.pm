package RpcService::Test;

sub new{
    my $class = shift;
    
    my $object = {
        
    };
    bless $object, $class;
    return $object;
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
    # better use your elaborate error handling instead!
    
    # require Error;
    # my $error = new Error();
    # die $error;
    
    my $result =  $params[0] + $params[1]
    return $result;
    
}

1;
 
 
# Example of simple and stupid Error class:
 
package Error;

 sub new{
    my $class = shift;
    
    my $error = {};
    
    bless $error, $class;
    return $error;
}

sub message{
    return "stupid error message";
}

sub code{
    return "934857"; # no real error code here
}
