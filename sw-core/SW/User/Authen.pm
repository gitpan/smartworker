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

package SW::User::Authen;

#------------------------------------------------------------
# SW::User::Authen
# 	Subclass of SW::User to wich can be delegated all 
#   user authentication tasks
#------------------------------------------------------------
# $Id: Authen.pm,v 1.16 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use Digest::MD5 qw(md5 md5_base64);


use SW;
use SW::Util;
use SW::Application;
use SW::User::Admin;
use SW::User::Manager;
use Apache;
use Apache::Constants qw(:common);
use SW::Data;
use DBI;
use SW::DB;
use SW::Constants;

use Data::Dumper;

@ISA = qw(SW::Component);

$VERSION = '0.02';

#------------------------------------------------------------
# new
# Creates a new user object.  The object is instantiated
# from the user database, or, if the user is not found, 
# it returns "guest" in the user name
#------------------------------------------------------------

sub new
{
	#print STDERR "+++++CREATING NEW AUTHEN TOKEN\n";
	my $className = shift;
	my $self = bless { }, $className;
	
	if(my $auth_token = SW->session->getPrivateValue("token"))
		{
		#print STDERR "USER " , SW->session->getPrivateValue("token"), " already known\n";
		($self->{username}, $self->{userid}) = split /:/, $auth_token;
	   $self->{_valid} = 1 if $self->{userid} != 0;
		$self->{_unknown}=1 if $self->{userid} == 0;
		return $self;
		}
	
	$self->init();
	
	return $self;
}

sub init {
	my $self = shift;
	
	#initialize the user object to sane values
	$self->{_unknown} = 1;
	$self->{_valid} = 0;
	$self->{_failed} = 0;
	$self->{'username'} = 'guest';
	$self->{'userid'} = 0;
	
	$self->validate();
	
	SW->session->setPrivateValue("token", $self->{username} . ":" . $self->{userid}) unless $self->{_failed};	
}

#sub responsible for the determination of the validity of a given user that has no token yet.
sub validate {
	my $self = shift;
	my $username = SW->data->{'login'} ;
	
	if($username)
		{
		my $password =SW->data->{'password'};
		delete SW->data->{'password'};
		
		$self->{_unknown} = 0; # we know your name :-)
		my $sth = SW::DB->getDbh->prepare(qq/SELECT password, uid from authentication where username="$username"/);
		$sth->execute();
		my $row = $sth->fetch;
		if (check($password,$row->[0]))
			{
			$self->{username} = $username;
			$self->{userid} = $row->[1];
			$self->{_valid} = 1;
			}
		else
			{
			$self->{_failed} = 1;
			}
		}
return;
}

sub username {
	return $_[0]->{username};
	}

sub userid {
	return $_[0]->{userid};
	}

sub failed {
	return $_[0]->{_failed};
	}
	
sub guestuser  {
	return $_[0]->{_unknown};
	}
	
sub valid {
	return $_[0]->{_valid};
	}
	
#sub checkPassword {
#	my $self = shift;
#	my $password = shift;
#	$password = cryptpwd($password);
#	my $sth = SW::DB::getDbh->prepare("SELECT * from authentication where password='$password' and uid='$self->{userid}'");
#	$sth->execute;
#	return $sth->rows;	
#	}

#AUTHEN SCHEME FUNCTIONS BEGIN

sub check {
	return $_[0] && (cryptpwd($_[0]) eq $_[1]);
	}

sub cryptpwd {
	return md5_base64($_[0]);
	}
	
#AUTHEN SCHEME FUNCTIONS END


sub set {
	my $self=shift;
	my $dbh = SW::DB::getDbh();
	
	if($self->guestuser) # are we already known ? no
		{	
		my ($username, $password) = @_;
		
		$password = cryptpwd($password);
		
		my $userid;
		
		if(SW::User::userNameExists($username)) # the user already exist ? YES
			{
			#so we are trying to get at a lost password
			my $query = "UPDATE authentication set password='$password' where username='$username'";
			my $sth = $dbh->prepare($query);
			$sth->execute;
			
			#re-sync the authentication object right away, so we can proceed to something else right away.
			$self->init($username,$password);
			}
		else  # the user wasn't found, so let's create it then.
			{
			my $query = "INSERT INTO authentication values(NULL,'$username','$password','$username\@'.SW::Config::MAIL_DOMAIN)";
			my $sth = $dbh->prepare($query);
			$sth->execute;
			$userid = $sth->{'insertid'};
			}
			
		$self->{username} = $username;
		$self->{userid} = $userid;
		$self->{_unknown} = 0;
		$self->{_valid} = 1;
		
		SW->session->setPrivateValue("token", $self->{username} . ":" . $self->{userid});
		}
	else # we are a logged-in user that wants to change his/her password/username
		{
		my $password = shift;
		$password = cryptpwd($password);
		my $sth = $dbh->prepare("UPDATE authentication SET  password='$password' WHERE uid='". $self->{userid} . "'");
		$sth->execute;
		}
	
	
	
}
	
