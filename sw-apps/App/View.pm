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

package SW::App::View;

#------------------------------------------------------------
# TransApp
#  Demo Trnaslation App
#------------------------------------------------------------
# $Id: View.pm,v 1.2 1999/09/07 16:23:17 gozer Exp $
#------------------------------------------------------------


use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;
use SW::Data;
use SW::Data::Document;
use SW::Util;

# Load the stringtables

# use View::Text;

@ISA = qw(SW::Application);


sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	bless ($self, $classname);

# 	$self->{stringTable} = View::Text->new("en");

	return $self;
}

sub swValidateUser
{
	my $self = shift;

	return 0 if ($self->{user}->{user} eq "guest");

	return 1;
}

sub swBuildUI
{
	my $self = shift;
	my $abort = shift;

	my $mainPanel = $self->getPanel();

	# set up the main screen

	$mainPanel->addElement(0, 0, new SW::GUIElement::Text($self, "Object Title", "White", "Red"));
 	$mainPanel->addElement(1, 0, new SW::GUIElement::Text($self, $self->{document}->{title}, "Black", "White"));
	$mainPanel->addElement(0, 1, new SW::GUIElement::Text($self, "Object Creator", "White", "Red"));
	$mainPanel->addElement(1, 1, new SW::GUIElement::Text($self, $self->{document}->{creator}, "Black", "White"));
	$mainPanel->addElement(0, 2, new SW::GUIElement::Text($self, "Object Data", "White", "Red"));
	$mainPanel->addElement(1, 2, new SW::GUIElement::Text($self, SW::Util::flatten($self->{document}->{storage}), "Black", "White"));

} #  end of draw sub

#------------------------------------------------------------
# swTranslate
#------------------------------------------------------------

sub swTranslate
{
	my $self = shift;

	my $textWidget = $self->getComponent("trans");

	my $textForTranslation = $textWidget->getValue();

	my %translatedText = SW::Util::translate($textForTranslation, "en", "de", "fr", "pt", "sp", "ge");

	my $resultPanel = new SW::Panel::HTMLPanel($self);

	$resultPanel->addElement(0, 0, new SW::GUIElement::Text($self, $translatedText{'fr'}, "White", "Red"));
	$resultPanel->addElement(0, 1, new SW::GUIElement::Text($self, $translatedText{'de'}, "White", "Red"));
	$resultPanel->addElement(0, 2, new SW::GUIElement::Text($self, $translatedText{'pt'}, "White", "Red"));
	$resultPanel->addElement(0, 3, new SW::GUIElement::Text($self, $translatedText{'sp'}, "White", "Red"));
	$resultPanel->addElement(0, 4, new SW::GUIElement::Text($self, $translatedText{'ge'}, "White", "Red"));

	my $newDataObject = new SW::Data::Document($self);

	$self->getPanel()->addElement(0, 2, $resultPanel);
}

#------------------------------------------------------------
# return true
#------------------------------------------------------------


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

  $Log: View.pm,v $
  Revision 1.2  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors

  Revision 1.1  1999/09/02 20:11:05  gozer
  New namespace convention

  Revision 1.4  1999/09/01 01:34:19  krapht
  Removed the #@)(*$)(@!#%*)(#* autoloader shit

  Revision 1.3  1999/04/20 05:04:55  kiwi
  Made these work with the new themes a bit.

  Revision 1.2  1999/04/17 21:30:11  kiwi
  Fixed up Browse to use document names, fixed View to correctly display
  document info.

  Revision 1.1  1999/04/16 18:09:14  kiwi
  Basic app components

  Revision 1.2  1999/04/13 21:57:31  kiwi
  Changed it to use stringtables.

  Revision 1.1  1999/04/13 16:40:05  scott
  Test applications altered to work in the new Master / Application model



=cut


