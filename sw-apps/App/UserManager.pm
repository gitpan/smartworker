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
use SW::Util::Prep;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for internal use only!!
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# UserManager
#
#     A test app that doesn't do that much user management
#	   but also demontrates some of the data object
#	   access funtionality
#------------------------------------------------------------
# $Id: UserManager.pm,v 1.2 1999/09/07 16:23:17 gozer Exp $
#------------------------------------------------------------

package SW::App::UserManager;

use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE @EXPORT @EXPORT_OK);

use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;
use SW::GUIElement::RadioButtonSet;
use SW::Data::Document;
use SW::App::UserManager::Text;
use SW;

@ISA = qw(SW::Application);


# constants

sub APP_ID () {'USERMGR'}
sub DATA_TYPES () { "( 'USERMGRTYPE' ) "}
sub DATA_TYPE () { 'USERMGRTYPE'}

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);

	$self->buildTable;
	
   $self->setValue('name', APP_ID);


   $self->{stringTable} = UserManager::Text->new();
	$self->{st} = $self->{stringTable};
	$self->{currLang} = $self->getLanguage();
	
	return $self;
}


sub swValidateUser
{
	my $self = shift;

	SW::debug($self,"Validating user - ".$self->{user}->{user});

	return 0 if ($self->{user}->{user} eq "guest");
	return 1;
}

sub swInitApplication
{
	my $self = shift;

	SW::debug($self, "Registering Application ".APP_ID,2);

	$self->{master}->{appRegistry}->register(APP_ID, DATA_TYPES, "This is the user manager app");
}

sub getGroups
#SW TransOrder 10
{
	my $self = shift;

	my $groups = $self->{user}->getGroups;

	foreach my $name (keys %$groups)
	{
		push @{$self->{groups}}, $groups->{$name};
		push @{$self->{groupNames}}, $name;
	}

	SW::debug($self,"Completed getGroups",1);

}

sub getUserObjects
#SW TransOrder 11
{
	my $self = shift;

	my $objects = $self->{user}->getObjectList('ALL_TYPES');

	my $panel = new SW::Panel::HTMLPanel($self, { -name=>"ObjectPanel", -border=>1, });

	#hack! should be able to get it by name below in Build UI	
	$self->{objectPanel} = $panel;

	return unless $objects;	
	return unless @$objects > 0;

	my @objKeys = keys %{$objects->[0]};

	SW::debug($self,"In getUserObjects");

	my $col = 0;
	foreach my $heading (@objKeys)
	{
		$panel->addElement($col, 0, new SW::GUIElement::Text($self, $heading));
		$col++;
	}

	my $row = 1;

	foreach my $obj (@$objects)
	{
		for (my $o=0; $o < @objKeys; $o++)
		{
			$panel->addElement($o,$row,new SW::GUIElement::Text($self, $obj->{$objKeys[$o]}));
		}
		$row++;
	}
	SW::debug($self,"Completed getUserObjects",1);
}
		
sub getGroupObjects
#SW TransOrder 12
{
	my $self = shift;

	my $objects = $self->{user}->getGroupObjectList( "ALL_TYPES","ALL_GROUPS");

	my $panel = new SW::Panel::HTMLPanel($self, { -name=>"ObjectPanel", -border=>1, });

	#hack! should be able to get it by name below in Build UI	
	$self->{groupObjectPanel} = $panel;

	return if !$objects;
	return if (@$objects < 1);

	my @objKeys = keys %{$objects->[0]};

	SW::debug($self,"In getUserObjects");

	my $col = 0;
	foreach my $heading (@objKeys)
	{
		$panel->addElement($col, 0, new SW::GUIElement::Text($self, $heading));
		$col++;
	}

	my $row = 1;

	foreach my $obj (@$objects)
	{
		for (my $o=0; $o < @objKeys; $o++)
		{
			$panel->addElement($o,$row,new SW::GUIElement::Text($self, $obj->{$objKeys[$o]}));
		}
		$row++;
	}

	SW::debug($self,"Completed getUserObjects",1);
}



