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

#!/usr/bin/perl 

#===================================================================#
#
# ContactManager.pm v1.0
# Contact Manager for SmartWorker
#
# Author: Frederic Hurtubise (fred@hbe.ca)
#
# Revisions:
#	v1.0	- Add, delete, load contact lists
#  AUG 20 99	- Add, delete, edit contacts
#		  You can also move or delete multiple contacts at
#		  one time
#		- Move a contact from one list to another list
#		  you can even create a new list and move an existing
#		  contact to that new list
#		- Sort contacts from first/last name, email address 
#		  or phone number
#		- Decide how many contacts you want to see at one time
#		- Navigate through contacts if they span over multiple
#		  screens
#		- vCard compliant
#		- French and English support
#
#==================================================================#
# $Id: ContactManager.pm,v 1.10 1999/09/20 19:51:15 gozer Exp $
#==================================================================#

#==================================================================#
# DEFINITION
#==================================================================#

package SW::App::ContactManager;

use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE);

use SW::App::ContactManager::Text;
use SW::App::ContactManager::Contact;
use SW::App::ContactManager::ContactList;

use SW::Application;
use SW::Data;
use SW::GUIElement;
use SW::Panel;
use SW::Util::Prep;
use SW::Util;

use Apache::Language;

@ISA = qw(SW::Application);

#==================================================================#
# CONSTANTS
#==================================================================#

sub APP_ID () {'CONTACTMGR'}
sub DATA_TYPE () {"CONTACTLIST"}
sub SMALL_VIEW () { 10; } # small number of contacts to show at once, this is the default one
sub LARGE_VIEW () { 25; } # large number of contacts to show at once
sub EXTRA_LARGE_VIEW () { 50; } # extra large number of contacts to show at once

#==================================================================#
# PROGRAM
#==================================================================#

#------------------------------------------------------------------#
# Create a new object
#------------------------------------------------------------------#
sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);

	# might be a good idea to change the default lang to user pref if existant
	#$self->{stringTable} = SW::App::ContactManager::Text->new();
   	$self->{Language} = new Apache::Language($self);
   
	$self->buildTable;

# TODO ** Maybe a user preference would be good here
	$self->{maxDisplay} = eval { $self->getDataValue("maxDisplay") } ||  # max number of displayed element at the same time
	$self->getSessionValue("maxDisplay");

# TODO ** Maybe a user preference would be good here
   
	#$self->{currLang} = $self->getLanguage(); # language used to draw UIs

	$self->setValue("name", APP_ID);

	# Loads all the lists name
	$self->{userLists} = {};
        foreach my $list (@{SW->user->getObjectList(DATA_TYPE)})
	{
		$self->{userLists}->{$list->{objectid}} = $list->{name};
	}

	return $self;
} # sub new


#------------------------------------------------------------------#
# Dispatcher
#------------------------------------------------------------------#
sub swDispatcher
#SW TransOrder 15
{
	my $self = shift;
	
	my $appState = $self->getSessionValue('appState');
	
	if ($appState eq "") { $self->buildMainUI; }
	else { $self->$appState(); }

	if ($self->{UImsg} ne "") { 
		$self->buildMainUI($self->{UImsg});
	}
} # sub swDispatcher

#-------------------------------------------------------------------#
# Draw the main interface
#-------------------------------------------------------------------#
sub buildMainUI
{
	my $self = shift;
	my $msg = shift;

	$self->deleteSessionValue("appState"); # make sure this isn't a leftover from a callback

	# now, add the number of contacts, i didn't do this in new because we might have an added/deleted contact in here
        foreach my $list (keys %{$self->{userLists}})
	{
		my $loadedList = SW::App::ContactManager::ContactList->load($self, $list);
		$self->{userLists}->{$list} .= " [".$loadedList->getNbContacts()."]";
	}

	# the current list is either the new list that has just been selected or 
	# the list that is currently in used (in the session data) or
	# the first one in the user's list
	# NOTE: the order is important 

	$self->{currList} = 
		eval { $self->getDataValue("currList") } 		|| # user just changed list
		eval { $self->getSessionValue("currList") }		|| # everything else i guess :)
		"";

	if ($self->{currList} eq "") { # magic trick to get first key that appears in the list
		foreach my $key (sort {$self->{userLists}->{$a} cmp $self->{userLists}->{$b}} keys (%{$self->{userLists}}))
		{
			$self->{currList} = $key;
			last;
		}
	}

	$self->setSessionValue("currList", $self->{currList});

	my $currList;
	my $numberOfContacts = 0;
	if ($self->{currList} ne "") {
		$currList = SW::App::ContactManager::ContactList->load($self, $self->{currList});
		$numberOfContacts = $currList->getNbContacts();
	}
	
	# if it's first call, set to the lowest value from SMALL_VIEW or numberOfContacts
	if ($self->{maxDisplay} eq "") {
		if ($numberOfContacts < SMALL_VIEW) { $self->{maxDisplay} = $numberOfContacts; }
		else { $self->{maxDisplay} = SMALL_VIEW; }
	}
	
	my $listOfCIDs = eval {$currList->getContactList()} || ();

	# Load some info for all CIDs in this list in order to print them on screen
	foreach my $CID (@{$listOfCIDs})
	{
		my $contact = SW::App::ContactManager::Contact->load($self, $CID);
		foreach my $key (("lastName", "firstName", "tel", "email"))
		{
			$currList->{contacts}->{$CID}->{$key} = $contact->getValue($key);
		}
	}

	# contacts can be sorted by lastName, firstName, phoneNumber or emailAddress
	my $sortOrder = eval { $self->getDataValue("sort") } || # user clicked on a column
		"lastName";					# default to lastName

	my $titlePanel = $self->getTitlePanel(1); # 1 is to get the language switching option

	# the topMenuPanel will contain the list options (switch, new, delete) as well as the logoff button
        my $topMenuPanel = new SW::Panel::HTMLPanel($self, {
                -bgColor        => "c0c0c0",
                -name           => "topMenuPanel",
        });

	# the bottomMenuPanel will contain information related to the contacts (how many showned, forward, reverse)
	my $bottomMenuPanel = new SW::Panel::FormPanel($self, {
                -bgColor        => "c0c0c0",
                -name           => "bottomMenuPanel",
        });

	# the contentPanel is where the action is!
	my $contentPanel = new SW::Panel::FormPanel($self, {
		-bgColor	=> "ffffff",
		-name		=> "contentPanel",
	});

	my $newListPosition = 0; # if there is a list, will be set to 5

	my $listPanel = new SW::Panel::FormPanel($self, {
		-grow_x		=> "false",
	});

	if (%{$self->{userLists}}) { # if there is at least one list
		# List of user lists, a load button, a new list button, a delete list button and a quit button
		
		$listPanel->addElement(0,0, new SW::GUIElement::SelectBox($self, {
			-name		=> 'currList',
			-optval		=> $self->{userLists},
			-selected 	=> $self->{currList},
        	}));	
	        $listPanel->addElement(1,0, new SW::GUIElement::Button($self, {
#        	        -text   	=> $self->{Language}{"menuLoadList"},),
                    -text     => $self->{Language}{"menuLoadList"},
	        }));
		$listPanel->addElement(2,0, $self->transparentGIF(10,1));
	        $listPanel->addElement(3,0, new SW::GUIElement::Button($self, {
        	        -text   	=> $self->{Language}{"menuDeleteList"},
                	-signal 	=> "executeDeleteList",
	        }));
		$listPanel->addElement(4,0, $self->transparentGIF(10,1));
	
		$newListPosition = 5;
	}

	$listPanel->addElement($newListPosition,0, new SW::GUIElement::Button($self, {
                -text   	=> $self->{Language}{"menuCreateList"},
                -signal 	=> "buildNewList",
        }));

	$listPanel->addElement($newListPosition+1,0, $self->transparentGIF(10,1));

# TODO ** This is suppose to logout the user. We need to implement that function in SW/Master.pm
        $listPanel->addElement($newListPosition+2,0, new SW::GUIElement::Button($self, {
		-text   	=> $self->{Language}{"menuLogOut"},
		-signal 	=> "logOut",
		-align		=> "right",
		-width		=> "100%",
	}));

	$topMenuPanel->addElement(0,0, $listPanel);

	# this is where to start in showing the contacts
	my $startCard = eval { $self->getDataValue("start") } 	|| 
		eval { $self->getSessionValue("start") }	||
		1;

	# this is where to end in showing the contacts
	my $endCard = eval { $self->getDataValue("end") } 	|| 
		eval { $self->getSessionValue("end") } 		||
		$self->{maxDisplay}				||
		$numberOfContacts;

	if ($endCard) { # probably not 1st call
		# just check to make sure there is enough cards
		if ($endCard > $numberOfContacts) { $endCard = $numberOfContacts; }
		# just make sure the value didn't get clobbered by the All trick
		if ($endCard eq "All") { $endCard = $numberOfContacts; }
	}

	# when rewinding, sometimes, endCard is smaller than it should be
	if ($startCard == 1 && (($endCard < $self->{maxDisplay}) && ($numberOfContacts > $self->{maxDisplay})) ) 	{
		$endCard = $self->{maxDisplay};
	}

	# Spacer for 1st column
	$contentPanel->addElement(0,0, new SW::GUIElement::Text($self, {
		-text		=> "&nbsp;",
		-bgColor	=> "dedede",
	}));

	# 1st element is the name referred to in the language dictionnary
	# 2nd element is the key to the hash under $self->{vCard}->{$CID}
	my (@columns) = (["vCard::name::last", "lastName"], ["vCard::name::first", "firstName"], ["vCard::telephone::number", "tel"], ["vCard::email::value", "email"]);

	for (my $x = 0; $x < @columns; $x++) # we have to start the x column at 1
	{
		# Headers for the data columns, they can be clicked to sort the order of the data
		$contentPanel->addElement($x + 1, 0, new SW::GUIElement::Link($self, {
			-text		=> $self->{Language}{$columns[$x]->[0]},
			-args		=> {
				sort		=> $columns[$x]->[1],
				start		=> $startCard,
				end		=> $endCard,
			},
			-attrib		=> ($sortOrder eq $columns[$x]->[1]) ? "ital" : "",
			-bgColor	=> "dedede",
		}));
	}

	# Headers for edit, move and delete columns
	$contentPanel->addElement(5,0, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"optionEdit"},
		-attrib		=> "bold",
		-bgColor	=> "dedede",
	}));
	$contentPanel->addElement(6,0, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"optionMove"},
		-attrib		=> "bold",
		-bgColor	=> "dedede",
	}));
	$contentPanel->addElement(7,0, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"optionDelete"},
		-attrib		=> "bold",
		-bgColor	=> "dedede",
	}));

	my $displayCounter = 1; # this will be used to track down how many elements were printed 
				# (and used for displaying additional rows)
	my $startCounter = 1; # this is used to make sure we start at the right element
	my $endCounter = $startCard; # this is used to make sure we end at the right element

	# sort the cards by the value of the column determined in the sortOrder
	foreach my $CID (sort {lc($currList->{contacts}->{$a}->{$sortOrder}) cmp lc($currList->{contacts}->{$b}->{$sortOrder})} keys %{$currList->{contacts}}) 
	{
		if ($startCounter < $startCard) { 
			$startCounter++;
			next; 
		} # loop until we get to right start card
		
		# Checkbox to select contact, last name, first name, phone number, email address, icons to edit/move/delete contact
		$contentPanel->addElement(0,$displayCounter, new SW::GUIElement::CheckBox($self, {
			-name		=> "CID$CID",
			-value		=> 1,
		}));

		$contentPanel->addElement(1,$displayCounter, new SW::GUIElement::Link($self, {
			-text		=> $currList->{contacts}->{$CID}->{lastName} || "N/A",
			-args		=> {
				"CID$CID"	=> 1,
				end		=> $endCard,
				start		=> $startCard,
			},
			-signal		=> "buildViewContact",
		}));
		$contentPanel->addElement(2,$displayCounter, new SW::GUIElement::Text($self, {
			-text		=> $currList->{contacts}->{$CID}->{firstName},
		}));
		# take the 1st phone number that has been filled in this order (home, work, cellular, pager)
		$contentPanel->addElement(3,$displayCounter, new SW::GUIElement::Text($self, {
			-text		=> $currList->{contacts}->{$CID}->{tel},
		}));
		$contentPanel->addElement(4,$displayCounter, new SW::GUIElement::LinkExternal($self, {
			-text		=> $currList->{contacts}->{$CID}->{email},
			-target		=> ($currList->{contacts}->{$CID}->{email}) ? "mailto:$currList->{contacts}->{$CID}->{email}" : "",
		}));
		$contentPanel->addElement(5,$displayCounter, new SW::GUIElement::Link($self, {
			-args		=> {
				"CID"	=> 	$CID,
			},
			-image		=> $self->editIcon,
			-signal		=> "buildEditContact",
		}));
		$contentPanel->addElement(6,$displayCounter, new SW::GUIElement::Link($self, {
			-args		=> {
				"CID$CID"	=> 1,
			},
			-image		=> $self->moveIcon,
			-signal		=> "buildMoveContacts",
		}));
		$contentPanel->addElement(7,$displayCounter, new SW::GUIElement::Link($self, {
			-args		=> {
				"CID$CID"	=> 1,
			},
			-image		=> $self->deleteIcon,
			-signal		=> "buildDeleteContacts",
		}));

		$displayCounter++; 

		if ($endCounter >= $endCard) { last; } # stop because we already have all the cards we wanted
		else { $endCounter++; }
	}
	
	# Blank line
	$contentPanel->addElement(0,$displayCounter + 1, $self->transparentGIF(1,20));

	my $buttonPanel = new SW::Panel::HTMLPanel($self, {
		-grow_x		=> "true",
		-border		=> 0,
	});

	if ($numberOfContacts >= 1) # if there were contacts to show, ie: not empty list
	{
		# CheckAll/UncheckAll, buttons to send mail/move/delete selected contacts and button to add a new contact
		$contentPanel->addElement(0, $displayCounter+2, $self->checkAllJS());

# TODO ** The email function needs more work on it
#		$buttonPanel->addElement(0,0, new SW::GUIElement::Button ($self, {
#			-text           => $self->{Language}{"menuSendEmail"},
#	                -signal         => "buildEmailContacts",
#      		}));
	
		# Blank line
		$buttonPanel->addElement(1,0, $self->transparentGIF(1,20));

		$buttonPanel->addElement(2,0, new SW::GUIElement::Button ($self, {
			-text           => $self->{Language}{"optionMove"},
                	-signal         => "buildMoveContacts",
	        }));
		# Blank line
		$buttonPanel->addElement(3,0, $self->transparentGIF(1,20));

		$buttonPanel->addElement(4,0, new SW::GUIElement::Button ($self, {
			-text           => $self->{Language}{"optionDelete"},
        	        -signal         => "buildDeleteContacts",
	        }));
	
		if ($startCard > 1) { # we are not at first contact, provide way to go back
			# Rewind (all the way) and step back (1 screen) buttons
			$bottomMenuPanel->addElement(0,0, new SW::GUIElement::Link ($self, {
				-text		=> "<<",
				-args		=> {
					start 		=> 1,
					sort		=> $sortOrder,
				},
			}));
			$bottomMenuPanel->addElement(1,0, new SW::GUIElement::Link($self, {
				-text		=> "<",
				-args		=> {
					start		=> (($startCard - $self->{maxDisplay}) > 1) ? ($startCard - $self->{maxDisplay}) : 1,
					end		=> $startCard - 1,
					sort		=> $sortOrder,
				},
			}));
		}

		# Show which cards we are displaying out of how many
		$bottomMenuPanel->addElement(2,0, new SW::GUIElement::Text($self, {
			-text		=> $self->{Language}{"menuShowing"} ." $startCard-$endCard ".$self->{Language}{"menuOf"}." $numberOfContacts",
		}));

		if ($numberOfContacts > $endCard) { # we are not at last contact, provide way to go forward
			# Step forward (1 screen) and Forward (all the way) buttons
			$bottomMenuPanel->addElement(3,0, new SW::GUIElement::Link($self, {
				-text		=> ">",
				-args		=> {
					start		=> $endCard + 1,
					end		=> (($endCard + $self->{maxDisplay}) > $numberOfContacts) ? $numberOfContacts : ($endCard + $self->{maxDisplay}),
					sort		=> $sortOrder,
				},
			}));
			$bottomMenuPanel->addElement(4,0, new SW::GUIElement::Link ($self, {
				-text		=> ">>",
				-args		=> {
					start		=> ($numberOfContacts > $self->{maxDisplay}) ? ($numberOfContacts - $self->{maxDisplay} + 1) : 1,
					end 		=> $numberOfContacts,
					sort		=> $sortOrder,
				},
			}));
		}	

		$bottomMenuPanel->addElement(7, 0, new SW::GUIElement::Text ($self, {
			-text		=> $self->{Language}{"menuContactsToShow"},
		}));

		my $cardsToShow;

		# if number of contacts is greater than each pre-defined view, allow the user to select that view
		foreach my $view ((SMALL_VIEW, LARGE_VIEW, EXTRA_LARGE_VIEW))
		{
			if ($numberOfContacts > $view) { 
				push (@{$cardsToShow->{options}}, $view);
				push (@{$cardsToShow->{values}}, $view);
			}
		}                

		# if the last available view for the user isn't the max number of contacts, let the user select all contacts
		if (@{$cardsToShow->{options}}->[$#{$cardsToShow->{options}}] != $numberOfContacts) { 
			push (@{$cardsToShow->{options}}, "All");
			push (@{$cardsToShow->{values}}, "All");
		}

		# now let the user to select the view he wants (defaults to SMALL_VIEW by the way)
		$bottomMenuPanel->addElement(8, 0, new SW::GUIElement::SelectBox ($self, {
			-name		=> 'maxDisplay',
			-options	=> $cardsToShow->{options},
			-values		=> $cardsToShow->{values},
			-selected	=> ($self->{maxDisplay} eq $numberOfContacts) ? "All" : $self->{maxDisplay},
		}));

		$bottomMenuPanel->addElement(9,0, new SW::GUIElement::Button ($self, {
			-text   	=> $self->{Language}{"optionGo"},
		}));	
	} else 	{ # there were no contacts to show for this list
		# either print a no contact in this list or no list message
		$contentPanel->addElement(1, $displayCounter + 2, new SW::GUIElement::Text($self, {
			-text		=> $self->{Language}{(%{$self->{userLists}}) ? "menuNoContact" : "menuNoList"},
			-grow_x		=> "true",
			-align		=> "center",
		}));

	}

	if (%{$self->{userLists}}) { # if at least one list
		# Blank line
		$buttonPanel->addElement(5,0, $self->transparentGIF(1,20));
		# The Add a contact button
      		$buttonPanel->addElement(6,0, new SW::GUIElement::Button ($self, {
			-text   	=> $self->{Language}{"menuAddNewCard"},
			-signal		=> "buildEditContact",
		}));	
		# Blank line
		$buttonPanel->addElement(7,0, $self->transparentGIF(1,20));

# TODO ** Fix the import method
#		# The Import a contact button
#	      	$buttonPanel->addElement(8,0, new SW::GUIElement::Button ($self, {
#			-text   	=> $self->{Language}{"optionImport"},
#			-signal		=> "buildImportContact",
#		}));	
	}
	$contentPanel->addElement(2,$displayCounter+2, $buttonPanel);

        my $mainPanel = $self->getPanel();
#	$mainPanel->setValue('fgColor', "000000");	

	$mainPanel->addElement(0, 0, $titlePanel);
	$mainPanel->addElement(0, 1, $topMenuPanel);
	$mainPanel->addElement(0, 2, $contentPanel);
	$mainPanel->addElement(0, 3, $bottomMenuPanel);

        if ($msg !~ /^\s*$/) {
                my $msgPanel = new SW::Panel::HTMLPanel($self, {
                        -bgColor        => "dedede",
                        -align          => 'center',	
			-grow_x		=> "center",
                });
                $msgPanel->addElement(0, 0, new SW::GUIElement::Text($self, {
                        -text           => $msg,
                        -attrib         => 'bold',
			-align		=> "center",
                }));
        
                $mainPanel->addElement(0, 4, $msgPanel);
        }
                
        $mainPanel->setValue('name',"SmartWORKER Contact List Manager");
	$mainPanel->setValue('jsLib', ["contactManager.js"]);
        
        $mainPanel->updateState();
} # sub buildMainUI

