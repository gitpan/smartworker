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

package SW::App::MineSweeper;

#------------------------------------------------------------
# MineSweeper
# Starts the MineSweeper Java applet
#------------------------------------------------------------
# $Id: MineSweeper.pm,v 1.3 1999/11/15 18:17:28 gozer Exp $
#------------------------------------------------------------

#------------------------------------------------------------
# This code was taken from kiwi's Chat.pm file
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA );


use SW::GUIElement;

@ISA = qw(SW::GUIElement);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

$VERSION = '0.01';

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_); # send theApp to super
	bless ($self, $classname);

	shift;  # get back in line ...
       
	$self->{renderCallback} = "renderMineSweeper";
 
	if (! $self->{hc}) 
	{ 
		$self->{params}->{user} = shift;
		$self->{params}->{width} = shift;
		$self->{params}->{height} = shift; 
	}

	$self->setValue("align","center");

	$self->{theApp}->debug("Created a MineSweeper object");
	return $self;
}

sub render
{
	my ($self, $renderer) = @_;
	my $renderCall = $self->{renderCallback};
	my $data = "<table><TR><TD width=12><img src=\"/images/nothing.gif\" width=12></td><td><BR>";
	$data .= $renderer->${renderCall}($self); 
	$data .= "</td></tr></table>"; 
	return $data; 
}
1;

__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::GUIElement::Chat - SmartWorker GUI class for a chat applet

=head1 SYNOPSIS

  use SW::GUIElement::Chat;

  $chat = new SW::GUIElement::Chat($self, [username], [width], [height]);

=head1 DESCRIPTION

This creates a simple chat applet of size [width] x [height] (in pixels), and connects to the chat server as user [username].

It currently puts all connected users into the same chat channel, but that
will change soon, and users will connect by their default group.

=head1 AUTHOR

Kyle Dawkins, kyle@hbe.ca

=head1 REVISION HISTORY

  $Log: MineSweeper.pm,v $
  Revision 1.3  1999/11/15 18:17:28  gozer
  Added Liscence on pm files

  Revision 1.2  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors

  Revision 1.1  1999/09/02 20:11:05  gozer
  New namespace convention

  Revision 1.2  1999/05/14 23:59:54  marcst
  unimportant changes to Mail.pm, Minesweeper.pm and MyApp.pm

  Revision 1.1  1999/05/05 15:05:15  scott
  adding minesweeper into the perl directory


=head1 SEE ALSO

perl(1).

=cut
__END__
