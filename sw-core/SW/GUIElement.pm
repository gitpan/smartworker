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

package SW::GUIElement;

#------------------------------------------------------------
# SW::GUIElement
# Never needed by itself, this is the parent class for
# all rendered visual elements
#------------------------------------------------------------
# $Id: GUIElement.pm,v 1.41 1999/11/15 18:17:32 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW;
use SW::Component;
use SW::Application;

#-----------------------------------
#  true GUI elements
#-----------------------------------
use SW::GUIElement::Text;
use SW::GUIElement::TextArea;
use SW::GUIElement::TextBox;
use SW::GUIElement::Button;
use SW::GUIElement::Image;
use SW::GUIElement::Spacer;
use SW::GUIElement::RadioButton;
use SW::GUIElement::RadioButtonSet;
use SW::GUIElement::CheckBox;
use SW::GUIElement::SelectBox;
use SW::GUIElement::ListBox;
use SW::GUIElement::Link;
use SW::GUIElement::LinkExternal;
use SW::GUIElement::Applet;
use SW::GUIElement::HorizontalRule;
use SW::GUIElement::PasswordField;
use SW::GUIElement::FileUpload;
use SW::GUIElement::ImageRollover;

#---------------------------------
#  others
#---------------------------------
use SW::Renderer::BaseRenderer;


@ISA = qw(SW::Component);

$VERSION = '0.01';


sub new
{
	my $swClassName = shift;
	my $self = $swClassName->SUPER::new(@_);

	bless ($self, $swClassName);

	$self->{cols} = 1;
	$self->{rows} = 1;

	if (!$self->{params}->{align})
	{
#		$self->{params}->{align} = "left";
	}
	$self->setValue('name', $self->getValue('name'));

	return $self;
}


#------------------------------------------------------------
# updateState
#
#------------------------------------------------------------

sub updateState
{
	my $self = shift;

	$self->processSessionData;
}


#------------------------------------------------------------
# go
#
# go where? go there!
#------------------------------------------------------------

sub go
{
	# do nothing
}


#------------------------------------------------------------
# processSessionData
#
# I can see a dog when looking at the code !!
#------------------------------------------------------------

sub processSessionData
{
	my $self = shift;

	my $returnValue = "";

	if ($self->{params}->{name})
	{
		my $theApp = $self->{theApp}->{master};
		my $data = $theApp->getData();

		my $name = $self->getValue('name');

		if($data->{$name})
		{
			SW->session->setPrivateValue($name,$data->{$name});

			$returnValue =  $data->{$name};
		}
		elsif((SW->session->getPrivateValue($name)) && ($data->{_submitted} ne $self->{panelName}))
		{
			SW::debug($self," ($name) --> Retrieved session data ".SW->session->getPrivateValue($name),5);
			$returnValue = SW->session->getPrivateValue($name);
		} 
	}
	return $returnValue;
}

#------------------------------------------------------------
# getElementSize
#
# Returns the size of the element in terms of rows and
# columns, undef if the number of arguments is not enough
#------------------------------------------------------------

sub getElementSize
{
	my $self = shift;
	if (@_) 
	{
		if ($_ < 2)
		{
			$self->{theApp}->debug("Error: insufficient args (@_) to new ".ref($self)."\n");
			return;
		}
		else
		{ 
			$self->{cols} = shift;
			$self->{rows} = shift;
		}
	}
	return ($self->{cols}, $self->{rows});
}


#------------------------------------------------------------
# setElementSize
#
#------------------------------------------------------------

sub setElementSize
{
	return getSize(@_);
}


#------------------------------------------------------------
# getSize
#
#------------------------------------------------------------

sub getSize
{
	my $self = shift;

	if (@_)
	{
		if ($_ < 2)
		{
			$self->{theApp}->debug("Error: insufficient args (@_) to new ".ref($self)."\n");
		}
		else
		{
			$self->{params}->{width} = shift;
			$self->{params}->{height} = shift;
		}
	}

	return ($self->{params}->{width} || 1, $self->{params}->{height} || 1) 
}


#------------------------------------------------------------
# setSize
#
#------------------------------------------------------------

sub setSize
{
	return getSize(@_);
}


#------------------------------------------------------------
# renderCallback
#
#------------------------------------------------------------

