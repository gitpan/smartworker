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

package SW::GUIElement::RadioButton;

#------------------------------------------------------------
# SW::GUIElement::RadioButton
# Creates and handles a set of SW::GUIElement::RadioButton
#------------------------------------------------------------
# $Id: RadioButton.pm,v 1.12 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::GUIElement;
use SW::Application;
use SW::Renderer::BaseRenderer;


@ISA = qw(SW::GUIElement);

$VERSION = '0.01';


#-------------------------------------------------------------------
#  new    !! Not to be called except by RadioButtonSet
#------------------------------------------------------------------

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_); # send theApp to super

	$self->{renderCallback} = "renderRadioButton"; 

	return $self;
}

#------------------------------------------------------------------
# updateState
#
#  Only gets called if the buttons not the set were added to the
#  panel.  Just refers the call to the parent
#
#------------------------------------------------------------------ 

sub updateState
{
	$_[0]->SUPER::updateState();
}

#------------------------------------------------------------------
# render
#------------------------------------------------------------------ 

sub render
{
	my ($self, $renderer) = @_;

	my $renderCall = $self->{renderCallback};

	return $renderer->${renderCall}($self);
}

1;
__END__

=head1 NAME

SW::GUIElement::RadioButton - SmartWorker Radio Button

=head1 SYNOPSIS

  see SW::GUIElement::RadioButtonSet

=head1 DESCRIPTION

  Individual Radio Button element

=head1 METHODS

  new (swApplication, swButtonSet, ref, value, text)

=head1 PROPERTIES

  set - swButtonSet this button belongs to
  ref - Ref name of the set
  value - value of this button
  text -  text caption

=head1 AUTHOR

Scott Wilson	scott@hbe.ca
Feb 17/99

=head1 REVISION HISTORY

  $Log: RadioButton.pm,v $
  Revision 1.12  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.11  1999/10/01 16:02:33  krapht
  Removed TreeView, and the bless line in each GUIElement, which was useless
  anyways!

  Revision 1.10  1999/09/01 21:38:40  krapht
  Changed ref to name, target to signal for internal links!

  Revision 1.9  1999/09/01 01:26:50  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.8  1999/08/30 19:50:10  krapht
  Removed the use Exporter lines and associated code (@EXPORT, etc.)

  Revision 1.7  1999/06/18 14:56:56  krapht
  Code cleanup...Removed SelectOnSubmit.pm (submit on select is in the selectbox now)

  Revision 1.6  1999/05/20 13:51:50  scott
  Changes for the new transaction model
    Changed around the package and compnent internal naming scheme

  Revision 1.5  1999/02/18 19:20:39  scott
  Fixed State problems is RadioButtonSet, moved setNameSpace($ref) into
  it's own method in swGUIElement (out of the processSessionData method)

  Revision 1.4  1999/02/18 10:42:51  scott
  New GUIElement components - LinkExternal, ListBox, SelectBox, TextBox, RadioButtonSet


=head1 SEE ALSO

perl(1).

=cut
