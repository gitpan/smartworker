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

package SW::GUIElement::ImageButton;

#------------------------------------------------------------
# SW::GUIElement::ImageButton
# Handles a button & its behaviour, with a twist!
#------------------------------------------------------------
# $Id: ImageButton.pm,v 1.10 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::GUIElement;
use SW::Application;
use SW::Renderer::BaseRenderer;


@ISA = qw(SW::GUIElement::Button);

$VERSION = '0.01';


# new takes no args or a Button String
sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_); # send theApp to super

	shift; # theApp, caught in the base class

	$self->{renderCallback} = "renderImageButton";

	if(!$self->{params}->{type})
	{
		$self->{params}->{type} = "image";
	}

	if(!$self->{hc})
	{
		$self->{params}->{signal} = shift;
		$self->{params}->{image} = shift;
	}

	if(!$self->getValue('signal') =~ /::/g)
	{
		$self->setValue('signal',$self->getValue('signal').'::'.$self->{theApp}->{package});
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

SW::GUIElement::ImageButton

=head1 SYNOPSIS

use SW::GUIElement::ImageButton;


my	$imageButton = new SW::GUIElement::ImageButton($self,
	{
		-signal	=> 'signal',
		-image	=> $url,
	});


=head1 DESCRIPTION

=head1 METHODS

=head1 PROPERTIES


=head1 AUTHOR

Jean-Francois Brousseau
HBE  krapht@hbe.ca
June 1999

=head1 REVISION HISTORY

$Log: ImageButton.pm,v $
Revision 1.10  1999/11/15 18:17:33  gozer
Added Liscence on pm files

Revision 1.9  1999/10/01 16:02:33  krapht
Removed TreeView, and the bless line in each GUIElement, which was useless
anyways!

Revision 1.8  1999/09/20 14:31:04  krapht
Don't know what I changed in there!


=head1 SEE ALSO

perl(1)

=cut