sub renderCallback
{
	my $self = shift;

	if (@_)
	{
		$self->{renderCallback} = shift;
	}
	else
	{
		return $self->{renderCallback};
	}
}


#------------------------------------------------------------
# render
#
#------------------------------------------------------------

sub render
{
	my $self = shift;
}


1;

__END__

=head1 NAME

SW::GUIElement - Super Class to all GUI elements in the Class Heirarchy

=head1 SYNOPSIS

  use SW::GUIElement;

  (never instantiated on its own, always inherited to specific GUI Elements)
   (from within subclass constructor vvv)
  	my $guielement = new SW::GUIElement($Application, x, y); assname = shift;
  	my $self = $classname->SUPER::new(shift); # send theApp to super

  my ($width, $height) = $guielement->getSize();
  $guielement->setSize(10,20);

  my ($cols, $rows) = $guielement->getElementSize();
  $guielement->setElementSize(1,2);

  my $alignment = $guielement->getAlignment();
  $guielement->setAlignment("CENTER");

  $guielement->setRenderCallBack($String_name_of_render_callback_function);  

=head1 DESCRIPTION

  Base class for all GUI elements in SmartWorker.  Will eventually hold some application default color schemes.  Will contain code for trickling in theme settings from the application.

  NOTE:  Most of these functions are written with all the functionality in the
         getBlaBLa() sub with the setBlaBLa() sub simply redirecting there either
         by { $self=shift; return $self->getBlaBla(@_); }  or simply { return getBlaBLa(@_); }

=head1 METHODS

  new -  create a new guielement  ALWAYS OVERIDDEN but subclasses should make a call ala
		my $classname = shift;
        	my $self = $classname->SUPER::new(shift); # send theApp to super


  getSize -  returns pixel or character width of the component
  setSize - set same  

  getElementSize - return table cell span info
  setElementSize - set same

  updateState - adds the application namespace to the beginning of the element's {ref} parameter, then
			it checks the incomming url arguments or session record for a corresponding value
			and returns it.  Called recursively down by the app between the end of 
			initializeApplication and the calling of any other callback functions.

=head1 AUTHOR

Scott Wilson
HBE	scott@hbe.ca
Jan 8/99

