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
# User registration
#------------------------------------------------------------
# $Id: UserAdministration.pm,v 1.4 1999/11/15 18:17:28 gozer Exp $
#------------------------------------------------------------

package SW::App::UserAdministration;

use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE);

use SW::Application;
use SW::Util;
use SW::Group;

@ISA = qw(SW::Application);

# constants

sub APP_ID () {'USERADMIN'}
sub DATA_TYPE () { 'USER'}

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);

	$self->buildTable;
	
	$self->setValue('name', APP_ID);

	return $self;
}

sub swInitApplication
{
	my $self = shift;

	$self->{master}->{appRegistry}->register(APP_ID, DATA_TYPE, "This is the user administration app");
}

#-------------------------------------------------------------------#
# Validate the user identity
#-------------------------------------------------------------------#
sub swValidateUser
{
        my $self = shift;
        
        SW::debug($self,"Validating user - ".$self->{user}->{user});

        return 0 if ($self->{user}->{user} eq "guest");
	# check if user is an admin
	my @groups = keys %{$self->{user}->getGroups()};
	return 0 if (! inArray ("admin", \@groups));
        return 1;
} # sub swValidateUser

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

	my $newPanel = new SW::Panel::FormPanel($self, {
		-bgColor	=> "ffffff",
	});

	my $row = 0;
	$newPanel->addElement(0, $row, new SW::GUIElement::Text ($self, {
		-text	=> "Username",
	}));
	$newPanel->addElement(1, $row++, new SW::GUIElement::TextBox ($self, {
		-name	=> "username",
		-width	=> 20,
	}));
	$newPanel->addElement(0, $row++, new SW::GUIElement::Button ($self, {
		-text	=> "View",
		-signal	=> "buildViewUser",
	}));

	$mainPanel->addElement(0, 0, $newPanel);
}

#==================================================================#
# CALLBACKS
#==================================================================#

sub buildViewUserWrapper
#SW Callback buildViewUser 10
{
	my $self = shift;
	$self->setSessionValue("appState", "buildViewUser");
} # buildViewUserWrapper

#==================================================================#
# INTERNAL METHODS
#==================================================================#

sub buildViewUser
{
	my $self = shift;
	
	my $mainPanel = $self->getPanel();

	
	my $userName = $self->getDataValue("username");

	my ($userValues, $groups, $msg);
	if (my $userId = SW::User::userNameExists($userName)) {
		$userValues = SW::User::getOtherUserValues($userId, ["email"]);
		$groups = SW::Group::getUserGroups($userId);
	} else {
		$msg = "Username $userName doesn't exist";
		$userName = undef;
		$userValues = {};
		$groups = {};
		
	}

	my $newPanel = new SW::Panel::FormPanel($self, {
		-bgColor	=> "ffffff",
	});

	my $row = 0;
	if (!$msg) {
		$newPanel->addElement(0, $row++, new SW::GUIElement::Text ($self, {
			-text	=> "Username : $userName",
		}));

		$newPanel->addElement(0, $row++, new SW::GUIElement::Text ($self, {
			-text	=> "Email: $userValues->{email}",
		}));

		if (%{$groups}) {
			$newPanel->addElement(0, $row++, new SW::GUIElement::HorizontalRule ($self, {
				-width		=> "100%",
				-noshade	=> "true",
			}));

			$newPanel->addElement(0, $row++, new SW::GUIElement::Text ($self, {
				-text	=> "Groups the user is in",
				-attrib	=> "BOLD",
				-bgColor	=> "dedede",
			}));

			foreach my $group (sort {$a cmp $b} keys %{$groups})
			{
				$newPanel->addElement(0, $row++, new SW::GUIElement::Text ($self, {
					-text	=> "$group",
				}));
			}
		} else {
			$newPanel->addElement(0, $row++, new SW::GUIElement::Text ($self, {
				-text	=> "This user isn't in any group",
			}));
		}
	}

	if ($msg ne "") { 
		$newPanel->addElement(0, $row++, new SW::GUIElement::Text ($self, {
			-text		=> $msg,
			-bgColor	=> "dedede",
		}));
	}

	$newPanel->addElement(0, $row, new SW::GUIElement::Button ($self, {
		-text	=> "Done",
	}));
	$newPanel->addElement(1, $row, new SW::GUIElement::Button ($self, {
		-text	=> "Edit",
	}));
	$newPanel->addElement(2, $row++, new SW::GUIElement::Button ($self, {
		-text	=> "Delete",
	}));

	$mainPanel->addElement(0, 0, $newPanel);
} #  buildViewUser


#SW end

1;
__END__

=head1 NAME

UserManager - User Manager Application

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 METHODS

=head1 PARAMETERS


=head1 AUTHOR

Fred Hurtubise
fred@hbe.ca
HBE Sep 01 1999

=head1 REVISION HISTORY

  $Log: UserAdministration.pm,v $
  Revision 1.4  1999/11/15 18:17:28  gozer
  Added Liscence on pm files

  Revision 1.3  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors

  Revision 1.2  1999/09/04 21:10:51  fhurtubi
  Changed a method call to a function call (object wasn't used anyways)

  Revision 1.1  1999/09/04 20:51:24  fhurtubi
  Basic user administration. Right now, we can only see the user info (email,
  groups user is in), but i'd like to add edit/delete methods

  Revision 1.3  1999/09/02 23:21:18  fhurtubi
  Added the invite function, this version is fully featured

  Revision 1.2  1999/09/02 20:38:07  fhurtubi
  For vCard stuff, I added Office::vCard and for groupManager, I've added SW::App::

  Revision 1.1  1999/09/02 20:20:08  fhurtubi
  1st version of Group Manager


=head1 SEE ALSO

SW::Application,  perl(1).

=cut