#===================================================================#
# CALLBACKS
#===================================================================#

sub executeDeleteListWrapper
#SW Callback executeDeleteList 10
{               
        my $self = shift;
        $self->setSessionValue("appState", "executeDeleteList");
} # sub executeDeleteListWrapper

sub buildNewListWrapper
#SW Callback buildNewList 10
{
        my $self = shift;
        $self->setSessionValue("appState", "buildNewList");
} # sub buildNewListWrapper

sub executeNewListWrapper
#SW Callback executeNewList 10
{
        my $self = shift;
        $self->setSessionValue("appState", "executeNewList");
} # sub executeNewListWrapper

sub logOutWrapper
#SW Callback logOut 10
{
        my $self = shift;
        $self->setSessionValue("appState", "logOut");
} # sub logOutWrapper

sub buildEmailContactsWrapper
#SW Callback buildEmailContacts 10
{               
        my $self = shift;
        $self->setSessionValue("appState", "buildEmailContacts");
} # sub buildEmailContactsWrapper

sub buildMoveContactsWrapper
#SW Callback buildMoveContacts 10
{
        my $self = shift;
        $self->setSessionValue("appState", "buildMoveContacts");
} # sub buildMoveContactsWrapper

sub executeMoveContactsWrapper
#SW Callback executeMoveContacts 10
{
        my $self = shift;
        $self->setSessionValue("appState", "executeMoveContacts");
} # sub executeMoveContactsWrapper

sub buildDeleteContactsWrapper
#SW Callback buildDeleteContacts 10
{
        my $self = shift;
        $self->setSessionValue("appState", "buildDeleteContacts");
} #sub buildDeleteContactsWrapper

sub executeDeleteContactsWrapper
#SW Callback executeDeleteContacts 10
{
        my $self = shift;
        $self->setSessionValue("appState", "executeDeleteContacts");
} #sub executeDeleteContactsWrapper

sub buildEditContactWrapper
#SW Callback buildEditContact 10
{
        my $self = shift;
        $self->setSessionValue("appState", "buildEditContact");
} #sub buildEditContactWrapper

sub executeEditContactWrapper
#SW Callback executeEditContact 10
{
        my $self = shift;
        $self->setSessionValue("appState", "executeEditContact");
} #sub executeEditContactWrapper

sub buildImportContactWrapper
#SW Callback buildImportContact 10
{
        my $self = shift;
        $self->setSessionValue("appState", "buildImportContact");
} # sub buildImportContactWrapper

sub executeImportContactWrapper
#SW Callback executeImportContact 10
{
        my $self = shift;
        $self->setSessionValue("appState", "executeImportContact");
} # sub executeImportContactWrapper

sub buildViewContactWrapper
#SW Callback buildViewContact 10
{
        my $self = shift;
        $self->setSessionValue("appState", "buildViewContact");
} # sub buildViewContactWrapper

sub cancelState
#SW Callback cancelState 10
{
	my $self = shift;
	$self->setSessionValue("appState", "executeCancelState");
}
#sub cancelState

#SW end

#==================================================================#
# Calls from wrappers
#==================================================================#

#-------------------------------------------------------------------#
# Checks whethere there is contacts in this list first, 
# if so, tells user to do so, otherwise, delete (no confirmation, list
# is empty anyways)
#-------------------------------------------------------------------#
sub executeDeleteList
{
        my $self = shift;
	my $msg;
	my $listToDelete = $self->getDataValue("currList");

	my $currList = SW::App::ContactManager::ContactList->load($self, $listToDelete);
	if ($currList->getNbContacts >= 1) {
		$msg = "There is at least one contact in this list. You will have to delete them first.";
	} else {
		SW->user->deleteObject($listToDelete); # remove from db
		delete $self->{userLists}->{$listToDelete}; # remove from selectbox
		$self->deleteDataValue("currList"); # remove from data 
		$self->deleteSessionValue("currList"); # remove from memory also...

		$msg = "List ".$currList->getName." was deleted";
	}

	$self->{UImsg} = $msg;
} # sub executeDeleteList

