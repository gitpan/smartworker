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

package SW::App::MessageBoard;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for internal use only!!
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# MessageBoard
# Message board for groups
#------------------------------------------------------------
# $Id: MessageBoard.pm,v 1.3 1999/11/15 18:17:28 gozer Exp $
#------------------------------------------------------------

use SW::Util::Prep;

use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE);


use SW::Application;
use SW::Data;
use SW::GUIElement;
use SW::Panel;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;
use SW::Util;


@ISA = qw(SW::Application);

$VERSION = '0.01';


sub DATA_TYPE () { "MSGBOARD" }
sub APP_ID () { "MSGBOARD" }

# This token is used to separate the actual message from its parent ID
# and its generation in the database storage.  It is important that we
# choose a token that has few chances of being inserted in the message
# body.
#
# This part will be changed as soon as Data::Dumper works again.  Scott
# is working on it.

my $tok = "~";


#------------------------------------------------------------
#  new
#------------------------------------------------------------

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_); 

	bless ($self, $classname);

	$self->buildTable();

	return $self;
}




#------------------------------------------------------------
# swValidateUser
#------------------------------------------------------------
#swValidateUser gets called automatically by the framework...
#  we only want to authenticate if the user wants to post ...
#	so we'll name it something else and call it from the post
#	and add board methods

sub swValidateUser
{
	my $self = shift;

	if($self->{user}->getName() eq "guest") { return 0; }
	return 1;	
}


sub swInitInstance
{
	my $self = shift;

	SW::debug($self,"In swInitApplication : initializing session variables");

	$self->setSessionValue('flatten',0);
	$self->setSessionValue('currBoardId',0);
	$self->setSessionValue('maxDisp',100);
	$self->setSessionValue('firstPost',0);
}


#------------------------------------------------------------
# buildUI
#------------------------------------------------------------

