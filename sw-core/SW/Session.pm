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

package SW::Session;

#------------------------------------------------------------
# SW::Session
# Handles session specific data
#------------------------------------------------------------
# $Id: Session.pm,v 1.38 1999/11/16 17:07:03 scott Exp $
#------------------------------------------------------------
use strict;

use vars qw($VERSION @ISA);

#use SW;
use SW::Session::DBI;
use SW::Util;
use SW::Component;

@ISA = qw(SW::Component);

$VERSION = '0.03';


#------------------------------------------------------------
# new
# creates a new instance of a session object. This is
# passed back and forth via cookies (preferred method)
# or via query strings or hidden fields (will work
# 
#------------------------------------------------------------

sub new
{
	my ($className, $id, $readonly) = @_;
	my %the_session;
	my $self = bless {}, $className;
	
	#print STDERR "GOT BACK session $id\n" if $id;
	SW::debug($self,"Got back SESSION_ID $id \n");	   

	if ($readonly)
	{
		tie %the_session, 'SW::Session::DBI', $id, {readonly => 1,};
	}
	else
	{
		tie %the_session, 'SW::Session::DBI', $id;
	}

	$self->{_session} = \%the_session;
	
	return $self;
}

#------------------------------------------------------------
# getSessionID - method
#
# Returns the session ID
#------------------------------------------------------------

sub getSessionID
{
	return $_[0]->{_session}->{_session_id};
}

#------------------------------------------------------------
# hash , do not use this, it's an ugly hack and will go away pretty soon!
#
#
#------------------------------------------------------------

sub hash {
	my $caller = caller;
	(tied %{$_[0]->{_session}})->make_modified();
	return $_[0]->{_session}{$caller};
}

#------------------------------------------------------------
# dump - method
#
# Returns a printable representation of the session
#------------------------------------------------------------

sub dump
{
	return (SW::Util::flatten($_[0]->{_session}) . "\n");
}
	
#------------------------------------------------------------
# setGlobalValue(key,value) - method
#
# Sets the key to value in the global part of the session
#------------------------------------------------------------

sub setGlobalValue
{
	my ($self,$key,$value) = @_;
	#print STDERR "setGlobalValue($key,$value)\n";
	#Sometimes the acces is missed...
	(tied %{$self->{_session}})->make_modified();
	return $self->{_session}{_global}{$key} = $value;
}
#------------------------------------------------------------
# setGlobalValue(key) - method
#
# Gets the value for key in the global part of the session
#------------------------------------------------------------

sub getGlobalValue
{
	my ($self,$key) = @_;
	#print STDERR "getGlobalValue($key)=",  $self->{_session}{_global}{$key}, " \n";
	return $self->{_session}{_global}{$key};
}


#------------------------------------------------------------
# delGlobalValue(key)
#
# Deletes the specified global key form the session
#------------------------------------------------------------
sub delGlobalValue
{
	my ($self,$key) = @_;
	#print STDERR "Deleting global session value $key (it was ", $self->{_session}{_global}{$key}, ")\n";;
	#Sometimes the acces is missed...
	(tied %{$self->{_session}})->make_modified();
	return delete $self->{_session}{_global}{$key};
}
*deleteGlobalValue = \&delGlobalValue;

#------------------------------------------------------------
# setPrivateValue(key,value) - method
#
# Sets the key to value in the private part of the session
#------------------------------------------------------------

sub setPrivateValue
{
	my ($self,$key,$value) = @_;
	my $caller = caller;
	$caller = $caller->APP_ID() if ($caller->can('APP_ID'));
	#Sometimes the acces is missed...
	(tied %{$self->{_session}})->make_modified();
	return $self->{_session}{$caller}{$key} = $value;
}

#------------------------------------------------------------
# setPrivateValueOnBehalfOf(caller,key,value) - method
#
# Sets the key to value in the private part of the session for a specific
# Application.  CALLED BY SW::Master ONLY!
#------------------------------------------------------------

sub setPrivateValueOnBehalfOf
{
	my ($self,$for,$key,$value) = @_;
	my $caller = caller;
	$for = $for->APP_ID() if ($for->can('APP_ID'));
	(tied %{$self->{_session}})->make_modified();
	return $self->{_session}{$for}{$key} = $value;
}

#------------------------------------------------------------
# getPrivateValue(key) - method
#
# Gets the value of key in the private part of the session
#------------------------------------------------------------