#------------------------------------------------------------------#
# Asks for the new list name
#------------------------------------------------------------------#
sub buildNewList
{
        my $self = shift;
        
        my $newPanel = new SW::Panel::FormPanel($self);

	# Creating a new list
        $newPanel->addElement(0,0, new SW::GUIElement::Text($self, {
                -text           => $self->{Language}{"creatingNewListTitle"},
                -bgColor        => "dedede",
		-fontSize	=> 5,
		-attrib		=> "bold",
		-grow_x 	=> "true",
        }));

	# Enter list name below
        $newPanel->addElement(0,1, new SW::GUIElement::Text($self, {
                -text           => $self->{Language}{"enterNewListName"},
                -bgColor        => "dedede",
		-fontSize	=> 2,
		-attrib		=> "ital",
		-grow_x 	=> "true",
        }));

	# The new list name
        $newPanel->addElement(0,2, new SW::GUIElement::TextBox($self, {
		-name		=> "newList",
		-width		=> 20,
		-maxlength	=> 20,
		-grow_x 	=> "true",
        }));

	# Create and Cancel buttons
	$newPanel->addElement(0,3, new SW::GUIElement::Button ($self, {
		-text           => $self->{Language}{"optionCreate"},
                -signal         => "executeNewList",
        }));
	$newPanel->addElement(1,3, new SW::GUIElement::Button ($self, {
		-text           => $self->{Language}{"optionCancel"},
		-signal		=> "cancelState",
		-width		=> "1%",
        }));

	my $mainPanel = $self->getPanel();
	$mainPanel->setValue('name',"SmartWORKER Contact List Manager");
	$mainPanel->setValue("bgColor", "ffffff");

        $mainPanel->addElement (0, 0, $self->getTitlePanel);
        $mainPanel->addElement (0, 1, $newPanel);

	$self->deleteSessionValue("appState");
} # sub buildNewList

#------------------------------------------------------------------#
# Create the new list
#------------------------------------------------------------------#
sub executeNewList
{               
	my $self = shift;

	my $wantedListName = $self->getDataValue("newList") || shift; # the list name, or a passed parameter in case
								      # this is a move and create operation
	my $typeOfTransaction = shift; # if this is called within a move to new list, will be set to 1
	my $msg;				 

	if ( inArray($wantedListName, [sort values %{$self->{userLists}}]) )  # new list but already exists
	{
		$msg = "This list already exists, transaction was not processed.";
		$self->deleteDataValue("currList"); # because up in buildMainUI, it checks for dataValue (currList) first
						    # then the session currList, and we want to keep the session one here
	} elsif ($wantedListName =~ /^\s*$/) {
		$msg = "You didn't supply a list name, transaction was not processed.";
		$self->deleteDataValue("currList");
	} else { # if list isn't existing already
		my $newList = SW::App::ContactManager::ContactList->new($self, '');
		$newList->setName($wantedListName);
		$newList->setAppId($self->APP_ID);

	    	# remove old session value and replace with the new name
		$self->deleteSessionValue("currList");
		$self->setSessionValue("currList", $newList->getObjectId());

		$self->{userLists}->{$newList->getObjectId()} = $wantedListName;

		$self->{UImsg} = "List $wantedListName was created";
		if ($typeOfTransaction == 1) { return $newList->getObjectId(); }
		return $newList->getObjectId();
	}

	$self->{UImsg} = $msg;

} # sub executeNewList

#-------------------------------------------------------------------#
# Logout Contact Manager
#-------------------------------------------------------------------#
sub logOut
{
        my $self = shift;
	my $msg;        

#TODO ** add the logout part in Master
#	$self->{master}->logOut;

	$msg = "Normally, you would have logged out, but I guess you didn't :)";
	$self->{UImsg} = $msg;
} # sub logOut

#-------------------------------------------------------------------#
# Email to selected contacts
#-------------------------------------------------------------------#
sub buildEmailContacts
{
        my $self = shift;
	my $msg;
        
	my $foundKeys = $self->findDataKey("CID");
	my @listOfKeys;

	foreach my $key (sort {$a <=> $b} keys %{$foundKeys})
	{
		if ($key !~ /^CID\d+$/) { next; } # we want only those who starts with CID as they are the checkbox keys
		$key =~ s/CID//;
		push (@listOfKeys, $key);
	}

	if (!@listOfKeys) {  # no keys, no cards
		$msg = "No contact was checked, can't email to nobody!";
	} else {

# TODO ** Call the email application (and decide which recipient is the To)

		$msg = "Emailing to CID ".join(", ", @listOfKeys);
	}

	$self->cancelState(1); # the 1 means don't go to buildMainUI afterwards, but come back here

	$self->{UImsg} = $msg;
} # sub buildEmailContacts

