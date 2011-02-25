use Test::More tests => 23;
use Test::Mojo;

use FindBin;
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/../example/lib';

use_ok 'MojoX::Dispatcher::Qooxdoo::Jsonrpc';
use_ok 'MojoApp';

my $t = Test::Mojo->new(app => 'MojoApp');

$t->post_ok('/jsonrpc','x')
  ->content_like(qr/This is not a JsonRPC request/,'Bad Request')
  ->status_is(500,'Internal Error');

$t->post_ok('/jsonrpc','{"id":1,"method":"test"}')
  ->content_like(qr/Missing service property/,'Missing service property');

$t->post_ok('/jsonrpc','{"id":1,"service":"test"}')
  ->content_like(qr/Missing method property/, 'Missing method property');

$t->post_ok('/jsonrpc','{"id":1,"service":"test","method":"test"}')
  ->json_content_is({error=>{origin=>1,code=>3,message=>"service test not available"},id=>1})
  ->content_type_is('application/json')
  ->status_is(200);

$t->post_ok('/jsonrpc','{"id":1,"service":"rpc","method":"test"}')
  ->json_content_is({error=>{origin=>1,code=>2,message=>"rpc access to method test denied"},id=>1});

$t->post_ok('/jsonrpc','{"id":1,"service":"rpc","method":"echo"}')
  ->json_content_is({error=>{origin=>2,code=>9999,message=>"error while processing rpc::echo: Argument Required! at \/home\/oetiker\/checkouts\/mojo-qooxdoo\/t\/..\/example\/lib\/JsonRpcService.pm line 53.\n"},id=>1});

$t->post_ok('/jsonrpc','{"id":1,"service":"rpc","method":"echo","params":["hello"]}')
  ->json_content_is({id=>1,result=>'hello'});

$t->get_ok('/jsonrpc?_ScriptTransport_id=1;_ScriptTransport_data={"id":1,"service":"rpc","method":"echo","params":["hello"]}')
  ->content_is('qx.io.remote.transport.Script._requestFinished( 1, {"id":"1","result":"hello"});')
  ->content_type_is('application/javascript')
  ->status_is(200);


exit 0;
