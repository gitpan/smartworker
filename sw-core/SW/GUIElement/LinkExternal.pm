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

package SW::GUIElement::LinkExternal;

#------------------------------------------------------------
# SW::GUIElement::LinkExternal
# Handles an external link 
#------------------------------------------------------------
# $Id: LinkExternal.pm,v 1.7 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::GUIElement;
use SW::Application;
use SW::Renderer::BaseRenderer;
use SW::Renderer::HTML3Renderer;

@ISA = qw(SW::GUIElement);

$VERSION = '0.01';


# new takes no args or a LinkExternal String
sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_); # send theApp to super

	shift; # theApp, caught in the base class

	if (! $self->{hc})
	{ 
		$self->{params}->{target} = shift;
		$self->{params}->{text} = shift;
		$self->{params}->{image} = shift;	
	}

	$self->{renderCallback} = "renderLinkExternal";

	return $self;
}

sub render
{
	my ($self, $renderer) = @_;

	my $renderCall = $self->{renderCallback};
	
	$renderer->${renderCall}($self);
}

sub getValue
{
	my $self = shift;

	if (@_) 
	{    
		my $name = shift;
		return $self->{params}->{$name};
	}
	else
	{
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

SW::GUIElement::LinkExternal - Link to a URL outside of SmartWorker

=head1 SYNOPSIS

  use SW::GUIElement::LinkExternal;

  my $application = new SW::Application(..);
  my $panel = new SW::HTMLPanel($application);
  my $elink = new SW::GUIElement::LinkExternal($Application, {
					 	target=>'$target', 
						text=>'$text',
						image=>'$image_url_or_element');
  
  $panel->addElement(0,0, $elink);



=head1 DESCRIPTION

SmartWorker LinkExternal, target will be a URL outside SmartWorker


=head1 METHODS

  new -  Creates a new LinkExternal Object
  render -  Called by swBaseRenderer
  getValue([param_name]) -  without argument returns target, otherwise returns the parameter named
                                param_name
  setValue([param_name],value) -  without argument sets target to value, otherwise sets named
                                  parameter to value
=head1 PROPERTIES

  target - External URL
  text - Link text
  image - URL to image or swImage element

=head1 AUTHOR

Scott Wilson
HBE	scott@hbe.ca
Jan 17/99

=head1 REVISION HISTORY

  $Log: LinkExternal.pm,v $
  Revision 1.7  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.6  1999/10/01 16:02:33  krapht
  Removed TreeView, and the bless line in each GUIElement, which was useless
  anyways!

  Revision 1.5  1999/09/01 21:38:40  krapht
  Changed ref to name, target to signal for internal links!

  Revision 1.4  1999/09/01 01:26:50  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.3  1999/08/30 19:50:10  krapht
  Removed the use Exporter lines and associated code (@EXPORT, etc.)

  Revision 1.2  1999/06/17 21:46:30  krapht
  Code cleanup

  Revision 1.1  1999/02/18 10:42:51  scott
  New GUIElement components - LinkExternal, ListBox, SelectBox, TextBox, RadioButtonSet


=head1 SEE ALSO

perl(1).

=cut