#-------------------------------------------------------------------#
# Before a contact is deleted, we need to get a user confirmation
#-------------------------------------------------------------------#
sub buildDeleteContacts
{
        my $self = shift;
	my $msg;
        
        my $newPanel = new SW::Panel::FormPanel($self, { 
		-grow_x	=> "true",
	});

	# Confirm the deletion
        $newPanel->addElement(0,0, new SW::GUIElement::Text($self, {
                -text           => $self->{Language}{"confirmDelete"},
                -bgColor        => "dedede",
		-fontSize	=> 5,
		-attrib		=> "bold",
        }));

	# Tell user that only checked items will be deleted
        $newPanel->addElement(0,1, new SW::GUIElement::Text($self, {
                -text           => $self->{Language}{"checkedDelete"},
                -bgColor        => "dedede",
		-attrib		=> "ital",
        }));

	my $displayCounter = 2; # start at 3rd row

	my $foundKeys = $self->findDataKey("CID"); # anon hash to all keys matching CID (checked contacts)

	if ($foundKeys) # if there is some contacts to delete
	{
		foreach my $CID (sort {$a cmp $b} keys %{$foundKeys})
		{
			if ($CID =~ /^CID\d+$/) { $CID =~ s/CID//; } # will be in the form of CID123, we need only the 123 part
			else { next; } # not suppose to happen
		
			# Checkbox (already checked) plus name of contact to delete
			$newPanel->addElement(0,$displayCounter, new SW::GUIElement::CheckBox($self, {
				-name		=> "CID$CID",
				-value		=> "1",
				-checked	=> 1,
				-align		=> "right",
				-width		=> "1%",
			}));

			my $vCard = SW::App::ContactManager::Contact->load ($self, $CID);
			$newPanel->addElement(1,$displayCounter, new SW::GUIElement::Text($self, {
				-text		=> ($vCard->getValue("lastName") eq "" && $vCard->getValue("firstName") eq "") ? "N/A" : 
					$vCard->getValue("lastName").",".$vCard->getValue("firstName"),
				-align		=> "left",
			}));
			$displayCounter++; # now print on next row
		}

		# Delete and Cancel buttons
		$newPanel->addElement(0,$displayCounter, new SW::GUIElement::Button ($self, {
			-text           => $self->{Language}{"optionDelete"},
                	-signal         => "executeDeleteContacts",
	        }));
		$newPanel->addElement(1,$displayCounter, new SW::GUIElement::Button ($self, {
			-text           => $self->{Language}{"optionCancel"},
			-signal		=> "cancelState",
	        }));	
	} else 	{ # nothing has been checked
		# Message telling the user that nothing has been checked
		$newPanel->addElement(0,$displayCounter, new SW::GUIElement::Text ($self, {
			-text		=> $self->{Language}{"optionNoChecked"},
		}));

		# Blank line
		$newPanel->addElement(0,$displayCounter + 1, $self->transparentGIF(1,10));

		# Done button to return to main UI
		$newPanel->addElement(0,$displayCounter + 2, new SW::GUIElement::Button ($self, {
			-text           => $self->{Language}{"optionDone"},
			-signal		=> "cancelState",
	        }));	
	}

	my $mainPanel = $self->getPanel();
	$mainPanel->setValue('name',"SmartWORKER Contact List Manager");
	$mainPanel->setValue("bgColor", "ffffff");

       	$mainPanel->addElement (0, 0, $self->getTitlePanel);
        $mainPanel->addElement (0, 1, $newPanel);

	$self->deleteSessionValue("appState");
} # sub buildDeleteContacts

#-------------------------------------------------------------------#
# Once the user has confirm the deletes, it's time to delete!
#-------------------------------------------------------------------#
sub executeDeleteContacts
{
        my $self = shift;
	my $msg;
        
	my $keysFound = $self->findDataKey("CID"); # anon hash containing contacts to be deleted

	if ($keysFound) { # if there was checked contacts to be deleted

		my $currList = SW::App::ContactManager::ContactList->load ($self, $self->getSessionValue('currList'));
		my $count = 0;
		foreach my $key (sort {$a cmp $b} keys %{$keysFound})
		{
			if ($key =~ /^CID\d+$/) { $key =~ s/CID//; }
			else { next; } # not suppose to happen!!!

			$currList->deleteContact($key); # remove CID from list & DB
			$count++;
		}
		$msg = "$count checked contacts were deleted.";
	} else {
		$msg = "No contact was deleted because you didn't check any of them!";
	}

	# now that all data has been taken care of, delete refs to CIDs so that contacts don't come back checked in main UI
	$self->cancelState(1); # the 1 means don't go to buildMainUI afterwards, but come back here

	$self->{UImsg} = $msg;
} # sub executeDeleteContacts

#-------------------------------------------------------------------#
# Before a contact is moved, we need to get a user confirmation
#-------------------------------------------------------------------#
sub buildMoveContacts
{
        my $self = shift;
        
        my $newPanel = new SW::Panel::FormPanel($self);

	# Confirm the move
        $newPanel->addElement(0,0, new SW::GUIElement::Text($self, {
                -text           => $self->{Language}{"confirmMove"},
                -bgColor        => "dedede",
		-fontSize	=> 5,
		-attrib		=> "bold",
        }));

	# Tell user that only checked items will be moved
        $newPanel->addElement(0,1, new SW::GUIElement::Text($self, {
                -text           => $self->{Language}{"checkedMove"},
                -bgColor        => "dedede",
		-attrib		=> "ital",
        }));

	my $displayCounter = 2; # start at 3rd row

	my $foundKeys = $self->findDataKey("CID"); # annon hash to all keys matching CID

	if ($foundKeys) # if there is some contacts to be moved
	{
		foreach my $CID (sort {$a cmp $b} keys %{$foundKeys})
		{
			if ($CID =~ /^CID\d+$/) { $CID =~ s/CID//; } # will be in the form of CID123, we need only the 123 part

			# Checkbox (already checked) plus name of contact to move 
			$newPanel->addElement(0,$displayCounter, new SW::GUIElement::CheckBox($self, {
				-name		=> "CID$CID",
				-value		=> "1",
				-checked	=> 1,
				-align		=> "left",
				-width		=> "1%",
			}));

			my $vCard = SW::App::ContactManager::Contact->load ($self, $CID);
			$newPanel->addElement(1,$displayCounter, new SW::GUIElement::Text($self, {
				-text		=> $vCard->getValue("lastName").", ".$vCard->getValue("firstName"),
				-align		=> "left",
			}));

			$displayCounter++; # now print on next row
		}

		# Blank line
		$newPanel->addElement(0,$displayCounter, $self->transparentGIF(1,10));

		# Button Set that will be used below
		my $buttonSet = new SW::GUIElement::RadioButtonSet ($self, {
			-name 		=> "listChoice",
			-buttons 	=> [],
			-orientation 	=> 'vertical',
			-checked 	=> "old",
		});

		# Destination list (selectBox with all userLists)
		$newPanel->addElement(0, $displayCounter+1, new SW::GUIElement::RadioButton ($self, {
			-name		=> "listChoice",
			-set		=> $buttonSet,
			-value		=> "old",
			-text		=> $self->{Language}{"destList"},
		}));

	        $newPanel->addElement(1,$displayCounter+1, new SW::GUIElement::SelectBox($self, {
        	        -name            => 'destination',
                        -optval         => $self->{userLists},
                        -selected       => $self->{currList},
			-grow_x		=> "false",
	        })); 

		# New list creation
		$newPanel->addElement(0, $displayCounter+2, new SW::GUIElement::RadioButton ($self, {
			-name		=> "listChoice",
			-set		=> $buttonSet,
			-value		=> "new",
			-text		=> $self->{Language}{"enterNewListName"},
		}));
		$newPanel->addElement(1, $displayCounter+2, new SW::GUIElement::TextBox ($self, {
			-name		=> "newList",
			-width		=> 20,
		}));	

		# Blank line
		$newPanel->addElement(0,$displayCounter+3, $self->transparentGIF(1,10));

		# Move and Cancel buttons
		$newPanel->addElement(0,$displayCounter+4, new SW::GUIElement::Button ($self, {
			-text           => $self->{Language}{"optionMove"},
                	-signal         => "executeMoveContacts",
	        }));
		$newPanel->addElement(1,$displayCounter+4, new SW::GUIElement::Button ($self, {
			-text           => $self->{Language}{"optionCancel"},
			-signal		=> "cancelState",
	        }));	

	} else 	{ # nothing was checked
		# Message telling the user that nothing has been checked
		$newPanel->addElement(0,$displayCounter, new SW::GUIElement::Text ($self, {
			-text		=> $self->{Language}{"optionNoChecked"},
		}));

		# Blank line
		$newPanel->addElement(0,$displayCounter + 1, $self->transparentGIF(1,10));

		# Done button to return to main UI
		$newPanel->addElement(0,$displayCounter + 2, new SW::GUIElement::Button ($self, {
			-text           => $self->{Language}{"optionDone"},
			-signal		=> "cancelState",
	        }));	
	}

	# now that all data has been taken care of, delete refs to CIDs
	$self->executeCancelState(1); # 1 so we come back here and don't go to buildMainUI

	my $mainPanel = $self->getPanel();
	$mainPanel->setValue('name',"SmartWORKER Contact List Manager");
	$mainPanel->setValue("bgColor", "ffffff");

       	$mainPanel->addElement (0, 0, $self->getTitlePanel);
        $mainPanel->addElement (0, 1, $newPanel);

	$self->deleteSessionValue("appState");
} # sub buildMoveContacts

#------------------------------------------------------------------#
# Once the user has confirm the moves, it's time to move!
#------------------------------------------------------------------#
sub executeMoveContacts
{
        my $self = shift;
	my $msg; 
        
	my $keysFound = $self->findDataKey("CID"); # anon hash containting contacts to move
	my $destinationId = $self->getDataValue("destination"); # the already created list possible to be moved to (ID)
	my $listChoice = $self->getDataValue("listChoice"); # the way the user wants to move (new or old)

	# have to hold onto this here - if we do a move to new list the currList gets
	#	 stomped in that method
	my $currListId = $self->getSessionValue('currList');

	my $found; # will be set to 1 if new list (if defined) already exists, 0 otherwise
	my $newList = eval { $self->getDataValue("newList") }; # the new list to be created
	if ($listChoice eq "new") { 
		if (! inArray($newList, [sort values %{$self->{userLists}}]) ) { # if list isn't existing already
			# strip blanks
			$newList =~ s/^\s*//;
			$newList =~ s/\s*$//;

			$destinationId = $self->executeNewList($newList, 1); 
		} else { $found = 1; }
	}

	if ( $found == 1 ) { # new list but already exists
		$msg = "The list $newList already exists, transaction was not processed";
	} elsif ($newList =~ /^\s*$/ && $listChoice eq "new") { # new list but no name
		$msg = "No contact has been moved because you didn't specify a name for the new list to be created";
	} elsif ($destinationId eq $currListId) { # old list but same as the one those contact were in
		$msg = "Contacts weren't moved because the selected list is their current list!";
	} elsif ($keysFound) { # 
		my $currList = SW::App::ContactManager::ContactList->load ($self, $currListId);
			SW::debug($self,"Moving from $currListId to $destinationId",3);
		
		my $count = 0;
		foreach my $key (sort {$a cmp $b} keys %{$keysFound})
		{
			if ($key =~ /^CID\d+$/) { $key =~ s/CID//; } # this is a multiple move key (checkbox)
			else { next; } # not suppose to happen!!!

			$currList->moveContact($key, $destinationId); 
			$count++;
		}
		my $destList = SW::App::ContactManager::ContactList->load($self, $destinationId);
		$msg = "$count checked cards were moved to list ".$destList->getName;
	} else {
		$msg = "No contact has been moved since you didn't check any of them";
	}

	$self->cancelState(1); # the 1 means don't go to buildMainUI afterwards, but come back here

	$self->{UImsg} = $msg;
} # sub executeMoveContacts

#------------------------------------------------------------------#
# View a contact info (full View)
#------------------------------------------------------------------#
sub buildViewContact
{
        my $self = shift;
        
        my $newPanel = new SW::Panel::FormPanel($self);
        
	my ($CID) = keys %{$self->findDataKey("CID")}; # get which contact is being viewed
	$CID =~ s/^CID//; # in case this is leftover, remove it

	my $vCard = SW::App::ContactManager::Contact->load ($self, $CID);
	my $currList = SW::App::ContactManager::ContactList->load ($self, $self->getSessionValue("currList"));

	# Name of contact plus edit/move/delete icons
        $newPanel->addElement(0,0, new SW::GUIElement::Text($self, {
                -text           => $vCard->strip_taginfo($vCard->fn)." (".$currList->getName.")",
                -bgColor        => "dedede",
		-fontSize	=> 5,
		-attrib		=> "bold",
		-grow_x		=> "true",
        }));

	my $optionPanel = new SW::Panel::HTMLPanel($self, {
		-grow_x		=> "true",
		-grow_y		=> "false",
		-bgColor	=> "dedede",
		-width		=> "1%",
	});
	$optionPanel->addElement(0,0, new SW::GUIElement::Link($self, {
		-args		=> {
			CID		=> $CID,
		},
		-image		=> $self->editIcon,
		-signal		=> "buildEditContact",
                -bgColor        => "dedede",
	}));
	$optionPanel->addElement(1,0, new SW::GUIElement::Link($self, {
		-args		=> {
			"CID$CID"	=> $CID,
		},
		-image		=> $self->moveIcon,
		-signal		=> "buildMoveContacts",
                -bgColor        => "dedede",
	}));
	$optionPanel->addElement(2,0, new SW::GUIElement::Link($self, {
		-args		=> {
			"CID$CID"	=> $CID,
		},
		-image		=> $self->deleteIcon,
		-signal		=> "buildDeleteContacts",
                -bgColor        => "dedede",
	}));

	$newPanel->addElement(1, 0, $optionPanel);

	# this will be set up for each section so it's easy to modify the look of the view card
	my $personalInformationRow = 1; 
	my $addressesRow = 4;
	my $phoneNumbersRow = 7;
	my $internetInformationRow = 10;
	my $optionsRow = 13;

	$newPanel->addElement(0, $personalInformationRow, new SW::GUIElement::Text($self, {
		-text		=> "Personal information",
		-fontSize	=> 4,
		-attrib		=> "bold",
		-bgColor	=> "c0c0c0",
	}));
	
	my $personalPanel = new SW::Panel::HTMLPanel ($self);

	my %loop = (
		1 => { 
			name 	=> "Nicknames",
			value 	=> $vCard->strip_taginfo($vCard->nickname()),
		},
		2 => { 
			name	=> "Birthday",
			value	=> $vCard->strip_taginfo($vCard->birthday()),
		},
		3 => { 
			name	=> "Timezone (off GMT)",
			value	=> $vCard->strip_taginfo($vCard->tz()),
		},
		4 => { 
			name	=> "Geographic location",
			value 	=> $vCard->strip_taginfo($vCard->geo()),
		},
		5 => { 
			name	=> "Mailer",
			value	=> $vCard->strip_taginfo($vCard->mailer()),
		},
		6 => { 
			name	=> "Organization",
			value	=> $vCard->strip_taginfo($vCard->org(0)),
		},
		7 => { 
			name	=> "Title",
			value	=> $vCard->strip_taginfo($vCard->title(0)),
		},
		8 => { 
			name	=> "Role", 
			value	=> $vCard->strip_taginfo($vCard->role(0)),
		},
		9 => { 
			name 	=> "Categories",
			value	=> $vCard->strip_taginfo($vCard->categories(0)),
		},
		10 => { 
			name	=> "Note",
			value	=> $vCard->strip_taginfo($vCard->note(0)),
		},
		11 => { 
			name	=> "Public key",
			value	=> $vCard->strip_taginfo($vCard->key()),
		},
		12 => { 
			name	=> "Photograph",
			link	=> "URL",
			value	=> $vCard->photo(0, "value")
		},
		13 => { 
			name	=> "Logo",
			link	=> "URL",
			value	=> $vCard->logo(0, "value")
		},
		14 => { 
			name	=> "Sound",
			link	=> "URL",
			value	=> $vCard->sound(0, "value")
		},
	);

	my $personalPanelRow = 0;
	my $alternate = 0;
	foreach my $keyName (sort {$a <=> $b} keys %loop)
	{
		if ($loop{$keyName}->{value} ne "") {
			if ($loop{$keyName}->{link} ne "URL") {
				$personalPanel->addElement($alternate % 2, $personalPanelRow, new SW::GUIElement::Text($self, {
					-text		=> "$loop{$keyName}->{name}: $loop{$keyName}->{value}",
					-width		=> "50%",
				}));
			} else {
				$personalPanel->addElement($alternate % 2, $personalPanelRow, new SW::GUIElement::LinkExternal($self, {
					-target		=> "$loop{$keyName}->{value}",
					-text		=> "$loop{$keyName}->{name}",
					-width		=> "50%",
				}));
			}
			$alternate++;
			if ($alternate % 2 == 0) { $personalPanelRow++; }
		}
	}
	
	if ($alternate == 0) {  # use that variable to count how many personal info fields were used
		$personalPanel->addElement(0,0, new SW::GUIElement::Text($self, {
			-text		=> "Sorry, no personal information is available for this contact",
			-attrib		=> "ital",
		}));
	}
	$newPanel->addElement(0, $personalInformationRow + 1, $personalPanel);

	# Blank line
	$newPanel->addElement(0, $personalInformationRow + 2, $self->transparentGIF(10, 10));

	$newPanel->addElement(0, $addressesRow, new SW::GUIElement::Text($self, {
		-text		=> "Adresses",
		-fontSize	=> 4,
		-attrib		=> "bold",
		-bgColor	=> "c0c0c0",
	}));

        my $superAddressPanel = new SW::Panel::HTMLPanel($self, { });

	my @nonEmpty;
	for (my $x = 0; $x <= 2; $x++) # addresses
	{	
		my %loop = (
			1 => {
				value	=> $vCard->address($x, "addr"),
				attrib	=> 'ital',
			},
			2 => {
				value	=> $vCard->address($x, "street"),
			},
			3 => {
				value	=> $vCard->address($x, "locale"),
				type	=> "stored",
			},
			4 => {
				value	=> $vCard->address($x, "region"),
			},
			5 => {
				value	=> $vCard->address($x, "country"),
			},
			6 => {
				value	=> $vCard->address($x, "code"),
			},
		);

		my $empty = 0;
		foreach my $keyName (sort {$a <=> $b} keys %loop)
		{
			if ($loop{$keyName}->{value} ne "") { $empty = 1; last;}	
		}
		if ($empty == 1) { push(@nonEmpty, $x); }
	}

	my $widthSize = "100%";
	if (@nonEmpty == 2) { $widthSize = "50%"; }
	elsif (@nonEmpty == 3) { $widthSize = "33%"; }

	my $counter = 0;
	foreach my $element (@nonEmpty)
	{
		my %loop = (
			1 => {
				value	=> $vCard->address($element, "addr"),
				attrib	=> 'ital',
			},
			2 => {
				value	=> $vCard->address($element, "street"),
			},
			3 => {
				value	=> $vCard->address($element, "locale"),
				type	=> "stored",
			},
			4 => {
				value	=> $vCard->address($element, "region"),
			},
			5 => {
				value	=> $vCard->address($element, "country"),
			},
			6 => {
				value	=> $vCard->address($element, "code"),
			},
		);

		my $stored;
		my $row = 0;

		my $tmpAddressPanel = new SW::Panel::HTMLPanel($self, {
			-width		=> $widthSize,
		});
		foreach my $keyName (sort {$a <=> $b} keys %loop)
		{
			# check first cuz key after stored is set might have empty value
			if ($stored ne "") { $loop{$keyName}->{value} = "${stored}, $loop{$keyName}->{value}"; }
			$loop{$keyName}->{value} =~ s/\, $//; # in case that key value is empty!

			if ($loop{$keyName}->{value} eq "") { next; }	

			if ($loop{$keyName}->{type} eq "stored") { $stored = $loop{$keyName}->{value}; next; } # don't print it now

			$tmpAddressPanel->addElement(0, $row, new SW::GUIElement::Text($self, {
				-text		=> $loop{$keyName}->{value},
				-attrib		=> $loop{$keyName}->{attrib},
				-width		=> $widthSize,
			}));
		
			$row++;
			$stored = ""; # clears memory
		}
		$superAddressPanel->addElement($counter, 0, $tmpAddressPanel);
		$counter++;
	}

	if (@nonEmpty == 0) { 
		$superAddressPanel->addElement(0,0, new SW::GUIElement::Text($self, {
			-text		=> "Sorry, no address information is available for this contact",
			-attrib		=> "ital",
		}));
	}

	$newPanel->addElement(0, $addressesRow + 1, $superAddressPanel);

	# Blank line
	$newPanel->addElement(0, $addressesRow + 2, $self->transparentGIF(10, 10));

	$newPanel->addElement(0, $phoneNumbersRow, new SW::GUIElement::Text($self, {
		-text		=> "Phone numbers",
		-fontSize	=> 4,
		-bgColor	=> "c0c0c0",
		-attrib		=> "bold",
	}));

        my $phonePanel = new SW::Panel::HTMLPanel($self);
	my $enteredNumbers = 0;
	my $col = 0;
	for (my $x = 0; $x <= 3; $x++) # phones
	{	
		my $typeValue = $vCard->telephone($x, "types");
		my $numberValue = $vCard->telephone($x, "number");
		my $value;

		if ($numberValue eq "") { next; }
		$phonePanel->addElement($x % 2, ($x >= 2), new SW::GUIElement::Text($self, {
			-text		=> "${typeValue}: $numberValue",
			-width		=> "50%",
		}));

		$col++;		
		$enteredNumbers++;
	}
	if ($enteredNumbers == 0) { # no phone number
		$phonePanel->addElement(0, 0, new SW::GUIElement::Text($self, {
			-text		=> "Sorry, no phone number is available for this contact",
			-attrib		=> "ital",
		}));
	}

	$newPanel->addElement(0, $phoneNumbersRow + 1, $phonePanel);

	# Blank line
	$newPanel->addElement(0, $phoneNumbersRow + 2, $self->transparentGIF(10, 10));

	$newPanel->addElement(0, $internetInformationRow, new SW::GUIElement::Text($self, {
		-text		=> "Internet information",
		-bgColor	=> "c0c0c0",
		-fontSize	=> 4,
		-attrib		=> "bold",
	}));

        my $internetPanel = new SW::Panel::HTMLPanel($self);
	$internetPanel->addElement(0, 0, new SW::GUIElement::Text($self, {
		-text		=> "Email addresses",
		-attrib		=> "ital",
		-width		=> "50%",
	}));
	$internetPanel->addElement(1, 0, new SW::GUIElement::Text($self, {
		-text		=> "URLs",
		-attrib		=> "ital",
		-width		=> "50%",
	}));

	my $enteredEmails = 0;
	my $enteredURLs = 0;
	for (my $x = 0; $x <= 3; $x++) # emails / URL
	{	
		my $typeValue = $vCard->email($x, "types");
		my $emailValue = $vCard->email($x, "address");
		my $URLValue = $vCard->strip_taginfo($vCard->URL($x));

		if ($emailValue ne "") {
			$enteredEmails++;

			$internetPanel->addElement(0, $enteredEmails, new SW::GUIElement::LinkExternal($self, {
				-text		=> ($typeValue eq "INTERNET") ? "$emailValue" : "$emailValue ($typeValue)",
				-target		=> "mailto:$emailValue",
			}));
		}
		if ($URLValue ne "") {
			$enteredURLs++;

			$internetPanel->addElement(1, $enteredURLs, new SW::GUIElement::LinkExternal($self, {
				-text		=> "$URLValue",
				-target		=> "$URLValue",
			}));
		}
	}

	if ($enteredEmails == 0) { # no email
		$internetPanel->addElement(0, 0, new SW::GUIElement::Text($self, {
			-text		=> "Sorry, no email address is available for this contact",
			-attrib		=> "ital",
		}));
	}
	if ($enteredURLs == 0) { # no URL
		$internetPanel->addElement(1, 0, new SW::GUIElement::Text($self, {
			-text		=> "Sorry, no URL is available for this contact",
			-attrib		=> "ital",
		}));
	}

	$newPanel->addElement(0, $internetInformationRow + 1, $internetPanel);
	
	# Blank line
	$newPanel->addElement(0,$internetInformationRow + 2, $self->transparentGIF(10,10));

	$newPanel->addElement(0, $optionsRow, new SW::GUIElement::Text($self, {
		-text		=> "vCard made with ".$vCard->strip_taginfo($vCard->prodid()).", last revision: ".$vCard->strip_taginfo($vCard->revisiondate()),
		-fontSize	=> 2,
		-align		=> "center",
	}));

	# Blank line
	$newPanel->addElement(0,$optionsRow + 1, $self->transparentGIF(10,10));

	# Done button
	$newPanel->addElement(0, $optionsRow + 2, new SW::GUIElement::Button ($self, {
		-text           => $self->{Language}{"optionDone"},
		-signal		=> "cancelState",
        }));	
	
	$self->cancelState(1); # the 1 means don't go to buildMainUI afterwards, but come back here

	# draw new UI since this is different than main UI
	my $mainPanel = $self->getPanel();
	$mainPanel->setValue('name',"SmartWORKER Contact List Manager");
	$mainPanel->setValue("bgColor", "ffffff");

        $mainPanel->addElement (0, 0, $self->getTitlePanel);
        $mainPanel->addElement (0, 1, $newPanel);
} # sub buildViewContact

#------------------------------------------------------------------#
# Edit a contact or Add a contact, the difference is that 
# in edition mode, a parameter is passed
#------------------------------------------------------------------#
sub buildEditContact
{
        my $self = shift;        

        my $newPanel = new SW::Panel::FormPanel($self);
        
	my $CID = $self->getDataValue("CID"); # the card to edit if present, otherwise, empty and this means we're adding a card
	if (!$CID) {  $self->deleteSessionValue("CID"); } # if you edit, go back, then add, it will be considered an update otherwise
	SW::debug ($self, "CID : $CID", 3);

	# either a Editing Card or Adding card message
        $newPanel->addElement(0,0, new SW::GUIElement::Text($self, {
                -text           => ($CID) ? $self->{Language}{"editingCardMenu"} : $self->{Language}{"addingCardMenu"},
                -bgColor        => "dedede",
		-fontSize	=> 5,
		-attrib		=> "bold",
		-grow_x		=> "true",
        }));

	if ($CID) # we're editing a card that means
	{
		# Add a move/delete icon
		$newPanel->addElement(5,0, new SW::GUIElement::Link($self, {
			-args		=> {
				"CID$CID"	=> 1,
			},
			-image		=> $self->moveIcon,
			-signal		=> "buildMoveContacts",
        	        -bgColor        => "dedede",
			-width		=> "1%",
		}));
		$newPanel->addElement(6,0, new SW::GUIElement::Link($self, {
			-args		=> {
				"CID$CID"	=> 1,
			},
			-image		=> $self->deleteIcon,
			-signal		=> "buildDeleteContacts",
        	        -bgColor        => "dedede",
			-width		=> "1%",
		}));
	}
	
	my $vCard = ($CID) ? SW::App::ContactManager::Contact->load ($self, $CID) : undef;

	# Blank line
	$newPanel->addElement(0,1, $self->transparentGIF(10,10));

	my $buttonPanel = new SW::Panel::HTMLPanel($self, {
		-grow_x	=> "false",
	});
	$buttonPanel->addElement(0, 0, new SW::GUIElement::Button ($self, {
		-text           => $self->{Language}{"optionSave"},
		-signal		=> "executeEditContact",
        }));	
	$buttonPanel->addElement(1, 0, new SW::GUIElement::Button ($self, {
		-text           => $self->{Language}{"optionCancel"},
		-signal		=> "cancelState",
        }));	
	$newPanel->addElement(0,2, $buttonPanel);

	# Blank line
	$newPanel->addElement(0,3, $self->transparentGIF(10,10));

	my $generalInformationRow = 4;
	my $addressInformationRow = 10;
	my $phoneInformationRow = 27;
	my $emailInformationRow = 36;
	my $otherInformationRow = 43;

	# General information header
	$newPanel->addElement(0,$generalInformationRow, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCardGeneralInformation"},
		-fontSize	=> 4,
		-bgColor	=> "c0c0c0",
		-attribs	=> "bold",
	}));

	# Prefix name
	$newPanel->addElement(0,$generalInformationRow+1, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::name::prefix"},
		-attribs	=> "bold",
		-grow_x		=> "false",
	}));
	$newPanel->addElement(1,$generalInformationRow+1, new SW::GUIElement::TextBox($self, {
		-name		=> "_SAVE_name_prefix",
		-text		=> ($CID) ? $vCard->name('prefix') : "",
		-width		=> 20,
		-grow_x		=> "false",
	}));
	# First name 
	$newPanel->addElement(2,$generalInformationRow+1, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::name::first"},
		-attribs	=> "bold",
		-grow_x		=> "false",
	}));
	$newPanel->addElement(3,$generalInformationRow+1, new SW::GUIElement::TextBox($self, {
		-name		=> "_SAVE_name_first",
		-text		=> ($CID) ? $vCard->name('first') : "",
		-width		=> 20,
		-grow_x		=> "false",
	}));

	# Middle name
	$newPanel->addElement(0,$generalInformationRow+2, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::name::middle"},
		-attribs	=> "bold",
		-grow_x		=> "false",
	}));
	$newPanel->addElement(1,$generalInformationRow+2, new SW::GUIElement::TextBox($self, {
		-name		=> "_SAVE_name_middle",
		-text		=> ($CID) ? $vCard->name('middle') : "",
		-width		=> 20,
		-grow_x		=> "false",
	}));
	# Last name
	$newPanel->addElement(2,$generalInformationRow+2, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::name::last"},
		-attribs	=> "bold",
		-grow_x		=> "false",
	}));
	$newPanel->addElement(3,$generalInformationRow+2, new SW::GUIElement::TextBox($self, {
		-name		=> "_SAVE_name_last",
		-text		=> ($CID) ? $vCard->name('last') : "",
		-width		=> 20,
		-grow_x		=> "false",
	}));

	# Suffix name
	$newPanel->addElement(0,$generalInformationRow+3, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::name::suffix"},
		-attribs	=> "bold",
		-grow_x		=> "false",
	}));
	$newPanel->addElement(1,$generalInformationRow+3, new SW::GUIElement::TextBox($self, {
		-name		=> "_SAVE_name_suffix",
		-text		=> ($CID) ? $vCard->name('suffix') : "",
		-width		=> 20,
		-grow_x		=> "false",
	}));
	# Nickname 
	$newPanel->addElement(2,$generalInformationRow+3, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::nickname"},
		-attribs	=> "bold",
		-grow_x		=> "false",
	}));
	$newPanel->addElement(3,$generalInformationRow+3, new SW::GUIElement::TextBox($self, {
		-name 		=> ($CID) ? "_SAVE_nickname" : "_SAVE_nickname_NEW", 
		-text		=> ($CID) ? $vCard->strip_taginfo($vCard->nickname()) : "",
		-width		=> 20,
		-grow_x		=> "false",
	}));

	# Photo
	$newPanel->addElement(0,$generalInformationRow+4, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::photo"},
		-attribs	=> "bold",
		-grow_x		=> "false",
	}));
	# if we're editing a card, it means it was already created, thus the 0, otherwise, NEW
	$newPanel->addElement(1,$generalInformationRow+4, new SW::GUIElement::TextBox($self, {
		-name		=> ($CID) ? "_SAVE_photo_0" : "_SAVE_photo_NEW",
		-text		=> ($CID) ? $vCard->photo(0, "value") : "", 
		-width		=> 20,
		-grow_x		=> "false",
	}));
	# Birthday
	$newPanel->addElement(2,$generalInformationRow+4, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::birthday"},
		-attribs	=> "bold",
		-grow_x		=> "false",
	}));
	$newPanel->addElement(3,$generalInformationRow+4, new SW::GUIElement::TextBox($self, {
		-name		=> "_SAVE_birthday",
		-text		=> ($CID) ? $vCard->strip_taginfo($vCard->birthday()) : "",
		-width		=> 20,
		-grow_x		=> "false",
	}));

	# Blank line
	$newPanel->addElement(0,$generalInformationRow+5, $self->transparentGIF(10,10));

	# Address information header
	$newPanel->addElement(0,$addressInformationRow, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCardAddressInformation"},
		-fontSize	=> 4,
		-bgColor	=> "c0c0c0",
		-attribs	=> "bold",
	}));

	my $yCoord = $addressInformationRow + 1;
	for (my $x = 0; $x <= 2; $x++) # we need 3 different address fields
	{
		# $x type of address
		$newPanel->addElement(0,$yCoord, new SW::GUIElement::Text($self, {
			-text		=> $self->{Language}{"vCard::address::type"},
			-attribs	=> "bold",
			-grow_x		=> "false",
			-valign		=> "top",
		}));
		$newPanel->addElement(1,$yCoord, new SW::GUIElement::SelectBox($self, {
			-name		=> "_SAVE_address_${x}_types",
			-options	=> ["DOM", "HOME", "INTL", "PARCEL", "POSTAL", "WORK"],
			-selected 	=> ($CID) ? $vCard->address($x, "types") || "INTL" : "INTL",
        	}));	
		# $x name of address
		$newPanel->addElement(2,$yCoord, new SW::GUIElement::Text($self, {
			-text		=> $self->{Language}{"vCard::address::name"},
			-attribs	=> "bold",
			-grow_x		=> "false",
			-valign		=> "top",
		}));
		$newPanel->addElement(3,$yCoord, new SW::GUIElement::TextBox($self, { 
			-name		=> ($CID) ? "_SAVE_address_${x}_addr" : "_SAVE_ADR_address_${x}_addr",
			-text		=> ($CID) ? $vCard->address($x, "addr") : "",
			-width		=> '20',
			-grow_x		=> "true",
		}));

		# $x street address
		$newPanel->addElement(0,$yCoord+1, new SW::GUIElement::Text($self, {
			-text		=> $self->{Language}{"vCard::address::street"},
			-attribs	=> "bold",
			-grow_x		=> "false",
		}));
		$newPanel->addElement(1,$yCoord+1, new SW::GUIElement::TextBox($self, {
			-name		=> "_SAVE_address_${x}_street",
			-text		=> ($CID) ? $vCard->address($x, "street") : "",
			-width		=> 20,
			-grow_x		=> "false",
		}));

		# $x locale address (city)
		$newPanel->addElement(2,$yCoord+1, new SW::GUIElement::Text($self, {
			-text		=> $self->{Language}{"vCard::address::locale"},
			-attribs	=> "bold",
			-grow_x		=> "false",
		}));
		$newPanel->addElement(3,$yCoord+1, new SW::GUIElement::TextBox($self, {
			-name		=> "_SAVE_address_${x}_locale",
			-text		=> ($CID) ? $vCard->address($x, "locale") : "",
			-width		=> 20,
			-grow_x		=> "false",
		}));

		# $x region address (province/state)
		$newPanel->addElement(0,$yCoord+2, new SW::GUIElement::Text($self, {
			-text		=> $self->{Language}{"vCard::address::region"},
			-attribs	=> "bold",
			-grow_x		=> "false",
		}));
		$newPanel->addElement(1,$yCoord+2, new SW::GUIElement::TextBox($self, {
			-name		=> "_SAVE_address_${x}_region",
			-text		=> ($CID) ? $vCard->address($x, "region") : "",
			-width		=> 20,
			-grow_x		=> "false",
		}));
		# $x code address (zip)
		$newPanel->addElement(2,$yCoord+2, new SW::GUIElement::Text($self, {
			-text		=> $self->{Language}{"vCard::address::code"},
			-attribs	=> "bold",
			-grow_x		=> "false",
		}));
		$newPanel->addElement(3,$yCoord+2, new SW::GUIElement::TextBox($self, {
			-name		=> "_SAVE_address_${x}_code",
			-text		=> ($CID) ? $vCard->address($x, "code") : "",
			-width		=> 20,
			-grow_x		=> "false",
		}));

		# $x country address
		$newPanel->addElement(0,$yCoord+3, new SW::GUIElement::Text($self, {
			-text		=> $self->{Language}{"vCard::address::country"},
			-attribs	=> "bold",
			-grow_x		=> "false",
		}));
		$newPanel->addElement(1,$yCoord+3, new SW::GUIElement::TextBox($self, {
			-name		=> "_SAVE_address_${x}_country",
			-text		=> ($CID) ? $vCard->address($x, "country") : "",
			-width		=> 20,
			-grow_x		=> "false",
		}));

		# Blank line
		$newPanel->addElement(0,$yCoord+4, $self->transparentGIF(10,10));

		$yCoord += 5; # be ready for next set
	}

	# Blank line
	$newPanel->addElement(0,$addressInformationRow + 16, $self->transparentGIF(10,10));

	# Phone information header
	$newPanel->addElement(0,$phoneInformationRow, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCardPhoneInformation"},
		-fontSize	=> 4,
		-bgColor	=> "c0c0c0",
		-attribs	=> "bold",
	}));

	$yCoord = $phoneInformationRow + 1;
	for (my $x = 0; $x <= 3; $x++) # 4 phone numbers
	{
		# $x type of telephone
		$newPanel->addElement(0,$yCoord, new SW::GUIElement::Text($self, {
			-text		=> $self->{Language}{"vCard::telephone::type"},
			-attribs	=> "bold",
			-grow_x		=> "false",
			-valign		=> "top",
		}));
		$newPanel->addElement(1,$yCoord, new SW::GUIElement::SelectBox($self, {
			-name		=> "_SAVE_telephone_${x}_types",
			-options	=> ["BBS", "CAR", "CELL", "FAX", "HOME", "ISDN", "MODEM", "MSG", "PAGER", "PREF", "VIDEO", "VOICE", "WORK"],
			-selected 	=> ($CID) ? $vCard->telephone($x, "types") || "VOICE" : "VOICE",
        	}));	

		# $x number of telephone
		$newPanel->addElement(2,$yCoord, new SW::GUIElement::Text($self, {
			-text		=> $self->{Language}{"vCard::telephone::number"},
			-attribs	=> "bold",
			-grow_x		=> "false",
			-valign		=> "top",
		}));
		$newPanel->addElement(3,$yCoord, new SW::GUIElement::TextBox($self, { 
			-name		=> "_SAVE_telephone_${x}_number",
			-text		=> ($CID) ? $vCard->telephone($x, "number") : "",
			-width		=> '20',
			-grow_x		=> "false",
		}));

		$yCoord++;
	}

	# Blank line
	$newPanel->addElement(0,$phoneInformationRow + 5, $self->transparentGIF(10,10));

	# Email information header
	$newPanel->addElement(0,$emailInformationRow, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCardEmailInformation"},
		-fontSize	=> 4,
		-bgColor	=> "c0c0c0",
		-attribs	=> "bold",
	}));

	$yCoord = $emailInformationRow + 1;
	for (my $x = 0; $x <= 3; $x++) # 4 email addresses
	{
		# $x type of email
		$newPanel->addElement(0,$yCoord, new SW::GUIElement::Text($self, {
			-text		=> $self->{Language}{"vCard::email::type"},
			-attribs	=> "bold",
			-grow_x		=> "false",
			-valign		=> "top",
		}));
		$newPanel->addElement(1,$yCoord, new SW::GUIElement::SelectBox($self, {
			-name		=> "_SAVE_email_${x}_types",
			-options	=> ["AOL", "Applelink", "ATTMail", "CIS", "eWorld", "INTERNET", "IBMMail", "MCIMail", "Powershare", "PRODIGY", "TLX", "X400"],
			-selected 	=> ($CID) ? $vCard->email($x, "types") || "INTERNET" : "INTERNET",
        	}));	

		# $x number of email
		$newPanel->addElement(2,$yCoord, new SW::GUIElement::Text($self, {
			-text		=> $self->{Language}{"vCard::email::value"},
			-attribs	=> "bold",
			-grow_x		=> "false",
			-valign		=> "top",
		}));
		$newPanel->addElement(3,$yCoord, new SW::GUIElement::TextBox($self, { 
			-name		=> "_SAVE_email_${x}_address",
			-text		=> ($CID) ? $vCard->email($x, "address") : "",
			-width		=> '20',
			-grow_x		=> "false",
		}));

		$yCoord++;
	}

	# mailer
	$newPanel->addElement(0,$emailInformationRow + 5, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::mailer"},
		-attribs	=> "bold",
		-grow_x		=> "false",
		-valign		=> "top",
	}));
	$newPanel->addElement(1,$emailInformationRow + 5, new SW::GUIElement::TextBox($self, { 
		-name		=> "_SAVE_mailer",
		-text		=> ($CID) ? $vCard->strip_taginfo($vCard->mailer()) : "",
		-width		=> '20',
		-grow_x		=> "false",
	}));
	
	# Blank line
	$newPanel->addElement(0,$emailInformationRow + 6, $self->transparentGIF(10,10));

	# Other information header
	$newPanel->addElement(0,$otherInformationRow, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCardOtherInformation"},
		-fontSize	=> 4,
		-bgColor	=> "c0c0c0",
		-attribs	=> "bold",
	}));

	# Timezone
	$newPanel->addElement(0,$otherInformationRow+1, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::tz"},
		-attribs	=> "bold",
		-grow_x		=> "false",
		-valign		=> "top",
	}));

	my @tz = (-12..-4, -3.5, -2..3, 3.5, 4, 4.5, 5, 5.5, 6..9, 9.5, 10..12);
	foreach (@tz)
	{
		if ($_ =~ s/\.5$/\:30/) {}
		else { $_ = "${_}:00"; }
		if ($_ eq "0:00") { $_ = "0$_"; }
	}
	@tz = ("", @tz);

	$newPanel->addElement(1,$otherInformationRow+1, new SW::GUIElement::SelectBox($self, { 
		-name		=> "_SAVE_tz",
		-options	=> \@tz,
		-selected	=> ($CID) ? $vCard->strip_taginfo($vCard->tz()) : "",
		-grow_x		=> "false",
	}));
	# Geographical reference
	$newPanel->addElement(2,$otherInformationRow+1, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::geo"},
		-attribs	=> "bold",
		-grow_x		=> "false",
		-valign		=> "top",
	}));
	$newPanel->addElement(3,$otherInformationRow+1, new SW::GUIElement::TextBox($self, { 
		-name		=> "_SAVE_geo",
		-text		=> ($CID) ? $vCard->strip_taginfo($vCard->geo()) : "",
		-width		=> '20',
		-grow_x		=> "false",
	}));
	# Blank line
	$newPanel->addElement(0,$otherInformationRow+2, $self->transparentGIF(10,10));

	# Title reference
	$newPanel->addElement(0,$otherInformationRow+3, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::title"},
		-attribs	=> "bold",
		-grow_x		=> "false",
		-valign		=> "top",
	}));
	$newPanel->addElement(1,$otherInformationRow+3, new SW::GUIElement::TextBox($self, { 
		-name		=> "_SAVE_title",
		-text		=> ($CID) ? $vCard->strip_taginfo($vCard->title(0)) : "",
		-width		=> '20',
		-grow_x		=> "false",
	}));
	# Role reference
	$newPanel->addElement(2,$otherInformationRow+3, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::role"},
		-attribs	=> "bold",
		-grow_x		=> "false",
		-valign		=> "top",
	}));
	$newPanel->addElement(3,$otherInformationRow+3, new SW::GUIElement::TextBox($self, { 
		-name		=> "_SAVE_role",
		-text		=> ($CID) ? $vCard->strip_taginfo($vCard->role(0)) : "",
		-width		=> '20',
		-grow_x		=> "false",
	}));

	# Blank line
	$newPanel->addElement(0,$otherInformationRow+4, $self->transparentGIF(10,10));

	# logo reference
	$newPanel->addElement(0,$otherInformationRow+5, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::logo"},
		-attribs	=> "bold",
		-grow_x		=> "false",
		-valign		=> "top",
	}));
	$newPanel->addElement(1,$otherInformationRow+5, new SW::GUIElement::TextBox($self, { 
		-name		=> ($CID) ? "_SAVE_logo_0" : "_SAVE_logo_NEW",
		-text		=> ($CID) ? $vCard->logo(0, "value") : "",
		-width		=> '20',
		-grow_x		=> "false",
	}));
	# organization reference
	$newPanel->addElement(2,$otherInformationRow+5, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::org"},
		-attribs	=> "bold",
		-grow_x		=> "false",
		-valign		=> "top",
	}));
	$newPanel->addElement(3,$otherInformationRow+5, new SW::GUIElement::TextBox($self, { 
		-name		=> "_SAVE_org",
		-text		=> ($CID) ? $vCard->strip_taginfo($vCard->org(0)) : "",
		-width		=> '20',
		-grow_x		=> "false",
	}));

	# Blank line
	$newPanel->addElement(0,$otherInformationRow+6, $self->transparentGIF(10,10));

	# categories reference
	$newPanel->addElement(0,$otherInformationRow+7, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::categories"},
		-attribs	=> "bold",
		-grow_x		=> "false",
		-valign		=> "top",
	}));
	$newPanel->addElement(1,$otherInformationRow+7, new SW::GUIElement::TextBox($self, { 
		-name		=> "_SAVE_categories",
		-text		=> ($CID) ? $vCard->strip_taginfo($vCard->categories(0)) : "",
		-width		=> '20',
		-grow_x		=> "false",
	}));
	# note reference
	$newPanel->addElement(2,$otherInformationRow+7, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::note"},
		-attribs	=> "bold",
		-grow_x		=> "false",
		-valign		=> "top",
	}));
	$newPanel->addElement(3,$otherInformationRow+7, new SW::GUIElement::TextBox($self, { 
		-name		=> "_SAVE_note",
		-text		=> ($CID) ? $vCard->strip_taginfo($vCard->note(0)) : "",
		-width		=> '20',
		-grow_x		=> "false",
	}));

	# Blank line
	$newPanel->addElement(0,$otherInformationRow+8, $self->transparentGIF(10,10));

	# Sound reference
	$newPanel->addElement(0,$otherInformationRow+9, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::sound"},
		-attribs	=> "bold",
		-grow_x		=> "false",
		-valign		=> "top",
	}));
	$newPanel->addElement(1,$otherInformationRow+9, new SW::GUIElement::TextBox($self, { 
		-name		=> ($CID) ? "_SAVE_sound_0" : "_SAVE_sound_NEW",
		-text		=> ($CID) ? $vCard->sound(0, "value") : "",
		-width		=> '20',
		-grow_x		=> "false",
	}));
	# key reference
	$newPanel->addElement(2,$otherInformationRow+9, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::key"},
		-attribs	=> "bold",
		-grow_x		=> "false",
		-valign		=> "top",
	}));
	$newPanel->addElement(3,$otherInformationRow+9, new SW::GUIElement::TextBox($self, { 
		-name		=> "_SAVE_key",
		-text		=> ($CID) ? $vCard->strip_taginfo($vCard->key()) : "",
		-width		=> '20',
		-grow_x		=> "false",
	}));	

	# Blank line
	$newPanel->addElement(0,$otherInformationRow+10, $self->transparentGIF(10,10));

	$newPanel->addElement(0, $otherInformationRow+11, new SW::GUIElement::Text($self, {
		-text		=> $self->{Language}{"vCard::URL"},
		-attribs	=> "bold",
		-grow_x		=> "false",
		-valign		=> "top",
	}));

	$yCoord = $otherInformationRow+11;
	my $xCoord = 0;
	for (my $x = 0; $x <= 3; $x++) # 4 URL
	{
		# $x URL
		$newPanel->addElement($xCoord+1,$yCoord, new SW::GUIElement::TextBox($self, { 
			-name		=> ($CID) ? "_SAVE_URL_${x}" : "_SAVE_NEW_URL_${x}",
			-text		=> ($CID) ? $vCard->strip_taginfo($vCard->URL($x)) : "",
			-width		=> '20',
			-grow_x		=> "false",
		}));

		$xCoord += 2;
		if ($x == 1) { $yCoord++; $xCoord = 0;}
	}

	# Blank line
	$newPanel->addElement(0,$otherInformationRow+13, $self->transparentGIF(10,10));

	# Save / Cancel buttons
	$newPanel->addElement(0,$otherInformationRow+14, $buttonPanel);
	
	if ($CID) { $self->setSessionValue('CID', $CID); }

	my $mainPanel = $self->getPanel();
	$mainPanel->setValue('name',"SmartWORKER Contact List Manager");
	$mainPanel->setValue("bgColor", "ffffff");

        $mainPanel->addElement (0, 0, $self->getTitlePanel);
        $mainPanel->addElement (0, 1, $newPanel);
} # sub buildEditContact


