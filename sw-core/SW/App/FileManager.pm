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

package SW::App::FileManager;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# $Id: FileManager.pm,v 1.25 1999/11/15 18:17:27 gozer Exp $
#------------------------------------------------------------

use SW::Util::Prep;

use strict;
use vars qw($VERSION $SW_FN_TABLE @ISA @SW_EXPORT);

use SW::Handler;
use SW::Exporter;

use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Data;
use SW::Util;
use SW::Constants;

use SW::Renderer::BaseRenderer;

use SW::App::MemoPad;

@ISA = qw(SW::Application SW::Exporter);


# These exports provide a way for other apps to call the boxes
# But it's incomplete right now!
@SW_EXPORT = qw(saveUI openUI);

sub DATA_TYPE () { "FOLDER" }
sub APP_ID() { "FILEMGR" }

my $fonts = "Verdana,Helvetica,Arial";


# Colors we use

my $white		= "#FFFFFF";
my $black		= "#000000";
my $yellow		= "#FFCC66";
my $lightgray	= "#DDDDDD";
my $gray			= "#BBBBBB";
my $darkgray	= "#666666";
my $lightblue	= "#BBBBEE";
my $blue			= "#000080";
my $darkblue	= "#000066";


#------------------------------------------------------------
# new
#
# This is a special "new" method.  The last argument is a
# string telling the application in which state it should
# start.  Possible values are listed here :
#
#------------------------------------------------------------

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);

	bless($self,$classname);

	$self->buildTable();

	my $args = $self->getArgs();

	my $toOpen = $self->getDataValue('openid');

	if($toOpen)
	{
		SW->session->deletePrivateValue('run');
		print STDERR "We got the following value for toOpen : $toOpen\n";
	}

	if(!SW->session->getPrivateValue('run'))
	{
		print STDERR "############### run wasn't assigned a value yet ##########\n";

		SW->session->setPrivateValue('run',1);

		SW->session->setPrivateValue('root', SW->user->getHome());

		($toOpen) ? (SW->session->setPrivateValue('currFolder1',$toOpen)) :
						(SW->session->setPrivateValue('currFolder1',SW->user->getHome()));

		SW->session->setPrivateValue('currFolder2',SW->user->getHome());

		$self->updatePath(1);
		$self->updatePath(2);
	}


	print STDERR "##### Going out of new!!!!!!!\n";

	return $self;
}


#------------------------------------------------------------
# dispatcher
#
# Takes care of calling the right functions, depending on
# the way the application was called, and its current state
#------------------------------------------------------------

sub dispatcher
#SW TransOrder 10
{
	print STDERR "############# dispatcher ###############\n";

	my $self = shift;
	my $appState = SW->session->getPrivateValue('appState');

	print STDERR "Value of appstate is $appState\n";

	if(!$appState)
	{
		$self->mainUI();
	}
	else
	{
		if(!$self->$appState())
		{
			$self->mainUI();
		}
	}
}


#------------------------------------------------------------
# mainUI
#------------------------------------------------------------