sub swBuildUI
#SW TransOrder 15
{
	my $self = shift;
	my $mainPanel = $self->getPanel();

	# Create the necessary panels
	my $topPanel = new SW::Panel::FormPanel($self,{ -bgColor => "#777777"});
	my $msgPanel = new SW::Panel::HTMLPanel($self,{ -bgColor => "#FFFFFF"});


	# Do some DB stuff
	# Get the necessary info from the database

	my $boards = $self->{user}->getObjectList(DATA_TYPE(),"ALL_GROUPS");

	if( !$self->getSessionValue('currBoardId') && scalar @$boards )
	{
		$self->setSessionValue('currBoardId',@$boards[0]->{objectid});
	}

	my $nbBoards = @$boards;

	my @boardNames;
	my @boardIds;

	foreach my $b (@$boards)
	{
		push(@boardNames, $b->{name});
		push(@boardIds, $b->{objectid});
	}

	#Open the actual board in the DB

	my $boardData = new SW::Data($self, $self->{user}, $self->{session}->{currBoardId});

	# Create the UI on the top panel

	my $pos = 0;

	my $boardList = new SW::GUIElement::SelectBox($self,
		{
			-name			=> "boards",
			-options		=> [@boardNames],
			-values		=> [@boardIds],
			-selected	=> $self->{session}->{currBoardId},
		});

	my $boardBtn = new SW::GUIElement::Button($self,
		{
			-signal	=> "changeBoard",
			-text		=> "Go!",
		});

	$topPanel->addElement($pos++,0,$boardList);
	$topPanel->addElement($pos++,0,$boardBtn);

	my $newBoard = new SW::GUIElement::Button($self,
		{
			-signal	=> "newBoard",
			-text		=> "New discussion board",
		});

	$topPanel->addElement($pos++,0,$newBoard);

	my $newMsg = new SW::GUIElement::Button($self,
		{
			-signal	=> "newMsg",
			-text		=> "New message",
		});

	$topPanel->addElement($pos++,0,$newMsg);

	my $flatten = new SW::GUIElement::Button($self,
		{
			-signal	=> "flatten",
			-text		=> "Flatten",
		});

	my $unflatten = new SW::GUIElement::Button($self,
		{
			-signal	=> "unflatten",
			-text		=> "Unflatten",
		});

	if(!$self->{session}->{flatten})
	{
		$topPanel->addElement($pos++,0,$flatten);

	} else {
		$topPanel->addElement($pos++,0,$unflatten);

	}

	my @possibleMaxDisplays = (10,20,50,100);

	my $selectMaxDisplay = new SW::GUIElement::SelectBox($self,
		{
			-ref			=> "maxDisp",
			-options		=> [@possibleMaxDisplays],
			-values		=> [@possibleMaxDisplays],
			-selected	=> $self->{session}->{maxDisp},
		});

	my $maxDisplayBtn = new SW::GUIElement::Button($self,
		{
			-text		=> "Change",
			-target	=> "changeMaxDisplay"
		});

	$topPanel->addElement($pos++,0,$selectMaxDisplay);
	$topPanel->addElement($pos++,0,$maxDisplayBtn);

	#----------------------------------------------------------------------------#
	# Done with topPanel, start with msgPanel                                    #
	#----------------------------------------------------------------------------#

	# JF - you had a comma before your first element in $boardData
	#  so I just regex it out, and you don't have the mystery element
	#  problem anymore.   --scott

	my $boardString = $boardData->getValue('storage');
	$boardString =~ s/^,//;	

	my @ids = split(",", $boardString);

	my $nbIds = 0;

	# Clean the ids array of any invalid entries (i.e. spaces)

	foreach my $i (@ids)
	{
		if($i ne "")
		{
			$nbIds++;
		}
		else { splice(@ids,$nbIds,1); } # Remove the bad entry
	}

	my $first = $self->{session}->{firstPost};
	my $max = $self->{session}->{maxDisp};

	if($max > $nbIds) { $max = $nbIds; }

	my $header = new SW::GUIElement::Text($self,
		{
			-text	=> $boardData->getName() . " discussion",
			-attrib	=> "bold",
			-fontSize => '6',
		});

	$msgPanel->addElement(0,0,$header);

	my $limit = (($first+$max) > $nbIds) ? $nbIds : ($first+$max);

	my $tinfo;

	($nbIds) ? ($tinfo = "Messages " .($first+1). " to " .$limit. " of " .$nbIds)
				: ($tinfo = "No messages available");


	my $info = new SW::GUIElement::Text($self,
		{
			-text			=> $tinfo,
			-fontSize	=> '4',
		});

	$msgPanel->addElement(0,1,$info);

	my $row = 2;

	for(my $x = $first; $x < $limit; $x++)
	{
		my $id = $ids[$x];

		my $col = 0;

		my $msg = new SW::Data($self, $self->{user}, $id);

		if(!$msg) { return; }

		my $blob = $msg->getValue('storage');
		my @blobFields = parseBlob($blob);

		$self->{session}->{$id} = "";

		if( $blobFields[1] != -1 ) # This message has a parent
		{
			$self->{session}->{$blobFields[1]} .= $id . ",";
		}

		my $title = new SW::GUIElement::Link($self,
			{
				-args => { objectid => $id },
				-text => $msg->getName(),
				-signal => "viewMsg",
			});

		my $username = new SW::GUIElement::Text($self,
			{
				-text => $msg->getValue('creator'),
			});

		my $tmstamp = SW::Util::parseTimeStamp($msg->getValue('lastmodified'));

		my $dateStr = $tmstamp->{month} . "/" . $tmstamp->{day} . "/" . $tmstamp->{year};

      my $date = new SW::GUIElement::Text($self,
			{
				-text => $dateStr,
			});

		my $replyLink = new SW::GUIElement::Link($self,
			{
				-args		=> { parentid => $id },
				-text		=> "Reply",
				-signal	=> "reply",
			});

		# Add the generation value to the column number

		$col += $blobFields[2];

		if( $self->{session}->{flatten} ) { $col = 0; }

		$msgPanel->addElement($col,$row,$title);
		$msgPanel->addElement(6,$row,$username);
		$msgPanel->addElement(7,$row,$date);
		$msgPanel->addElement(8,$row,$replyLink);

		$row++;
	}

	my $bottomPanel = new SW::Panel::HTMLPanel($self,
		{
			-bgColor => "#FFFFFF",
		});


	if($self->{user}->getName() eq $boardData->getValue('creator'))
	{
		my $prefsLink = new SW::GUIElement::Link($self,
			{
				-text	=> "Preferences",
				-signal	=> "prefs",
			});

		$bottomPanel->addElement(0,4,$prefsLink);
	}

	if( $first > 0 )
	{
		my $goDown = new SW::GUIElement::Link($self,
			{
				-args    => { newFirst  => ($first-$max), },
				-text    => ($first-$max+1). " to " . ($first),
				-signal  => "changePosts",
			});

		$bottomPanel->addElement(0,0,$goDown);
	}

	if( ($first+$max) < $nbIds )
	{
		$limit = (($first+$max+$max) > $nbIds) ? $nbIds : ($first+$max+$max);

		my $goUp = new SW::GUIElement::Link($self,
			{
				-args    => { newFirst  => ($first+$max), },
				-text    => ($first+$max+1) . " to " . $limit,
				-signal  => "changePosts",
				-align	=> 'right',
			});

		$bottomPanel->addElement(1,0,$goUp);
	}

	# Set the title for the Web page
	$mainPanel->setValue('name',"SmartWorker Discussion Board");

	# Add all the other panels
	$mainPanel->addElement(0,0,$topPanel);
	$mainPanel->addElement(0,1,$msgPanel);
	$mainPanel->addElement(0,2,$bottomPanel);
}


