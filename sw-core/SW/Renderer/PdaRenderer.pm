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

package SW::Renderer::PdaRenderer;

#------------------------------------------------------------
# SW::Renderer::PdaRenderer
# Renders HTML suitable for display by PDA's like the
# PalmPilot or PSION Organiser
#------------------------------------------------------------
# $Id: PdaRenderer.pm,v 1.6 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::Renderer::BaseRenderer;


@ISA = qw(SW::Renderer::BaseRenderer);

$VERSION = '0.01';

my $STYLE = 'Pda';

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	bless ($self, $classname);
	$self->{style} = $STYLE;
	return $self;
}


1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::Renderer::PdaRenderer - Perl extension for blah blah blah

=head1 SYNOPSIS

  use SW::Renderer::PdaRenderer;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for SW::Renderer::PdaRenderer was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