sub mainUI
{
	my $self = shift;
	my $mainPanel = $self->getPanel();
	my @fIds;
	my $folder;
	my $bitmask;

	$mainPanel->setValue('name','File Manager');
	$mainPanel->setValue('bgColor',$blue);
	$mainPanel->setValue('width','100%');

	my $topPanel = new SW::Panel::HTMLPanel($self,
		{
			-bgColor	=> $darkblue,
			-align	=> 'center',
		});

	my $toptitle = new SW::GUIElement::Text($self,
		{
			-text			=> "OpenFileManager",
			-textColor	=> $white,
			-font			=> $fonts,
			-fontSize	=> 3,
			-attrib		=> BOLD,
			-valign		=> 'center',
		});

	$topPanel->addElement(0,0,$toptitle);

	my $pathPanel = new SW::Panel::HTMLPanel($self,
		{
			-bgColor	=> $lightgray,
		});

	my $path = new SW::GUIElement::Text($self,
		{
			-text			=> SW->session->getPrivateValue('path1'),
			-font			=> $fonts,
			-fontSize	=> 2,
			-attrib		=> BOLD,
		});

	my $newDoc = new SW::GUIElement::Link($self,
		{
			-text			=> "New document",
			-signal		=> 'newDocUI',
			-font			=> $fonts,
			-fontSize	=> 2,
			-attrib		=> BOLD,
		});

	my $upload = new SW::GUIElement::Link($self,
		{
			-text			=> "Upload document",
			-signal		=> 'uploadUI',
			-font			=> $fonts,
			-fontSize	=> 2,
		});

	$pathPanel->addElement(0,0,$path);
	$pathPanel->addElement(0,1,$newDoc);
	$pathPanel->addElement(0,2,$upload);

	my $browsePanel = new SW::Panel::HTMLPanel($self,
		{
			-bgColor		=> $white,
			-textColor	=> $gray,
			-padding		=> 5,
			-width		=> '100%',
		});

	my $nothing = new SW::GUIElement::Text($self,
		{
			-text		=> '&nbsp;',
			-bgColor	=> $darkblue,
		});

	my $name = new SW::GUIElement::Text($self,
		{
			-text			=> "Name",
			-bgColor		=> $darkblue,
			-textColor	=> $white,
			-align		=> 'center',
			-font			=> $fonts,
			-fontSize	=> 2,
			-attrib		=> BOLD,
		});

	my $app = new SW::GUIElement::Text($self,
		{
			-text			=> "Application",
			-bgColor		=> $darkblue,
			-textColor	=> $white,
			-align		=> 'center',
			-font			=> $fonts,
			-fontSize	=> 2,
			-attrib		=> BOLD,
		});

	my $actions = new SW::GUIElement::Text($self,
		{
			-text			=> "Actions",
			-bgColor		=> $darkblue,
			-textColor	=> $white,
			-align		=> 'center',
			-font			=> $fonts,
			-fontSize	=> 2,
			-attrib		=> BOLD,
		});

	my $date = new SW::GUIElement::Text($self,
		{
			-text			=> "Date Modified",
			-bgColor		=> $darkblue,
			-textColor	=> $white,
			-align      => 'center',
			-font			=> $fonts,
			-fontSize	=> 2,
			-attrib     => BOLD,
		});

	my $owner = new SW::GUIElement::Text($self,
		{
			-text			=> "Owner",
			-bgColor		=> $darkblue,
			-textColor	=> $white,
			-align      => 'center',
			-font			=> $fonts,
			-fontSize	=> 2,
			-attrib     => BOLD,
		});

	my $perms = new SW::GUIElement::Text($self,
		{
			-text			=> "Permissions",
			-bgColor		=> $darkblue,
			-textColor	=> $white,
			-align      => 'center',
			-font			=> $fonts,
			-fontSize	=> 2,
			-attrib     => BOLD,
		});

	$browsePanel->addElement(0,0,$nothing);
	$browsePanel->addElement(1,0,$name);
	$browsePanel->addElement(2,0,$app);
	$browsePanel->addElement(3,0,$actions);
	$browsePanel->addElement(8,0,$date);
	$browsePanel->addElement(9,0,$owner);
	$browsePanel->addElement(10,0,$perms);

	my $folderId = SW->session->getPrivateValue('currFolder1');

	if($folderId)
	{
		$folder = new SW::Data::Folder($self,$folderId);
	}
	else
	{
		$self->displayError("Exception in FileManager: no current folder found");
	}

	if(!$folder)
	{
		$self->displayError("Error in opening folder with ID $folderId");
	}

	my @dirs = $folder->getFolders();
	my @docs = $folder->getDocuments();

	my $goUp = new SW::GUIElement::Link($self,
		{
			-args		=> {
								id			=> $folder->getParent(),
								which		=> 1,
								caller	=> 'mainUI',
							},
			-image	=> "http://nulix.hbe.ca/goup.gif",
			-signal	=> 'changeDir',
		});

	$browsePanel->addElement(0,1,$goUp);

	my $row = 2;
	my $len = @dirs;

	foreach my $node (@dirs,@docs)
	{
		# Here, I use row for another purpose, determining wether we are
		# dealing with a folder or a document

		my $col = 0;

		my $f = new SW::Data($self,$node);

		if(!$f)
		{
			$self->displayError("Error in opening folder with ID $node");
		}
		
		my $perms = $f->getUserPermissions();

		# Don't show hidden files
		if($perms & HIDDEN) { next; }

		my $ftype = $f->getValue('type');

		my $fimage = new SW::GUIElement::Link($self,
			{
				-args		=> {
									app		=> $f->getValue('appid'),
									id			=> $node,
									which		=> 1,
									caller	=> 'mainUI',
								},
				-image	=> getIcon($f->getValue('type')),
				-signal	=> ($ftype eq "FOLDER") ? 'changeDir' : 'startApp',
				-bgColor	=> $gray,
			});

		my $fname = new SW::GUIElement::Link($self,
			{
				-args			=> {
										app		=> $f->getValue('appid'),
										id			=> $node,
										which		=> 1,
										caller	=> 'mainUI',
									},
				-text			=> $f->getName() || "Unnamed Object",
				-signal		=> ($ftype eq "FOLDER") ? 'changeDir' : 'startApp',
				-valign		=> 'center',
				-font			=> $fonts,
				-fontSize	=> 1,
				-attrib		=> BOLD,
			});

		my $fapp = new SW::GUIElement::Text($self,
			{
				-text			=> $f->getValue('appid') || "UNKNOWN",
				-align		=> 'center',
				-valign		=> 'center',
				-font			=> $fonts,
				-fontSize	=> 1,
				-attrib		=> BOLD,
			});

		my $frename;

		if(($perms & WRITABLE) && !($perms & SYSTEM))
		{
			# The user has the right to rename the doc

			$frename = new SW::GUIElement::Link($self,
				{
					-args			=> { id => $node },
					-text			=> "Rename",
					-signal		=> 'renameUI',
					-align		=> 'right',
					-valign		=> 'center',
					-font			=> $fonts,
					-fontSize	=> 1,
					-attrib		=> BOLD,
				});
		}
		else
		{
			$frename = new SW::GUIElement::Text($self,
				{
					-text			=> "Rename",
					-textColor	=> $gray,
					-align		=> 'right',
					-valign		=> 'center',
					-font			=> $fonts,
					-fontSize	=> 1,
					-attrib		=> BOLD,
				});
		}



		my $fmove;

		if(!($perms & SYSTEM) && !($perms & STICKY))
		{
			$fmove = new SW::GUIElement::Link($self,
				{
					-args			=> { id => $node },
					-text			=> "Move",
					-signal		=> 'moveUI',
					-valign		=> 'center',
					-font			=> $fonts,
					-fontSize	=> 1,
					-attrib		=> BOLD,
				});
		}
		else
		{
			$fmove = new SW::GUIElement::Text($self,
				{
					-text			=> "Move",
					-textColor	=> $gray,
					-align		=> 'center',
					-valign		=> 'center',
					-font			=> $fonts,
					-fontSize	=> 1,
					-attrib		=> BOLD,
				});
		}

		my $fdelete;

		if(($perms & WRITABLE) && !($perms & SYSTEM) && !($perms & STICKY))
		{
			$fdelete = new SW::GUIElement::Link($self,
				{
					-args			=> { id => $node },
					-text			=> "Delete",
					-signal		=> 'deleteUI',
					-align		=> 'left',
					-valign		=> 'center',
					-font			=> $fonts,
					-fontSize	=> 1,
					-attrib		=> BOLD,
				});
		}
		else
		{
			$fdelete = new SW::GUIElement::Text($self,
				{
					-text			=> "Delete",
					-textColor	=> $gray,
					-align		=> 'left',
					-valign		=> 'center',
					-font			=> $fonts,
					-fontSize	=> 1,
					-attrib		=> BOLD,
				});
		}

		my $separator = new SW::GUIElement::Text($self,
			{
				-text			=> " | ",
				-valign		=> 'center',
				-font			=> $fonts,
				-fontSize	=> 1,
				-attrib		=> BOLD,
			});

		my $date = SW::Util::parseTimeStamp($f->getValue('lastmodified'));

		my $date_str = $date->{month} . "/" . $date->{day} . "/" . $date->{year};

		my $fdate = new SW::GUIElement::Text($self,
			{
				-text			=> $date_str,
				-align		=> 'center',
				-valign		=> 'center',
				-font			=> $fonts,
				-fontSize	=> 1,
				-attrib		=> BOLD,
			});

		my $fowner = new SW::GUIElement::Text($self,
			{
				-text			=> $f->getOwnerByName() || "?",
				-align		=> 'center',
				-valign		=> 'center',
				-font			=> $fonts,
				-fontSize	=> 1,
				-attrib		=> BOLD,
			});

		my $fperms = new SW::GUIElement::Text($self,
			{
				-text			=> $f->getPermissionByName($f->getUserPermissions()) || "",
				-valign		=> 'center',
				-font			=> $fonts,
				-fontSize	=> 1,
				-attrib		=> BOLD,
			});

		my $leftPar = new SW::GUIElement::Text($self,
			{
				-text			=> ' (',
				-valign		=> 'center',
				-font			=> $fonts,
				-fontSize	=> 1,
				-attrib		=> BOLD,
			});

		my $fpermsEdit = new SW::GUIElement::Link($self,
			{
				-args			=> { id => $node },
				-text			=> "Edit",
				-signal		=> 'editPermsUI',
				-valign		=> 'center',
				-font			=> $fonts,
				-fontSize	=> 1,
				-attrib		=> BOLD,
			});

		my $rightPar = new SW::GUIElement::Text($self,
			{
				-text			=> ')',
				-valign		=> 'center',
				-font			=> $fonts,
				-fontSize	=> 1,
				-attrib		=> BOLD,
			});

		$browsePanel->addElement($col,$row,$fimage);
		$browsePanel->addElement(++$col,$row,$fname);
		$browsePanel->addElement(++$col,$row,$fapp);
		$browsePanel->addElement(++$col,$row,$frename);
		$browsePanel->addElement(++$col,$row,$separator);
		$browsePanel->addElement(++$col,$row,$fmove);
		$browsePanel->addElement(++$col,$row,$separator);
		$browsePanel->addElement(++$col,$row,$fdelete);
		$browsePanel->addElement(++$col,$row,$fdate);
		$browsePanel->addElement(++$col,$row,$fowner);
		$browsePanel->addElement(++$col,$row,$fperms);
		$browsePanel->addElement(++$col,$row,$leftPar);
		$browsePanel->addElement(++$col,$row,$fpermsEdit);
		$browsePanel->addElement(++$col,$row++,$rightPar);
	}

	$mainPanel->addElement(0,0,$topPanel);
	$mainPanel->addElement(0,1,$pathPanel);
	$mainPanel->addElement(0,2,$browsePanel);
}

