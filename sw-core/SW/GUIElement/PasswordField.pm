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

package SW::GUIElement::PasswordField;

#------------------------------------------------------------
# SW::GUIElement::PasswordField
# Password input box
#------------------------------------------------------------
# $Id: PasswordField.pm,v 1.6 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::GUIElement;
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

	$self->{renderCallback} = "renderPasswordField";

	if (! $self->{hc})
	{ 
		$self->{params}->{name} = shift;
		$self->{params}->{size} = shift;
		$self->{params}->{maxlen} = shift;
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
