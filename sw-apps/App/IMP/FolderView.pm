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

package FolderView;
use SW::Util::Prep;
#---------------------------------------------------------------
# YaMailapp
# an IMP clone for SmartWorker
#---------------------------------------------------------------
# $Id: FolderView.pm,v 1.2 1999/09/07 16:23:22 gozer Exp $
#---------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE @EXPORT @EXPORT_OK);

use SW::Application;
use SW::Renderer;
use SW::Panel;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;
use SW::GUIElement;
use SW::GUIElement::SelectBox;  # is this really necessary?
use SW::GUIElement::Link;
use SW::GUIElement::LinkExternal;
use SW::GUIElement::Button;
use SW::GUIElement::Text;
use SW::Data;
use SW::Data::Document;

@ISA = qw(SW::Application Exporter AutoLoader);
@EXPORT = qw(

);

#
# initialise the app
#
sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	bless ($self, $classname);

#	$self->{stringTable} = Calendar::Text->new("en");

	$self->buildTable();	
	return $self;
}

sub swResponseSendMail
{
    my $self = shift;

}

sub runCompose
#SW CallBack Compose 8
{
	my $self = shift;
}


sub swResponseComposeMail
{
    my $self = shift;
    my $topPanel  = $self->getComponent("TopPanel");
    my $leftPanel = $self->getComponent("LeftPanel"); 
    my $compPanel = new SW::Panel::FormPanel($self);
    $self->debug("in swResponseComposeMail");
    $compPanel->addElement(0,1, new SW::GUIElement::Button($self, {
	-text=>"Send",
	-target=>'FolderView::SendMail',
	-postBuild=>'true'}));
    $compPanel->addElement(0,2, new SW::GUIElement::Text($self, {
	-text=>"To:"}));
    $compPanel->addElement(0,2, new SW::GUIElement::TextBox($self, {
	-ref=>'to_addr',
	-width=>'65'}));
    $compPanel->addElement(0,3, new SW::GUIElement::TextArea($self, {
	-width=>'65',
	-height=>'40',
	-ref=>'CurrentMessageBody'
	}));
    my $mainPanel = $self->getPanel();
    $mainPanel->addElement(0,0,$topPanel);
    $mainPanel->addElement(0,1,$leftPanel,2);
    $mainPanel->addElement(2,1,$compPanel);
}

sub swResponseViewMsg
{
    my $self = shift;

}

sub swResponseViewFolder
{
    my $self = shift;

}

sub swResponseContactList
{
    my $self = shift;

}

