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

package SW::App::Preferences;

#------------------------------------------------------------
# Preferences
#  User Preference Editor
#------------------------------------------------------------
# $Id: Preferences.pm,v 1.2 1999/09/07 16:23:17 gozer Exp $
#------------------------------------------------------------
use SW::Util::Prep;

use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE @EXPORT @EXPORT_OK);

use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Data;
use SW::Util;

# Load the stringtables
use SW::App::Preferences::Text;

# use View::Text;

@ISA = qw(SW::Application Exporter AutoLoader);
@EXPORT = qw(

);

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);

	bless ($self, $classname);

	$self->buildTable();
	return $self;
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

	my $mainPanel = $self->getPanel();
 	my $prefs = $self->{user}->getSystemPreferences();
	
	print STDERR  " prefs are: ".SW::Util::flatten($self->{user}->{profile})."\n";


 	# set up the main screen
 
 	my $formPanel = new SW::Panel::FormPanel($self, {-name=>'prefs',
 											-target => 'Change',
											-valign => 'top',
											-background => '.'} );

	$mainPanel->setValue('valign', "top");
 
 	my $y=0;

	my $order = ["Full Name", "Email Address", "Font", "Font Size", 
					"Screen Size", "Language", "Foreground Colour",
					"Background Colour"];

 	foreach my $p (@$order)
 	{
		$formPanel->addElement(0, $y, new SW::GUIElement::Text($self,
 					$self->{stringTable}->getString($p,SW::Language::getCode($self->getLanguage())), "", $prefs->{'Foreground Colour'}));
 
 		
		if ($p eq "Font")
		{
			# For now, this is hard coded but in the future, 
			# this has to be extracted from two sources: Language
			# and Browser type

			$formPanel->addElement(1, $y, new SW::GUIElement::SelectBox($self,
							{ '-ref' => $p,
								'-name' => $p,
								'-options' => ["Verdana", "Trebuchet MS", "Tacoma MS",
													"Arial", "Comic Sans MS"],
								'-selected' => $prefs->{$p},
							}));
							
		}
		elsif ($p eq "Font Size")
		{
			$formPanel->addElement(1, $y, new SW::GUIElement::SelectBox($self,
							{ '-ref' => $p,
								'-name' => $p,
								'-options' => ["Small", "Medium", "Large"],
								'-selected' => $prefs->{$p},
							}));
							
		} 
		elsif ($p eq "Screen Size")
		{
			$formPanel->addElement(1, $y, new SW::GUIElement::SelectBox($self,
							{ '-ref' => $p,
								'-name' => $p,
								'-options' => ["800x600", "1024x768", "1280x1024",
													"640x200", "480x220"],
								'-selected' => $prefs->{$p},
							}));
							
		}
		elsif ($p eq "Language")
		{
			$formPanel->addElement(1, $y, new SW::GUIElement::SelectBox($self,
							{ '-ref' => $p,
								'-name' => $p,
								'-options' => ["English", "French", "Chinese"],
								'-selected' => $prefs->{$p},
							}));
							
		}
		else
		{
			$formPanel->addElement(1, $y, new SW::GUIElement::TextBox($self,
 						{  '-ref' => $p,
 							'-name' => $p,
 							'-text' => $prefs->{$p},
							'-height' => '1',
 							'-width' => 15 }));
		}

 		$y++;
 	}
	$formPanel->addElement(0, $y, new SW::GUIElement::Button($self,
						{	'-target' => 'Change',
							'-text' => 'Submit',
							'-type' => 'submit',
							'-preBuild' => "true",
						}));
						
	my $addFormPanel = new SW::Panel::FormPanel($self, {-name=>'alter',
									-target => 'Add'} );

	$addFormPanel->addElement(0, 0, new SW::GUIElement::Text($self,
							"Add Key:",
							"White", "Blue"));

	$addFormPanel->addElement(1, 0, new SW::GUIElement::TextArea($self,
							{	'-ref' => '_add',
								'-text' => '',
								'-height' => '1',
								'-width' => '15' }));

	$addFormPanel->addElement(0, 1, new SW::GUIElement::Text($self,
							"Delete Key:",
							"White", "Blue"));

	$addFormPanel->addElement(1, 1, new SW::GUIElement::TextArea($self,
							{	'-ref' => '_delete',
								'-text' => '',
								'-height' => '1',
								'-width' => '15' }));

	$addFormPanel->addElement(0, 2, new SW::GUIElement::Button($self,
							{	'-target' => 'swAdd',
								'-text' => 'Alter',
								'-type' => 'submit',
								'-preBuild' => 'true',
							}));