#------------------------------------------------------------
# swResponseNewMsg
#
# Replaces the current discussion panel with a panel
# containing fields to fill for the addition of a new
# message to the discussion.
#------------------------------------------------------------

sub swResponseNewMsg
#SW Callback newMsg 16
{
	my $self = shift;

	$self->{session}->{reply} = 0;  # Tell addMsg that this is not a reply

	my $mainPanel = $self->getPanel();
	my $newMsgPanel = new SW::Panel::FormPanel($self, { -bgColor => "#FFFFFF"});

	my $titleBox = new SW::GUIElement::TextBox($self,
		{
			-name		=> "title",
			-width	=> '24',
		});

	my $msgBox = new SW::GUIElement::TextArea($self,
		{
			-name		=> "message",
			-width	=> '50',
			-height	=> '10',
		});

	my $acceptBtn = new SW::GUIElement::Button($self,
		{
			-signal	=> "addMsg",
			-text		=> "Send message",
		});


	$newMsgPanel->addElement(0,0,$titleBox);
	$newMsgPanel->addElement(0,1,$msgBox);
	$newMsgPanel->addElement(0,2,$acceptBtn);

	$mainPanel->addElement(0,1,$newMsgPanel);

}

#------------------------------------------------------------
# swResponseViewMsg
#
# Opens a message for viewing when clicking on the title
#------------------------------------------------------------

sub swResponseViewMsg
#SW Callback viewMsg 16
{
	my $self = shift;

	my $id = $self->getDataValue('objectid');

	my $msg = new SW::Data($self, $self->{user}, $id );

	my $mainPanel = $self->getPanel();
	my $viewPanel = new SW::Panel::FormPanel($self,
		{
			-bgColor => "#FFFFFF",
		});

	my $title = new SW::GUIElement::Text($self,
		{
			-text			=> $msg->getValue('name'),
			-fontSize	=> '5',
			-attrib		=> 'bold',
		});

	my $user = new SW::GUIElement::Text($self,
		{
			-text => $msg->getValue('creator'),
		});

	my $blob = $msg->getValue('storage');

	my @blobFields = parseBlob($blob);

	my $message = new SW::GUIElement::Text($self,
		{
			-text => "<PRE>" . $blobFields[0] . "</PRE>",
		});

	my $replyLink = new SW::GUIElement::Link($self,
		{
			-args		=> { objectid => $id },
			-text		=> "Reply",
			-signal	=> 'reply',
		});

	my $replies = new SW::GUIElement::Text($self,
		{
			-text			=> "Replies :",
			-fontSize	=> '5',
		});

	$viewPanel->addElement(0,0,$title);
	$viewPanel->addElement(1,0,$user);
	$viewPanel->addElement(0,1,$message);
	$viewPanel->addElement(0,2,$replyLink);
	$viewPanel->addElement(0,3,$replies);

	# Find the children and display them

#	my @children = buildChildrenList($self,$id);

	my @children;

	my $row = 4;

	foreach my $child (@children)
	{
		my $childMsg = new SW::Data($self, $self->{user}, $child);

		my @childBlob = split($tok,$childMsg->getValue('storage'));

		my $childTitle = new SW::GUIElement::Link($self,
			{
				-args		=> { objectid => $child },
				-text		=> $childMsg->getName(),
				-signal	=> "viewMsg",
			});

		my $childUser = new SW::GUIElement::Text($self,
			{
				-text => $childMsg->getValue('creator'),
			});

		my $tmstamp = SW::Util::parseTimeStamp($msg->getValue('lastmodified'));

		my $dateStr = $tmstamp->{month} . "/" . $tmstamp->{day} . "/" . $tmstamp->{year};

		my $childDate = new SW::GUIElement::Text($self,
			{
				-text => $dateStr,
			});

		my $childReplyLink = new SW::GUIElement::Link($self,
			{
				-args    => { parentid => $child },
				-text    => "Reply",
				-signal  => "reply",
			});

		my $col = $childBlob[2];

		$viewPanel->addElement($col++,$row,$childTitle);
		$viewPanel->addElement($col++,$row,$childUser);
		$viewPanel->addElement($col++,$row,$childDate);
		$viewPanel->addElement($col++,$row++,$childReplyLink);
	}

	my $bottomPanel = new SW::Panel::HTMLPanel($self,
		{
			-bgColor => "#FFFFFF",
			-grow_x	=> 'true',
		});

	my $goBackLnk = new SW::GUIElement::Link($self,
		{
			-text		=> "Go back",
			-signal	=> "goBack",
		});

	$bottomPanel->addElement(0,0,$goBackLnk);

	$mainPanel->addElement(0,1,$viewPanel);
	$mainPanel->addElement(0,2,$bottomPanel);
}


