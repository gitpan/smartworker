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

package SW::App::NewsManager;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for internal use only!!
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# NewsManager
# Small app to manage a news system using a database
#
# Only admins can add/edit/delete a message
#
#------------------------------------------------------------
# $Id: NewsManager.pm,v 1.5 1999/11/15 18:17:28 gozer Exp $
#------------------------------------------------------------

use SW::Util::Prep;

use strict;
use vars qw($VERSION $SW_FN_TABLE @ISA);

use SW::Application;
use SW::Data;
use SW::Panel;
use SW::GUIElement;
use SW::Util;

@ISA = qw(SW::Application);
$VERSION = '0.01';

#==================================================================#
# CONSTANTS
#==================================================================#

sub APP_ID () { "NEWSMANAGER" }
sub DATA_TYPE () { "NEWS" }

#==================================================================#
# PROGRAM
#==================================================================#

#------------------------------------------------------------
#  new
#------------------------------------------------------------
sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_); 

	bless ($self, $classname);

	$self->buildTable();
	$self->setValue("name", APP_ID);

	return $self;
} # sub new

#------------------------------------------------------------------#
# Registering the app
#------------------------------------------------------------------#
sub swInitApplication
{
        my $self = shift;

        SW::debug($self, "Registering Application ".APP_ID,2);
        $self->{master}->{appRegistry}->register(APP_ID, DATA_TYPE, "This is the news manager app");
} # sub swInitApplication

#------------------------------------------------------------------#
# Initialize some variables (once per session)
#------------------------------------------------------------------#
sub swInitInstance
{
	my $self = shift;

	# Set color prefs

	$self->{session}->{mainColor} = "#408090";
	$self->{session}->{titleColor} = "#6D67B0";
	$self->{session}->{textColor} = "#9F99D9";

	$self->{session}->{currNewsMgrId} = 0;
	$self->{session}->{maxDisp} = 10;
	$self->{session}->{firstNews} = 0;
}

#------------------------------------------------------------------#
# Action dispatcher
#------------------------------------------------------------------#
sub dispatcher
#SW TransOrder 15
{
        my $self = shift;
        
        my $appState = $self->getSessionValue('appState');
SW::debug ($self, "DISPATCHER: $appState", 3);
        
	# tricky...when we call the login function (master->error), it closes the session first,
	# we need a way to provide a msg to the user if his login isn't valid for administrating the
	# site...so if user is ne guest and justloggedin session value != 1, show msg, otherwise, dont
	# bother

	$self->{UImsg} = " ";

        if ($appState ne "") 
	{ 
		delete ($self->{UImsg}); # might be set in $appState
		$self->$appState(); 
	}
	
	if ($self->{UImsg} ne "") { # ok, if no appState, will come here, and if appState set
				    # an msg, will come here too!
		$self->buildMainUI($self->{UImsg}); 
	}
} # sub dispatcher

