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

use SW::Util::Prep;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for internal use only!!
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# GroupManager - Group management for SmartWorker
##------------------------------------------------------------
# $Id: GroupManager.pm,v 1.6 1999/09/07 16:23:17 gozer Exp $
#------------------------------------------------------------

package SW::App::GroupManager;

use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE);

use SW::Application;
use SW::Group;
use SW::User;

@ISA = qw(SW::Application);

# constants

sub APP_ID () {'GROUPMGR'}
sub DATA_TYPE () { 'GROUPMGRTYPE'}

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);

	$self->buildTable;
	
	$self->setValue('name', APP_ID);

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

	$self->{master}->{appRegistry}->register(APP_ID, DATA_TYPE, "This is the group manager app");
}

sub dispatcher
#SW TransOrder 15
{
        my $self = shift;

        my $appState = $self->getSessionValue('appState');
        
        if ($appState eq "") { $self->buildMainUI; }
        else {
                $self->$appState();
                if ($self->{UImsg} ne "") {
                        $self->buildMainUI($self->{UImsg});
                }
        }

	delete $self->{UImsg};
	$self->deleteSessionValue("appState");
}

sub buildMainUI
{
	my $self = shift;
	
	my $mainPanel = $self->getPanel();
	
	my $groups = SW::Group::getUserGroups($self->{user}->getUserId());

	foreach my $name (keys %$groups)
	{
		$self->{groups}->{$name} = $groups->{$name}; # name => id
	}

	my $groups = SW::Group::getAllGroups();

	my $newPanel = new SW::Panel::HTMLPanel ($self, {
		-bgColor	=> "ffffff",
		-border		=> 1,
	});

	$newPanel->addElement(0, 0, new SW::GUIElement::Text ($self, {
		-text		=> "Hello ".$self->{user}->getName.", here are the groups you can have access to...",
		-attrib		=> "ITAL",
	}));

	my $i = 0;
	foreach my $header (qw{Action Public Name Options})
	{
		$newPanel->addElement($i, 1, new SW::GUIElement::Text ($self, {
			-text		=> $header,
			-attrib		=> "bold",
			-bgColor	=> "dedede",
		}));
		$i++;
	}

	my $row = 2;
	foreach my $name (sort {$a cmp $b} keys %{$groups})
	{
		if (	($groups->{$name}->{PERM} == 1) 				&& 
			(! $self->{groups}->{$name}) 					&&
			($groups->{$name}->{CREATOR} != $self->{user}->getUserId)
		) { next; } # this is private and the user is not part of it nor the creator

		$newPanel->addElement(0, $row, new SW::GUIElement::Link ($self, {
			-text		=> ($self->{groups}->{$name}) ? "LEAVE" : "JOIN",
			-args		=> {
				action		=> ($self->{groups}->{$name}) ? "leave" : "join",
				GID		=> $groups->{$name}->{GID},
			},
			-signal		=> "executeJoinOrLeaveGroup",
		}));

		$newPanel->addElement(1, $row, new SW::GUIElement::Text ($self, {
			-text		=> ($groups->{$name}->{PERM} == 0) ? "X" : "&nbsp;",
			-align		=> "center",
		}));

		$newPanel->addElement(2, $row, new SW::GUIElement::Text ($self, {
			-text		=> $name."(".SW::Group::getNbInGroup($groups->{$name}->{GID}).")",
		}));
		
		# until the renderer fixes this, here's a hack to align the columns properly:
		my $tmpHash = { 3 => "Edit", 4 => "View", 5 => "Invite", 6 => "Delete", };
		for (my $x = 3; $x <= 6; $x++)
		{
			$newPanel->addElement($x, $row, new SW::GUIElement::Text ($self, {
				-text		=> $tmpHash->{$x},
				-textColor	=> "eeeeee",
			}));
		}

		if ($self->{user}->getUserId == $groups->{$name}->{CREATOR}) { # if user is creator of the group
			$newPanel->addElement(3, $row, new SW::GUIElement::Link ($self, {
				-text		=> "Edit",
				-args		=> {
					GID => $groups->{$name}->{GID},
				},
				-signal		=> "buildEditGroup",
			}));
			if (SW::Group::getNbInGroup($groups->{$name}->{GID}) == 0) {
				$newPanel->addElement(6, $row, new SW::GUIElement::Link ($self, {
					-text		=> "Delete",
					-args		=> {
						GID => $groups->{$name}->{GID},
					},
					-signal		=> "executeDeleteGroup",
				}));
			}
		} 
		
		if ((($groups->{$name}->{PERM} == 0) 				|| # if group is public
		     ($self->{groups}->{$name})  				|| # or you're a member of that group (eg: private)
		     ($groups->{$name}->{CREATOR} == $self->{user}->getUserId)     # or you're the creator of it
		    )								&&
		    (SW::Group::getNbInGroup($groups->{$name}->{GID}) != 0) 	   # and the group is non empty!
                   )
		{
			$newPanel->addElement(4, $row, new SW::GUIElement::Link ($self, {
				-text		=> "View",
				-args		=> {
					GID => $groups->{$name}->{GID},
				},
				-signal		=> "buildViewGroup",
			}));
		}

		if (($groups->{$name}->{PERM} == 1)) {
			$newPanel->addElement(5, $row, new SW::GUIElement::Link ($self, {
				-text		=> "Invite",
				-args		=> {
					GID => $groups->{$name}->{GID},
				},
				-signal		=> "buildInviteUser",
			}));			
		}
		$row++;
	}

	$groups = undef;
	$groups = SW::Group::getUserInvitedGroups($self->{user}->getUserId);

	foreach my $name (sort {$a cmp $b} keys %{$groups})
	{
		$newPanel->addElement(0, $row, new SW::GUIElement::Link ($self, {
			-text		=> "INVITED",
			-args		=> {
				GID		=> $groups->{$name}->{GID},
			},
			-signal		=> "executeJoinInvitedGroup",
		}));

		$newPanel->addElement(1, $row, new SW::GUIElement::Text ($self, {
			-text           => ($groups->{$name}->{PERM} == 0) ? "X" : "&nbsp;",
			-align		=> "center",
		}));

		$newPanel->addElement(2, $row, new SW::GUIElement::Text ($self, {
			-text		=> $name."(".SW::Group::getNbInGroup($groups->{$name}->{GID}).")",
		}));
		
		# until the renderer fixes this, here's a hack to align the columns properly:
		my $tmpHash = { 3 => "Edit", 4 => "View", 5 => "Invite", 6 => "Delete", };
		for (my $x = 3; $x <= 6; $x++)
		{
			$newPanel->addElement($x, $row, new SW::GUIElement::Text ($self, {
				-text		=> $tmpHash->{$x},
				-textColor	=> "eeeeee",
			}));
		}

		$newPanel->addElement(4, $row, new SW::GUIElement::Link ($self, {
			-text		=> "View",
			-args		=> {
				GID => $groups->{$name}->{GID},
			},
			-signal		=> "buildViewGroup",
		}));
		$row++;
	}
	
	
	$newPanel->addElement(0, $row, new SW::GUIElement::Link ($self, {
		-text	=> "Create a group",
		-signal	=> "buildEditGroup",
	}));

	if ($self->{UImsg} ne "") {
		$newPanel->addElement(0, $row+1, new SW::GUIElement::Text ($self, {
			-text		=> $self->{UImsg},
			-bgColor	=> "dedede",
		}));
	}

	$mainPanel->addElement(0, 0, $newPanel);

	my $testPanel = new SW::Panel::HTMLPanel ($self, {
		-bgColor => "dddddd",
	});
	$testPanel->addElement(0, 0, new SW::GUIElement::Link ($self, {
		-URI		=> "UserRegistration.pm",
		-text		=> "Change your user parameters",
	}));
	$mainPanel->addElement(0, 1, $testPanel);
} #  buildMainUI