#------------------------------------------------------------
# newDocUI
#------------------------------------------------------------

sub newDocUI
{
	my $self = shift;
	my $mainPanel = $self->getPanel();

	my $newDocPanel = new SW::Panel::FormPanel($self,
		{
			-bgColor	=> $lightgray,
			-align	=> 'center',
		});

	my $title = new SW::GUIElement::Text($self,
		{
			-text			=> "Create New Document",
			-textColor	=> $white,
			-font			=> $fonts,
			-fontSize	=> 2,
			-align		=> 'center',
			-attrib		=> BOLD,
			-bgColor		=> $darkblue,
		});

	my $nameBox = new SW::GUIElement::TextBox($self,
		{
			-name		=> 'doc_name',
			-width	=> '20',
		});

	my $fileType = new SW::GUIElement::SelectBox($self,
		{
			-name		=> 'filetype',
			-options	=> getActiveDataTypes(),
			-values	=> getActiveDataTypes(),
		});

	my $createButton = new SW::GUIElement::Button($self,
		{
			-text		=> "Create Document",
			-signal	=> 'newDoc',
		});

	my $cancelButton = new SW::GUIElement::Button($self,
		{
			-text		=> "Cancel",
			-signal	=> 'cancel',
		});

	$newDocPanel->addElement(0,0,$title);
	$newDocPanel->addElement(0,1,$nameBox);
	$newDocPanel->addElement(0,2,$fileType);
	$newDocPanel->addElement(0,3,$createButton);
	$newDocPanel->addElement(1,3,$cancelButton);

	$mainPanel->addElement(0,0,$newDocPanel);
}


#------------------------------------------------------------
# saveUI
#
# Draws a nice little "Save As.." box on the screen.  This
# function is used by other apps to provide a dialog box
# when a user has to save files.
#------------------------------------------------------------

