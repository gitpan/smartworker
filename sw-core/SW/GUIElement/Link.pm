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

package SW::GUIElement::Link;

#------------------------------------------------------------
# SW::GUIElement::Link
# Handles an internal link & its behaviour
#------------------------------------------------------------
# $Id: Link.pm,v 1.14 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::GUIElement;
use SW::Application;
use SW::Renderer::BaseRenderer;

@ISA = qw(SW::GUIElement);

$VERSION = '0.01';


# new takes no args or a Link String
sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_); # send theApp to super

	shift; # theApp, caught in the base class

	if (! $self->{hc}) { 
		$self->{params}->{text} = shift;
		$self->{params}->{image} = shift;	
	}

	$self->{renderCallback} = "renderLink";

	if (! $self->getValue('URI'))
	{
		$self->setValue('URI', SW->request->uri());
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
	
	$renderer->${renderCall}($self);
}

sub updateState  # not relevant to link
{
}

sub getValue
{
	my $self = shift;
	if (@_)
	{
		my $name = shift;
		return $self->{params}->{$name};
	} else {
		return $self->{params}->{target};
	}
}

sub setValue
{
	my $self = shift;

	if (@_ > 1)
	{
		my ($name, $value) = @_;
		$self->{params}->{$name} = $value;
		return $value;
	} else {
		my $value = shift;
		$self->{params}->{target} = $value;
		return $value;
	}
}		


1;
__END__

=head1 NAME

SW::GUIElement::Link - swLink, Link within the SmartWorker environment. 

=head1 SYNOPSIS

  use SW::GUIElement::Link;

  my $application = new SW::Application(..);
  my $panel = new SW::HTMLPanel($application);
  my $link = new SW::GUIElement::Link($Application, 
				{	  text=>'$text',
					  image=>'$image_url_or_element'
					  signal=>'someSignal',
				} );
  
  $panel->addElement(0,0, $link);



=head1 DESCRIPTION

  SmartWorker Internal Link object. 
   Passes SmartWorker session state and User Authentication status automatically.

=head1 METHODS

  new -  Creates a new Link Object
  render -  Called by swBaseRenderer
  getValue([param_name]) -  without argument returns target, otherwise returns the parameter named
				param_name
  setValue([param_name],value) -  without argument sets target to value, otherwise sets named
				  parameter to value

=head1 PARAMETERS

  target - Internal URL (Optional, defaults back to the curren script)
  signal	- The name of the response handler to call eg:
  					{ -signal=>"compose" }  would call
				
					sub myrespone
					#SW CallBack compose 8

  text - Link text, defaults to target if not set
  image - image URL or swImage element

=head1 AUTHOR

Scott Wilson
HBE	scott@hbe.ca
Jan 12/99

=head1 REVISION HISTORY

  $Log: Link.pm,v $
  Revision 1.14  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.13  1999/10/01 16:02:33  krapht
  Removed TreeView, and the bless line in each GUIElement, which was useless
  anyways!

  Revision 1.12  1999/09/20 15:02:01  krapht
  Replaced getRequest by SW->request

  Revision 1.11  1999/09/01 21:38:40  krapht
  Changed ref to name, target to signal for internal links!

  Revision 1.10  1999/09/01 01:26:50  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.9  1999/08/30 19:50:10  krapht
  Removed the use Exporter lines and associated code (@EXPORT, etc.)

  Revision 1.8  1999/06/29 15:03:13  scott
  Fixed up the docs on signals

  Revision 1.7  1999/06/18 15:27:36  scott
  For DHTML in windows

  Revision 1.6  1999/06/17 21:46:30  krapht
  Code cleanup

  Revision 1.5  1999/06/01 18:45:43  scott
  more fixes for internal signals...

  Revision 1.4  1999/06/01 16:12:11  scott
  Changed (finally) so internal links work, they take a parameter called signal which is the callback
  signal to call (and optionally a package if the destination isn't the creating app)

  Revision 1.3  1999/02/22 00:52:58  scott
  1)  added a $object->visible() method to enable hiding objects
  2)  created TreeView
  3)  implemented an easier, more flexible callback system to facilitate
  	callbacks calling other callbacks and better control over which
  	level of objects get the callbacks.  Also allows argument passing
  	to the callback.

  Revision 1.2  1999/02/18 10:42:50  scott
  New GUIElement components - LinkExternal, ListBox, SelectBox, TextBox, RadioButtonSet

  Revision 1.1  1999/02/12 22:48:24  scott
  create swLink


=head1 SEE ALSO

perl(1).

=cut
