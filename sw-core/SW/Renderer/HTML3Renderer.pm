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

package SW::Renderer::HTML3Renderer;

#------------------------------------------------------------
# SW::Renderer::HTML3Renderer
# Standard HTML 3.0 compliant rendering
#------------------------------------------------------------
# $Id: HTML3Renderer.pm,v 1.8 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::Renderer::BaseRenderer;


@ISA = qw(SW::Renderer::BaseRenderer);

$VERSION = '0.01';

my $STYLE = 'HTML3';


sub new 
{
	my $classname = shift;

	my $self = $classname->SUPER::new(@_);
	bless ($self, $classname);

	$self->{style} = $STYLE;
	return $self;

}


#---------------------
#
#   The actual work sub,  passing browser in here in case there's browser
#   specific quirks to fix at render time.
#
#--------------------


1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::Renderer::HTML3Renderer - SmartWorker Renderer for HTML 3 Browsers

=head1 SYNOPSIS

  use SW::Renderer::HTML3Renderer;

  (initialized by Renderer based on the agent string passed to it)

  $self->{renderer} = new SW::Renderer::HTML3Renderer($Application, $Browser);

=head1 DESCRIPTION


  HTML 3 Renderer Class,  inherits almost everything from SW::Renderer::BaseRenderer


=head1 REVISION HISTORY

$Log: HTML3Renderer.pm,v $
Revision 1.8  1999/11/15 18:17:33  gozer
Added Liscence on pm files

Revision 1.7  1999/09/01 01:26:56  krapht
Hahahahha, removed this %#*(!&()*$& autoloader shit!

Revision 1.6  1999/08/30 19:59:22  krapht
Removed the Exporter stuff



=head1 AUTHOR

Scott Wilson
HBE
Feb 8/99

=head1 SEE ALSO

perl(1).

=cut