sub saveUI
{
	my $self = shift;
	my $mainPanel = $self->getPanel();

	$mainPanel->setValue('bgColor','#FFFFFF');

	my @options = $self->getDatatypes();
	my @values = @options;

	my $saveAsPanel = new SW::Panel::FormPanel($self,
		{
			-bgColor		=> $lightgray,
			-align		=> 'center',
			-valign		=> 'center',
		});

	my $nicePanel = new SW::Panel::HTMLPanel($self,
		{
			-bgColor		=> $black,
			-align		=> 'center',
			-valign		=> 'center',
		});


	my $browsePanel = new SW::Panel::HTMLPanel($self,
		{
			-bgColor		=> $white,
			-align		=> 'center',
		});

	my $fId = SW->session->getPrivateValue('currFolder1');

	print STDERR "###########\nValue of fId : $fId\n";

	my $f = new SW::Data::Folder($self,$fId);

	if(!$f)
	{
		$self->displayError("Error in opening folder with ID $fId");
	}


	my @entries = $f->getFolders();

	push(@entries,$f->getDocuments());

	my $row = 0;

	foreach (@entries)
	{

		my $info = SW::Data::getInfoFromID($_);

		my $icon = new SW::GUIElement::Link($self,
			{
				-args		=> {
									id			=> $_,
									which		=> 1,
									caller	=> 'saveUI',
								},
				-image	=> getIcon($info->{type}),
				-signal	=> ($info->{type} eq "FOLDER") ? ('changeDir'):('cancel'),
				-align	=> 'left',
			});

		my $name = new SW::GUIElement::Link($self,
			{
				-text		=> $info->{name},
				-args		=> {
									id			=> $_,
									which		=> 1,
									caller	=> 'saveUI',
								},
				-signal	=> 'changeDir',
				-align	=> 'left',
			});

		$browsePanel->addElement(0,$row,$icon);
		$browsePanel->addElement(1,$row++,$name);
	}

	my $saveAsText = new SW::GUIElement::Text($self,
		{
			-text	=> "Save as ...",
			-textColor	=> $white,
			-font			=> $fonts,
			-fontSize	=> 2,
			-attrib		=> BOLD,
			-bgColor		=> $darkblue,
		});

	my $nameTxt = new SW::GUIElement::Text($self,
		{
			-text			=> "Name :",
			-textColor	=> $black,
			-font			=> $fonts,
			-fontSize	=> 1,
			-attrib		=> BOLD,
		});

	my $nameBox = new SW::GUIElement::TextBox($self,
		{
			-name		=> "filename",
			-width	=> 20,
		});

	my $ftText = new SW::GUIElement::Text($self,
		{
			-text			=> "File type ",
			-textColor	=> $black,
			-font			=> $fonts,
			-fontSize	=> 1,
			-attrib		=> BOLD,
		});

	my $filetype = new SW::GUIElement::SelectBox($self,
		{
			-name		=> 'filetype',
			-options	=> [@options],
			-values	=> [@values],
		});

	my $saveButton = new SW::GUIElement::Button($self,
		{
			-text		=> "Save",
			-signal	=> 'save',
			-align	=> 'center',
		});

	my $cancelButton = new SW::GUIElement::Button($self,
		{
			-text		=> "Cancel",
			-signal	=> 'shit',
			-align	=> 'center',
		});

	$saveAsPanel->addElement(0,0,$saveAsText);
	$saveAsPanel->addElement(0,1,$nameTxt);
	$saveAsPanel->addElement(1,1,$nameBox);

	$saveAsPanel->addElement(0,2,$ftText);
	$saveAsPanel->addElement(1,2,$filetype);

	$nicePanel->addElement(0,0,$browsePanel);

	$saveAsPanel->addElement(0,5,$nicePanel);

	$saveAsPanel->addElement(0,6,$saveButton);
	$saveAsPanel->addElement(1,6,$cancelButton);

	$mainPanel->addElement(0,0,$saveAsPanel);
}


#------------------------------------------------------------
# openUI
#------------------------------------------------------------

sub openUI
{
	my $self = shift;
	my $mainPanel = $self->getPanel();

	my $openPanel = new SW::Panel::FormPanel($self,
		{
			-bgColor	=> $lightgray,
			-align	=> 'center',
			-valign	=> 'center',
		});

	my $title = new SW::GUIElement::Text($self,
		{
			-text			=> "Open",
			-textColor	=> $white,
			-font			=> $fonts,
			-fontSize	=> 2,
			-bgColor		=> $darkblue,
			-attrib		=> BOLD,
		});

	my $openName = new SW::GUIElement::TextBox($self,
		{
			-name	=> 'openid',
			-size	=> '20',
		});

	my $openButton = new SW::GUIElement::Button($self,
		{
			-text		=> "Open",
			-signal	=> 'fmreturn',
		});

	my $cancelButton = new SW::GUIElement::Button($self,
		{
			-text		=> "Cancel",
			-signal	=> 'cancel',   # Fake signal for now
		});

	$openPanel->addElement(0,0,$title);
	$openPanel->addElement(0,1,$openName);
	$openPanel->addElement(0,3,$openButton);
	$openPanel->addElement(1,3,$cancelButton);

	$mainPanel->addElement(0,0,$openPanel);
}


#------------------------------------------------------------
# uploadUI
#------------------------------------------------------------

sub uploadUI
{
	my $self = shift;

	my $mainPanel = $self->getPanel();

	my $uploadPanel = new SW::Panel::FormPanel($self,
		{
			-bgColor	=> '#453399',
		});

	my $title = new SW::GUIElement::Text($self,
		{
			-text	=> "Upload File",
		});

	my $upload = new SW::GUIElement::FileUpload($self,
		{
			-name		=> 'filename',
			-width	=> 20,
		});

	my $submit = new SW::GUIElement::Button($self,
		{
			-text		=> "Send File",
			-signal	=> 'uploadFile',
		});

	$uploadPanel->addElement(0,0,$title);
	$uploadPanel->addElement(0,1,$upload);
	$uploadPanel->addElement(0,2,$submit);

	$mainPanel->addElement(0,0,$uploadPanel);
}

#------------------------------------------------------------
# renameUI
#------------------------------------------------------------

sub renameUI
{
	my $self = shift;
	my $mainPanel = $self->getPanel();

	my $docId = $self->getDataValue('id');

	SW->session->setPrivateValue('currId',$docId);

	my $doc = new SW::Data($self,$docId);

	if(!$doc)
	{
		$self->displayError("Error in opening folder with ID $docId");
	}

	my $renamePanel = new SW::Panel::FormPanel($self,
		{
			-bgColor	=> $lightgray,
			-align	=> 'center',
			-valign	=> 'center',
			-width	=> 150,
			-height	=> 100,
		});

	my $title = new SW::GUIElement::Text($self,
		{
			-text			=> "Rename",
			-textColor	=> $white,
			-font			=> $fonts,
			-fontSize	=> 2,
			-attrib		=> BOLD,
			-bgColor		=> $darkblue,
			-align		=> 'center',
		});

	my $oldName = new SW::GUIElement::Text($self,
		{
			-text			=> "Current name is ".$doc->getValue('name'),
			-font			=> $fonts,
			-fontSize	=> 1,
			-attrib		=> BOLD,

		});

	my $newName = new SW::GUIElement::TextBox($self,
		{
			-text		=> $doc->getValue('name'),
			-name		=> 'new_name',
			-width	=> 20,
			-align	=> 'center',
		});

	my $renameButton = new SW::GUIElement::Button($self,
		{
			-text		=> "Rename",
			-signal	=> 'renameDoc',
			-align	=> 'center',
		});

	my $cancelButton = new SW::GUIElement::Button($self,
		{
			-text		=> "Cancel",
			-signal	=> 'cancel',
			-align	=> 'center',
		});

	$renamePanel->addElement(0,0,$title);
	$renamePanel->addElement(0,1,$oldName);
	$renamePanel->addElement(0,2,$newName);
	$renamePanel->addElement(0,3,$renameButton);
	$renamePanel->addElement(1,3,$cancelButton);

	$mainPanel->addElement(0,0,$renamePanel);
}


