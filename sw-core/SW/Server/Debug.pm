#  SmartWorker, an Application Framework
#  Copyright (1999) HBE Software Inc.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package SW::Server::Debug;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::Server::Debug
#
#	Stub code - beginnings of an external debugging console
#
#		This module should be loaded from httpd.conf as 
#		PerlChildInitHandler	SW::Server::Debug
#------------------------------------------------------------
# $Id: Debug.pm,v 1.3 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;

use IO::Socket;
use Apache::Constants qw(:common);

use vars qw($VERSION);

$VERSION = '0.01';


$Server::Debug::socket = undef;

#------------------------------------------------------------
#  package variables
#------------------------------------------------------------

$SW::VERSION = '0.01';
@SW::Log = ();
@SW::Debug = ();

#------------------------------------------------------------
# handler - called on childInit
#------------------------------------------------------------

sub handler
{
	my $r = shift;

	$Server::Debug::socket = IO::Socket::INET->new(PeerAddr => "father.hardboiledegg.com:7999",
																	Type 		=>	SOCK_STREAM,
																	Proto		=> 'tcp',
																	Timeout	=>	10 )
		or print STDERR "Error on socket creation $@\n";

	print STDERR "Created socket - connected\n";

	return DECLINED;
}

#------------------------------------------------------------
#  postDebugMessage
#		takes a string
#------------------------------------------------------------

sub postDebugMessage
{
	my $caller = shift;
	my $msg = shift;
	my $priority = shift;

	if ($Server::Debug::socket)
	{

		my $string = $priority.':-:'.time.':-:'.$caller.':-:'."$msg";

		handler unless $Server::Debug::socket->connected;

		print $Server::Debug::socket $string."\n";
	}

	return 1;
}

1;

__END__

=head1 NAME

SW -  logging interface, constant definitions... 

=head1 SYNOPSIS

use SW;

...

SW::debug($self, "This is what happened...", $level);


=head1 DESCRIPTION


=head1 METHODS

  handler - opens the socket connection (call with ChildInitHandler)
  postDebugMessage - posts the message through the socket to the server

=head1 PARAMETERS

=head1 AUTHOR

Scott Wilson
HBE	scott@hbe.ca
July 18/99

=head1 REVISION HISTORY

  $Log: Debug.pm,v $
  Revision 1.3  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.2  1999/09/07 15:51:22  gozer
  Pod syntax error fixed

  Revision 1.1  1999/07/18 20:50:48  scott
  First addiiton of this stub code that interfaces the SmartWorker
  debugging code to an external socket server and debugging console


=head1 SEE ALSO

perl(1).

=cut