#------------------------------------------------------------
# swResponseAddMsg
#
# Adds a message into the database.
# Must add some error checking!
#------------------------------------------------------------

sub swResponseAddMsg
#SW Callback addMsg 1
{
	my $self = shift;

	my $msg = new SW::Data($self, $self->{user},"","MSG");

	my $msgStr = $self->getDataValue('message');

	$msgStr .= $tok;

	if( !$self->{session}->{reply} ) { $msgStr .= '-1' . $tok . '0'; }
	else
	{
		$msgStr .= $self->{session}->{parentId} . $tok;

		my $parent = new SW::Data($self, $self->{user}, $self->{session}->{parentId});

		my @stuff = parseBlob($parent->getValue('storage'));

		$msgStr .= ($stuff[2]+1);
	}
	
	$msg->{storage}->{storage} = $msgStr;

	my $msgTitle = $self->getDataValue('title') || "Unnamed message";

	$msg->setName($msgTitle);

	my $board = new SW::Data($self, $self->{user}, $self->{session}->{currBoardId});

	my $str = $board->getValue('storage');

	if( $self->{session}->{reply} )
	{
		my $token = "," . $self->{session}->{parentId} . ",";

		my ($part1,$part2) = split($token,$str);

		my $buf = $part1 . $token . $msg->getObjectId() . "," . $part2;

		$board->{storage}->{storage} = $buf;

	} else { # This is a 0 generation message, so we put it on top

		my $buf2 = "," . $msg->getObjectId() . $str;

		$board->{storage}->{storage} = $buf2;

		SW::debug($self,"Current buffer string is $buf2");

	}

	$msg->publish($self,'GUEST','READ_ONLY');
}


#------------------------------------------------------------
# swResponseReply
#
#------------------------------------------------------------
 
sub swResponseReply
#SW Callback reply 16
{
   my $self = shift;

	$self->{session}->{reply} = 1;  # Tell addMsg that this is a reply

	my $parentId = $self->getDataValue('parentid');

	my $parentData = new SW::Data($self, $self->{user}, $parentId);

	$self->{session}->{parentId} = $parentId;

	my $mainPanel = $self->getPanel();
	my $replyPanel = new SW::Panel::FormPanel($self, { -bgColor => "#FFFFFF" } );

	my $titleBox = new SW::GUIElement::TextBox($self,
		{
			-ref		=> "title",
			-width	=> '24',
			-text		=> "Re: " . $parentData->getName(),
		});

	my $msgBox = new SW::GUIElement::TextArea($self,
		{
			-ref => "message",
			-width => '50',
			-height => '10',
			-maxlength	=> '50',
		});
 
	my $acceptBtn = new SW::GUIElement::Button($self,
		{
			-target => "addMsg",
			-text => "Send reply",
		});

	$replyPanel->addElement(0,0,$titleBox);
	$replyPanel->addElement(0,1,$msgBox);
	$replyPanel->addElement(0,2,$acceptBtn);

	$mainPanel->addElement(0,1,$replyPanel);
}


#-------------------------------------------------------
# swResponseNewBoard
#-------------------------------------------------------

