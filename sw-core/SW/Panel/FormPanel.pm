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

package SW::Panel::FormPanel;

#------------------------------------------------------------
# SW::Panel::FormPanel
#------------------------------------------------------------
# $Id: FormPanel.pm,v 1.8 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::Panel;
use SW::Renderer;


@ISA = qw(SW::Panel);

$VERSION = '0.01';


# Preloaded methods go here.

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);

	bless($self, $classname);

	$self->{renderCallback} = "renderFormPanel";

	return $self;
}

sub render
{
	my $self = shift;
	my $renderer = shift;
	my $renderCall = $self->{renderCallback};
	return $renderer->$renderCall($self);
}


1;
__END__

=head1 NAME

SW::Panel::FormPanel - SW Panel for displaying form displays

=head1 SYNOPSIS

  use SW::Panel::FormPanel;

=head1 DESCRIPTION

=head1 PROPERTIES

	bgColor - default background color for the panel  (may be overridden
					for a given cell with addElement($el,1,1,color);
	fgColor - default text color for the panel



=head1 METHODS

=head1 AUTHOR

Scott Wilson	scott@hbe.ca
Feb 17/99

=head1 REVISION HISTORY

  $Log: FormPanel.pm,v $
  Revision 1.8  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.7  1999/09/01 01:26:52  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.6  1999/08/30 20:05:03  krapht
  Removed the Exporter stuff

  Revision 1.5  1999/06/17 21:46:34  krapht
  Code cleanup

  Revision 1.4  1999/05/05 16:06:21  scott
  fixed for panel cell backgrounds

  Revision 1.3  1999/02/22 00:52:58  scott
  1)  added a $object->visible() method to enable hiding objects
  2)  created TreeView
  3)  implemented an easier, more flexible callback system to facilitate
  	callbacks calling other callbacks and better control over which
  	level of objects get the callbacks.  Also allows argument passing
  	to the callback.

  Revision 1.2  1999/02/18 10:42:53  scott
  New GUIElement components - LinkExternal, ListBox, SelectBox, TextBox, RadioButtonSet


=head1 SEE ALSO

perl(1).

=cut
