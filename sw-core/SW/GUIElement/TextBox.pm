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

package SW::GUIElement::TextBox;

#------------------------------------------------------------
# SW::GUIElement::TextBox
# Creates and handles a SW::GUIElement::TextBox
#------------------------------------------------------------
# $Id: TextBox.pm,v 1.11 1999/11/15 18:17:33 gozer Exp $
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

	$self->{renderCallback} = "renderTextBox";

	if (! $self->{hc}) 
	{ 
		$self->{params}->{'ref'} = shift;
		$self->{params}->{text} = shift;
		$self->{params}->{width} = shift;
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
	}
	else
	{
		$self->{params}->{text} = shift;
		my $session = $self->{theApp}->getSession();
		my $name = $self->{params}->{'name'};
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

sub getSize
{ 
	my $self = shift;

	if ($self->{params}->{iwidth}) {
	    return ($self->{params}->{iwidth}, 1);
	} else {
	    return ($self->{params}->{width}, 1);
	}
}


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::GUIElement::TextBox - Smart Worker TextBox Object

=head1 SYNOPSIS

  use SW::GUIElement::TextBox;

  my $textbox = new SW::GUIElement::TextBox($app, { 
	-ref		=> 'TextBoxName',
	-text		=> "StartingText",
	-width		=> '80',
	-maxlength	=> '100',
  });

  $panel->addElement($textbox);

=head1 DESCRIPTION

  Smart Worker TextBox object

=head1 METHODS

  new ($Application, { hash of properties });		preferred
  new ($Application, ref, text, width, maxlength);

  render -  Called by swBaseRenderer
  getValue([param_name]) -  without argument returns target, otherwise returns the parameter named
                                param_name
  setValue([param_name],value) -  without argument sets target to value, otherwise sets named
                                  parameter to value

=head1 PROPERTIES

  text 		=> Text in thet tex box
  ref 		=> Name reference of text box
  width 	=> size of box in characters
  maxlength 	=> max length of characters allowed in box (from user input, otherwise, if application text is bigger than
		   maxlength, the whole text still shows up)

=head1 AUTHOR

Scott Wilson	scott@hbe.ca
Jan 17/99

=head1 REVISION HISTORY

  $Log: TextBox.pm,v $
  Revision 1.11  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.10  1999/10/01 16:02:33  krapht
  Removed TreeView, and the bless line in each GUIElement, which was useless
  anyways!

  Revision 1.9  1999/09/29 20:35:59  jzmrotchek
  Backwards compatibility hack for iwidth attribute so as to break less things. :)

  Revision 1.8  1999/09/29 19:41:27  jzmrotchek
  Changed parameter name from width to iwidth in getSize(), so that it didn't conflict with the width
  attribute of the panel it's in.

  Revision 1.7  1999/09/01 21:38:40  krapht
  Changed ref to name, target to signal for internal links!

  Revision 1.6  1999/09/01 01:26:50  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.5  1999/08/30 19:50:10  krapht
  Removed the use Exporter lines and associated code (@EXPORT, etc.)

  Revision 1.4  1999/07/16 18:43:47  fhurtubi
  Added the maxlength parameter

  Revision 1.3  1999/06/18 14:56:56  krapht
  Code cleanup...Removed SelectOnSubmit.pm (submit on select is in the selectbox now)

  Revision 1.2  1999/04/20 05:02:28  kiwi
  Fixed the problem regarding "setValue" when it should have been "getValue"

  Revision 1.1  1999/02/18 10:42:53  scott
  New GUIElement components - LinkExternal, ListBox, SelectBox, TextBox, RadioButtonSet


=head1 SEE ALSO

perl(1).

=cut