sub swResponseNewBoard
#SW Callback newBoard 16
{
	my $self = shift;

	my $mainPanel = $self->getPanel();
	my $boardPanel = new SW::Panel::FormPanel($self, { -bgColor => "#FFFFFF" });

	my $inst1 = new SW::GUIElement::Text($self,
		{
			-text		=> "New board name :",
			-attrib	=> "bold",
		});

	$boardPanel->addElement(0,0,$inst1);

	my $warning = "If no name is provided, the board will be named \"Unnamed ";
	$warning .= "Board\".  You can always change the name in the preferences.";

	my $inst2 = new SW::GUIElement::Text($self,
		{
			-text => $warning,
			-attrib	=> "italic",
		});

	$boardPanel->addElement(0,1,$inst2);

	my $boardName = new SW::GUIElement::TextBox($self,
		{
			-ref		=> "boardTitle",
			-width	=> '24',

		});

	$boardPanel->addElement(0,2,$boardName);

	my $submitBtn = new SW::GUIElement::Button($self,
		{
			-text		=> "Submit board",
			-target	=> "addBoard",
		});

	$boardPanel->addElement(0,3,$submitBtn);

	$mainPanel->addElement(0,1,$boardPanel);

}


#-------------------------------------------------------
# swResponseAddBoard
#
#-------------------------------------------------------

sub swResponseAddBoard
#SW Callback addBoard 1
{
	my $self = shift;

	my $newBoard = new SW::Data($self, $self->{user},"",DATA_TYPE());
	my $boardTitle = $self->getDataValue('boardTitle') || "Unnamed Board";

	$newBoard->setName($boardTitle);

	$newBoard->publish($self,'ALL','READ_WRITE');

	$self->{session}->{currBoardId} = $newBoard->getObjectId();

}


#-------------------------------------------------------
# swResponseChangeBoard
#
# Callback to change the actual message board
#-------------------------------------------------------

sub swResponseChangeBoard
#SW Callback changeBoard 4
{
	my $self = shift;

	$self->setSessionValue('currBoardId',$self->getDataValue('boards')); 
}


#-------------------------------------------------------
#
#-------------------------------------------------------

sub swResponsePrefs
#SW Callback prefs 17
{
	my $self = shift;
	my $mainPanel = $self->getPanel();

	my $prefsPanel = new SW::Panel::FormPanel($self,
		{
			-bgColor	=> "#FFFFFF",
		});

	my $titleText = new SW::GUIElement::Text($self,
		{
			-text	=> "Board title :",
		});

	my $titleBox = new SW::GUIElement::TextBox($self,
		{
			-ref     => 'newTitle',
			-width   => '24',
		});


	my $commit = new SW::GUIElement::Button($self,
		{
			-text	=> "Commit changes",
			-target	=> "changeTitle",
		});


	$prefsPanel->addElement(0,0,$titleText);
	$prefsPanel->addElement(1,0,$titleBox);
	$prefsPanel->addElement(0,1,$commit);

	$mainPanel->addElement(0,1,$prefsPanel);
}


#-------------------------------------------------------
# swResponseChangePosts
#-------------------------------------------------------

sub swResponseChangePosts
#SW Callback changePosts 5
{
	my $self = shift;

	$self->setSessionValue('firstPost',$self->getDataValue('newFirst'));
}


#-------------------------------------------------------
# swResponseFlatten
#-------------------------------------------------------

sub swResponseFlatten
#SW Callback flatten 1
{
	my $self = shift;

	$self->setSessionValue('flatten',1);
}


#-------------------------------------------------------
# swResponseUnflatten
#-------------------------------------------------------

sub swResponseUnflatten
#SW Callback unflatten 1
{
	my $self = shift;

	$self->setSessionValue('flatten',0);
}


#-------------------------------------------------------
# goBack
#-------------------------------------------------------

sub swResponseGoBack
#SW Callback goBack 4
{
	# do nothing
}


#-------------------------------------------------------
# swResponseChangeMaxDisplay
#-------------------------------------------------------

sub swResponseChangeMaxDisplay
#SW Callback changeMaxDisplay 1
{
	my $self = shift;

	$self->{session}->{maxDisp} = $self->getDataValue('maxDisp');
}


#-------------------------------------------------------
# parseBlob
#-------------------------------------------------------

sub parseBlob
{
	my $blob = shift;
	my @data = split($tok, $blob);

	return @data;
}

#-------------------------------------------------------
# buildChildrenList
#
# Recursive function that builds a tree of children
# using the ID of the parent and the indexing in
# {session} (see buildUI)
#
# Returns an array of sorted children IDs depending on
# the nesting.
#-------------------------------------------------------