#------------------------------------------------------------
#  import a card   RSW Aug 14/1999
#------------------------------------------------------------

sub buildImportContact
{
	my $self = shift;

	my $newPanel = new SW::Panel::FormPanel($self);

	# Import a card title
        $newPanel->addElement(0,0, new SW::GUIElement::Text($self, {
                -text           => $self->{Language}{"importingNewCardTitle"},
                -bgColor        => "dedede",
		-fontSize	=> 5,
		-attrib		=> "bold",
		-grow_x 	=> "true",
        }));

	# Enter list name below
        $newPanel->addElement(0,1, new SW::GUIElement::Text($self, {
                -text           => $self->{Language}{"importingPaste"},
                -bgColor        => "dedede",
		-fontSize	=> 2,
		-attrib		=> "ital",
		-grow_x 	=> "true",
        }));

	# The new list name
        $newPanel->addElement(0,2, new SW::GUIElement::TextArea($self, {
		-name		=> "newList",
		-width		=> 80,
		-height 	=> 20,
		-grow_x 	=> "true",
        }));

	# Create and Cancel buttons
	$newPanel->addElement(0,3, new SW::GUIElement::Button ($self, {
		-text           => $self->{Language}{"optionImport"},
                -signal         => "executeImportContact",
        }));
	$newPanel->addElement(1,3, new SW::GUIElement::Button ($self, {
		-text           => $self->{Language}{"optionCancel"},
		-signal		=> "cancelState",
		-width		=> "1%",
        }));

	## import by upload  panel

	my $upPanel = new SW::Panel::FormPanel($self, {
		-name => "uploadPanel",
		-grow_x => "true",
	});

	# Select file to upload
        $upPanel->addElement(0,0, new SW::GUIElement::Text($self, {
                -text           => $self->{Language}{"importingUpload"},
                -bgColor        => "dedede",
		-fontSize	=> 2,
		-attrib		=> "ital",
		-grow_x 	=> "true",
        }));

	# Create and Cancel buttons
# 	$upPanel->addElement(0,1, new SW::GUIElement::Upload ($self, {
# 		-text           => $self->{Language}{"optionSelectFile"},
#                 -signal         => "ImportedFileName",
#         }));
	$upPanel->addElement(0,2, new SW::GUIElement::Button ($self, {
		-text           => $self->{Language}{"optionSave"},
                -signal         => "executeUploadedContact",
        }));
	$upPanel->addElement(1,2, new SW::GUIElement::Button ($self, {
		-text           => $self->{Language}{"optionCancel"},
		-signal		=> "cancelState",
		-width		=> "1%",
        }));

	my $mainPanel = $self->getPanel();
	$mainPanel->setValue('name',"SmartWORKER Contact List Manager");
	$mainPanel->setValue("bgColor", "ffffff");

        $mainPanel->addElement (0, 0, $self->getTitlePanel);
        $mainPanel->addElement (0, 1, $newPanel);
        $mainPanel->addElement (0, 2, $upPanel);

	$self->deleteSessionValue("appState");        
}


