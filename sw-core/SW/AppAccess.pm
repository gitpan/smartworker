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

package SW::AppAccess;

#------------------------------------------------------------
# SW::User
# Generic User Class for SmartWorker users
#------------------------------------------------------------
# $Id: AppAccess.pm,v 1.3 1999/11/15 18:17:32 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION);

use SW;
use SW::Util;
use SW::Application;
use SW::User::Admin;
use SW::User::Manager;
use Data::Dumper;
use Apache;
use SW::DB;



$VERSION = '0.01';

#------------------------------------------------------------
# new
# Creates a new user object.  The object is instantiated
# from the user database, or, if the user is not found, 
# it returns "guest" in the user name
#------------------------------------------------------------

sub new
{
	my $className = shift;
	my $master = shift;
   
   my $user  = $master->{user};

	my $dbh = SW::DB->getDbh(); 	
   
   my $query = qq/SELECT action, target, groupid, uid 
                  FROM appaccess ac , apps ap 
                  WHERE ap.aid=ac.aid and ap.package=?
                  ORDER BY action, target
                  /;
   my $sth = $dbh->prepare($query);
   
   my $self = { "master" => $master,
                "user" => $user,
					 "dbh" => $dbh,
                "sth" => $sth,
             };
   
	bless $self, $className;
	
	return $self;
}


sub Rejected {
   my $self = shift;
   return $self->{rejected};
   }

sub isGranted {
   my $self = shift;
   my $package = shift;
   
   my $valid_for = $self->{master}->getSessionValue("_sessionAuthzFor");
   
   #we already checked for this package/user combination
   
   return 1 if($valid_for eq $package);
   
   $self->{sth}->execute($package) || print STDERR "SQL Error :", $self->{sth}->errstr;
 
 
   while(my $res = $self->{sth}->fetchrow_hashref)
      {
      if($res->{action} eq "DENY")
         {
         if ($res->{target} eq "ANY") 
            {
            $self->{rejected}=1;
            return undef;
            }
         elsif ($res->{target} eq "GROUP")
            {
            if(SW->user->inGroup($res->{groupid}))
               {
               $self->{rejected}=1;
               return undef;
               }
            }
         elsif ($res->{target} eq "USER" )
            {
            if(SW->user->getUserId == $res->{uid})
               {
               $self->{rejected}=1;
               return undef;
               }
            }
         elsif ($res->{target} eq "GUEST") 
            { 
            $self->{rejected}=1;
            return undef;
            }
         else 
            {
            print STDERR "What is this shit ? --> $res->{action} $res->{target} ?\n";
            return undef;
            }
         }
      elsif($res->{action} eq "ALLOW")
         {
         if($res->{target} eq "GUEST")
            {
            $self->{master}->setSessionValue("_sessionAuthzFor", $package);
            return 1;
            }
         elsif($res->{target} eq "ANY")
            {
               if( SW->user->getUserName ne "guest")
                  {
                  $self->{master}->setSessionValue("_sessionAuthzFor", $package);
                  return 1;
                  }
            }
         elsif($res->{target} eq "GROUP")
            {
               if(SW->user->inGroup($res->{groupid}))
                  {
                  $self->{master}->setSessionValue("_sessionAuthzFor", $package);
                  return 1;
                  }
            }
          elsif ($res->{target} eq "USER" )
            {
            if(SW->user->getUserId == $res->{uid})
               {
               $self->{master}->setSessionValue("_sessionAuthzFor", $package);
               return 1;
               }
            }
         else 
            {
            print STDERR "What is this shit ? --> $res->{action} $res->{target} ?\n";
            return undef;
            }
        
         }
      }


#Here we passed thru all the rules and nothing was done.  So allow guest to try logging in and drop already logged-in users

$self->{rejected}=1 unless SW->user->getUserName eq "guest";

return undef;

}



1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::User - SmartWorker User Base Class

=head1 SYNOPSIS

  use SW::User;

  $app->{user} = new SW::User($app);

  if (!$app->{user})
  {
     # error
  }

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

=head1 FUNCTIONS
	
	getOtherUserValues - pass a uid and a anon array of keys to retrieve. will return
		values of those keys
	
	userNameExists - pass a username, will return the uid if it exists, undef otherwise

=head1 AUTHOR

Kyle Dawkins, kyle@hbe.ca

=head1 REVISION HISTORY

  $Log: AppAccess.pm,v $
  Revision 1.3  1999/11/15 18:17:32  gozer
  Added Liscence on pm files

  Revision 1.2  1999/09/20 19:58:32  fhurtubi
  Changed references of $self->{user} to SW->user

  Revision 1.1  1999/09/12 18:59:40  gozer
  EMERGENCY UPDATE BEFORE MY MACHINES CRASHES FOR REAL

  Moved user Authorization outside everything and inside it's own package SW::AppAccess
  The swValidateUser should be removed from the code now.
  Removed login info from smartworker.conf, not needed anymore
  added $SW::CONFIG::LOGIN_HANDLER = "SW::Login"
  added to the new SW::App::Admin::Applications so you can edit the access privlieges for your app in there

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