#------------------------------------------------------------
# moveUI
#------------------------------------------------------------

sub moveUI
{
	my $self = shift;
	my $mainPanel = $self->getPanel();

	$mainPanel->setValue('bgColor',$blue);

	my $current = SW->session->getPrivateValue('currFolder1');
	my $current2 = SW->session->getPrivateValue('currFolder2');

	my $globalPanel = new SW::Panel::FormPanel($self,
		{
			-bgColor => $white,
			-spacing => 1,
		});

	my $movePanel1 = new SW::Panel::HTMLPanel($self,
		{
			-bgColor => $white,
			-padding => '5',
		});

	my $middlePanel = new SW::Panel::HTMLPanel($self,
		{
			-bgColor => $lightblue,
			-padding => '5',
		});

	my $movePanel2 = new SW::Panel::HTMLPanel($self,
		{
			-bgColor => $white,
			-padding => '5',
		});


	my $title = new SW::GUIElement::Text($self,
		{
			-text			=> "Move Documents",
			-textColor	=> $white,
			-bgColor		=> $darkblue,
			-font			=> $fonts,
			-fontSize	=> 2,
			-align		=> 'center',
			-attrib		=> BOLD,
		});


	my $folder1 = new SW::Data::Folder($self,$current);
	my @contents1 = $folder1->getFolders();

	push(@contents1,$folder1->getDocuments());

	SW->session->setPrivateValue('tomove',stringize(@contents1));

	my $folder2 = new SW::Data::Folder($self,$current2);
	my @contents2 = $folder2->getFolders();
	push(@contents2,$folder2->getDocuments());

	my $path1 = new SW::GUIElement::Text($self,
		{
			-text			=> SW->session->getPrivateValue('path1'),
			-textColor	=> $darkblue,
			-font			=> $fonts,
			-fontSize	=> 1,
			-attrib		=> BOLD,
			-bgColor		=> $lightgray,
		});

	my $row = 1;

	foreach my $c (@contents1)
	{
		my $col = 0;

		my $data = new SW::Data($self,$c);

		my $box = new SW::GUIElement::CheckBox($self,
			{
				-name 	=> 'ID'. $c,
				-value	=> '1',
			});

		my $icon = new SW::GUIElement::Link($self,
			{
				-args		=> {
									id			=> $c,
									which		=> 1,
									caller	=> 'moveUI',
								},
				-image	=> getIcon($data->getStorage('type')),
				-signal	=> 'changeDir',
				-bgColor	=> $gray,
			});

		my $name = new SW::GUIElement::Link($self,
			{
				-args			=> {
										id			=> $c,
										which		=> 1,
										caller	=> 'moveUI',
									},
				-text			=> $data->getName(),
				-signal		=> 'changeDir',
				-valign		=> 'center',
				-font			=> $fonts,
				-fontSize	=> 1,
				-attrib		=> BOLD,
				-bgColor		=> $lightgray,
			});

		$movePanel1->addElement($col++,$row,$box);
		$movePanel1->addElement($col++,$row,$icon);
		$movePanel1->addElement($col++,$row++,$name);
	}

	my $path2 = new SW::GUIElement::Text($self,
		{
			-text			=> SW->session->getPrivateValue('path2'),
			-textColor	=> $darkblue,
			-font			=> $fonts,
			-fontSize	=> 1,
			-attrib		=> BOLD,
			-bgColor		=> $lightgray,
		});

	$row = 1;
 
	foreach my $c (@contents2)
	{
		my $col = 0;
 
		my $data = new SW::Data($self,$c);

		my $icon = new SW::GUIElement::Link($self,
			{
				-args    => {
									id			=> $c,
									which		=> 2,
									caller	=> 'moveUI',
								},
				-image   => getIcon($data->getStorage('type')),
				-signal  => 'changeDir',
				-bgColor	=> $gray,
			});
 
		my $name = new SW::GUIElement::Link($self,
			{
				-args    	=> {
										id			=> $c,
										which		=> 2,
										caller	=> 'moveUI',
									},
				-text    	=> $data->getStorage('name'),
				-signal  	=> 'changeDir',
				-valign		=> 'center',
				-font			=> $fonts,
				-fontSize	=> 1,
				-attrib		=> BOLD,
				-bgColor		=> $lightgray,
			});
 
		$movePanel2->addElement($col++,$row,$icon);
		$movePanel2->addElement($col++,$row++,$name);
	}

	my $goUp1 = new SW::GUIElement::Link($self,
		{
			-args		=> {
								id			=> $folder1->getParent(),
								which		=> 1,
								caller	=> 'moveUI',
							},

			-image	=> "http://nulix.hbe.ca/goup.gif",
			-signal	=> 'changeDir',
			-bgColor	=> $lightgray,
		});

	my $goUp2 = new SW::GUIElement::Link($self,
		{
			-args		=> {
								id			=> $folder2->getParent(),
								which		=> 2,
								caller	=> 'moveUI',
							},

			-image   => "http://nulix.hbe.ca/goup.gif",
			-signal  => 'changeDir',
			-bgColor	=> $lightgray,
		});

	$movePanel1->addElement(0,0,$goUp1);
	$movePanel1->addElement(1,0,$path1);
	$movePanel2->addElement(0,0,$goUp2);
	$movePanel2->addElement(1,0,$path2);

	my $moveLink = new SW::GUIElement::Link($self,
		{
			-text		=> "&gt;&gt;",
			-bgColor	=> $yellow,
			-align	=> 'center',
			-font		=> $fonts,
			-attrib	=> BOLD,
		});

	my $srcTitle = new SW::GUIElement::Text($self,
		{
			-text			=> "Source Folder",
			-textColor	=> $white,
			-bgColor		=> $darkgray,
			-align		=> 'center',
			-font			=> $fonts,
			-fontSize	=> 1,
			-attrib		=> BOLD,
		});

	my $moveToTitle = new SW::GUIElement::Text($self,
		{
			-text			=> "Move To",
			-textColor	=> $white,
			-bgColor		=> $darkgray,
			-align		=> 'center',
			-font			=> $fonts,
			-fontSize	=> 1,
			-attrib		=> BOLD,
		});

	my $destTitle = new SW::GUIElement::Text($self,
		{
			-text       => "Destination Folder",
			-textColor	=> $white,
			-bgColor    => $darkgray,
			-align      => 'center',
			-font       => $fonts,
			-fontSize   => 1,
			-attrib     => BOLD,
		});

	my $moveButton = new SW::GUIElement::Button($self,
		{
			-text		=> "Move &gt;&gt;",
			-signal	=> 'move',
			-align	=> 'center',
		});

	my $closeButton = new SW::GUIElement::Button($self,
		{
			-text		=> "Close",
			-signal	=> 'cancel',
			-align	=> 'center',
		});

	$middlePanel->addElement(0,2,$moveButton);
	$middlePanel->addElement(0,3,$closeButton);

	$globalPanel->addElement(0,0,$title);
	$globalPanel->addElement(0,1,$srcTitle);
	$globalPanel->addElement(1,1,$moveToTitle);
	$globalPanel->addElement(2,1,$destTitle);

	$globalPanel->addElement(0,0,$title);

	$globalPanel->addElement(0,2,$movePanel1);
	$globalPanel->addElement(1,2,$middlePanel);
	$globalPanel->addElement(2,2,$movePanel2);

	$mainPanel->addElement(0,0,$globalPanel);

	SW->session->setPrivateValue('appState','move');
}