#change an existing user
		
sub DESTROY {
	#print STDERR "-----AUTHEN TOKEN DESTROYED\n";
	}


1;

__END__


=head1 NAME

SW::User::AUthen - SmartWorker User Authentication class

=head1 SYNOPSIS

  

=head1 DESCRIPTION


Embodies the basic information involved in a SmartWorker user.  This object retrieves
the login and password information from submission data and validates the user against
the database.  At present, this occurs on every transaction, but we will probably switch
to using some kind of ticketing scheme instead that avoids hitting the DB every call.

It returns a reference to the new SW::User object or "undef" if the user is not valid.

It also adds an encrypted parameter "swa" (SmartWorker Authorization) to the "appendages" hash
of the application, which is then appended to every form or link that is internal to the system.

In a SmartWorker application, the current user can be discovered by requesting it
from the application using the "getUser" object, which returns a reference to
an instance of the User class.  Information about this user can be accessed
using standard accessor methods such as "getHome" and "setHome".  The developer
never needs to save the user object explicitly if changes are made to the object
through legal means: the instance will be marked as "dirty" and written back to the
database after the transaction is finished.

!! SW 24/07/99  None of the home stuff is functional for now .... that's to implements
	desktops and folders type stuff.  I'll try to fdix that soon.

A note about the HOME property:
A user's HOME property will always refer to an object on the SAME master database
as the user herself. Therefore, the HOME property is simple a unique ID that resides
in the object table in the same DB, and it doesn't encode any information about
location or table.  This is to save space in the database (say, one hundred thousand
users times the number of characters it takes to specify the database + table is
way over a megabyte of essentially redundant data) and enforce a distribution
mechanism so that databases grow proportional to their number of users.

June 14/99 - Implemented the beginnings of some security in here with the getUserInfo
that only allows one access by master.  More needs to be done at the level of Apache::Session to 
protect the swa and prevent setting the value as well.

=head1 METHODS

	getGroups - returns a hash of the users groups as  { 'name'=>'gid', 'name2'=>'gid2' }

	inGroup - takes a group name as an argument and returna true or false as to whether 
					or not this user is in that group	

	getObjectList - returns an array of hashed represensting basic browse list
						type info about objects owned by the user.  Optionally taking
						a group parameter so the funtion internally calls getGroupObjectList

	getGroupObjectList - similar to above, but only searches for group owned objects

	deleteObject - deletes objects from the database.  Takes a list of one or more objectids to delete
						from the DB.  eg   qw(1 3 6 7)

	getUserName - returns text user name
	
	getUserId - returns the unique id belonging to that user

	create - create a new user based on the user info (you have to set the info in your app)
			will create entries in both authentication and users tables

	setValue - set the value for a user key

	getValue - get the value of a user key

        setPref($prefkey,$prefvalue) - sets the User preference '$prefkey' to value '$prefvalue'

        getPref($prefkey) - returns the value of User preference '$prefkey'


=head1 FUNCTIONS
	
	getOtherUserValues - pass a uid and a anon array of keys to retrieve. will return
		values of those keys
	
	userNameExists - pass a username, will return the uid if it exists, undef otherwise

=head1 AUTHOR

Kyle Dawkins, kyle@hbe.ca