#------------------------------------------------------------------#
# Save a contact
#------------------------------------------------------------------#

sub executeEditContact
{
	my $self = shift;
	my $msg;

	my $CID = $self->getSessionValue("CID");
	
	$self->{currList} = $self->getSessionValue("currList"); # the list the contact is created in

	SW::debug($self,"current list ".$self->{currList},5);
	SW::debug ($self, "CID : $CID", 3);

	my $currList = SW::App::ContactManager::ContactList->load($self, $self->{currList});
	my $vCard = ($CID) ? SW::App::ContactManager::Contact->load($self, $CID) : 
		SW::App::ContactManager::Contact->new($self);
	$CID = ($CID) ? $CID : $vCard->getCID();

	SW::debug($self,"cid for the new contact is $CID",5);

	# basically, get back all fields that have a _SAVE prefix, remove the prefix,
	# check whether we need to construct an ARRAY, then extract the parameters (separated by _)
	# 1st param is the method to be called, which we simply add _set to it.
	foreach my $keyName (sort {$a cmp $b} keys %{$self->findDataKey("_SAVE") || {}})
	{
		my $keyNameCopy = $keyName;
		my $value;

		$keyNameCopy =~ s/^_SAVE_//;

		if ($keyNameCopy =~ s/^ARRAY_//) { 
			@{$value} = split (/\s*,\s*/, $self->getDataValue($keyName));
			my ($methodName, @params) = split (/_/, $keyNameCopy);
			$methodName .= "_set";
		
			if (@params == 0) {
				$vCard->$methodName (@{$value});
			} else { 
				$vCard->$methodName (@params, @{$value});
			}
		} elsif ($keyNameCopy =~ s/^NEW_//) { # for the URL type, since we go from 0 to 3 we need to change field name
						      # but we need to drop the 0-3 so we pass the correct arguments..ill explain
						      # that better i guess :)
			my ($methodName, @params) = split (/_/, $keyNameCopy);
			$methodName .= "_set";
			$value = $self->getDataValue($keyName);

			pop (@params); # remove the x element

			if (@params == 0) {
				$vCard->$methodName ('NEW', $value);
			} else {
				$vCard->$methodName ('NEW', @params, $value);
			}
		} elsif ($keyNameCopy =~ s/^ADR_//) {
			# i need a trick for the address thingie..since we can't easily call the full blown method of address_set which takes 10 params,
			# if i need to create a new object, ill do it here and then ill just continue on my way

			my ($methodName, @params) = split (/_/, $keyNameCopy);
			$methodName .= "_set";
			$value = $self->getDataValue($keyName);

			$vCard->$methodName('NEW', '', '', '', '', '', '', '', '', ''); # create the address first
			$vCard->$methodName (@params, $value); # use it for this one, next address calls will go to the else loop
		} else {
			my ($methodName, @params) = split (/_/, $keyNameCopy);
			$methodName .= "_set";
			$value = $self->getDataValue($keyName);

			if (@params == 0) { 
				$vCard->$methodName ($value);
			} else { 
				$vCard->$methodName (@params, $value);
			}
		}
	}

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);	
	$mon++; # starts at 0
	if ($sec < 10) { $sec = "0$sec"; }
	if ($min < 10) { $min = "0$min"; }
	if ($hour < 10) { $hour = "0$hour"; }
	if ($mday < 10) { $mday = "0$mday"; }
	if ($mon < 10) { $mon = "0$mon"; }
	$year += 1900; # y2k compliant

	$vCard->revisiondate_set("${mon}/${mday}/${year} ${hour}:${min}:${sec}");
	$vCard->build_fn;
	$vCard->build_label("ALL");

	SW::debug($self,"Trying to add it to the list.... ...",1);

