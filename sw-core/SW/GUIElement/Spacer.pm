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

package SW::GUIElement::Spacer;

#------------------------------------------------------------
# Spacer - basically, a transparent GIF
#------------------------------------------------------------
# $Id: Spacer.pm,v 1.3 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::GUIElement;
use SW::Application;
use SW::Renderer::BaseRenderer;

@ISA = qw(SW::GUIElement);

$VERSION = '0.01';


sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_); # send theApp to super

	shift; # get back in line ...
       
	$self->{renderCallback} = "renderSpacer";
 
	if (! $self->{hc})
	{
		$self->{params}->{width} = shift || 10;
		$self->{params}->{height} = shift || 10;
		$self->{params}->{bgColor} = shift;
		$self->{params}->{grow_x} = shift || "true";
		$self->{params}->{grow_y} = shift || "true";

	}

	return $self;
}

sub render
{
	my ($self, $renderer) = @_;

	my $renderCall = $self->{renderCallback};
	
	$renderer->${renderCall}($self);
}


1;
__END__

=head1 NAME

SW::GUIElement::Spacer

=head1 SYNOPSIS

  use SW::GUIElement::Text;

  my $application = new SW::Application(..);
  my $panel = new SW::HTMLPanel($application);
  my $text = new SW::GUIElement::Text($Application, text, bgcolor, textcolor);
  
  $panel->addElement(0,0, $text);

=head1 DESCRIPTION

SmartWorker Generic text object.

=head1 METHODS

  new ($Application, { hash of properties } );	preferred
  new ($Application, text, hgcolor, textcolor);

  render - called by Renderer..
  getValue('name') - fetch property value for property name 'name'
  setValue('name','value') - set property 'name' to 'value'

=head1 PROPERTIES

  text - The text
  textColor - Text Color
  bgColor - Background color

=head1 AUTHOR

Scott Wilson
HBE
Jan 8/99

=head1 REVISION HISTORY

  $Log: Spacer.pm,v $
  Revision 1.3  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.2  1999/10/01 16:02:33  krapht
  Removed TreeView, and the bless line in each GUIElement, which was useless
  anyways!

  Revision 1.1  1999/09/27 20:21:20  fhurtubi
  Added this GUIElement Class for transparent GIF spacers

  Revision 1.8  1999/09/01 21:38:40  krapht
  Changed ref to name, target to signal for internal links!

  Revision 1.7  1999/09/01 01:26:50  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.6  1999/08/30 19:50:10  krapht
  Removed the use Exporter lines and associated code (@EXPORT, etc.)

  Revision 1.5  1999/08/30 01:06:39  krapht
  Removed a line which hardcoded the text color to 808080

  Revision 1.4  1999/06/18 14:56:56  krapht
  Code cleanup...Removed SelectOnSubmit.pm (submit on select is in the selectbox now)

  Revision 1.3  1999/04/22 15:58:15  kiwi
  *** empty log message ***

  Revision 1.2  1999/02/18 10:42:53  scott
  New GUIElement components - LinkExternal, ListBox, SelectBox, TextBox, RadioButtonSet


=head1 SEE ALSO

perl(1).

=cut