=head1 REVISION HISTORY

  $Log: Authen.pm,v $
  Revision 1.16  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.15  1999/11/11 07:13:54  gozer
  MOre fixes to add changeusername functionnality

  Revision 1.14  1999/10/25 21:31:26  scott
  fixed to use mail domain setting

  Revision 1.13  1999/10/09 02:55:16  gozer
  Removed debugging messages

  Revision 1.12  1999/09/28 16:30:18  gozer
  Changed a bit more authentication to have password changing/checking thru swauthd

  Revision 1.11  1999/09/26 20:22:01  gozer
  oupss. forgot qw(md5_base64)

  Revision 1.10  1999/09/26 20:19:10  gozer
  back to base_64 encoding

  Revision 1.9  1999/09/26 19:30:01  gozer
  Modularized some more
  Added Challenge-Response thing

  Revision 1.8  1999/09/23 04:52:34  gozer
  Modified to include the new PasswordReminder

  Revision 1.7  1999/09/22 21:06:09  gozer
  Fixed the User save process

  Revision 1.6  1999/09/22 19:23:26  gozer
  Fixed a stupid logig bug that was allowing you only to modify one application per session :-/

  Revision 1.5  1999/09/21 03:41:47  gozer
  Now passwords are stored MD5 encrypted in the authentication table

  Revision 1.4  1999/09/20 19:51:19  gozer
  Temp fix for the lost DataValues

  Revision 1.1  1999/09/17 21:37:37  gozer
  Forgot to add those

  Revision 1.65  1999/09/14 01:25:33  gozer
  Little type correction, preparing for the moving of session and user out of master

  Revision 1.61  1999/09/13 18:28:06  scott
  *** empty log message ***

  Revision 1.60  1999/09/13 18:00:58  scott
  fixing the user creation code

  Revision 1.59  1999/09/13 15:00:57  scott
  lots of changes, sorry this is bad documentation :-(

  Revision 1.58  1999/09/12 21:32:24  krapht
  Fixed a typo where $self->{failed} must be assigned a value of 1

  Revision 1.57  1999/09/12 18:59:40  gozer
  EMERGENCY UPDATE BEFORE MY MACHINES CRASHES FOR REAL

  Moved user Authorization outside everything and inside it's own package SW::AppAccess
  The swValidateUser should be removed from the code now.
  Removed login info from smartworker.conf, not needed anymore
  added $SW::CONFIG::LOGIN_HANDLER = "SW::Login"
  added to the new SW::App::Admin::Applications so you can edit the access privlieges for your app in there

  Revision 1.56  1999/09/11 22:41:07  jzmrotchek
  Bug fix in reference to getPref() and setPref() code.

  Revision 1.55  1999/09/11 22:15:13  jzmrotchek
  Added some perldoc.

  Revision 1.54  1999/09/11 21:36:08  jzmrotchek
  Added setPref() and getPref() methods to set and get user specific preference values.  Note that these are user specific, and not app specific.

  Revision 1.53  1999/09/11 08:44:36  gozer
  Made a whole bunch of little kwirps.
  Fixed Handler to deal correctly with SW_App_Namespace without defaulting to SW::App when the var is set
  Fixed the bug that made Login.pm create an empty hidden argument on every login attempt
  Added a whole bunch of modules preloading in sw-perl-startup, good speed improvment
  Fixed a few warning here and there.  Only one missing the sweep.  Application.pm and AUTOLOAD warning ?!?
  Changed the SW::Util::flatten and circular_flatten to succesfully use Data::Dumper ;-} (-180 lines of code)
  Gone to bed very late

  Revision 1.52  1999/09/11 07:07:23  scott
  Made substantial changes to the database schema and data storage models.
  Now there's three global tables called datamap, dataaccess, and
  datainfo.  These hide the many other more data specific tables
  where the infomation is actually stored.

  Revision 1.51  1999/09/10 16:21:35  fhurtubi
  Added a getNameByField function

  Revision 1.50  1999/09/07 03:33:06  scott
  added some methods in app registry for getting data types

  Revision 1.49  1999/09/06 17:58:02  krapht
  Added a getHome function, that returns the objectid of a user's home folder

  Revision 1.48  1999/09/04 21:18:40  fhurtubi
  Added some documentation

  Revision 1.47  1999/09/04 21:10:11  fhurtubi
  Added new methods and functions to be used by the user registrator and administration center

  Revision 1.46  1999/09/01 01:26:46  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.45  1999/08/30 20:04:00  krapht
  Removed the Exporter stuff

  Revision 1.44  1999/08/20 01:58:21  scott
  minor bug tweaking ...

  Revision 1.43  1999/08/18 02:59:20  scott
  changed around getGroups so that the keys are the group names and the ids
  are the values ... seemed a little more useful that way tonight (probably won't
  again tommorow!)

  Revision 1.42  1999/08/17 23:12:23  scott
  fixed a logic mistake in getObjectList

  Revision 1.41  1999/08/17 16:02:47  krapht
  fixed a bug in getGroupObjectList with doctype specified

  Revision 1.40  1999/08/17 15:18:30  krapht
  Changed getObjectGroupList to returned [] if $objects is undefined!

  Revision 1.39  1999/08/17 15:11:50  scott
  Working on user permissions

  Revision 1.38  1999/08/16 22:14:14  scott
  fixed getObjectList so we don't get duplicates for group owned objects

  Revision 1.37  1999/08/16 21:15:52  scott
  oops added getUserName

  Revision 1.36  1999/08/16 21:14:21  scott
  fixed a confusing name - it's now getGroupObjectList

  Revision 1.35  1999/08/16 18:19:21  scott
  Changes to user to accomodate the groups and permissions some more

  Revision 1.34  1999/08/12 14:45:11  fhurtubi
  Little bug correction

  Revision 1.33  1999/08/11 22:37:57  krapht
  Changed some minor stuff

  Revision 1.32  1999/08/11 15:27:00  scott
  Small bug fixes on the code I wrote last night

  Revision 1.31  1999/08/10 13:51:54  scott
  Added the deleteObjects() method called with a list of object ids to
  delete - No permission checking yet!!

  Revision 1.30  1999/08/09 15:50:22  fhurtubi
  Added missing quotes in getObjectList

  Revision 1.29  1999/08/04 19:26:37  krapht
  Added a getName function in User.pm so we can use $self->{user}->getName
  instead of $self->{user}->{user} now

  Revision 1.28  1999/07/28 21:59:20  fhurtubi
  There a blank space missing before a and in a query, resulting in nice errors!

  Revision 1.27  1999/07/25 02:40:39  scott
  lots of changes, reworked and simplified the user object a bit, accomodated
  some database naming changes, and the addition of an authentication table
  which holds just passwords and basic autorization info.

  Revision 1.26  1999/07/19 13:29:19  scott
  Lots of clean-up work, debugged and improved the desctructor calling of all
  copmonents so none should be left lingering after the transaction completes.

  This in turn solved the session problem (destructor wasn't being called
  because it was persisting past the end of the transaction)

  Revision 1.25  1999/07/08 15:55:48  scott
  typo bug...

  Revision 1.24  1999/07/08 15:45:27  scott
  oops - should have done these separately ...

  Working on changes to the database code for users, groups, and objects

  as well as debugging and signals

  Revision 1.23  1999/06/18 15:27:18  scott
  Work on User is for some changes to the database layout ....

  Master and Registry are for the new debugging

  Revision 1.22  1999/05/05 15:26:23  scott
  fixed debug code

  Revision 1.21  1999/04/20 20:31:18  kiwi
  Uses session for swa now

  Revision 1.20  1999/04/20 05:04:09  kiwi
  Added the "isUnique" function to test for unique-ness of name

  Revision 1.19  1999/04/17 21:29:44  kiwi
  Altered "testPermission" to work with generic access hashes instead of
  with access hashes that belong to existing objects.

  Revision 1.18  1999/04/16 18:09:06  kiwi
  *** empty log message ***

  Revision 1.17  1999/04/14 20:27:33  kiwi
  Changing addObject, added addObjectTree

  Revision 1.16  1999/04/13 19:08:41  kiwi
  Added "guest" clause to allow for retrieval by anyone of objects
  created by guest.

  Revision 1.15  1999/04/13 19:03:51  scott
  fixed for empty group string

  Revision 1.14  1999/04/13 16:49:56  kiwi
  Fixed the "requires" function and added basic permission checking
  using "canRead" and "canWrite".

  Revision 1.13  1999/04/13 16:38:15  scott
  nothing - debug code

  Revision 1.12  1999/04/09 18:45:14  kiwi
  Added "requires" function that checks for certain resources.

  Revision 1.11  1999/03/30 23:17:54  kiwi
  Fixed the User object to correctly multiplex large databases, and improved
  the authentication procedure to reduce performance costs.

  Revision 1.10  1999/03/29 20:59:09  kiwi
  Allowed users to be authenticated across multiple databases.  This
  only occurs the first time the user logs in.  The database handle is then
  retained for future transactions.

  Revision 1.9  1999/03/27 21:50:55  kiwi
  Implemented accessor methods for most properties.
  Added save/load facility

  Revision 1.8  1999/03/19 22:42:23  kiwi
  Adding the "save" feature, and a set of methods to allow
  access to properties.

  Revision 1.7  1999/02/22 15:43:45  kiwi
  New functionality to retrieve user profiles when a user is validated.

  Revision 1.6  1999/02/17 17:08:51  kiwi
  Altered class to use hierarchical parent/child app relationships

  Revision 1.5  1999/02/12 22:32:36  kiwi
  *** empty log message ***


=head1 SEE ALSO

perl(1).

=cut
