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

package SW::Renderer::TextRenderer;

#------------------------------------------------------------
# SW::Renderer::TextRenderer
# Basic Text-based rendering of HTML for browsers like
# Lynx or Arena
#------------------------------------------------------------
# $Id: TextRenderer.pm,v 1.7 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::Renderer::BaseRenderer;


@ISA = qw(SW::Renderer::BaseRenderer);

$VERSION = '0.01';

my $STYLE = 'Text';


sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	bless ($self, $classname);

	$self->{style} = $STYLE;
	return $self;
}

sub renderLink
{
	my $self = shift;
	my $params = shift;
	my $target = $params->{target}."?";

	if ($target =~ /^\//)
	{
		while (my ($k, $v) = each(%{$self->{theApp}->getAppendages()}))
		{
			$target .= "$k=$v&";
		}
	}

	my $data = qq/<a href="$target">/;

	if ($params->{text})
	{
		$data .= $params->{text};
	} else
	{
		$data .= $params->{target};
	}
	$data .= "</a>";

	return $data;
}


1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::Renderer::TextRenderer - Perl extension for blah blah blah

=head1 SYNOPSIS

  use SW::Renderer::TextRenderer;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for SW::Renderer::TextRenderer was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 REVISION HISTORY

$Log: TextRenderer.pm,v $
Revision 1.7  1999/11/15 18:17:33  gozer
Added Liscence on pm files

Revision 1.6  1999/09/01 01:26:56  krapht
Hahahahha, removed this %#*(!&()*$& autoloader shit!

Revision 1.5  1999/08/30 19:59:22  krapht
Removed the Exporter stuff


=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