=head1 REVISION HISTORY

  $Log: GUIElement.pm,v $
  Revision 1.41  1999/11/15 18:17:32  gozer
  Added Liscence on pm files

  Revision 1.40  1999/10/12 15:10:01  matju
  deleting the Chat widget
  adding the Applet widget
  general facelifting that may introduce fresh, new, innovative bugs
  other stuff that i don't really remember

  Revision 1.39  1999/10/01 20:36:01  krapht
  Removed the use TreeView line

  Revision 1.38  1999/09/29 22:01:19  krapht
  Changed getSession for SW->session, and stuff

  Revision 1.37  1999/09/29 21:05:20  fhurtubi
  removed setting align to left by default...

  Revision 1.36  1999/09/27 20:21:39  fhurtubi
  Added the spacer class

  Revision 1.35  1999/09/23 18:17:22  krapht
  Added use SW::GUIElement::ImageRollover as a true GUI element

  Revision 1.34  1999/09/12 13:25:59  krapht
  Added some function delimiters, removed setTheme (obsolete?!)

  Revision 1.33  1999/09/11 08:44:36  gozer
  Made a whole bunch of little kwirps.
  Fixed Handler to deal correctly with SW_App_Namespace without defaulting to SW::App when the var is set
  Fixed the bug that made Login.pm create an empty hidden argument on every login attempt
  Added a whole bunch of modules preloading in sw-perl-startup, good speed improvment
  Fixed a few warning here and there.  Only one missing the sweep.  Application.pm and AUTOLOAD warning ?!?
  Changed the SW::Util::flatten and circular_flatten to succesfully use Data::Dumper ;-} (-180 lines of code)
  Gone to bed very late

  Revision 1.32  1999/09/09 19:14:13  krapht
  Added FileUpload in the true GUIElements in the top of the file

  Revision 1.31  1999/09/03 16:15:33  fhurtubi
  Added GUIElement::PasswordField

  Revision 1.30  1999/09/02 18:59:05  krapht
  Sorry, forgot a semi-colon on the HorizontalRule line

  Revision 1.29  1999/09/02 18:57:53  krapht
  Added HorizontalRuler to the GUIElements

  Revision 1.28  1999/09/01 01:26:46  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.27  1999/08/30 20:04:00  krapht
  Removed the Exporter stuff

  Revision 1.26  1999/08/30 17:40:43  krapht
  Removed the ImageButton line.  ImageButton now inherits from Button

  Revision 1.25  1999/08/29 23:56:10  krapht
  Changed the name of texas to testdb.smartworker.org

  Revision 1.24  1999/08/12 14:45:11  fhurtubi
  Little bug correction

  Revision 1.23  1999/07/25 02:42:27  scott
  Mostly changes to squash circular reference bugs that were causing
  sessions and applications to linger arouond until server restart
  (thus really messing up the session storage)

  Revision 1.22  1999/07/19 13:29:19  scott
  Lots of clean-up work, debugged and improved the desctructor calling of all
  copmonents so none should be left lingering after the transaction completes.

  This in turn solved the session problem (destructor wasn't being called
  because it was persisting past the end of the transaction)

  Revision 1.21  1999/07/14 21:37:33  fhurtubi
  showing fred

  Revision 1.20  1999/07/08 15:45:27  scott
  oops - should have done these separately ...

  Working on changes to the database code for users, groups, and objects

  as well as debugging and signals

  Revision 1.19  1999/05/20 13:51:45  scott
  Changes for the new transaction model
    Changed around the package and compnent internal naming scheme

  Revision 1.18  1999/04/20 20:30:33  kiwi
  *** empty log message ***

  Revision 1.17  1999/04/20 05:02:08  kiwi
  Fixed up the basic themes

  Revision 1.16  1999/04/17 21:28:43  kiwi
  Now includes the SW::GUIElement::Chat class

  Revision 1.15  1999/04/13 16:34:53  scott
  Slight changes to updateState

  Revision 1.14  1999/03/29 20:49:36  scott
  rendering tweaks...

  Revision 1.13  1999/02/22 00:52:58  scott
  1)  added a $object->visible() method to enable hiding objects
  2)  created TreeView
  3)  implemented an easier, more flexible callback system to facilitate
  	callbacks calling other callbacks and better control over which
  	level of objects get the callbacks.  Also allows argument passing
  	to the callback.

  Revision 1.12  1999/02/18 23:59:28  kiwi
  Changed the way tables are formatted so the source is easier to read

  Revision 1.11  1999/02/18 19:20:39  scott
  Fixed State problems is RadioButtonSet, moved setNameSpace($ref) into
  it's own method in swGUIElement (out of the processSessionData method)

  Revision 1.10  1999/02/18 10:42:50  scott
  New GUIElement components - LinkExternal, ListBox, SelectBox, TextBox, RadioButtonSet

  Revision 1.9  1999/02/17 22:50:26  kiwi
  Added go() method (which does nothing yet).

  Revision 1.8  1999/02/17 17:08:41  kiwi
  Altered class to use hierarchical parent/child app relationships

  Revision 1.7  1999/02/12 22:42:23  scott
  added updateState()
  added swLink
  added setTheme() to set up some default color combinations

  Revision 1.6  1999/02/12 00:05:13  scott
  added processSessionData to receive url args, retrieve session info and fix namespace on refs

  Revision 1.5  1999/02/11 20:59:02  kiwi
  Removed log at the top.

  Revision 1.4  1999/02/11 18:58:47  scott
  added RadioButton and CheckBox

  Revision 1.3  1999/02/10 23:05:08  kiwi
  Commented out the use statements for radiobutton and checkbox

  Revision 1.2  1999/02/10 20:11:15  scott
  Added Image, RadioButton, CheckBox to use

  Revision 1.1.1.1  1999/02/10 19:49:10  kiwi
  SmartWorker

  Revision 1.3  1999/02/09 23:53:34  scott
  Changed to inherit from SW::Component, moved developer accessible settings  into $self->{params}->{whatever}

  Revision 1.2  1999/02/09 19:46:59  scott
  Added more default methods for get/setSize and get/setElementSize   RSW


=head1 SEE ALSO

perl(1).

=cut