SW::debug ($self, "NB of contacts: ".$currList->getNbContacts(), 3);
	$currList->addContact($CID);
SW::debug ($self, "NB of contacts: ".$currList->getNbContacts(), 3);

	# hack - problems with tied hash
	SW::debug($self,"About to force write ...",1);
	$vCard->forceWrite();
	$self->deleteSessionValue("CID");
	$self->deleteSessionValue("maxDisplay");

	SW::debug ($self, "Saved contact $CID into ".$currList->getName, 3);

	$msg = "The contact was saved";

	$self->{UImsg} = $msg;
} # sub executeEditContact

#------------------------------------------------------------------#
# This is to clear all leftovers of CIDs (usually when user clicks
# on a Cancel button)
#------------------------------------------------------------------#
sub executeCancelState
{
	my $self = shift;
	my $return = shift;

	foreach my $CID (keys %{$self->findDataKey("CID") || {}})
	{
		delete $self->{data}->{$CID};
        	$self->deleteSessionValue($CID);
	}

	$self->deleteSessionValue("appState");
	if ($return != 1) { $self->{UImsg} = " "; } # up in dispatcher, i check if string is empty, space is to make sure we go in mainUI
	# else, go back to where you were!!!
} # sub executeCancelState  

#===================================================================#
# INTERNAL METHODS
#===================================================================#