sub buildMainUI
{
	my $self = shift;
	my $msg = shift;
	my $userIsAdmin;

	# weird stuff, if we call Master->error, it jumps back right here without
	# printing out SW::debug stuff...weird...
	if ($self->{user}->{user} ne "guest") {
		my @groups = keys %{$self->{user}->getGroups()};
		if (!inArray('admin',\@groups)) {
			$msg = "Sorry, you are not in the administrator group!";
		} else {
			if ($self->getSessionValue("beenHere") != 1) {
				$msg = "Welcome back ".$self->{user}->{user}.", $msg";
				$self->setSessionValue("beenHere", 1);
			}
			$userIsAdmin = 1;
		}
	}

	my $mainPanel = $self->getPanel();
	$mainPanel->setValue('bgColor', "#B2B9FA");
	$mainPanel->setValue('name',"SmartWorker news page");
	my $newsPanel = new SW::Panel::HTMLPanel($self,
		-width 	=> "500",
	);

	my $lists = $self->{user}->getObjectList("NEWSLIST","ALL_GROUPS");

	print STDERR "groups returned ...".SW::Util::flatten($lists)."\n";

	# If list isn't already set in session, check whether a list already exists
	# if so, load it, otherwise, create one and use it
	if(! $self->{session}->{currNewsMgrId} )
	{
		# if there is a list, load first list (should be only one list anyways)
		if( scalar(@$lists) ) {
			$self->setSessionValue("currNewsMgrId", @$lists[0]->{objectid});
		} else 	{ # or create one otherwise
			my $newNewsList = new SW::Data($self, $self->{user}, "", "NEWSLIST");
			$newNewsList->publish($self,'GUEST',SW::Constants::READ_ONLY);

			$self->setSessionValue("currNewsMgrId", $newNewsList->getObjectId());
		}
	}

	# load list data (news that is)
	my $newsList = new SW::Data($self, $self->{user}, $self->{session}->{currNewsMgrId});
	
	my @newsList = split(',',$newsList->getValue('storage'));

	my $nbNews = @newsList;
	print STDERR "Number of news found : $nbNews \n\n";

	my $first = $self->getSessionValue("firstNews");
	my $max = $self->getSessionValue("maxDisp");

	my $row = 0;
	# if there is more news to show (newer ones)
	if( $first > 0 )
	{
		my $recentLnk = new SW::GUIElement::Link($self,
			{
				-args		=> 
				{ 
					action => 'newer' 
				},
				-text		=> "Recent news",
				-signal		=> "executeChangeNews",
			});

		$newsPanel->addElement(0,$row++,$recentLnk);
	}

	my $currNews = 0;
	
	# for each news message...
	foreach my $newsId (@newsList) 
	{
		if( $currNews < $first )
		{
			$currNews++;
			next;
		}
		elsif( $currNews >= ($first+$max) )
		{
			last;
		}

		# load data (message)
		my $news = new SW::Data($self, $self->{user}, $newsId);

		my $title = $news->getName();
		my $text = $news->getValue('storage');

		my $titleTxt = new SW::GUIElement::Text($self,
			{
				-text			=> $title,
				-textColor	=> "#ffffff",
	#			-align 		=> 'center',
				-fontSize	=> '4',
			});

		my $date = SW::Util::parseTimeStamp( $news->getValue('lastmodified') );
		my $dateStr = SW::Util::getDateStr($date);

		my $dateTxt = new SW::GUIElement::Text($self,
			{
				-text		=> $dateStr." by ".$news->getValue('creator'),
				-align 		=> "left",
				-textColor	=> "#ffffff",
				-fontSize 	=> '2',
			});

		my $titleBar = new SW::Panel::HTMLPanel($self,
			{
				-bgColor => $self->{session}->{titleColor},
				-align	=> "left",
				-grow_x	=> "true",
				-border	=> '1',
			});

		$titleBar->addElement(0,0,$titleTxt);
		$titleBar->addElement(0,1,$dateTxt);

		my $textBar = new SW::Panel::HTMLPanel($self,
			{
				-bgColor => $self->{session}->{textColor},
				-grow_x	=> "true",
				-border	=> '1',
			});
		my $textTxt = new SW::GUIElement::Text($self,
			{
				-text			=> $text,
				-textColor	=> "#000000",
			});

		$textBar->addElement(0,0,$textTxt);

		$newsPanel->addElement(0,$row++,$titleBar);
		$newsPanel->addElement(0,$row++,$textBar);

		$currNews++;
	}

	# if there is more news to show (older ones)
	if( ($first+$max) < $nbNews)
	{
		my $olderLnk = new SW::GUIElement::Link($self,
			{
				-args		=> { 
					action => 'older' 
				},
				-text		=> "Older news",
				-signal		=> "executeChangeNews",
			});

		$newsPanel->addElement(0,$row,$olderLnk);

	}

	$mainPanel->addElement(0,0,$newsPanel);

	# if user is an admin...
	if ($userIsAdmin == 1)
	{
		$mainPanel->addElement(0,1, new SW::GUIElement::Link($self,
		{
			-text	=> "Add news",
			-signal	=> "executeLogin",
			-args	=> {
				action	=> "buildEditNews",
			},
		}));
		$mainPanel->addElement(1,1, new SW::GUIElement::Link($self, {
			-text	=> "Edit news",
			-signal	=> "executeLogin",
			-args	=> {
				action	=> "buildNewsList",
				type	=> "Edit",
			},
		}));
		$mainPanel->addElement(2,1, new SW::GUIElement::Link($self, {
			-text	=> "Delete news",
			-signal	=> "executeLogin",
			-args	=> {
				action	=> "buildNewsList",
				type	=> "Delete",
			},
		}));
	} else { # leave a link to login
		$mainPanel->addElement(0,2, new SW::GUIElement::Link($self, {
			-text	=> "Admin Login",
			-signal => "executeLogin",
		}));
	}
	
	if ($msg !~ /^\s*$/) {
		my $size = [$mainPanel->getSize()]; # [1] = height
		SW::debug ($self, "HEIGHT? $size->[1]",3);

		my $msgPanel = new SW::Panel::HTMLPanel($self,
			-width 	=> "500",
		);

		$msgPanel->addElement(0, 0, new SW::GUIElement::Text ($self, {
			-text		=> $msg,
			-attrib		=> 'bold',
			-textColor	=> "ff0000",
		}));

		$mainPanel->addElement(0, $size->[1], $msgPanel);
	}
} # sub buildMainUI

