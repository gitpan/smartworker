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

package SW::GUIElement::Applet;

#------------------------------------------------------------
# SW::GUIElement::Applet
# Interface for the <APPLET> tag
#------------------------------------------------------------
# $Id: Applet.pm,v 1.3 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::GUIElement;


@ISA = qw(SW::GUIElement);

$VERSION = '0.01';


# new takes no args or a Text String
sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_); # send theApp to super
	bless ($self, $classname);

	shift;  # get back in line ...
       
#	$self->{renderCallback} = "renderChat";
	$self->{renderCallback} = "renderApplet";
 
	if (! $self->{hc}) 
	{ 
		$self->{params}->{user} = shift;
		$self->{params}->{width} = shift;
		$self->{params}->{height} = shift; 
	}

	$self->setValue("align", "center");

	return $self;
}

sub render
{
	my ($self, $renderer) = @_;
	my $renderCall = $self->{renderCallback};
	return $renderer->${renderCall}($self);
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

=head1 SEE ALSO

perl(1).

=cut