sub buildChildrenList
{
	my $self = shift;
	my $rootId = shift;

	print STDERR "checking $rootId #####################################\n";

	my @childrenId = split(",",$self->{session}->{$rootId});

	my $len = @childrenId;

	print STDERR "Length of childrenId is $len and the array is " . SW::Util::flatten(\@childrenId) . "\n\n";

	my $pos = 0;

	foreach my $id (@childrenId)
	{
		if($id eq "") { next; }

		print STDERR "About to call buildChildrenList with an argument of $id\n";

		my @ids = buildChildrenList($self,$id);

		print STDERR "\n\nIn foreach :" . SW::Util::flatten(\@childrenId) . SW::Util::flatten(@ids) . "\n\n";

		splice(@childrenId,$pos++,0,@ids);

	}

	return @childrenId;
}


#SW end

1;

__END__

=head1 NAME

MessageBoard - one line description of the module 

=head1 SYNOPSIS

A cool message board system to post messages on various subjects.  Users can create new
boards, depending on the permissions set and post or read board messages.

=head1 DESCRIPTION


=head1 METHODS

  new -  Creates a new instance

=head1 PARAMETERS


=head1 AUTHOR

Jean-Francois Brousseau
HBE	krapht@hbe.ca
August 11/99

=head1 REVISION HISTORY

  $Log: MessageBoard.pm,v $
  Revision 1.3  1999/11/15 18:17:28  gozer
  Added Liscence on pm files

  Revision 1.2  1999/09/20 14:30:08  krapht
  Changes in most of the files to use the new way of referring to session,
  user, etc. (SW->user, SW->session).

  Revision 1.1  1999/09/02 20:11:05  gozer
  New namespace convention

  Revision 1.18  1999/09/01 01:34:18  krapht
  Removed the #@)(*$)(@!#%*)(#* autoloader shit

  Revision 1.17  1999/08/30 16:32:00  krapht
  FileManager finally looks a little more like what it is!!
  Some new UI stuff and displays more info

  Revision 1.16  1999/08/26 23:24:29  krapht
  New app to simulate the main desk.  MessageBoard got some minor fixes

  Revision 1.15  1999/08/19 18:03:56  krapht
  In the middle of hunting a bug in buildChildrenList

  Revision 1.14  1999/08/18 03:08:21  scott
  arrgghhh - still doesn't work with guest privileges .. I need to fix the group
    available object retrieval stilll......

  Revision 1.13  1999/08/18 02:56:30  scott
  Solved problems with publish, and the missing first message

  Revision 1.12  1999/08/17 22:43:14  krapht
  Newer version, some improvements in the display system!

  Revision 1.11  1999/08/17 21:39:18  krapht
  Changes so there can be a limit on the number of viewed messages!
  There are still problems with the App when no Message Board is available.

  Revision 1.10  1999/08/16 16:15:27  krapht
  Users can now change message boards with a select box ; added titles ;
  replies seem to work fine and boards can be created

  Revision 1.9  1999/08/13 23:45:40  krapht
  The board is now fully functional ( 95%, no vaporware!!) but I'll keep adding
  features!

  Revision 1.8  1999/08/13 19:57:49  krapht
  Changed some stuff for replies, etc.

  Revision 1.7  1999/08/13 14:35:52  scott
  Small fixes to ContactManager,  changed getDataValue('list')
  to $self->{session}->{currList} in the addCard method

  no significant changes to MessageBoard

  Revision 1.6  1999/08/12 19:43:45  krapht
  Added some date formatting, and Scott found the DB bug.  Messages now get
  written to the DB and I still need to work on the reply part

  Revision 1.5  1999/08/12 18:40:07  krapht
  Viewing of messages works, problem with writing messages to DB, though.

  Revision 1.4  1999/08/12 16:38:19  krapht
  Many things fixed, new messages can be added, viewing a message has problems!
  Next version should improve many things

  Revision 1.3  1999/08/12 13:50:57  scott
  added an error check (was debugging Data.pm problem)

  Revision 1.2  1999/08/11 22:38:36  krapht
  Second version, more database code, but still doesn't work...hmmmm strange!

  Revision 1.1  1999/08/11 16:58:25  krapht
  New app for a discussion board

  Revision 1.3  1999/07/14 21:46:03  fhurtubi
  *** empty log message ***


  Revision 1.2  1999/06/18 15:27:18  scott
  Work on User is for some changes to the database layout ....

  Master and Registry are for the new debugging


=head1 SEE ALSO

perl(1).

=cut
