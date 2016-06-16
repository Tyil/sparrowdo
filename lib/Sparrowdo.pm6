use v6;

unit module Sparrowdo;

use Terminal::ANSIColor;

use JSON::Tiny;

sub task_run(%args) is export { 

  say colored('running task <' ~ %args<task> ~ '> plg <' ~ %args<plugin> ~ '> ', 'bold green on_blue');

  say 'parameters:';

  say %args<parameters>;

  my $host = $Sparrowdo::Host;

  ssh_shell 'sparrow index update', $host;

  ssh_shell 'sparrow plg install ' ~ %args<plugin>, $host;

  ssh_shell 'sparrow project create sparrowdo', $host;

  my $sparrow_task = %args<task>.subst(/\s+/,'_', :g);

  ssh_shell  'sparrow task add sparrowdo ' ~ $sparrow_task ~ ' ' ~ %args<plugin>, $host;

  my $filename = '/tmp/' ~ $sparrow_task ~ '.json';
  
  my $fh = open $filename, :w;

  $fh.say(to-json %args<parameters>);

  $fh.close;

  scp $filename, $host;

  ssh_shell 'sparrow task run sparrowdo ' ~ $sparrow_task ~ ' --json ' ~ $filename, $host;


}
 

sub ssh_shell ( $cmd, $host ) {


  my @bash_commands = ();

  @bash_commands.push:  'export http_proxy=' ~ $Sparrowdo::HttpProxy if $Sparrowdo::HttpProxy;
  @bash_commands.push:  'export https_proxy=' ~ $Sparrowdo::HttpsProxy if $Sparrowdo::HttpsProxy;
  @bash_commands.push:  $cmd;

  my $ssh_cmd = 'ssh -q -tt ' ~ $host ~ " ' sudo bash -c \"" ~ ( join ' ; ', @bash_commands ) ~ "\"'";

  say colored($ssh_cmd, 'bold green') if $Sparrowdo::Verbose;

  shell $ssh_cmd;
}

sub scp ($file, $host) {
  
  shell 'scp ' ~ $file ~ ' ' ~ $host ~ ':/tmp/';

}
