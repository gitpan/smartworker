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

#!/usr/bin/perl -I/usr/local/apache/dev/v1
package SW::App::Desktop;
use SW::Util::Prep;

#------------------------------------------------------------
# Desktop
#  Desktop Panel
#------------------------------------------------------------
# $Id: Desktop.pm,v 1.3 1999/11/15 18:17:27 gozer Exp $
#------------------------------------------------------------


use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE);

use SW::Application;
use SW::GUIElement;

@ISA = qw(SW::Application Exporter AutoLoader);

#sub swValidateUser
#{
#	my $self = shift;
#
#	return 0 if ($self->{user}->{user} eq "guest");
#
#	return $self->{user}->requires("CLASS:Admin");
#}

sub new
{
	my $cname = shift;
	my $self = $cname->SUPER::new(@_);
	bless $self, $cname;

	$self->buildTable();
	return $self;
}

sub swBuildUI
#SW TransOrder 15
{
	my $self = shift;
	my $panel = $self->getPanel();

	$panel->setValue('bgColor', "#000038");

	my $ico = new SW::GUIElement::Image ($self, { -url=> $SW::Config::MEDIA_PATH."/images/icons/big/2.gif" } );
	my $link = new SW::GUIElement::Link ($self, {
											-text=> "Object Browser",
											-image=> $ico,
											-signal=> "Browser",  #unused for DHTML
											-launch=> "/apps/Browse.pm",
											-targetWin=> "BrowseWindow",
							} );


	$panel->addElement(0,0,$link);

	return 1;
} #  end of draw sub

sub swBrowser
#SW TransOrder 16
{
	my $self = shift;

	return 1;
}

#SW end

1;
__END__

=head1 NAME

SW::Application - Main framework class for SmartWorker applications

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Kyle Dawkins, kyle@hbe.ca

=head1 SEE ALSO

perl(1).

=head1 REVISION HISTORY

  $Log: Desktop.pm,v $
  Revision 1.3  1999/11/15 18:17:27  gozer
  Added Liscence on pm files

  Revision 1.2  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors

  Revision 1.1  1999/09/02 20:11:05  gozer
  New namespace convention

  Revision 1.2  1999/07/18 21:01:44  scott
  Removed a whole pile of out of date apps from the apps directory

  Revision 1.1  1999/04/21 05:57:53  scott
  New files for April 21/99 Demo

  Revision 1.2  1999/04/13 21:57:31  kiwi
  Changed it to use stringtables.

  Revision 1.1  1999/04/13 16:40:05  scott
  Test applications altered to work in the new Master / Application model



=cut