#==================================================================#
# CALLBACKS
#==================================================================#
sub executeLoginWrapper
#SW Callback executeLogin 10
{
	my $self = shift;

	SW::debug($self,"Validating user - ".$self->{user}->{user});

	my @groups = keys %{$self->{user}->getGroups()};
	my $action = $self->getDataValue("action"); # either Add or Edit

	if (! inArray('admin',\@groups))	
	{ 
		# as the next method will quit this app, we need to set an appState
		# to check what happened to the login
		$self->setSessionValue("appState", "executeVerifyLogin");

		# force login
		$self->{master}->error();
	} else {
		$self->setSessionValue("appState", $action);
	}
} # sub executeLoginWrapper

sub executeEditNewsWrapper
#SW Callback executeEditNews 10
{
        my $self = shift;
        $self->setSessionValue("appState", "executeEditNews");
} # sub executeEditNewsWrapper

sub buildEditNewsWrapper
#SW Callback buildEditNews 10
{
        my $self = shift;
        $self->setSessionValue("appState", "buildEditNews");
} # sub buildEditNewsWrapper

sub executeChangeNewsWrapper
#SW Callback executeChangeNews 10
{
        my $self = shift;
        $self->setSessionValue("appState", "executeChangeNews");
} # sub executeChangeNewsWrapper

sub executeDeleteNewsWrapper
#SW Callback executeDeleteNews 10
{
        my $self = shift;
        $self->setSessionValue("appState", "executeDeleteNews");
} # sub executeDeleteNewsWrapper

sub buildNewsListWrapper
#SW Callback executeDeleteNews 10
{
        my $self = shift;
        $self->setSessionValue("appState", "buildNewsList");
} # sub buildNewsListWrapper

#==================================================================#
# INTERNAL METHODS
#==================================================================#

sub executeVerifyLogin
{
	my $self = shift;

	# now check if login was successfull
	my @groups = keys %{$self->{user}->getGroups()};
	if (! inArray('admin',\@groups)) {
		$self->{UImsg} = "You don't have an admin access";
	}
} # sub executeVerifyLogin

#------------------------------------------------------------
# if no newsID is specied, add a news item to the current news list.  
# Note that, unless specified otherwise by the owner, only the
# creator (i.e. owner) of the newslist can add news to it.
#------------------------------------------------------------

sub buildEditNews
{
	my $self = shift;

	my $NID = $self->getDataValue("NID");
	$self->setSessionValue("NID", $NID);

#toto
        my $news = new SW::Data($self, $self->{user}, $NID);

	my $mainPanel = $self->getPanel();

	my $addPanel = new SW::Panel::FormPanel($self,
		{
			-bgColor => $self->{session}->{textColor},
		});

	my $titleBox = new SW::GUIElement::TextBox($self,
		{
			-text	=> ($NID) ? $news->getName() : "",
			-name	=> "title",
			-width	=> '24',
		});

	my $newsBox = new SW::GUIElement::TextArea($self,
		{
			-text	=> ($NID) ? $news->getValue('storage') : "",
			-name	=> "news",
			-width	=> '40',
			-height	=> '8',
		});

	my $addBtn = new SW::GUIElement::Button($self,
		{
			-text	=> ($NID) ? "Edit news" : "Add news",
			-signal	=> "executeEditNews",
		});

	$addPanel->addElement(0,0,$titleBox);
	$addPanel->addElement(0,1,$newsBox);
	$addPanel->addElement(0,2,$addBtn);

	$mainPanel->addElement(0,0,$addPanel);

	$self->deleteSessionValue("appState");
} # sub buildEditNews

