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

package SW::App::NewDocument;

#------------------------------------------------------------
# NewDocument
#------------------------------------------------------------
# $Id: NewDocument.pm,v 1.3 1999/11/15 18:17:28 gozer Exp $
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

@ISA = qw(SW::Application Exporter AutoLoader);
@EXPORT = qw(

);

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	bless ($self, $classname);

   if (@_)
	{

		my $cb = sub { $self->swCreateDocument(@_) };
		$self->registerCallback("swCreateDocument", $cb);

		my $cb = sub { $self->swGetName(@_) };
		$self->registerCallback("swGetName", $cb);
	}

	else 
	{

		my $cb = sub {  $self->swCreateDocument($self->{data}->{node}, $self) };
      $self->registerCallback("swCreateDocument", $cb);	

      my $cb = sub { $self->swGetName($self->{data}->{node}, $self) };
      $self->registerCallback("swGetName", $cb);

	}

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

	if ($self->{getName})
	{
		my $formPanel = new SW::Panel::FormPanel($self,
							{ "-target" => "swCreateDocument",
							});

		$formPanel->addElement(0, 1, new SW::GUIElement::TextBox($self,
													{ "-name" => "title",
													  "-ref" => "title",
													  "-text" => "Untitled document",
													  "-width" => 20,
													}));
		$formPanel->addElement(0, 2, new SW::GUIElement::Button($self,
													{ "-target" => "swCreateDocument",
													  "-type" => "submit",
													  "-text" => "Create",
													}));

		$mainPanel->addElement(0, 0, $formPanel);
	} 
	else
	{
		my @registeredTypes = SW::AppRegistry::registeredTypes($self);

		$self->debug(SW::Util::flatten(\@registeredTypes));

		my $i=0;
		my (@tPanel) = ();

		foreach my $t (@registeredTypes)
		{
			$tPanel[$i] = new SW::Panel::HTMLPanel($self, 
									{ "-name" => $i,
									  "-align" => "center",
									  "-width" => "64",
									  "-background" => "h",
									});

			my $tempimage =  new SW::GUIElement::Image($self,
										{ "-align" => "center",
										 "-url" => $SW::Config::MEDIA_PATH."/images/icons/$t.gif",
										});

			$tPanel[$i]->addElement(0, 0, new SW::GUIElement::Link($self,
								{ "-target" => "swGetName",
								  "-args" => { "doc" => $t },
								  "-image" => $tempimage,
								}));
			my $tClass;
			my $tName;

			($tClass, $tName) = SW::AppRegistry::getRegisteredApp($self, $t);

			$tPanel[$i]->addElement(0, 1, new SW::GUIElement::Link($self,
								{ "-target" => "swGetName",
								  "-args" => { "doc" => $t },
								  "-text" => $tName,
								}));


			$mainPanel->addElement($i%4, int($i/4), $tPanel[$i]);
			$i++;
		}
	}
} #  end of draw sub

#------------------------------------------------------------
# swGetName
#------------------------------------------------------------

sub swGetName
{
	my $self = shift;

	$self->addAppendage("doc", $self->getDataValue("doc"));
	$self->{getName} = 1;
}

#------------------------------------------------------------
# swCreateDocument
#------------------------------------------------------------

sub swCreateDocument
{
	my $self = shift;

	my $newDocType = $self->getDataValue('doc');

	# Create a new doc right here...

	my $currentLoc;

	if ($self->{document})
	{
		$currentLoc = $self->{document}->getFullPath();
	}
	else
	{
		$currentLoc = $self->{user}->getFullHome();
	}

	$self->debug("Adding document to location $currentLoc");

	my $newDocument = new SW::Data::Document($self, "", $self->{user}, $currentLoc);

	my $title = $self->getDataValue("NewDocument::title");

	$newDocument->setTitle($title);
	$self->debug("Set new document title to $title");

	# Update the tree somehow...

	# Locate the right app

	# Launch it
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

  $Log: NewDocument.pm,v $
  Revision 1.3  1999/11/15 18:17:28  gozer
  Added Liscence on pm files

  Revision 1.2  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors

  Revision 1.1  1999/09/02 20:11:05  gozer
  New namespace convention

  Revision 1.3  1999/04/21 05:57:53  scott
  New files for April 21/99 Demo

  Revision 1.2  1999/04/21 01:33:06  kiwi
  Fixed up some of the response code.

  Revision 1.1  1999/04/20 20:08:27  kiwi
  Added NewDocument.pm to allow for the creation of new documents

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