sub swBuildUI
#SW TransOrder 15
{
	my $self = shift;
	
	my $leftPanel = new SW::Panel::FormPanel($self, "NamePanel" );
	my $rightPanel = new SW::Panel::FormPanel($self);
	my $bottomPanel = new SW::Panel::FormPanel($self, {
								-name=>"SnowBoarding",
#								-debug_layout_grid=>"true",
								-grid_x=>10,
								-bgColor => "black",
							}  );



	my $image = new SW::GUIElement::Image($self, "http://www.webshots.com/photos/imgs2/snowboard3/1640-small.jpg");
	my $image3 = new SW::GUIElement::Image($self, {  -url=>"http://www.webshots.com/html/hc/sfhnk016-small.jpg",
							-border=>'1',
							-visible=>'1',
							} );
	my $image2 = new SW::GUIElement::Image($self, {  -url=>"http://www.webshots.com/photos/imgs2/snowboard3/1648-small.jpg",  
							-border=>'1',
							} );
	$self->addComponent($image3,"visibleImage");
	my $image4 = new SW::GUIElement::Image($self, {  -url=>"http://www.webshots.com/html/hc/sab015-small.jpg",  
							-border=>'1',
							} );

	my $bannerimage = new SW::GUIElement::Image($self, {  -url=>"http://www.ridesnowboards.com/news/imgs/work.jpg",  
							-border=>'1',
							} );


	my $header = $self->getTitlePanel(1);

	my $group_select = new SW::GUIElement::SelectBox($self, { 
																		-name=>'groupSelect',
																		-options=> $self->{groupNames},
																		-values=> $self->{groups},
																		});
	my $new_group_button = new SW::GUIElement::Button($self, {
																		-name=>'NewGroupButton',
																		-target=>'NewGroup',
																		-text=>$self->{st}->getString("buttonNewGroup",$self->{currLang}),
																		});

	my $del_doc_button = new SW::GUIElement::Button($self, {
																		-name=>'DeleteButton',
																		-target=>'DeleteDocs',
																		-text=>$self->{st}->getString("buttonDeleteDocs",$self->{currLang}),
																		});
	

	$leftPanel->addElement(0,2, $group_select);
	$leftPanel->addElement(0,3, $new_group_button);

	$bottomPanel->addElement(1,0, $del_doc_button);
	$bottomPanel->addElement(0,1, $image);
	$bottomPanel->addElement(1,1, $image3);
	$bottomPanel->addElement(2,1, $image2);
	$bottomPanel->addElement(0,2, $bannerimage);

	my $mainPanel = $self->getPanel();
	$mainPanel->setValue('background', "none");


	$mainPanel->addElement(0, 0, $header);
	$mainPanel->addElement(0, 1, $leftPanel);
	$mainPanel->addElement(1, 1, $rightPanel);

	$mainPanel->addElement(0, 2, $self->{objectPanel});
	$mainPanel->addElement(0, 3, $self->{groupObjectPanel}) if ($self->{groupObjectPanel});

	$mainPanel->addElement(0, 4, $bottomPanel);

	SW::debug($self,"Finished BuildUI",5);

	$mainPanel->updateState();	
} #  end of draw sub

sub createDocument
#SW Callback NewGroup 7
{
	my $self = shift;

	SW::debug($self, "Got New Group Callback",1);


}

sub deleteDocuments
#SW Callback DeleteDocs 7
{
	my $self = shift;
	my @types = eval (DATA_TYPES);

	SW::debug ($self, "Deleting documents with type ".$types[0], 5);

	my $objects = $self->{user}->getObjectList($types[0]);

	my @ids;

	foreach my $obj (@$objects)
	{
			push @ids,$obj->{objectid};
	}

	$self->{user}->deleteObject(@ids);
}

#------------------------------------------------------------------#
# Return the main header, if 1 is passed as a parameter, provide a
# for the user to change language
#------------------------------------------------------------------#
sub getTitlePanel
{
   my $self = shift;
   my $changeLang = shift || 0;


	SW::debug($self,"Beginning build of Title Panel current lang is ".$self->{currLang},5);

   my $userName = $self->{user}->getName();

   # The header panel
        my $titlePanel = new SW::Panel::FormPanel($self, {
                -bgColor        => "000000",
                -name           => "titlePanel",
      -align      => "center",
      -height     => "1%",
        });

   # The app title and welcome message to the current user
        $titlePanel->addElement(0,0, new SW::GUIElement::Text($self, {
                -text           => uc($self->{stringTable}->getString("menuHeader",$self->{currLang})),
      -fontSize   => 5,
      -textColor  => "c0c0c0",
      -attrib     => "bold",
        }));
   $titlePanel->addElement(1,0, new SW::GUIElement::Text($self, {
                -text           => $self->{stringTable}->getString("menuWelcome",$self->{currLang})." $userName",
      -attrib     => "ital",
      -attrib     => "bold",
      -align      => "center",
      -textColor  => "ffffff",
      -fontSize   => "+1",
      -grow_x     => "false",
         }));

# TODO ** Make sure there is no list of pre-defined language somewhere else

   if ($changeLang == 1) { # if we allow user to change language
      # list of our defined languages and the GO button to change language
      $titlePanel->addElement(2,0, new SW::GUIElement::SelectBox($self, {
         -ref     => 'lang',
         -options => ['English', 'Français'],
         -values     => ['en', 'fr'],
#        -options => ['English', 'Français', 'Español'],
#        -values     => ['en', 'fr', 'es'],
         -selected   => $self->{currLang},
         -width      => "1%",
      }));
           $titlePanel->addElement(3,0, new SW::GUIElement::Button($self, {
         -text    => $self->{stringTable}->getString("optionGo",$self->{currLang}),
         -width      => "1%",
           }));
   }
	SW::debug($self,"Completed build of Title Panel",5);

   return ($titlePanel);
}


#SW end

1;
__END__

=head1 NAME

UserManager - Manages Users

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 METHODS

=head1 PARAMETERS


=head1 AUTHOR

Scott Wilson
HBE   scott@hbe.ca
Jul 22/99

=head1 REVISION HISTORY

  $Log: UserManager.pm,v $
  Revision 1.2  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors

  Revision 1.1  1999/09/02 20:11:05  gozer
  New namespace convention

  Revision 1.6  1999/08/20 01:59:03  scott
  fixed a bug with the groups get I think

  Revision 1.5  1999/08/18 02:57:18  scott
  updated to reflect changes to $user->getGroups

  Revision 1.4  1999/08/17 05:19:50  scott
  changes commenced but not yet copmleted (it still works tho!)

  Revision 1.3  1999/08/11 21:34:11  scott
  changed to have a single data type

  Revision 1.2  1999/08/10 13:53:05  scott
  Added a delete button to demonstrate delete by type

  Revision 1.1  1999/07/25 02:49:59  scott
  changes to test apps.

  Most noably UserManager, displays some of the use of the
  data access methods, and the newly repaired user authentication


=head1 SEE ALSO

SW::Application,  perl(1).

=cut