#------------------------------------------------------------
# deleteUI
#------------------------------------------------------------

sub deleteUI
{
	my $self = shift;
	my $mainPanel = $self->getPanel();
	my $id = $self->getDataValue('id');

	SW->session->setPrivateValue('currId',$id);

	my $deletePanel = new SW::Panel::FormPanel($self,
		{
			-bgColor	=> $gray,
			-align	=> 'center',
			-valign	=> 'center',
		});

	my $title = new SW::GUIElement::Text($self,
		{
			-text			=> "Delete file",
			-font			=> $fonts,
			-textColor	=> $white,
			-bgColor		=> $darkblue,
			-fontSize	=> 2,
			-align		=> 'center',
			-attrib		=> BOLD,
		});

	my $deleteButton = new SW::GUIElement::Button($self,
		{
			-text		=> "Delete",
			-signal	=> 'deleteDoc',
		});

	my $cancelButton = new SW::GUIElement::Button($self,
		{
			-text		=> "Cancel",
			-signal	=> 'cancel',
		});

	$deletePanel->addElement(0,0,$title);
	$deletePanel->addElement(0,1,$deleteButton);
	$deletePanel->addElement(1,1,$cancelButton);

	$mainPanel->addElement(0,0,$deletePanel);

	SW->session->setPrivateValue('appState','deleteDoc');
}


#------------------------------------------------------------
# startApp - method
#
# Callback to start an application related to the document
# type on which the user clicked.  I still don't know exactly
# how we'll do this, so to come!!
#------------------------------------------------------------

sub startApp
{
	my $self = shift;
	my $docid = $self->getDataValue('id');
	my $appId = $self->getDataValue('app');

	my $classname = &getAppClass($appId);

	print STDERR "We are going to start the app $classname with docID $docid\n";

	my $app = $classname->new("$classname",$self,$docid);

	my $mainPanel = $self->getPanel();

	$mainPanel->addElement(0,1,$app);
}


#------------------------------------------------------------
# changeDir - method
#
# Callback to change the current directory to the one on
# which the user just clicked
#------------------------------------------------------------

sub changeDir
{
	my $self = shift;
	my $id = $self->getDataValue('id');
	my $anc;
	my $caller = $self->getDataValue('caller');

	SW->session->setPrivateValue('appState',$caller);

	# We can't go higher than the root folder
	if(!$id)
	{
		return;
	}

	my $which = $self->getDataValue('which');

	my $f;

	($which eq '1') ? ($f = 'currFolder1') : ($f = 'currFolder2');

	SW->session->setPrivateValue($f,$id);

	print STDERR "####### We set $f to the value $id\n";

	$self->updatePath($which);

	$self->$caller();
}


#------------------------------------------------------------
# newDoc
#
# Callback that takes care of creating a new document
#------------------------------------------------------------

sub newDoc
{
	my $self = shift;
	my $newDoc;

	my $name = $self->getDataValue('doc_name');
	my $type = $self->getDataValue('filetype');

	my $fId = SW->session->getPrivateValue('currFolder1');

	print STDERR "Creating new doc of type $type called $name in folder $fId\n";

	if($type eq "FOLDER")
	{
		$newDoc = new SW::Data::Folder($self,"",$fId,DATA_TYPE);

		if(!$name)
		{
			$name = "New Folder";
		}
	}
	else
	{
		$newDoc = new SW::Data::Document($self,"",$type);

		if(!$name)
		{
			$name = "Unnamed document";
		}
	}

	$newDoc->setName($name);

	$newDoc->setStorage('appid',&getApp($type));

	my $docId = $newDoc->getObjectId();

	my $folder = new SW::Data::Folder($self,$fId);

	print STDERR "We are adding it in the folder with ID $folder\n\n\n";

	if($type eq "FOLDER")
	{
		$folder->addFolder($docId);
	}
	else
	{
		$folder->addDocument($docId);
	}

	$folder = undef;
	$newDoc = undef;

	return 0;
}


#------------------------------------------------------------
# renameDoc
#------------------------------------------------------------

sub renameDoc
{
	my $self = shift;

	my $docId = SW->session->getPrivateValue('currId');
	my $name = $self->getDataValue('new_name');

	print STDERR "################# renameDoc ####################\n";

	my $doc = new SW::Data($self,$docId);

	if($name)
	{
		$doc->setName($name);
	}

	$doc = undef;

	return 0;
}


#------------------------------------------------------------
# move
#------------------------------------------------------------