#-------------------------------------------------------------
# Takes care of writing the added/edited news to the database
#-------------------------------------------------------------
sub executeEditNews
{
	my $self = shift;

	# load list
	my $newsList = new SW::Data($self, $self->{user}, $self->{session}->{currNewsMgrId});

	my $NID = $self->getSessionValue("NID");
	my $news = ($NID) ? new SW::Data($self, $self->{user}, $NID, DATA_TYPE() ) :
		new SW::Data($self, $self->{user}, "", DATA_TYPE() );
 
	# save form data
	$news->{storage}->{storage} = $self->getDataValue('news');
	$news->setName( $self->getDataValue('title') );

	# basically here, we retrieve the list of news id already stored, and put the new
	# id in front (only if adding)

	if (!$NID) {
		my $newsIds = $newsList->getValue('storage');
		$newsList->{storage}->{storage} = $news->getObjectId() . ",";
		if($newsIds) {
			$newsList->{storage}->{storage} .= $newsIds;
		}
	}

	$self->{UImsg} = "News was ".(($NID) ? "edited " : "added")." succesfully";
} # sub executeEditNews

sub executeDeleteNews
{
	my $self = shift;

	my $NID = $self->getDataValue("NID");

        my $newsList = new SW::Data($self, $self->{user}, $self->{session}->{currNewsMgrId});
        my @newsList = split(',',$newsList->getValue('storage'));
	my @tmpList;
	foreach my $newsID (@newsList)
	{
 		if ($NID != $newsID) { # keep
			push (@tmpList, $newsID);
		} else {
			$self->{user}->deleteObject($newsID);
		}
	}

	$newsList->{storage}->{storage} = join (",", @tmpList);
	
	$self->{UImsg} = "News was deleted";
} # sub executeDeleteNews

sub buildNewsList
{
	my $self = shift;

	my $type = $self->getDataValue("type");
	my $newsList = new SW::Data($self, $self->{user}, $self->{session}->{currNewsMgrId});
	my @newsIDs = split(',',$newsList->getValue('storage'));

	my $mainPanel = $self->getPanel();

	foreach my $NID (@newsIDs)
	{
                my $news = new SW::Data($self, $self->{user}, $NID);
                my $title = $news->getName();
                my $date = SW::Util::parseTimeStamp( $news->getValue('lastmodified') );
                my $dateStr = SW::Util::getDateStr($date);
		$dateStr." by ".$news->getValue('creator'),

		my $newsPanel = new SW::Panel::HTMLPanel($self, {
			-bgColor	=> $self->{session}->{textColor},
		});

		$newsPanel->addElement(0,0, new SW::GUIElement::Text($self, {
			-text	=> $dateStr,
#toto
			-bgColor	=> $self->getSessionValue("titleColor"),
			-textColor	=> "ffffff",
		}));
		$newsPanel->addElement(0,1, new SW::GUIElement::Text($self, {
			-text	=> $title,
			-textColor	=> "000000",
		}));
		$newsPanel->addElement(1,1, new SW::GUIElement::Link($self, {
			-text	=> $type,
			-signal => ($type eq "Delete") ? "executeDeleteNews" : "buildEditNews",
			-args	=> {
				"NID" => $NID,
			},
		}));
		
		my $size = [$mainPanel->getSize()]; # [1] = height	
		$mainPanel->addElement(0,$size->[1], $newsPanel);
	}

	my $size = [$mainPanel->getSize()]; # [1] = height	
	$mainPanel->addElement(0,$size->[1]+1, new SW::GUIElement::Link($self, {
		-text		=> "Back to main page",	
		-bgColor	=> "dedede",
		-textColor 	=> "ffffff",
	}));
	$self->deleteSessionValue("appState");
}
#sub buildNewsList
	