#==================================================================#
# CALLBACKS
#==================================================================#

sub buildEditGroupWrapper
#SW Callback buildEditGroup 10
{
	my $self = shift;
	$self->setSessionValue("appState", "buildEditGroup");
} # buildEditGroupWrapper

sub executeEditGroupWrapper
#SW Callback executeEditGroup 10
{
	my $self = shift;
	$self->setSessionValue("appState", "executeEditGroup");
} # executeEditGroupWrapper

sub executeDeleteGroupWrapper
#SW Callback executeDeleteGroup 10
{
	my $self = shift;
	$self->setSessionValue("appState", "executeDeleteGroup");
} # executeDeleteGroupWrapper

sub buildViewGroupWrapper
#SW Callback buildViewGroup 10
{
	my $self = shift;
	$self->setSessionValue("appState", "buildViewGroup");
} # buildViewGroupWrapper

sub buildInviteUserWrapper
#SW Callback buildInviteUser 10
{
	my $self = shift;
	$self->setSessionValue("appState", "buildInviteUser");
} # buildInviteUserpWrapper

sub executeInviteUserWrapper
#SW Callback executeInviteUser 10
{
	my $self = shift;
	$self->setSessionValue("appState", "executeInviteUser");
} # executeInviteUserWrapper

sub executeJoinOrLeaveGroupWrapper
#SW Callback executeJoinOrLeaveGroup 10
{
	my $self = shift;
	$self->setSessionValue("appState", "executeJoinOrLeaveGroup");
} # executeJoinOrLeaveGroupWrapper

