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

package SW::GUIElement::HorizontalRule;

#------------------------------------------------------------
# SW::GUIElement::HorizontalRule
# Creates a horizontal rule on the screen
#------------------------------------------------------------
# $Id: HorizontalRule.pm,v 1.4 1999/11/15 18:17:33 gozer Exp $
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

	shift; # theApp, caught in the base class

	$self->{renderCallback} = "renderHorizontalRule";

	if (! $self->{hc})
	{ 
		$self->{params}->{width} = shift;
		$self->{params}->{height} = shift;
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
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::GUIElement::HorizontalRule - HorizontalRule

=head1 SYNOPSIS

	my $hr = new SW::GUIElement::HorizontalRule($self,
		{
			-width	=> '200',
			-height	=> '20',

		});

=head1 DESCRIPTION

Creates an instance of a horizontal rule, that can be inserted in a panel

=head1 METHODS

	new 
	new ($Application, { hash of properties } );   # preferred
	new ($Application, target, text, type);	# the fast, lazy way

=head1 PROPERTIES

	width  - width of the bar on screen (in pixels)
	height - height of the bar on screen (in pixels)

=head1 AUTHOR

Jean-Francois Brousseau
HBE	krapht@hbe.ca
September 2/99

=head1 REVISION HISTORY

  $Log: HorizontalRule.pm,v $
  Revision 1.4  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.3  1999/10/01 16:02:33  krapht
  Removed TreeView, and the bless line in each GUIElement, which was useless
  anyways!

  Revision 1.2  1999/09/07 15:51:20  gozer
  Pod syntax error fixed

  Revision 1.1  1999/09/02 18:48:37  krapht
  New GUIElement : horizontal rule


=head1 SEE ALSO

perl(1).

=cut
