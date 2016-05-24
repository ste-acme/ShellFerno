################################################################
#
#  Copyright notice
#
#  (c) 2016 ste-acme
#
#  This script is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  The GNU General Public License can be found at
#  http://www.gnu.org/copyleft/gpl.html.
#  A copy is found in the textfile GPL.txt and important notices to the license
#  from the author is found in LICENSE.txt distributed with these scripts.
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  This copyright notice MUST APPEAR in all copies of the script!
#
################################################################

# derived from GenShellSwitch.pm

package main;

use strict;
use warnings;

###################################
sub
ShellFerno_Initialize($)
{
  my ($hash) = @_;

  $hash->{SetFn}     = "ShellFerno_Set";
  $hash->{DefFn}     = "ShellFerno_Define";
  $hash->{AttrList}  = "loglevel:0,1,2,3,4,5,6 runtime ". $readingFnAttributes;
}

###################################
sub
ShellFerno_Set($@)
{
  my ($hash, @a) = @_;

  return "no set value specified" if(int(@a) < 2);
  return "Unknown argument $a[1], choose one of up down stop toggle partial_down" if($a[1] eq "?");

  my $v = $a[1];
  my $v2= "";
  if(defined($a[2])) { $v2=$a[2]; }
  
  # Handle special case of partial down
  if($v eq "partial_down")
  {
	return "Error: runtime value not set!" if($attr{$hash->{NAME}}{runtime} == "");

	#Calculate runtime for percentage
	Log 1, "runtime: $attr{$hash->{NAME}}{runtime}";

	my $runtime = $attr{$hash->{NAME}}{runtime};
	my $percent = $v2;
	my $ontime = $runtime/100 * $percent;

	Log 1, "On for $ontime seconds";

	InternalTimer(gettimeofday()+$ontime, "ShellFerno_on_timeout",$hash, 0);
	$v="down";
  }

  ShellFerno_execute($hash,$v);

  Log GetLogLevel($a[0],2), "ShellFerno set @a";

  $hash->{CHANGED}[0] = $v;
  $hash->{STATE} = $v;
  $hash->{READINGS}{state}{TIME} = TimeNow();
  $hash->{READINGS}{state}{VAL} = $v;

  DoTrigger($hash->{NAME}, undef);

  return undef;
}

###################################
sub 
ShellFerno_on_timeout($)
{
  my ($hash) = @_;
  my @a;

  $a[0]=$hash->{NAME};
  $a[1]="stop"; 

  ShellFerno_Set($hash,@a);

  return undef;
}

###################################
sub
ShellFerno_execute($@)
{
  my ($hash, $cmd) = @_;
  my $command=$hash->{Command};
  
  if($cmd eq "up")
  {
    $command.=$hash->{UpValue}." |";
  }
  elsif($cmd eq "down")
  {
    $command.=$hash->{DownValue}." |";
  }
  elsif($cmd eq "stop")
  {
    $command.=$hash->{StopValue}." |";
  }
  else
  {
    return undef;
  }

  Log GetLogLevel($hash->{NAME},4), "ShellFerno command line: $command";
  open(DATA,$command);
  while ( defined( my $line = <DATA> )  ) 
  {
    chomp($line);
    Log GetLogLevel($hash->{NAME},3), "ShellFerno command result: $line";
  }
  close DATA;
  
  #little sleep to avoid continous activities; controller might not like this
  sleep 0.25;

  return undef;
}

###################################
sub
ShellFerno_Define($$)
{
  my ($hash, $def) = @_;
  my $name=$hash->{NAME};

  my @a = split("[ \t][ \t]*", $def);  
  return "Wrong syntax: use define <name> ShellFerno <send command e.g. /home/pi/ShellFerno-pi/send a 1 1> <on value e.g. 1> <off value e.g. 0>" if(int(@a) < 6);
  
  #define Rollladen.Wohnzimmer.1 ShellFerno /home/pi/fernotron-control/FernotronRemote.sh 2 1 u d s
  
  my $command;
  my $max = int(@a)-3;
  for (my $i=2;$i<$max;$i+=1)
  {
    $command.=$a[$i]." ";
  }
  my $onvalue = $a[int(@a)-3];
  my $offvalue = $a[int(@a)-2];
  my $stopvalue = $a[int(@a)-1];
  
  $hash->{Command} = $command;
  $hash->{UpValue} = $onvalue;
  $hash->{DownValue} = $offvalue;
  $hash->{StopValue} = $stopvalue;
 
  return undef;
}

1;

=pod
=begin html

<a name="ShellFerno"></a>
<h3>ShellFerno</h3>
<ul>
  Note: Take care that commands can be executed with fhem's user rights.
  <br><br>
  <a name="ShellFerno"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; ShellFerno &lt;command&gt &lt;up value&gt; &lt;down value&gt; &lt;stop value&gt;</code>
    <br><br>
    Defines a device that executes a command via FernotronRemote.sh. This is used to control Fernotron shutters. &lt;command&gt may contain spaces. Command is executed followed by the up/down/stop value.<br><br>


    Examples:
    <ul>
      <code>define MyShutter ShellFerno /home/pi/fernotron-control/FernotronRemote.sh 3 3 u d s</code><br>
    </ul>
  </ul>
  <br>

  <a name="ShellFernoset"></a>
  <b>Set </b>
  <ul>
    <code>set &lt;name&gt; &lt;value&gt;</code>
    <br><br>
    where <code>value</code> is one of:<br>
    <pre>
    up
    down
    partial_down &lt;percent&gt;
    stop
    </pre>
    Examples:
    <ul>
      <code>set myShutter down</code><br>
    </ul>
    <br>
    Notes:
    <ul>
      <li>Toggle is special implemented. List name returns "on" or "off" even after a toggle command</li>
    </ul>
  </ul>
</ul>

=end html
=cut