sub getPrivateValue
{
	my ($self,$key) = @_;
	my $caller = caller;
	$caller = $caller->APP_ID() if ($caller->can('APP_ID'));
	return $self->{_session}{$caller}{$key};
}

#------------------------------------------------------------
# getPrivateValueOnBehalfOf(caller,key,value) - method
#
# Gets the key to value in the private part of the session for a specific
# Application.  CALLED BY SW::Master ONLY!
#------------------------------------------------------------

sub getPrivateValueOnBehalfOf
{
	my ($self, $for, $key) = @_;
	my $caller = caller;
	$for = $for->APP_ID() if ($for->can('APP_ID'));
	return $self->{_session}{$for}{$key};
}


#------------------------------------------------------------
# delGlobalValue(key) - method
#
# Deletes the specified private key form the session
#------------------------------------------------------------

sub delPrivateValue
{
	my ($self,$key) = @_;
	my $caller = caller;
	$caller = $caller->APP_ID() if ($caller->can('APP_ID'));
	#Sometimes the acces is missed...
	(tied %{$self->{_session}})->make_modified();
	return delete $self->{_session}{$caller}{$key};
}
*deletePrivateValue = \&delPrivateValue;


#------------------------------------------------------------
# clearPrivateValues - method
#
#  Delete all private sessions values for the calling app
#------------------------------------------------------------
sub clearPrivateValues
{
	my ($self,$key) = @_;
	my $caller = caller;
	$caller = $caller->APP_ID() if ($caller->can('APP_ID'));
	#Sometimes the acces is missed...
	(tied %{$self->{_session}})->make_modified();
	$self->{_session}{$caller} = {};
	return 1;
}



#------------------------------------------------------------
# delGlobalValueOnBehalfOf(caller, key) - method
#
# Deletes the specified private key form the session
#------------------------------------------------------------

sub delPrivateValueOnBehalfOf
{
	my ($self,$for, $key) = @_;
	my $caller = caller;
	$for = $for->APP_ID() if ($for->can('APP_ID'));
	#Sometimes the acces is missed...
	(tied %{$self->{_session}})->make_modified();
	return delete $self->{_session}{$for}{$key};
}

# ALIASES

*deleteValue = \&delPrivateValue;
*setValue = \&setPrivateValue;
*getValue = \&getPrivateValue;



sub stackPush
{
	my ($self, $class, $args) = @_;

	unshift (@{$self->{_session}{"SW::Handler"}{'stack'}}, [$class, $args]);
	(tied %{$self->{_session}})->make_modified();
}	

sub stackPass
{
	my ($self, $class, $args) = @_;

	my $removed = shift;
	push (@{$self->{_session}{"SW::Handler"}{'stack'}}, [$class, $args]);
	(tied %{$self->{_session}})->make_modified();
}	

sub stackPop
{
	my ($self, $class, $args) = @_;

	my $removed = pop (@{$self->{_session}{"SW::Handler"}{'stack'}});
	foreach my $k (keys %$args)
	{
		SW->master->addAppendage($k, $args->{$k});
	}	
	(tied %{$self->{_session}})->make_modified();
	return $removed;
}	

sub stackPeek
{
	my $self = shift;
	if ($self->{_session}{"SW::Handler"}{'stack'}->[0])
	{
		return $self->{_session}{"SW::Handler"}{'stack'}->[0];
	}
	else
	{
		return undef;
	}
}

sub DESTROY
{
	my $self = shift;
	#print STDERR "Session DESTROYED\n";
	#just in case, make sure it's flushed correctly if it's needed
	untie $self->{_session};
}


1;

__END__

=head1 NAME

SW::Session - SmartWorker Session tracking class

=head1 SYNOPSIS

  use SW::Session;

  ... create app ...
  $self->{session} = new SW::Session($self);

=head1 DESCRIPTION

The SW::Session object is probably temporary: at least until the Apache::Session developers
get their act together and solve their development problems. 

At present, it takes care of session tracking transparently by serialising itself to
storage when it's destroyed, and being woken up as in the example above.

Any type of perl pure-data structures can be stored in it, but no circular references or
anything executable is allowed.

There are currently two implementations: files and cookies.  See the SW::Session::File and
SW::Session::Cookie documentation on how these two methods work.

=head1 AUTHOR

Kyle Dawkins, kyle@hbe.ca

