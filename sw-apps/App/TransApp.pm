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

package SW::App::TransApp;

#------------------------------------------------------------
# TransApp
#  Demo Trnaslation App
#------------------------------------------------------------
# $Id: TransApp.pm,v 1.2 1999/09/07 16:23:17 gozer Exp $
#------------------------------------------------------------
use SW::Util::Prep;

use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE @EXPORT @EXPORT_OK);

use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;
use SW::Data;
use SW::Data::Document;

# Load the stringtables

use SW::App::TransApp::Text;

@ISA = qw(SW::Application Exporter AutoLoader);
@EXPORT = qw(

);

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	bless ($self, $classname);

	$self->{stringTable} = TransApp::Text->new("en");

	$self->buildTable();

	return $self;
}

#------------------------------------------------------------
# initialise the app
#------------------------------------------------------------

sub swInitApplication
{
	my $self = shift;

	my $appRegistry = $self->{master}->{appRegistry};

	$appRegistry->register(ref $self, "", [2], "Translation App");
}

sub swValidateUser
{
	my $self = shift;

	return 0 if ($self->{user}->{user} eq "guest");

	return 1;
}

sub swBuildUI
#SW TransOrder 15
{
	my $self = shift;
	my $abort = shift;

	my $tr = SW::Language::getCode($self->{user}->preference("Language"));

	my $mainPanel = $self->getPanel();
	$mainPanel->setValue('bgColor','black');

	my $instructions = new SW::Panel::HTMLPanel($self, { -background => "."} );

	$instructions->addElement(0,0, new SW::GUIElement::Text($self, $self->{stringTable}->getString("ENTER", $tr)));

	my $formPanel = new SW::Panel::FormPanel($self, { -name => "text", -background => "." });

	my $textbox = new SW::GUIElement::TextArea($self, { -ref => "trans", -height => 6, -width => 40 } );
	my $submit = new SW::GUIElement::Button($self, { -text => $self->{stringTable}->getString("SUBMIT", $tr),
										-target => "Translate" } );

	# add elements to the panel

	$formPanel->addElement(0, 0, $textbox);
	$formPanel->addElement(0, 1, $submit);

	# set up the main screen

	$mainPanel->addElement(0, 0, $instructions);
	$mainPanel->addElement(0, 1, $formPanel);
} #  end of draw sub

#------------------------------------------------------------
# swTranslate
#------------------------------------------------------------

sub swTranslate
#SW Callback Translate 12
{
	my $self = shift;

#	my $textWidget = $self->getComponent("trans");
#	my $textForTranslation = $textWidget->getValue();
	my $textForTranslation = $self->getDataValue('trans');

	my %translatedText = SW::Util::translate($textForTranslation, "en", "de", "fr", "pt", "sp", "ge");

	my $resultPanel = new SW::Panel::HTMLPanel($self, {-bgColor => "#000080"});

	$resultPanel->addElement(0, 1, new SW::GUIElement::Text($self, $translatedText{'fr'}) );
	$resultPanel->addElement(0, 2, new SW::GUIElement::Text($self, $translatedText{'pt'}, ));
	$resultPanel->addElement(0, 3, new SW::GUIElement::Text($self, $translatedText{'sp'}, ));
	$resultPanel->addElement(0, 4, new SW::GUIElement::Text($self, $translatedText{'ge'}, ));

	$self->getPanel()->addElement(0, 2, $resultPanel);
}

#SW end

#----------------------
# return true
#----------------------

1;

__END__

=head1 NAME

SW::App::FillIn - Fill In

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 PARAMETERS

=head1 AUTHOR

=head1 REVISION HISTORY

$Log: TransApp.pm,v $
Revision 1.2  1999/09/07 16:23:17  gozer
Fixed pod syntax errors


=head1 SEE ALSO

perl(1).

=cut