sub move
{
	my $self = shift;

	my $src = SW->session->getPrivateValue('currFolder1');
	my $dest = SW->session->getPrivateValue('currFolder2');

	if($src eq $dest)
	{
		return 0;
	}

	my $srcData = new SW::Data::Folder($self,$src);
	my $destData = new SW::Data::Folder($self,$dest);

	if(!$srcData || !$destData)
	{
		$self->displayError("Error in opening folder in sub move");
	}
	else
	{
		my @targets = arrayize(SW->session->getPrivateValue('tomove'));

		foreach (@targets)
		{
			my $value = $self->getDataValue('ID' . $_);

			if($value)
			{
				$srcData->unlinkDocument($_);
				$destData->addDocument($_);

				my $info = getInfoFromID($_);

				if($info->{type} eq "FOLDER")
				{
					my $f = new SW::Data::Folder($self,$_);
					$f->setParent($destData);
				}
			}
		}
		$srcData = undef;
		$destData = undef;
	}

	return 0;
}


#------------------------------------------------------------
# deleteDoc
#
#------------------------------------------------------------

sub deleteDoc
{
	my $self = shift;

	my $docId = SW->session->getPrivateValue('currId');

	if(!$docId) { return 0; }

	print STDERR "Deleting id $docId from the DB! ##################\n";

	SW->user->deleteObject($docId);

	my $id = SW->session->getPrivateValue('currFolder1');

	my $parent = new SW::Data::Folder($self,$id);

	if(!$parent)
	{
		$self->displayError("Error in opening parent folder with ID $id in sub deleteDoc");
	}
	else
	{
		$parent->unlinkDocument($docId);
		SW->session->setPrivateValue('currId','');
		$parent = undef;
	}

	return 0;
}


#------------------------------------------------------------
# uploadFile
#------------------------------------------------------------

sub uploadFile
{
	my $self = shift;

	my $f = new SW::Data::File($self,$self->getDataValue('filename'));

	if(!$f)
	{
		$self->displayError("Error in creating new file entry");
	}
	else
	{
		my $fId = SW->session->getPrivateValue('currFolder1');
 
		my $folder = new SW::Data::Folder($self,$fId);

		print STDERR "################## in uploadFile ##################\n";
		print STDERR "got file " , $self->getDataValue('filename'), " with ID $fId\n";

		$folder->addDocument($f->getObjectId());

		$f = undef;
		$folder = undef;
	}

	return 0;
}


#------------------------------------------------------------
# editPermsUI
#------------------------------------------------------------

sub editPermsUI
{
	my $self = shift;
	my $mainPanel = $self->getPanel();

	my $docId = $self->getDataValue('id');

	SW->session->setPrivateValue('currId',$docId);

	print STDERR "In editPermsUI, we got ID $docId\n";

	my $editPanel = new SW::Panel::FormPanel($self,
		{
			-bgColor	=> $lightgray,

		});

	my $title = new SW::GUIElement::Text($self,
		{
			-text			=> "Edit permissions",
			-textColor	=> $white,
			-font			=> $fonts,
			-fontSize	=> 2,
			-attrib		=> BOLD,
			-align		=> 'center',
			-bgColor		=> $darkblue,
		});

	my $select = new SW::GUIElement::SelectBox($self,
		{
			-name		=> 'perms',
			-options	=> [ 'Full Access', 'Read & Write', 'Read Only' ],
			-values	=> [ '4','2','1' ],

		});

	my $editButton = new SW::GUIElement::Button($self,
		{
			-text		=> "Save changes",
			-signal	=> 'editPerms',
		});

	my $cancelButton = new SW::GUIElement::Button($self,
		{
			-text		=> "Cancel",
			-signal	=> 'cancel',
		});


	$editPanel->addElement(0,0,$title);
	$editPanel->addElement(0,1,$select);
	$editPanel->addElement(0,2,$editButton);
	$editPanel->addElement(1,2,$cancelButton);

	$mainPanel->addElement(0,0,$editPanel);
}


#------------------------------------------------------------
# editPerms
#------------------------------------------------------------

sub editPerms
{
	my $self = shift;
	my $doc;

	print STDERR "################### editPerms #########################\n";

	my $newPerms = $self->getDataValue('perms');

	my $docId = SW->session->getPrivateValue('currId');
	print STDERR "Got back value $docId for the document ID\n";

	if(!$docId)
	{
		$self->displayError("Unexpected situation in FileManager: no value for current folder");
	}
	else
	{
		$doc = new SW::Data($self,$docId);

		if(!$doc)
		{
			$self->displayError("Error in opening document with ID $docId");
		}
		else
		{
			$doc->setUserPermissions($newPerms);
			$doc = undef;
		}
	}

	return 0;
}


#------------------------------------------------------------
# cancel
#------------------------------------------------------------

sub cancel
{
	my $self = shift;

	return 0;
}


#------------------------------------------------------------
# getIcon
#
# Returns the URL to an icon associated with a document type
# so the file manager can appropriately show nice graphics
# with the available docs
#------------------------------------------------------------

sub getIcon
{
	my $doctype = shift;

	my %paths = (
		FOLDER		=> "http://nulix.hbe.ca/folder.gif",
		MEMO			=> "http://nulix.hbe.ca/worddoc.gif",
		TODO			=> "http://nulix.hbe.ca/todo.jpg",
		CONTACTLIST	=> "http://nulix.hbe.ca/contactlist.jpg",
		UNKNOWN		=> "http://nulix.hbe.ca/unknown.jpg",
		CALENDAR		=> "http://nulix.hbe.ca/calendar.gif",
	);

	if(exists $paths{$doctype})
	{
		return $paths{$doctype};
	}

	return $paths{'UNKNOWN'};
}



sub getAppClass
{
	my $appId = shift;

	print STDERR "Getting name of Application for $appId\n";

	my %apps = (
		MEMOPAD		=> "MemoPad",
		CONTACTLIST	=> "ContactManager",
		APPLICATION	=> "ContactManager",
	);

	return "SW::App::" . $apps{$appId};
}


sub getApp
{
	my $doctype = shift;

	my %apps = (
		FOLDER		=> "FILEMGR",
		MEMO			=> "MEMOPAD",
		CONTACTLIST	=> "CONTACTMGR",
		CALENDAR		=> "CALENDARMGR",
		GENERIC		=> "UNKNOWN",
	);

	return $apps{$doctype};
}


