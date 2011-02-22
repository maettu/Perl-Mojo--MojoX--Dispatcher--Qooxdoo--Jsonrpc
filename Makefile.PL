#use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MojoX::Dispatcher::Qooxdoo::Jsonrpc.pm',
    VERSION_FROM      => 'lib/MojoX/Dispatcher/Qooxdoo/Jsonrpc.pm', # finds $VERSION
    PREREQ_PM         => { Mojolicious => 1.11 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT	      => 'dispatch Qooxdoo applications with Mojo', 
       AUTHOR         => 'Matthias Bloch <matthias at puffin ch>') : ()),
);
