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

package SW::GUIElement::TextArea;

#------------------------------------------------------------
# SW::GUIElement::TextArea
# Creates and handles a SW::GUIElement::TextArea
#------------------------------------------------------------
# $Id: TextArea.pm,v 1.10 1999/11/15 18:17:33 gozer Exp $
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
	my $self = $classname->SUPER::new(@_);

	shift; # theApp, got it in the base class

	$self->{renderCallback} = "renderTextArea";

	if (! $self->{hc})
	{ 
		$self->{params}->{ref} = shift;
		$self->{params}->{text} = shift;
		$self->{params}->{width} = shift;
		$self->{params}->{height} = shift;
	}

	return $self;
}

sub updateState
{
	my $self = shift;

	my $sessionData = $self->processSessionData();

if ($sessionData ne "")
	{
		$self->{params}->{text} = $sessionData;
	}
}

sub render
{
	my ($self, $renderer) = @_;
	my $renderCall = $self->{renderCallback};

	$renderer->$renderCall(	$self);
}

sub setValue
{
	my $self = shift;

	if (@_ > 1)  # ie calling set on an attribute of the textarea not it's text value
	{
		$self->SUPER::setValue(@_);
	} else {
		$self->{params}->{text} = shift;
		my $session = $self->{theApp}->getSession();
		my $name = $self->{params}->{name};
		$session->{$name}=$self->{params}->{text};
	}
}

sub getValue
{
	my $self = shift;	

	if (@_) 
	{
		return $self->SUPER::getValue(@_);
	}
	else
	{
		return $self->{params}->{text};	
	}
}


1;

__END__

=head1 NAME

SW::GUIElement::TextArea - Smart Worker TextArea Object

=head1 SYNOPSIS

  use SW::GUIElement::TextArea;

  my $textarea = new SW::GUIElement::TextArea($app, { -ref=>'TextAreaName',
						      -text=>"StartingText",
						      -width=>'80',
						      -height=>'40',
						} );

  $panel->addElement($textarea);

=head1 DESCRIPTION

  Smart Worker TextArea object

=head1 METHODS

  new ($Application, { hash of properties });           preferred
  new ($Application, ref, text, width, height);

  render -  Called by swBaseRenderer
  getValue([param_name]) -  without argument returns target, otherwise 
				returns the parameter named param_name
  setValue([param_name],value) -  without argument sets target to value, 
				otherwise sets named parameter to value

=head1 PROPERTIES

  text => Text in the tex area
  ref => Name reference of text area
  width => in characters
  height => in lines

=head1 AUTHOR

Scott Wilson	scott@hbe.ca
Jan 12/99

=head1 REVISION HISTORY

  $Log: TextArea.pm,v $
  Revision 1.10  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.9  1999/10/01 16:02:33  krapht
  Removed TreeView, and the bless line in each GUIElement, which was useless
  anyways!

  Revision 1.8  1999/09/01 21:38:40  krapht
  Changed ref to name, target to signal for internal links!

  Revision 1.7  1999/09/01 01:26:50  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.6  1999/08/30 19:50:10  krapht
  Removed the use Exporter lines and associated code (@EXPORT, etc.)

  Revision 1.5  1999/04/21 05:55:58  scott
  Fixed problems with the getValue function

  Revision 1.4  1999/02/18 10:42:53  scott
  New GUIElement components - LinkExternal, ListBox, SelectBox, TextBox, RadioButtonSet

  Revision 1.3  1999/02/12 22:44:23  scott
  added updateState() and getValue(), setValue()


=head1 SEE ALSO

perl(1).

=cut