sub swBuildUI
#SW TransOrder 15
{
    my $self = shift;

#-----------------------------------------------------------------------------#
# Colours and things#
#-----------------------------------------------------------------------------#

    my $darkblue='002266';
    my $black='000000';
    my $white='ffffff';
    my $yellow='002266';
    my $offwhite='e0e0e0';
    my $softwhite='e9e9e9';
    my $grey='dcdcdc';
    my $impgfxdir = '/horde/imp/graphics/';

    my @folders=(get_local_folders());
    my $blank = new SW::GUIElement::Text($self, {-text=>'&nbsp;'});
#    my $current_render_style = $self->{renderer}->renderStyle();
#    my $current_render_style =new SW::GUIElement::Text($self, {
#	-textColor=>'red',
#	-text=>$current_render_style});

#-----------------------------------------------------------------------------#
# Top page
#-----------------------------------------------------------------------------#

    my $topPanel = new SW::Panel::FormPanel($self, {
	-name=>"TopPanel",
	-debug_layout_grid=>'true',
#	-grid_x=>10,
	-linkColor=>$white,
	-bgColor=>$darkblue});    

    my $folderSelect = new SW::GUIElement::SelectBox($self,{
	-ref=>'TopPanelfolderSelect',
	-options=>\@folders,
	-selected=>'inbox'});
#	});

    $topPanel->addElement(0,0,new SW::GUIElement::Link($self, {
	-image=>$impgfxdir.'open_folder.gif'}));
    $topPanel->addElement(1,0,$folderSelect);
    $topPanel->addElement(3,0,new SW::GUIElement::Text($self, {
	-text=>'Mailbox: status message goes here...',
	-align=>'center',
	-textColor=>$white}));
    $topPanel->addElement(5,0,new SW::GUIElement::LinkExternal($self, {
	-text=>'IMP home page',
	-align=>'right',
	-target=>'http://horde.org/imp'}));

#-----------------------------------------------------------------------------#
# Left (control) panel
#-----------------------------------------------------------------------------#

    my $leftPanel = new SW::Panel::FormPanel($self, {
	-name=>"LeftPanel",
	-grid_x=>2,
	-bgColor=>$darkblue
	});
    
    $leftPanel->addElement(0,0,new SW::GUIElement::Link($self, {
	-image=>$impgfxdir.'inbox.gif'
	}));  

# BUG:SW::GUIElement::Link: setting link colors doesn't work yet...
    $leftPanel->addElement(1,0,new SW::GUIElement::Link($self, {
	-text=>'Check Inbox',
	-linkColor=>'white',
	-vlink=>'white',
	-alink=>'white',
	-textColor=>'white'
	}));

    $leftPanel->addElement(0,1,new SW::GUIElement::Link($self, {
								-image=>$impgfxdir.'compose.gif',
								-signal=>'Compose',
								}));  
    $leftPanel->addElement(1,1,new SW::GUIElement::Link($self, {
								-target=>'/perl/Compose.pm',
								-signal=>'Compose',
								-text=>'Compose',
								-linkColor=>$white
								}));
#    $leftPanel->addElement(1,1,new SW::GUIElement::Button($self, {
#	-text=>'Try This',
#	-target=>'FolderView::ComposeMail',
#	-postBuild=>'true',
#	}));
    $leftPanel->addElement(0,2,new SW::GUIElement::Link($self, {	
	-image=>$impgfxdir.'addressbook.gif'
	})); 
    $leftPanel->addElement(1,2,new SW::GUIElement::Link($self, {
	-text=>'Contacts',
	-linkColor=>$white
	}));
 
    $leftPanel->addElement(0,3,new SW::GUIElement::Link($self, {
	-image=>$impgfxdir.'folder.gif'
	}));  
    $leftPanel->addElement(1,3,new SW::GUIElement::Link($self, {
	-text=>'Folders',
	-linkColor=>$white
	}));

    $leftPanel->addElement(0,4,new SW::GUIElement::Link($self, {
	-image=>$impgfxdir.'prefs.gif'
	}));  
    $leftPanel->addElement(1,4,new SW::GUIElement::Link($self, {
	-text=>'Preferences',
	-linkColor=>$white
	})),

    $leftPanel->addElement(0,5,new SW::GUIElement::Link($self, {
	-image=>$impgfxdir.'help.gif'
	}));  
    $leftPanel->addElement(1,5,new SW::GUIElement::Link($self, {
	-linkColor=>$white,
	-text=>'FAQ'}));

    $leftPanel->addElement(0,6,new SW::GUIElement::Text($self, {
	-text=>'&nbsp;'
	}));

#-----------------------------------------------------------------------------#
# Folder contents view panel
#-----------------------------------------------------------------------------#

#
# build some elements
#
    my $mailviewPanel = new SW::Panel::HTMLPanel($self, {
		-name=>'MailViewPanel',
		-grid_x=>10,
		-bgColor=>$white});
    my $mailviewTopPanel = new SW::Panel::FormPanel($self, {
	-name=>'MailViewTop',
	-grid_x=>10,
	-textColor=>$black,
	-bgColor=>$grey});
    my $mailviewBottomPanel = new SW::Panel::FormPanel($self, {
	-name=>'MailViewBottom',
	-grid_x=>10,
	-textColor=>$black,
	-bgColor=>$grey});

    my $selectmsg = 'Selected mail to:';
    my @tempoptions = ($selectmsg,@folders);

# BUG: SW::GUIElement::SelectBox: documentation doesn't quite jive with reality
    my $mailviewfolderSelect = new SW::GUIElement::SelectBox($self, {
		-ref=>'MailViewFolderSelect',
		-options=>\@tempoptions,
		-selected=>$selectmsg});
    my $dellink = new SW::GUIElement::Link($self,{
		-text=>'[Delete]'});
    my $undellink = new SW::GUIElement::Link($self,{
		-text=>'[Undelete]'});
    my $movelink = new SW::GUIElement::Link($self,{
		-text=>'[Move]'});
    my $copylink = new SW::GUIElement::Link($self,{
		-text=>'[Copy]'});
    my $selalllink = new SW::GUIElement::Link($self,{
		-text=>'[Select all]'});
    my $deselalllink = new SW::GUIElement::Link($self,{
		-text=>'[Deselect all]'});
    my $trashlink = new SW::GUIElement::Link($self,{
		-text=>'[Empty trash]'});
#
# now fill up the panel
#    
    $mailviewTopPanel->addElement(1,0,$dellink);
    $mailviewTopPanel->addElement(2,0,$undellink);
    $mailviewTopPanel->addElement(3,0,new SW::GUIElement::Text($self, {
	-textColor=>$black,
	-text=>'selected&nbsp;mail',
	-align=>'left'}));
#    $mailviewTopPanel->addElement(4,1,$blank);
#    $mailviewTopPanel->addElement(5,1,$blank);
    $mailviewTopPanel->addElement(5,0,$movelink);
    $mailviewTopPanel->addElement(6,0,$copylink);
    $mailviewTopPanel->addElement(7,0,$mailviewfolderSelect);

    $mailviewBottomPanel->addElement(1,0,$dellink);
    $mailviewBottomPanel->addElement(2,0,$undellink);
    $mailviewBottomPanel->addElement(3,0,new SW::GUIElement::Text($self, {
	-textColor=>$black,
	-text=>'selected&nbsp;mail',
	-align=>'left'}));
#    $mailviewBottomPanel->addElement(4,1,$blank);
#    $mailviewBottomPanel->addElement(5,1,$blank);
    $mailviewBottomPanel->addElement(5,0,$movelink);
    $mailviewBottomPanel->addElement(6,0,$copylink);
    $mailviewBottomPanel->addElement(7,0,$mailviewfolderSelect);
    $mailviewPanel->addElement(1,1,new SW::GUIElement::Text($self, {
	-bgColor=>$darkblue,
	-textColor=>$white,
	-text=>$self->getComponent('TopPanelfolderSelect')->getValue(),
	-align=>'left'}));
    $mailviewPanel->addElement(7,1,new SW::GUIElement::Text($self, {
	-bgColor=>$darkblue,
	-textColor=>$white,
	-text=>'M - N of N Messages goes here',
	-align=>'right'}));
    $mailviewPanel->addElement(1,2,$mailviewTopPanel);
    $mailviewPanel->addElement(1,4,$mailviewBottomPanel);
    

#
#
#-----------------------------------------------------------------------------#
# Main Panel
#-----------------------------------------------------------------------------#
#
#    $mainPanel->setValue('bgColor','white');
#
    my $mainPanel= $self->getPanel();

    $mainPanel->addElement(0,0,$topPanel);
    $mainPanel->addElement(0,1,$leftPanel);
    $mainPanel->addElement(2,1,$mailviewPanel);
}

