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

package SW::GUIElement::Button;

#------------------------------------------------------------
# SW::GUIElement::Button
# Handles a button & its behaviour
#------------------------------------------------------------
# $Id: Button.pm,v 1.15 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);
use SW::GUIElement;
use SW::GUIElement::ImageButton;
use SW::Application;
use SW::Renderer::BaseRenderer;

@ISA = qw(SW::GUIElement);

$VERSION = '0.01';


# new takes no args or a Button String
sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_); # send theApp to super

	shift; # theApp, caught in the base class

	$self->{renderCallback} = "renderButton";

	if (!$self->{params}->{type})
	{
		$self->{params}->{type} = "submit";	# default to being a submit button
	}

	if (! $self->{hc})
	{ 
		$self->{params}->{signal} = shift;
		$self->{params}->{text} = shift;
		$self->{params}->{type} = shift;
	}

	if (!($self->getValue('signal') =~ /::/g))
	{
		$self->setValue('signal', $self->getValue('signal').'::'.$self->{theApp}->{package});
	}

	return $self;
}

sub render
{
	my ($self, $renderer) = @_;

	my $renderCall = $self->{renderCallback};

	$renderer->${renderCall}($self );
}


1;

__END__


=head1 NAME

SW::GUIElement::Button - swButton   Form Button Element

=head1 SYNOPSIS

  use SW::GUIElement::Button;

  my $application = new SW::Application(..);
  my $panel = new SW::HTMLPanel($application);
  my $button = new SW::GUIElement::Button($Application, {
												signal => "mysignal", 
												text => "$text", 
												type => "$type",
												preBuild => ?,
											});
  
  $panel->addElement(0,0, $button);

  --- would call back to the same Application, but this callback in the App would be called:
  
	sub swResponseSignal
	#SW Callback mysignal 1
	{
		my $app = shift;

		$app->getComponent('some_component')->getValue();
	}


=head1 DESCRIPTION

SmartWorker Form Button.  Supported types are: submit, reset
			  Defaults to being a submit button unless specified


=head1 METHODS

  new -  Creates a new Button Object
	 new ($Application, { hash of properties } );   # preferred
	 new ($Application, signal, text, type);	# the fast, lazy way

=head1 PROPERTIES

  target => callback name (if applicable)
  type => submit, clear, etc
  preBuild => define if you want the callback called before the UI
					tree is built rather than after
  

=head1 AUTHOR

Scott Wilson
HBE	scott@hbe.ca
Jan 8/99

=head1 REVISION HISTORY

  $Log: Button.pm,v $
  Revision 1.15  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.14  1999/10/01 16:02:33  krapht
  Removed TreeView, and the bless line in each GUIElement, which was useless
  anyways!

  Revision 1.13  1999/09/20 14:31:04  krapht
  Don't know what I changed in there!

  Revision 1.12  1999/09/01 21:38:40  krapht
  Changed ref to name, target to signal for internal links!

  Revision 1.11  1999/09/01 01:26:50  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.10  1999/08/31 15:51:45  krapht
  Removed a comment in Button.pm and some useless lines in ImageButton (now
  that it inherits Button)

  Revision 1.9  1999/08/30 19:50:10  krapht
  Removed the use Exporter lines and associated code (@EXPORT, etc.)

  Revision 1.8  1999/08/30 17:40:50  krapht
  ImageButton now inherits from Button

  Revision 1.7  1999/06/17 21:46:30  krapht
  Code cleanup

  Revision 1.6  1999/05/20 13:51:47  scott
  Changes for the new transaction model
    Changed around the package and compnent internal naming scheme

  Revision 1.5  1999/04/16 16:15:04  scott
  Fixed bug so buttons other than submit work

  Revision 1.4  1999/04/15 22:12:34  scott
  Fixed up the docs

  Revision 1.3  1999/02/18 10:42:50  scott
  New GUIElement components - LinkExternal, ListBox, SelectBox, TextBox, RadioButtonSet

  Revision 1.2  1999/02/12 00:05:34  scott
  added support for sessions

  Revision 1.1.1.1  1999/02/10 19:49:10  kiwi
  SmartWorker

  Revision 1.3  1999/02/09 23:53:45  scott
  Changed to inherit from SW::Component, moved developer accessible settings  into $self->{params}->{whatever}

  Revision 1.2  1999/02/09 19:48:39  scott
  Added support for image button in DHTML (get/setImage() )   RSW


=head1 SEE ALSO

perl(1).

=cut