#------------------------------------------------------------------#
# Return the main header, if 1 is passed as a parameter, provide a
# for the user to change language
#------------------------------------------------------------------#
sub getTitlePanel
{
	my $self = shift;
	my $changeLang = shift || 0;

	my $userName = SW->user->getName;

	# The header panel
        my $titlePanel = new SW::Panel::FormPanel($self, {
                -bgColor        => "000000",
                -name           => "titlePanel",
		-align		=> "center",
		-height		=> "1%",
        });

	# The app title (which is Contact List Manager), a welcome message to the current user
        $titlePanel->addElement(0,0, new SW::GUIElement::Text($self, {
                -text           => uc($self->{Language}{"menuHeader"}),
		-fontSize	=> 5,
		-textColor	=> "c0c0c0",
		-attrib		=> "bold",			
        }));
	$titlePanel->addElement(1,0, new SW::GUIElement::Text($self, {
                -text           => $self->{Language}{"menuWelcome"}." $userName",
		-attrib		=> "ital",
		-attrib		=> "bold",
		-align		=> "center",
		-textColor	=> "ffffff",
		-fontSize	=> "+1",
		-grow_x		=> "false",
       	}));

	if ($changeLang == 1) { # if we allow user to change language
		 $titlePanel->addElement(2,0, $self->{Language}->getLanguagePicker("titlePanel"));
       }

	return ($titlePanel);
}

#------------------------------------------------------------------#
# In order to efficiently have spacing between rows, I created this
# method to put a transparentGIF of width x height between rows
# This is created from a 10x10 transparent GIF
#------------------------------------------------------------------#
sub transparentGIF
{
	my $self = shift;
	my $width = shift || 10;
	my $height = shift || 10;	

        my $transparentGIF = new SW::GUIElement::Image($self, {   
                -url            => "/sw_lib/images/transparent.gif",
                -border         => '0',
		-width		=> $width,
		-height		=> $height,
        });

	return ($transparentGIF);
}

#------------------------------------------------------------------#
# This returns the edit icon which can be used in a link method
#------------------------------------------------------------------#
sub editIcon
{
	my $self = shift;

        my $editIcon = new SW::GUIElement::Image($self, {  
		-url		=> "/sw_lib/contactManager/editIcon.gif", 
		-border		=> '0',
	});

	return ($editIcon);
}

#------------------------------------------------------------------#
# This returns the move icon which can be used in a link method
#------------------------------------------------------------------#
sub moveIcon
{
	my $self = shift;

        my $moveIcon = new SW::GUIElement::Image($self, {  
		-url		=> "/sw_lib/contactManager/moveIcon.gif", 
		-border		=> '0',
	});

	return ($moveIcon);
}

#------------------------------------------------------------------#
# This returns the delete icon which can be used in a link method
#------------------------------------------------------------------#
sub deleteIcon
{
	my $self = shift;

        my $deleteIcon = new SW::GUIElement::Image($self, {  
		-url		=> "/sw_lib/contactManager/deleteIcon.gif", 
		-border		=> '0',
	});

	return ($deleteIcon);
}

#------------------------------------------------------------------#
# This adds a CheckAll / ClearAll Javascript link that works with
# a set of checkboxes. The function called is in this app JS lib
# and the function is specific to this app. 
# ** We might want to create unspecific functions in the future
#------------------------------------------------------------------#
sub checkAllJS
{
	my $self = shift;

# TODO ** As this is a Hack to include Javascript call, we might want to have a real JS method

	my $jsCode = new SW::GUIElement::Text($self, {
		-text => qq(<a href="javascript:CheckAll(true)">Check&nbsp;All</a> - <a href="javascript:CheckAll(false)">Clear&nbsp;All</a>),
	});
}

1; # true

__END__

=head1 NAME

ContactManager.pm - A Contact manager for vCards

=head1 SYNOPSIS

   Give a simple example of the module's use

=head1 DESCRIPTION


=head1 METHODS


=head1 PARAMETERS

=head1 AUTHOR

Frederic Hurtubise
HBE      fred@hbe.ca
July 28/99

=head1 REVISION HISTORY

  $Log: ContactManager.pm,v $
  Revision 1.10  1999/09/20 19:51:15  gozer
  Temp fix for the lost DataValues

  Revision 1.9  1999/09/17 21:18:16  gozer
  This is a major modification on the whole SW structure
  New methods in SW:
  SW->master	: returns the current Master o bject
  SW->session	: returns the current session object
  SW->user	: returns the current user
  SW->data	: returns the current URL/URI parsed data (getDataValue, setDataValue) but it's incomplete for now

  Now, no object needs to get a hold on any of those structures, they can access them thru the global methods instead.  Thus fixing a lot of problems with circular dependencies.

  Completed the User class with User::Authen for authentication User::Authz for authorization and User::Group for group membership.

  I modified quite many files to use the new SW-> methods instead of holding on them.  Still some cleaning up to do

  Tonight, I debug this change and tommorrow I'll document everything in details.

  SW::Session now has 2 accesses  set/get/delGlobalValues and set/get/delPrivateValues for private(per application class) and global.

  Revision 1.8  1999/09/11 07:07:32  scott
  Made substantial changes to the database schema and data storage models.
  Now there's three global tables called datamap, dataaccess, and
  datainfo.  These hide the many other more data specific tables
  where the infomation is actually stored.

  Revision 1.7  1999/09/11 07:06:07  scott
  Tweaking these apps so they work with the new datamap model
  (actually they don't change at all unless they were being bad
  and writing their own SQL).

  Revision 1.6  1999/09/09 18:52:28  gozer
  First Application to have been rewritten under the new Apache::Language::SW
  And it works

  Revision 1.5  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors

  Revision 1.4  1999/09/04 20:52:10  fhurtubi
  Tried to add the logout part, but it didn't work. Im reverting back to the last
  working version. I might also have corrected a minor bug somewhere.

  Revision 1.3  1999/09/03 01:11:07  scott
  fixed signal / target problems

  Revision 1.2  1999/09/02 20:38:07  fhurtubi
  For vCard stuff, I added Office::vCard and for groupManager, I've added SW::App::

  Revision 1.1  1999/09/02 20:11:05  gozer
  New namespace convention

  Revision 1.37  1999/09/01 14:11:16  fhurtubi
  Fixed a major bug while moving cards to a new list...

  Revision 1.36  1999/08/30 21:45:33  fhurtubi
  Removed exporter call

  Revision 1.35  1999/08/30 03:10:01  fhurtubi
  Like Scott says, shame on me for not commiting my changes, now i dont even
  remember what might have changed in here !!!

  Revision 1.34  1999/08/27 23:44:32  jzmrotchek
  This is actually scott ... cleaning up zed's cvs tree.  Fred probably made
  the same changes to ContactManager, but he forgot to check them in :-(

  Revision 1.33  1999/08/27 20:51:15  fhurtubi
  Changed addSessionValue to setSessionValue

  Revision 1.32  1999/08/27 20:06:54  fhurtubi
  Added a contact count next to each list name in the popup menu. While fixing vCard.pm, it fixed the URL bug.
  Added an empty element to timezone (tz) which is now the default, and not -5:00. Removed (CID) prints in some
  places

  Revision 1.31  1999/08/20 02:05:43  fhurtubi
  Added documentation and commented out stuff that isn't done yet

  Revision 1.30  1999/08/19 18:48:51  fhurtubi
  Fixed a bug with buildViewContact and CID not being cancelled

  Revision 1.29  1999/08/19 05:09:11  scott
  commented out a debug line that caused server error when we had no lists....

  Revision 1.28  1999/08/18 23:17:34  fhurtubi
  Fixed small bugs, changed the infrastructure from one end to the other. Instead of having a bunch of spaghetti calls from
  buildMainUI to a callback then back to buildMainUI, there is a dispatcher who's job is to ... dispatch! buildMainUI gets
  called only when it needs to, so there is no waste of ressources.

  Revision 1.27  1999/08/18 15:38:35  fhurtubi
  View Card is done with a lot of value checking (so we don't print empty values)

  Revision 1.26  1999/08/17 22:09:19  fhurtubi
  Viewing card is in process...Fixed links from icons in the view stage..

  Revision 1.25  1999/08/17 05:20:44  scott
  implementing the Import function - GUI is there but the rest isn't yet...

  Revision 1.24  1999/08/16 22:41:11  fhurtubi
  Modified  maxDisplay  to add default view screen

  Revision 1.23  1999/08/16 17:46:39  fhurtubi
  Everything is working perfectly with the vCard methods, maxDisplay is now fixed
  (I hope).

  Revision 1.22  1999/08/14 16:55:28  scott
  Fixed a problem with move to new list function

  Revision 1.21  1999/08/14 00:22:19  scott
  ContactList - move, delete, edit all work!!!!

  There's still some fields that need to be cleaned up between the
  edit screen and the vcard ... 'org' in particular doesn't work in
  the vcard

  Revision 1.20  1999/08/14 00:14:03  scott
  oops!

  Revision 1.19  1999/08/14 00:10:06  scott
  fixed deletion -

  Revision 1.18  1999/08/13 23:19:33  scott
  fixed the NICKNAME problem ( added a stripTag to it ....)

  Revision 1.17  1999/08/13 23:17:18  scott
  Commented out the "org" stuff in ContactManager, it seems to be broken in
  vCard

  Revision 1.16  1999/08/13 20:48:00  fhurtubi
  Just to make sure everyone has the same version, not sure if big mods have been made

  Revision 1.13  1999/08/13 17:09:11  scott
  added a call to forceWrite to trick it into writing to the db

  Revision 1.12  1999/08/13 17:01:31  fhurtubi
  Removed a session value that was hanging too long

  Revision 1.11  1999/08/13 16:27:09  scott
  nothing

  Revision 1.10  1999/08/13 16:24:20  fhurtubi
  Removed bunch of evals

  Revision 1.9  1999/08/13 16:02:54  scott
  Bug fixes with ContactList

  Revision 1.8  1999/08/13 15:19:20  fhurtubi
  Replaced new with load when loading a card

  Revision 1.7  1999/08/13 14:35:52  scott
  Small fixes to ContactManager,  changed getDataValue('list')
  to $self->{session}->{currList} in the addCard method

  no significant changes to MessageBoard

  Revision 1.6  1999/08/12 21:58:52  fhurtubi
  Corrected (again) an address call that was erroneous

  Revision 1.5  1999/08/12 21:38:09  fhurtubi
  Fixed calls to address method in vCard

  Revision 1.4  1999/08/12 20:31:11  fhurtubi
  Add/Edit screen should be functional and compliant with vCard.pm

  Revision 1.3  1999/08/12 14:15:28  fhurtubi
  New version that is starting to use ContactList/Contact

  Revision 1.2  1999/07/29 03:07:42  fhurtubi
  Added full path to my directory so tests can work fine

  Revision 1.1  1999/07/28 22:35:05  fhurtubi
  First version that is working with simulated data from flat files


=head1 SEE ALSO

perl(1).

=cut
