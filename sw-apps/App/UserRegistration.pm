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
# $Id: UserRegistration.pm,v 1.3 1999/09/07 16:23:17 gozer Exp $
#------------------------------------------------------------

package SW::App::UserRegistration;

use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE);

use SW::Application;

@ISA = qw(SW::Application);

# constants

sub APP_ID () {'USERREG'}
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

	$self->{master}->{appRegistry}->register(APP_ID, DATA_TYPE, "This is the user registration app");
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

	my ($email, $userName);
	if ($self->{user}->getName ne "guest") {	
		$email = $self->{user}->getValue("email");
		$userName = $self->{user}->getName;
	}

	my $newPanel = new SW::Panel::FormPanel($self, {
		-bgColor	=> "ffffff",
	});

	my $row = 0;
	$newPanel->addElement(0, $row, new SW::GUIElement::Text ($self, {
		-text	=> "Username",
	}));
	$newPanel->addElement(1, $row++, new SW::GUIElement::TextBox ($self, {
		-text	=> $userName,
		-name	=> "userName",
		-width	=> 20,
	}));

	$newPanel->addElement(0, $row, new SW::GUIElement::Text ($self, {
		-text	=> "Email",
	}));
	$newPanel->addElement(1, $row++, new SW::GUIElement::TextBox ($self, {
		-text	=> $email,
		-name	=> "email",
		-width	=> 20,
	}));

	$newPanel->addElement(0, $row, new SW::GUIElement::Text ($self, {
		-text	=> "New password",
	}));
	$newPanel->addElement(1, $row++, new SW::GUIElement::PasswordField ($self, {
		-name	=> "newPassword",
		-width	=> 20,
	}));

	$newPanel->addElement(0, $row, new SW::GUIElement::Text ($self, {
		-text	=> "Confirm new password",
	}));
	$newPanel->addElement(1, $row++, new SW::GUIElement::PasswordField ($self, {
		-name	=> "confirmPassword",
		-width	=> 20,
	}));
	
	$newPanel->addElement(0, $row, new SW::GUIElement::Button ($self, {
		-text	=> "Submit",
		-signal	=> "executeEditUser",
	}));
	$newPanel->addElement(1, $row, new SW::GUIElement::Button ($self, {
		-text	=> "Cancel",
	}));

	if ($self->{UImsg} ne "") {
		$newPanel->addElement(0, ++$row, new SW::GUIElement::Text ($self, {
			-text           => $self->{UImsg},
			-bgColor        => "dedede",
		}));
	}

	$mainPanel->addElement(0, 0, $newPanel);
} #  buildMainUI

#==================================================================#
# CALLBACKS
#==================================================================#

sub executeEditUserWrapper
#SW Callback executeEditUser 10
{
	my $self = shift;
	$self->setSessionValue("appState", "executeEditUser");
} # executeEditUserWrapper

#==================================================================#
# INTERNAL METHODS
#==================================================================#

sub executeEditUser
{
	my $self = shift;

	my $userName = $self->getDataValue("userName");
	my $email = $self->getDataValue("email");
	my $newPassword = $self->getDataValue("newPassword");
	my $confirmPassword = $self->getDataValue("confirmPassword");

	if ($userName =~ /^\s*$/) { # no username
		$self->{UImsg} = "You have to provide a username";
	} elsif ((SW::User::userNameExists($userName) != $self->{user}->getUserId) &&
			(SW::User::userNameExists($userName) != 0)) { # username exists 
		$self->{UImsg} = "This username already exists!";
	} elsif ($newPassword ne "" && $newPassword ne $confirmPassword) {  # password mismatch
		$self->{UImsg} = "Passwords don't match. Try again";
	} elsif ($newPassword eq "" && $self->{user}->getName eq "guest") { # new user, no password
		$self->{UImsg} = "You must provide a password with your username";
	} elsif ((length($newPassword) < 3) && 
			( ($self->{user}->getName eq "guest") || 
	 		 (($self->{user}->getName ne "guest") && ($newPassword ne "")
		         )
			)
		) { # if pw is less than 3 characters, and : if user is guest, or if user isn't guest but pw is empty (that means 
		    # don't change pw)

		$self->{UImsg} = "Your password must be at least 3 characters long";
	} else {
		if ($self->{user}->getName ne "guest") { # this means the user is editing his info because we already have
							 # his username...
			$self->{user}->setValue("email", $email);
			$self->{user}->setValue("password", $newPassword) if ($newPassword ne "");
			$self->{user}->setValue("user", $userName) if ($userName ne $self->{user}->getUserName);

			$self->{user}->setValue("dirty", 1); # this will force a save at the cleanup stage
		} else {
			$self->{user}->setValue("email", $email);
			$self->{user}->setValue("password", $newPassword);
			$self->{user}->setValue("user", $userName);

			$self->{user}->create();
		}

		# force the change of the userinfo, 
		$self->{master}->{sessionHandler}->setUserInfo($self->{user}->getUserId, $self->{user}->getName, $self->{user}->getValue("password"));
		$self->{UImsg} = "Save successful";
	}
	
	return 1;
} # sub executeEditGroup

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

  $Log: UserRegistration.pm,v $
  Revision 1.3  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors

  Revision 1.2  1999/09/04 21:10:51  fhurtubi
  Changed a method call to a function call (object wasn't used anyways)

  Revision 1.1  1999/09/04 20:55:37  fhurtubi
  Basic user registration. Works with both usre creation and user modification (for
  modification, you have to call this from another app as this App is not taking
  care of the user validation)

  Revision 1.3  1999/09/02 23:21:18  fhurtubi
  Added the invite function, this version is fully featured

  Revision 1.2  1999/09/02 20:38:07  fhurtubi
  For vCard stuff, I added Office::vCard and for groupManager, I've added SW::App::

  Revision 1.1  1999/09/02 20:20:08  fhurtubi
  1st version of Group Manager


=head1 SEE ALSO

SW::Application,  perl(1).

=cut