#  	$mainPanel->addElement(0, 0, $titlePanel);
 	$mainPanel->addElement(0, 0, $formPanel);
#  	$mainPanel->addElement(0, 1, $addFormPanel);
} #  end of draw sub

#------------------------------------------------------------
# swChange
#------------------------------------------------------------

sub swChange
#SW Callback Change 10
{
	my $self = shift;

 	my $prefs = $self->{user}->getSystemPreferences();

	foreach my $p (keys %$prefs)
	{
 		$prefs->{$p} = $self->getDataValue("Preferences::$p");
	}

 	$self->{user}->{dirty} = 1;
	$self->{user}->save();

	#------------------------------------------------------------
	# HACK WARNING
	# This will refresh the entire screen if we're running in
	# full screen mode
	#------------------------------------------------------------

#	if ($self->getPanel()->{renderer}->{Style} eq "DHTML")
#	{
#		$self->{session}->closeSession();
#		$self->getMaster()->error("/perl/Demo1.pm");
#	}	

	#------------------------------------------------------------
	# Otherwise just refresh the current page
	#------------------------------------------------------------

	$self->getMaster()->error($self->getMaster()->{r}->uri());

	#------------------------------------------------------------
	# End of hack warning
	#------------------------------------------------------------
}

#------------------------------------------------------------
# swAdd
#------------------------------------------------------------

sub swAdd
#SW Callback Add 11
{
	my $self = shift;

	my $newField = $self->getDataValue("Preferences::_add");
	my $oldField = $self->getDataValue("Preferences::_delete");

	my $prefs = $self->{user}->getSystemPreferences();

	if (!$prefs->{$newField} && $newField ne "")
	{
		$prefs->{$newField} = "";
		$self->{user}->{dirty} = 1;
		#$self->swBuildUI();
	}

	if ($oldField ne "")
	{
		delete ($prefs->{$oldField});	
		$self->{user}->{dirty} = 1;
	}
}

#SW end

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

  $Log: Preferences.pm,v $
  Revision 1.2  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors

  Revision 1.1  1999/09/02 20:11:05  gozer
  New namespace convention

  Revision 1.11  1999/09/01 01:34:18  krapht
  Removed the #@)(*$)(@!#%*)(#* autoloader shit

  Revision 1.10  1999/07/25 02:49:59  scott
  changes to test apps.

  Most noably UserManager, displays some of the use of the
  data access methods, and the newly repaired user authentication

  Revision 1.9  1999/06/04 19:41:51  krapht
  Changed the order in callback registering because Scott messed it up : )  hahaha

  Revision 1.8  1999/06/02 19:55:02  krapht
  Changed to the new transaction model.  Still needs some work and cleaning

  Revision 1.7  1999/04/22 13:35:54  kiwi
  Updated some new apps with stringtablesd and stuff

  Revision 1.6  1999/04/21 08:56:30  kiwi
  Getting text tables to work

  Revision 1.5  1999/04/21 06:24:25  krapht
  Preferences file for SmartWorker

  Revision 1.4  1999/04/21 05:57:53  scott
  New files for April 21/99 Demo

  Revision 1.3  1999/04/21 05:44:50  krapht
  A sample SmartWorker app

  Revision 1.2  1999/04/20 23:28:18  kiwi
  Added image to background in login.pl, Preferences.pm had minor
  cosmetic changes

  Revision 1.1  1999/04/20 19:15:06  kiwi
  created basic preferences editor

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


