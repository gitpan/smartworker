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

package SW::GUIElement::Image;

#------------------------------------------------------------
# SW::GUIElement::Image
# Creates and handles a SW::GUIElement::Image
#------------------------------------------------------------
# $Id: Image.pm,v 1.9 1999/11/15 18:17:33 gozer Exp $
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

	if (! $self->{hc})
	{
		$self->{params}->{url} = shift;
		$self->{params}->{width} = shift;
		$self->{params}->{height} = shift;
		$self->{params}->{align} = shift;
		$self->{params}->{border} = shift;
	}

	$self->{renderCallback} = "renderImage";

	return $self;
}

sub updateState  # don't care about state of an image...
{
}

sub render
{
	my ($self, $renderer) = @_;

	my $renderCall = $self->{renderCallback};

	$renderer->${renderCall}($self);
}

sub DESTROY
{
	my $self = shift;
	$self->SUPER::DESTROY($self->{params}->{url});
}


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::GUIElement::Image - swImage element

=head1 SYNOPSIS

  use SW::GUIElement::Image;

  my $application = new SW::Application(..);
  my $panel = new SW::HTMLPanel($application);
  my $image = new SW::GUIElement::Image($Application, { -url=>'$URL',
							} );
  
  $panel->addElement(0,0, $image);


=head1 DESCRIPTION

  Smartworker Image class.  URL will most likely be some kind of smartworker
  URL or pointer to the image strored in the database.  For now regular URLs will
  work as well

=head1 PROPERTIES

url - internal or external url for the image src
width - in pixels
height - in pixels 
border - in pixels (default 0)
align - alignment within the frame (default left)
text - text alternative for text only browers / tool tips

=head1 METHODS

  new ($Application, { hash of properties })   preferred
  new ($Application, $url)

  getValue('name') - returns the value of property name 'name'
  setValue('name','value') - sets the property 'name' to 'value'

=head1 AUTHOR

Scott Wilson
HBE             scott@hbe.ca
Jan 8/99


=head1 REVISION HISTORY

  $Log: Image.pm,v $
  Revision 1.9  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.8  1999/10/01 16:02:33  krapht
  Removed TreeView, and the bless line in each GUIElement, which was useless
  anyways!

  Revision 1.7  1999/09/01 01:26:50  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.6  1999/08/30 19:50:10  krapht
  Removed the use Exporter lines and associated code (@EXPORT, etc.)

  Revision 1.5  1999/06/17 21:46:30  krapht
  Code cleanup

  Revision 1.4  1999/02/22 00:52:58  scott
  1)  added a $object->visible() method to enable hiding objects
  2)  created TreeView
  3)  implemented an easier, more flexible callback system to facilitate
  	callbacks calling other callbacks and better control over which
  	level of objects get the callbacks.  Also allows argument passing
  	to the callback.

  Revision 1.3  1999/02/18 10:42:50  scott
  New GUIElement components - LinkExternal, ListBox, SelectBox, TextBox, RadioButtonSet

  Revision 1.2  1999/02/12 22:43:40  scott
  set the renderCallback to default to renderImage to accomodate images not
  directly owned by forms

  Revision 1.1  1999/02/10 20:12:26  scott
  New File - Image object implementation


=head1 SEE ALSO

perl(1).

=cut