sub executeJoinInvitedGroupWrapper
#SW Callback executeJoinInvitedGroup 10
{
	my $self = shift;
	$self->setSessionValue("appState", "executeJoinInvitedGroup");
} # executeJoinInvitedGroupWrapper

#==================================================================#
# INTERNAL METHODS
#==================================================================#

sub buildEditGroup
{
	my $self = shift;

	my $mainPanel = $self->getPanel();
	
	my $newPanel = new SW::Panel::FormPanel($self, {
		-bgColor	=> "ffffff",
	});

	my $GID = $self->getDataValue("GID");
	if ($GID) { $self->setSessionValue('GID', $GID); }

	my $group = ($GID) ? SW::Group::loadGroup ($GID) : undef;

	$newPanel->addElement(0, 0, new SW::GUIElement::Text ($self, {
		-text		=> "Group name",
	}));
	$newPanel->addElement(1, 0, new SW::GUIElement::TextBox ($self, {
		-text		=> $group->{name},
		-name		=> "name",
		-width		=> 20,
	}));
	$newPanel->addElement(0, 1, new SW::GUIElement::Text ($self, {
		-text		=> "Permissions",
	}));

	my $buttonSet = new SW::GUIElement::RadioButtonSet ($self, {
		-name           => "perm",
		-buttons        => [],
		-orientation    => 'horizontal',
		-checked        => $group->{perm} || 0,
	});
        
	$newPanel->addElement(1, 1, new SW::GUIElement::RadioButton ($self, {
		-name            => "perm",
		-set            => $buttonSet,
		-value          => "0",
		-text           => "Public",
	}));

	$newPanel->addElement(2, 1, new SW::GUIElement::RadioButton ($self, {
		-name            => "perm",
		-set            => $buttonSet,
		-value          => "1",
		-text           => "Private",
	}));

	$newPanel->addElement(0,2, new SW::GUIElement::Button ($self, {
		-text           => "Save",
		-signal         => "executeEditGroup",
	}));
	$newPanel->addElement(1,2, new SW::GUIElement::Button ($self, {
		-text           => "Cancel",
		-signal         => "cancelState",
	}));

	$mainPanel->addElement(0, 0, $newPanel);
} # sub buildEditGroup

sub buildViewGroup
{
	my $self = shift;

	my $mainPanel = $self->getPanel();
	
	my $newPanel = new SW::Panel::HTMLPanel($self, {
		-bgColor	=> "ffffff",
	});

	my $GID = $self->getDataValue("GID");

	my $group = SW::Group::loadGroup ($GID);

	$newPanel->addElement(0, 0, new SW::GUIElement::Text ($self, {
		-text		=> "Viewing members of group ".$group->{name},
		-bgColor	=> "dedede",
	}));

	my $users = SW::Group::getMembers ($GID);

	$newPanel->addElement(0, 1, new SW::GUIElement::HorizontalRule ($self, {
		-width	=> "100%",
		-height	=> 1,
	}));

	my $row = 2;
	foreach my $user (sort {$a cmp $b} keys (%{$users}))
	{
		#$users->{$user}->{uid}
		#$users->{$user}->{perm} (0 = pending, 1 = member, 2 = admin)
		$newPanel->addElement(0, $row++, new SW::GUIElement::Text ($self, {
			-text	=> $user
		}));
	}

	if (! %{$users} ) {
		$newPanel->addElement(0, $row++, new SW::GUIElement::Text ($self, {
			-text	=> "This group is empty",
			-attrib	=> "ITAL",
		}));
	}

	$newPanel->addElement(0, $row, new SW::GUIElement::Link ($self, {
		-text	=> "DONE",
	}));

	$mainPanel->addElement(0, 0, $newPanel);
} # sub buildViewGroup

