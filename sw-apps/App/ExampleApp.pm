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
# Sample App demonstrating a state machine style 
#	system to decide what UI to Draw
#
#------------------------------------------------------------
# $Id: ExampleApp.pm,v 1.2 1999/09/07 16:23:17 gozer Exp $
#------------------------------------------------------------

package SW::App::ExampleApp;

use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE);

use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;
use SW::GUIElement::RadioButtonSet;
use SW::Data::Document;
use UserManager::Text;
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


sub Dispatcher
#SW TransOrder 15
{
	my $self = shift;

	# this demonstrates the idea blatantly obviously ..	if you were clever and
	#  careful about it, you could make htis a lot shorter by doing something like:
	#
	#  $self->Build$appstate()


	my $appstate = $self->getSessionValue('appState') || 'MAIN';

	if ($state eq "MAIN" || $state eq "SAVE_EDIT" || $state eq "SAVE_ADD")
	{
		$self->$BuildMainUI;
	} 
	elsif($state eq "EDIT" || $state eq "ADD")
 	{
		$self->$BuildEditUI;
	}
	elseif ($state eq "CONFIRM_DELETE")
	{	
		$self->$BuildConfirmUI;	
	} 
	else
	{
		## Error, unknown state
	}
}

sub BuildMainUI    # Note no #SW line here, this is always called from the Dispatcher
{
	my $self = shift;

	# ... draw the Main UI stuff 

	$self->setSessionValue('appState', 'MAIN');
}	

sub BuildEditUI
{
	my $self = shift;

	# draw the edit/add screen ....

	if ($self->getSessionValue('appState') eq "EDIT")
	{
		$self->setSessionValue('appState', 'SAVE_EDIT');
	}
	else
	{
		$self->setSessionValue('appState', 'SAVE_NEW');
	}
}

sub BuildConfirmUI
{
	my $self = shift;

	# draw the confirm screen

	$self->setSessionValue('appState', 'EXECUTE_DELETE');
}

sub responseDelete
#SW CallBack DeleteStaging 10
{
	my $self = shift;
	$self->setSessionValue('appState','CONFIRM_DELETE');
}

sub responseExecuteDelete
#SW CallBack DeleteExecution 10
{
	my $self = shift;
	
	# do the deletion....

	$self->setSessionValue('appState', 'MAIN');
}
	
sub responseAdd
#SW CallBack AddNew 10
{
	my $self = shift;
	
	$self->setSessionValue('appState','ADD');
}

sub responseExecutionAdd
#SW CallBack Save 10
{
	my $self = shift;

	# do the saving....	

	$self->setSessionValue('appState', 'MAIN');
	# that was repetitive, Dispatcher and Main would have done the same thing....
	# would be needed if this callback was one called after the UI got built
	#   (say 18)
}

#SW end

1;

__END__

=head1 NAME

ExampleApp - This is an example

=head1 SYNOPSIS

none

=head1 DESCRIPTION

	This is just a code example for the transaction order and application
	state handling.  It doesn't do anything.


=head1 METHODS

=head1 PARAMETERS

=head1 AUTHOR

Scott Wilson
HBE   scott@hbe.ca
Aug 16/99

=head1 REVISION HISTORY

  $Log: ExampleApp.pm,v $
  Revision 1.2  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors

  Revision 1.1  1999/09/02 20:11:05  gozer
  New namespace convention

  Revision 1.2  1999/08/27 19:58:17  krapht
  Changed calls to addSessionValue for setSessionValue (changed Master as well)

  Revision 1.1  1999/08/16 18:04:37  scott
  Added a little code example of app state.


=head1 SEE ALSO

SW::Application,  www.smartworker.org

=cut

