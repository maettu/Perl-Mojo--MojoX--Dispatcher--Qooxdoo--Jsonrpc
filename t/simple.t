use Test::More tests => 24;
use Test::Mojo;

use FindBin;
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/../example/lib';

use_ok 'MojoX::Dispatcher::Qooxdoo::Jsonrpc';
use_ok 'Mojolicious::Plugin::QooxdooJsonrpc';
use_ok 'QxExample::MojoApp';

my $t = Test::Mojo->new('QxExample::MojoApp');

$t->post_ok('/jsonrpc','x','non-jsonrpc request sent')
  ->content_like(qr/This is not a JsonRPC request/,'bad request identified')
  ->status_is(500);

$t->post_ok('/jsonrpc','{"id":1,"method":"test"}','request without service')
  ->content_like(qr/Missing service property/,'missing service found');

$t->post_ok('/jsonrpc','{"id":1,"service":"test"}','request without method')
  ->content_like(qr/Missing method property/, 'missing method found');

$t->post_ok('/jsonrpc','{"id":1,"service":"test","method":"test"}','requesting unknown service')
  ->json_content_is({error=>{origin=>1,code=>2,message=>"service test not available"},id=>1},'json error for invalid service')
  ->content_type_is('application/json; charset=utf-8')
  ->status_is(200);

$t->post_ok('/jsonrpc','{"id":1,"service":"rpc","method":"test"}','requesting invalid method')
  ->json_content_is({error=>{origin=>1,code=>6,message=>"rpc access to method test denied"},id=>1},'json error for invalid method');

$t->post_ok('/jsonrpc','{"id":1,"service":"rpc","method":"echo"}')
  ->json_content_is({error=>{origin=>2,code=>123,message=>"Argument Required!"},id=>1},'propagating generic exception');

$t->post_ok('/jsonrpc','{"id":1,"service":"rpc","method":"echo","params":["hello"]}','proper post jsonrpc call')
  ->json_content_is({id=>1,result=>'hello'},'proper response');

$t->get_ok('/jsonrpc?_ScriptTransport_id=1;_ScriptTransport_data={"id":1,"service":"rpc","method":"echo","params":["hello"]}')
  ->content_like(qr/qx.io.remote.transport.Script._requestFinished/, 'proper get response')
  ->content_type_is('application/javascript; charset=utf-8')
  ->status_is(200);


exit 0;