#------------------------------------------------------------
# updatePath
#
# This function takes care of updating the path value,
# depending on the actions taken (change directory, go up one
# level, etc.).
#------------------------------------------------------------

sub updatePath
{
	my ($self,$which) = @_;
	my $path = "";
	my $c;

	($which eq '1') ? ($c = 'currFolder1') : ($c = 'currFolder2');

	my $currF = SW->session->getPrivateValue($c);

	while($currF ne SW->session->getPrivateValue('root'))
	{
		my $data = new SW::Data::Folder($self,$currF);
		$path = $data->getName() . "/" . $path;
		$currF = $data->getParent();
	}

	$path = "/" . $path;

	($which eq '1') ?
		SW->session->setPrivateValue('path1',$path) :
		SW->session->setPrivateValue('path2',$path);
}


#------------------------------------------------------------
# stringize
#------------------------------------------------------------

sub stringize
{
	my $string = join(',',@_);
	$string .= ',';
	return $string;
}


#------------------------------------------------------------
# arrayize
#------------------------------------------------------------

sub arrayize
{
	my @array = split(',',shift);
	return @array;
}



#------------------------------------------------------------
# displayError - method
#------------------------------------------------------------

sub displayError
{
	my ($self,$msg) = @_;
	my $mainPanel = $self->getPanel();

	$mainPanel->setValue('bgColor',$blue);
	$mainPanel->setValue('name',"Error");

	my $errorText = new SW::GUIElement::Text($self,
		{
			-text			=> "Error in processing your request"
			-font			=> $fonts,
			-fontSize	=> 3,
			-fgColor		=> $black,
			-attrib		=> BOLD,
		});

	my $msg = new SW::GUIElement::Text($self,
		{
			-text			=> $msg,
			-font			=> $fonts,
			-fontSize	=> 2,
			-fgColor		=> $gray,
			-attrib		=> BOLD + ITAL,
		});


	$mainPanel->addElement(0,0,$errorText);
	$mainPanel->addElement(0,1,$msg);

	# Set the root folder as the new current folder
	# This provides a poor way of reparing the situation
	# but it's better than nothing for the moment


	SW->session->setPrivateValue('currId',SW->session->getPrivateValue('root'));
}


#SW end

1;

__END__

=head1 NAME

FileManager - file and folder viewer/manager

=head1 SYNOPSIS

The File Manager is a very unregular application in itself.  It can be
called like a normal app would be, but it also provides a way for other
applications to include "Save As" boxes and "Open" boxes.



	my $file_viewer = new FileManager("",$self,"SAVEAS_BOX");



=head1 DESCRIPTION










=head1 REVISION HISTORY

$Log: FileManager.pm,v $
Revision 1.25  1999/11/15 18:17:27  gozer
Added Liscence on pm files

Revision 1.24  1999/09/27 20:56:19  krapht
Uses openid instead of id, and checks for permissions, if users can modify certain files

Revision 1.23  1999/09/24 18:08:17  krapht
Modified the new again so it can restart itself if it receives another
id after being started.

Revision 1.22  1999/09/23 21:53:55  krapht
Fixed a stupid bug (return before some code in new) and updatePath at the
beginning!

Revision 1.21  1999/09/23 21:46:53  krapht
Some new changes because Fred is lame : )

Revision 1.20  1999/09/23 21:40:56  krapht
Added a stupid getDataValue line because Fred can't use new

Revision 1.19  1999/09/23 20:26:39  krapht
Some minor fixes, glitches, etc.

Revision 1.18  1999/09/23 16:06:37  krapht
Works with the new Folder system (parentids inside, etc.)

Revision 1.17  1999/09/22 01:45:44  krapht
A couple of bug fixes, removed messages!!!

Revision 1.16  1999/09/21 21:15:33  krapht
Fixed some bugs related to the new session and user stuff!

Revision 1.15  1999/09/20 20:43:16  krapht
It works!!  It works!!  We fixed the problem we had with session.
_insertSignal had problems, it was setting appState as a global, but it
really is a private value for each app.

Revision 1.14  1999/09/20 20:42:28  krapht
It works!!  It works!!  We fixed the problem we had with session.

Revision 1.13  1999/09/20 15:01:47  krapht
Minor changes

Revision 1.12  1999/09/20 14:30:08  krapht
Changes in most of the files to use the new way of referring to session,
user, etc. (SW->user, SW->session).

Revision 1.11  1999/09/16 15:19:00  fhurtubi
Deleted appstate session value once we're done with it

Revision 1.10  1999/09/15 01:45:32  krapht
Minor change to a bad filename declaration in mainUI (to start apps),
added debugging messages in newDoc to find a bug that Scott had while
creating new documents.

Revision 1.9  1999/09/14 20:56:59  krapht
Fixed some stuff with FileUpload.  Now, it works in part.  The only problem
is that the file doesn't get uploaded (but it's such a minor glitch :)

Revision 1.8  1999/09/14 02:05:19  krapht
I fixed the renaming bug, worked on the UI a bit, etc.

Revision 1.7  1999/09/13 17:11:57  krapht
Working version of FileManager.  Still needs some work, permission changing
doesn't work (it's fake, gotta change this).  Also needs more work to be
called as a sub app!

Revision 1.6  1999/09/08 18:58:32  krapht
Move is almost working, and I worked on the UI a bit!

Revision 1.5  1999/09/07 16:23:17  gozer
Fixed pod syntax errors

Revision 1.4  1999/09/05 20:47:34  krapht
Paths are now OK, but some bugs appear in the manager in rare occasions
(possible race conditions??)

Revision 1.3  1999/09/05 03:44:26  krapht
Wow, way cool, lots of stuff works (renaming, deleting) and the hierarchy
seems to be ok!  We still need to fix the stuff about home creation!

Revision 1.2  1999/09/03 16:48:44  krapht
Some improvements, but I need to work on an easy way to make the app
communicate with parents!

Revision 1.5  1999/09/01 01:51:13  krapht
Newer version, changed the structure for saveas and open, etc.

 
=head1 METHODS
 
  new -  Creates a new instance
 
=head1 PARAMETERS


=head1
