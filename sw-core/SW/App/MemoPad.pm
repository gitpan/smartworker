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

package SW::App::MemoPad;

#------------------------------------------------------------
# Memo
#  
#------------------------------------------------------------
# $Id: MemoPad.pm,v 1.4 1999/11/15 18:17:28 gozer Exp $
#------------------------------------------------------------

use SW::Util::Prep;

use strict;
use vars qw($VERSION $SW_FN_TABLE @ISA);

use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Data;
use SW::Crypto;



@ISA = qw(SW::Application);

sub DATA_TYPE() { "MEMO" }


sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);

	bless ($self, $classname);

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

	$appRegistry->register(ref $self, "", [9], "Memo Editor");
}


#------------------------------------------------------------
#
#------------------------------------------------------------

sub swInitInstance
{
	my $self = shift;

	$self->setSessionValue('crypto',new SW::Crypto("Blowfish",40));

	$self->setSessionValue('fmreturn','');
}


#------------------------------------------------------------
# dispatcher
#
# 
#
#------------------------------------------------------------

sub dispatcher
#SW TransOrder 10
{
	my $self = shift;
	my $state = $self->getSessionValue('appState');

	if(!$state)
	{
		$self->mainUI();
	}
	else
	{
		if(!$self->$state())
		{
			$self->mainUI();
		}
	}

	$self->deleteSessionValue('appState');
}


#------------------------------------------------------------
# mainUI
#
# Draws the main interface of the application.
#------------------------------------------------------------

sub mainUI
{
	my $self = shift;
	my $title;
	my $text;
	my $args;
	my $doc;

	my $mainPanel = $self->getPanel();
	my $return = $self->getSessionValue('fmreturn');

	if(!$return)
	{
		$args = $self->getArgs();
	}
	else
	{
		$doc = new SW::Data($self,$return);
		$title = $doc->getName();
		$text = $doc->getStorage();
	}

	if($args)
	{
		$doc = new SW::Data($self,$args);

		$title = $doc->getName();
		$text = $doc->getStorage('storage');
	}

	my $memoPanel = new SW::Panel::FormPanel($self,
		{
			-bgColor	=> '#440099',
		});

	my $titlebox = new SW::GUIElement::TextBox($self,
		{
			-name		=> 'title',
			-text		=> $title,
			-width	=> '20',
		});

	my $textbox = new SW::GUIElement::TextArea($self,
		{
			-name		=> 'text', 
			-text		=> $text,
			-height	=> 10,
			-width	=> 40,
		});

	my $submit = new SW::GUIElement::Button($self,
		{
			-text		=> "Save",
			-signal	=> 'save',
		});

	my $cancel = new SW::GUIElement::Button($self,
		{
			-text		=> "Cancel",
			-signal	=> 'cancel',
		});

	my $open = new SW::GUIElement::Button($self,
		{
			-text		=> "Open file",
			-signal	=> 'openFile',
		});


	$memoPanel->addElement(0,0,$titlebox);
	$memoPanel->addElement(0,1,$textbox);
	$memoPanel->addElement(0,2,$submit);
	$memoPanel->addElement(1,2,$cancel);

	$memoPanel->addElement(0,3,$open);

	$mainPanel->addElement(0,0,$memoPanel);
}

#------------------------------------------------------------
# save
#------------------------------------------------------------

sub save
{
	my $self = shift;
	my $data;

	my $title = $self->getDataValue('title');
	my $text = $self->getDataValue('text');

	my $key = "abcde";

	my $crypto = $self->getSessionValue('crypto');

	my $id = $self->getSessionValue('file');


	print STDERR "############ call to swResponseSave in MemoPad.pm #####\n";
	print STDERR "We are trying to save to $id, with $title and $text\n";

	if($id)
	{
		$data = new SW::Data($self,$id);
	}
	else
	{
		$data = new SW::Data($self,"", DATA_TYPE);
	}

	$data->setName($title);

	my $scrambled = $crypto->encrypt($text,$key);

	print STDERR "Here is the result of crypting the text : $scrambled\n";

	$data->setStorage('storage',$text);

	$data = undef;
}


sub openFile
{
	my $self = shift;

	my $openBox = new SW::App::FileManager("Yo",$self,"OPEN_BOX");

	$self->setSessionValue('appState','mainUI');
}


sub cancel
{
	my $self = shift;
}


sub fmreturn
{
	my $self = shift;

	my $value = $self->setSessionValue('fmreturn',$self->getDataValue('openid'));

	$self->setSessionValue('appState','');
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

  $Log: MemoPad.pm,v $
  Revision 1.4  1999/11/15 18:17:28  gozer
  Added Liscence on pm files

  Revision 1.3  1999/09/20 14:30:08  krapht
  Changes in most of the files to use the new way of referring to session,
  user, etc. (SW->user, SW->session).

  Revision 1.2  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors

  Revision 1.1  1999/09/06 19:31:45  krapht
  Changed Memo to MemoPad and made the changes so it could work with the newer
  versions of SW

  Revision 1.1  1999/09/02 20:11:05  gozer
  New namespace convention

  Revision 1.2  1999/08/27 19:48:32  krapht
  Moved Desk.pm to FileManager.pm, which is more appropriate

  Revision 1.1  1999/04/21 06:12:51  kiwi
  A couple of basic apps

  Revision 1.3  1999/04/20 19:15:06  kiwi
  created basic preferences editor

  Revision 1.2  1999/04/13 21:57:31  kiwi
  Changed it to use stringtables.

  Revision 1.1  1999/04/13 16:40:05  scott
  Test applications altered to work in the new Master / Application model



=cut