#
# local subs
#
sub get_local_folders
{
    my $user = shift;

    $user = 'marcst' unless $user ;
    my $maildir = (getpwnam($user))[7]."/mail";
    my @local_folders;

    if ( -d $maildir ) {
	opendir(DIR,"$maildir");
	@local_folders = sort grep(!/^\./, readdir(DIR));
	closedir(DIR);
    }
    return @local_folders;
}

sub compose_msg
{
    return;
}

sub view_msg
{
    return;
}

#SW end

#-------------#
# return true #
#-------------#
1;
# docs start here
__END__

=head1 NAME

FolderView - Views a folder

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Marc St-Laurent, marcst@hbe.ca

=head1 SEE ALSO

perl(1).

=head1 REVISION HISTORY

  $Log: FolderView.pm,v $
  Revision 1.2  1999/09/07 16:23:22  gozer
  Fixed pod syntax errors

  Revision 1.1  1999/09/02 20:11:15  gozer
  New namespace convention

  Revision 1.4  1999/08/12 14:45:32  fhurtubi
  Little bug correction

  Revision 1.3  1999/07/18 21:02:06  scott
  commented out debug grid view - it seems broken right now

  Revision 1.2  1999/06/10 18:44:52  scott
  Fixed up to use new callbacks

  Revision 1.1  1999/05/15 00:01:18  marcst
  Simple Demo clone of IMP


=cut