=head1 REVISION HISTORY

  $Log: Session.pm,v $
  Revision 1.38  1999/11/16 17:07:03  scott
  added code so that you can make a session read-only

  Revision 1.37  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.36  1999/11/15 16:23:37  scott
  added clearPrivateValues

  Revision 1.35  1999/10/10 20:00:14  gozer
  Now session private keys are APP_ID() if avaliable, className otherwise

  Revision 1.34  1999/09/30 11:38:52  gozer
  Added the support for cookies

  Revision 1.33  1999/09/28 15:03:16  scott
  Begginings of the stack implementation

  Revision 1.32  1999/09/24 22:04:25  gozer
  Modified DB access to hide username/password

  Revision 1.31  1999/09/21 16:09:03  gozer
  Added a Launching ability to SW::Handler, you can now call a specific package name with
  /apps/launch/SW::App::AppTest

  Revision 1.30  1999/09/21 05:41:36  gozer
  Some little clean-up of aliases and debuging stuff

  Revision 1.27  1999/09/20 20:43:13  krapht
  It works!!  It works!!  We fixed the problem we had with session.
  _insertSignal had problems, it was setting appState as a global, but it
  really is a private value for each app.

  Revision 1.26  1999/09/20 14:30:00  krapht
  Changes in most of the files to use the new way of referring to session,
  user, etc. (SW->user, SW->session).

  Revision 1.25  1999/09/19 20:34:42  gozer
  Documented SW.pm and I changed a few more $self->{master} stuff to SW->master

  Revision 1.24  1999/09/17 21:18:16  gozer
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

  Revision 1.20  1999/09/12 13:34:37  krapht
  Added some function delimiters

  Revision 1.19  1999/09/10 14:44:51  fhurtubi
  First draft of the back button checker...
  Its working, but right now, if a back button click is detected, it does nothing
  but writing it in the error log

  Revision 1.18  1999/09/07 23:05:35  scott
  added getSessionID method

  Revision 1.17  1999/09/04 20:58:37  fhurtubi
  Removed checking if $self->{_sw_set} was already set so we can change the user info
  in the UserRegistration App

  Revision 1.16  1999/09/04 19:08:05  scott
  Fixed a hash syntax problem in getDataSourceString and Session

  Revision 1.15  1999/09/03 20:22:16  scott
  Fixing Session so that it doesn't have hardcoded database names

  Revision 1.14  1999/09/01 01:26:46  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.13  1999/08/30 20:04:00  krapht
  Removed the Exporter stuff

  Revision 1.12  1999/07/25 02:42:27  scott
  Mostly changes to squash circular reference bugs that were causing
  sessions and applications to linger arouond until server restart
  (thus really messing up the session storage)

  Revision 1.11  1999/07/19 13:29:19  scott
  Lots of clean-up work, debugged and improved the desctructor calling of all
  copmonents so none should be left lingering after the transaction completes.

  This in turn solved the session problem (destructor wasn't being called
  because it was persisting past the end of the transaction)

  Revision 1.10  1999/07/08 15:45:27  scott
  oops - should have done these separately ...

  Working on changes to the database code for users, groups, and objects

  as well as debugging and signals

  Revision 1.9  1999/06/01 18:46:32  scott
  trivial - debugging

  Revision 1.8  1999/05/20 13:52:31  scott
  Nothing significant changed

  Revision 1.7  1999/05/04 15:53:51  scott
  -New Apache::Session based database session tracking
  -New debugging scheme

  Revision 1.6  1999/04/13 16:37:58  scott
  nothing - debug code

  Revision 1.5  1999/02/17 17:08:49  kiwi
  Altered class to use hierarchical parent/child app relationships

  Revision 1.4  1999/02/12 22:32:02  kiwi
  Changed Session to use the SW::Util::flatten method

  Revision 1.3  1999/02/11 20:59:06  kiwi
  Removed log at the top.

  Revision 1.2  1999/02/11 18:05:02  kiwi
  Added cookie detection.  If any cookies are detected, the SW::Session object
  uses cookie-based session tracking instead of file-based sessions.

  Revision 1.1.1.1  1999/02/10 19:49:11  kiwi
  SmartWorker

  Revision 1.3  1999/02/10 17:23:20  kiwi
  First working session object.  Uses Session::File to store
  session data in temporary files.  This will be replaced later with
  a more secure and robust session system but for now, it's
  enough for what we need.

  Revision 1.2  1999/02/09 22:53:46  kiwi
  Added the "new" and "closeSession" methods.


=head1 SEE ALSO

SW::Application(1), perl(1).

=cut