sub buildInviteUser
{
	my $self = shift;

	my $mainPanel = $self->getPanel();
	
	my $newPanel = new SW::Panel::FormPanel($self, {
		-bgColor	=> "ffffff",
	});

	my $GID = $self->getDataValue("GID");
	$self->setSessionValue('GID', $GID);

	my $group = SW::Group::loadGroup ($GID);

	my $row = 0;
	$newPanel->addElement(0, $row++, new SW::GUIElement::Text ($self, {
		-text		=> "Inviting someone to group ".$group->{name},
		-bgColor	=> "dedede",
	}));

	my $users = SW::Group::getMembers ($GID);

	$newPanel->addElement(0, $row++, new SW::GUIElement::HorizontalRule ($self, {
		-width	=> "100%",
		-height	=> 1,
	}));

	$newPanel->addElement(0, $row++, new SW::GUIElement::Text ($self, {
		-text	=> "Enter the name of the user you wish to invite",
	}));

	$newPanel->addElement(0, $row++, new SW::GUIElement::TextBox ($self, {
		-name	=> "userName",
		-width	=> 20,
	}));

	$newPanel->addElement(0, $row, new SW::GUIElement::Button ($self, {
		-text	=> "Invite",
		-signal	=> "executeInviteUser",
	}));
	$newPanel->addElement(1, $row++, new SW::GUIElement::Button ($self, {
		-text	=> "Cancel",
	}));

	$mainPanel->addElement(0, 0, $newPanel);
} # sub buildInviteUser

sub executeEditGroup
{
	my $self = shift;

	my $GID = $self->getSessionValue("GID"); # read it now because...
	$self->deleteSessionValue("GID"); # don't need it anymore

	my $groupName = $self->getDataValue("name");
	my $groupPerm = $self->getDataValue("perm");

	SW::Group::saveGroup ($GID, $groupName, $groupPerm, $self->{user}->getUserId);
	
	$self->{UImsg} = "Saving of $groupName successful";
	return 1;
} # sub executeEditGroup

sub executeDeleteGroup
{
	my $self = shift;

	my $GID = $self->getDataValue("GID");

	my $groupName = SW::Group::deleteGroup ($GID);
	
	$self->{UImsg} = "Deletion of $groupName successful";
	return 1;
} # sub executeEditGroup

sub executeInviteUser
{
	my $self = shift;

	my $GID = $self->getSessionValue("GID"); # read it now because...
	$self->deleteSessionValue("GID"); # don't need it anymore

	my $userName = $self->getDataValue("userName");
	
	my $userId = SW::User::userNameExists ($userName);

	if ($userId) {
		my $groupName = SW::Group::inviteToGroup ($GID, $userId);
		$self->{UImsg} = "Invitation of $userName to $groupName successful";
	} else {
		$self->{UImsg} = "The user $userName doesn't exists";
	}
	return 1;
} # sub executeInviteUser

sub executeJoinOrLeaveGroup
{
	my $self = shift;

	my $action = $self->getDataValue("action");
	my $GID = $self->getDataValue("GID");

	my $groupName;
	if ($action eq "join") { 
		$groupName = SW::Group::joinGroup ($GID, $self->{user}->getUserId);
		$action = "joined";
	} else {
		$groupName = SW::Group::leaveGroup ($GID, $self->{user}->getUserId);
		$action = "left";
	}

	$self->{UImsg} = "You $action the $groupName group";
	return 1;
}

sub executeJoinInvitedGroup
{
	my $self = shift;

	my $GID = $self->getDataValue("GID");

	my $groupName = SW::Group::joinInvitedGroup ($GID, $self->{user}->getUserId);

	$self->{UImsg} = "You joined the $groupName group";
	return 1;
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

Fred Hurtubise
fred@hbe.ca
HBE Sep 01 1999

=head1 REVISION HISTORY

  $Log: GroupManager.pm,v $
  Revision 1.6  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors

  Revision 1.5  1999/09/04 21:41:14  fhurtubi
  Changed a call to a SW::Group function that should really have been done to a SW::User
  function

  Revision 1.4  1999/09/04 20:54:24  fhurtubi
  Fixed some minor bugs

  Revision 1.3  1999/09/02 23:21:18  fhurtubi
  Added the invite function, this version is fully featured

  Revision 1.2  1999/09/02 20:38:07  fhurtubi
  For vCard stuff, I added Office::vCard and for groupManager, I've added SW::App::

  Revision 1.1  1999/09/02 20:20:08  fhurtubi
  1st version of Group Manager


=head1 SEE ALSO

SW::Application,  perl(1).

=cut