#------------------------------------------------------------------#
# Load other news on screen (older/newer)
#------------------------------------------------------------------#
sub executeChangeNews
{
	my $self = shift;

	my $action = $self->getDataValue('action');

	if( $action eq 'older')
	{
		$self->{session}->{firstNews} += $self->{session}->{maxDisp};

	}
	elsif( $action eq 'newer' )
	{
		$self->{session}->{firstNews} -= $self->{session}->{maxDisp};

		if( $self->{session}->{firstNews} < 0 ) { $self->{session}->{firstNews} = 0; }
	}

	$self->{UImsg} = " "; # trick to go in buildMainUI;
} # sub executeChangeNews;


#SW end

1;    # All perl module must return true at the completion of loading
__END__

=head1 NAME

NewsManager - one line description of the module 

=head1 SYNOPSIS



=head1 DESCRIPTION


=head1 METHODS

  new -  Creates a new instance

=head1 PARAMETERS


=head1 AUTHOR

Jean-Francois Brousseau
HBE	krapht@hbe.ca
August 16/99

=head1 REVISION HISTORY

  $Log: NewsManager.pm,v $
  Revision 1.5  1999/11/15 18:17:28  gozer
  Added Liscence on pm files

  Revision 1.4  1999/09/11 07:07:33  scott
  Made substantial changes to the database schema and data storage models.
  Now there's three global tables called datamap, dataaccess, and
  datainfo.  These hide the many other more data specific tables
  where the infomation is actually stored.

  Revision 1.3  1999/09/11 07:06:07  scott
  Tweaking these apps so they work with the new datamap model
  (actually they don't change at all unless they were being bad
  and writing their own SQL).

  Revision 1.2  1999/09/04 20:52:52  fhurtubi
  Changed ref to name and target to signal where it needed to

  Revision 1.1  1999/09/02 20:11:05  gozer
  New namespace convention

  Revision 1.13  1999/08/27 19:58:17  krapht
  Changed calls to addSessionValue for setSessionValue (changed Master as well)

  Revision 1.12  1999/08/20 06:51:52  fhurtubi
  I added edit/delete functions, and I modified the code so it works with a dispatcher. There is something
  tricky in there that we might want to look at (master->error), it's working right now because i found a
  way to work around it, but it might not be the best way to do it (but there is MTOWTDI, so)

  Revision 1.11  1999/08/20 01:59:33  scott
  Fixed it so news board are published to the guest group, and so
  members of an admin group can post news.

  Revision 1.10  1999/08/19 21:11:37  krapht
  Testing some auth!

  Revision 1.9  1999/08/19 18:55:10  krapht
  This would be called version 1.0, because it works OK.  The Manager can now
  handle empty databases (i.e. no NewsLists present) gracefully, which it did
  not before.  It still needs improvement, especially on the authentication
  side.

  Revision 1.8  1999/08/19 18:03:14  krapht
  Removed some more stuff that was hardcoded!  It shouldn't have any problem when
  no NewsList is available

  Revision 1.7  1999/08/18 19:30:26  krapht
  The change between recent and old news works OK now!

  Revision 1.6  1999/08/18 16:58:39  krapht
  Added some date output for news posts

  Revision 1.5  1999/08/18 15:52:08  krapht
  Removed some of the hardcoded numbers for news list IDs.

  Revision 1.4  1999/08/18 15:17:22  krapht
  Very minor changes!

  Revision 1.3  1999/08/17 05:18:57  scott
  minor cosmetic changes - there's a lot of stuff hardcoded it here,
  hey JF!  ;-)

  Revision 1.2  1999/08/16 18:05:51  krapht
  New almost complete version.  News can be added but it needs some features
  to recognize the user, create a new News page

  Revision 1.1  1999/08/16 16:19:26  krapht
  Moved News to NewsManager (makes more sense)

  Revision 1.1  1999/08/16 16:14:03  krapht
  New app : News manager


=head1 SEE ALSO

perl(1).

=cut
