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

package SW::User;

#------------------------------------------------------------
# SW::User
# Generic User Class for SmartWorker users
#------------------------------------------------------------
# $Id: User.pm,v 1.99 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA *userset $authen $authz $group $pref);

use SW::User::Admin;
use SW::User::Manager;
use SW::Util qw(inArray);

$authen =	$SW::Config::AUTHEN_MODULE || 'SW::User::Authen';
$authz = 	$SW::Config::AUTHZ_MODULE	|| 'SW::User::Authz';
$group = 	$SW::Config::GROUP_MODULE	|| 'SW::User::Group';
$pref =		$SW::Config::PREF_MODULE	|| 'SW::User::Pref';

foreach my $mod ($authen, $authz, $group, $pref)
{
	eval "use $mod";
	die "SW::User Couldn't locate $mod at startup $@\n" if $@;
}

use Apache;
use Apache::Constants qw(:common);
use DBI;
use SW::DB;
use SW::Constants;

@ISA = qw(SW::Component);

$VERSION = '0.01';

#------------------------------------------------------------
# new
# Creates a new user object.  The object is instantiated
# from the user database, or, if the user is not found, 
# it returns "guest" in the user name
#------------------------------------------------------------

sub new
{
	my ($className) = @_;

	my $self = {
			_dirty => 0,
	};

	bless $self, $className;	

	return $self;
}

sub DESTROY
{
	my $self = shift;
	$self->save();
	delete $self->{_authen} if $self->{_authen} ;
	delete $self->{_authz} if $self->{_authz};
	delete $self->{_group} if $self->{_group};
	delete $self->{_pref} if  $self->{_pref};
}


#------------------------------------------------------------
# authenticate - method
#
# A description would be nice!  Phil?
#------------------------------------------------------------

sub authenticate
{
	my $self = shift;
	$self->{_authen} ||= $authen->new(@_);
	return $self->{_authen};
}


#------------------------------------------------------------
# authorize - method
#
# Description, please!
#------------------------------------------------------------

sub authorize
{
	my $self = shift;
	$self->{_authz} ||= $authz->new(@_);
	return $self->{_authz};
}


#------------------------------------------------------------
# group - method
#
# This thing should really be called getGroup!
# group is not a very explicit name!
#------------------------------------------------------------

sub group
{
	my $self = shift;
	$self->{_group} ||= $group->new(@_);
	return $self->{_group};
}


#------------------------------------------------------------
# pref - method
#
# Same thing here
#------------------------------------------------------------

sub pref
{
	my $self = shift;
	$self->load();
	$self->{_pref} || $self->newPref($self->{profile},@_);
	return $self->{_pref};
}


#------------------------------------------------------------
# newPref - method
#
# And again...who writes all this stuff?
#------------------------------------------------------------

sub newPref
{
	my $self = shift;
	$self->{_pref} = $pref->new(@_);
}



sub load
{
	my $self = shift;
	return if $self->{_loaded};
	
	my $uid = $self->getUid;	
	my $username = $self->getName;
	
	print STDERR "load $uid, $username\n";

	my $row = getOtherUserValues($uid, [ "profile", "home", "quota", "du", "lastseen", "level", "email" , "locks"]);

		###############HAVE TO MOVE AS SUB-USER CLASS
		$self->{profile} = eval $row->{profile};
		###############
		$self->{home} = $row->{home};   
		$self->{quota} = $row->{quota};
		$self->{du} = $row->{du};
		$self->{lastseen} = SW::Util::parseTimeStamp($row->{lastseen});
		$self->{level} = $row->{level};
		$self->{email} = $row->{email};	
		$self->{locks} = eval $row->{locks};	
	
		$self->{_loaded} = 1;
		SW::debug($self,"Successfully loaded up user data",5);
		return;
}


#------------------------------------------------------------
# getOtherUserValues - function
#
# This will return certain values that belong to a user id
# IN:  a userId and values in an anonymous array.
# OUT:  values in anonymous hash.
#------------------------------------------------------------

sub getOtherUserValues
{
	my $userId = shift;
	my $values = shift;
	my $dbh = getDbh();
	my $userValues = {};

	my $query = "select ";
	$query .= join (",", @{$values});
	$query .= " from users where uid = $userId";	

	my $sth = $dbh->prepare($query) ||
			SW::debug("SW::User", "getUid prepare error ".$dbh->errstr,1);

	$sth->execute ||
			SW::debug("SW::User", "getUid execute error ".$dbh->errstr,1);

	my $row = $sth->fetchrow_hashref;

	foreach my $value (@{$values})
	{
		$userValues->{$value} = $row->{$value};
	}

	$sth->finish;
	return $userValues;
}


#------------------------------------------------------------
# getUid - method
#
# Takes $self->{user} and finds the corresponding uid
#
# Returns the uid
#------------------------------------------------------------

sub getUid
{
	my $self = shift;
	return $self->authenticate->userid;
}
*getUserId = \&getUid;


#------------------------------------------------------------
# getName
#
# Returns the user name
#------------------------------------------------------------

sub getName
{
	my $self = shift;
	return $self->authenticate->username;
}
*Name = \&getName;
*getUserName = \&getName;

#------------------------------------------------------------
# getHome - method
#
# Returns the objectid of the home folder of the user.
#------------------------------------------------------------

sub getHome
{
	my $self = shift;
	$self->load();
	return $self->{home};
}


#------------------------------------------------------------
# getQuota - method
#
# Returns the current quota set for the user (in bytes).
#------------------------------------------------------------

sub getQuota
{
	my $self = shift;
	$self->load();

	return ($self->{quota}*1024*1024);
}


#------------------------------------------------------------
# getDiskUsage - method
#
# Returns the current disk usage for the user (in Kbytes).
#------------------------------------------------------------

sub getDiskUsage
{
	my ($self) = @_;
	$self->load();
	return $self->{du};
}


#------------------------------------------------------------
# setDiskUsage - method
#
# Sets a new value for the disk usage.  Make sure to add the
# old value if you're adding some data.
#------------------------------------------------------------

sub setDiskUsage
{
	my ($self,$size) = @_;
	$self->{du} = $size;
	$self->makeModified();
}


#------------------------------------------------------------
# getLevel - method
#------------------------------------------------------------

sub getLevel
{
	my $self = shift;
	$self->load();
	return $self->{level};
}

#------------------------------------------------------------
# getNameByField - function
#------------------------------------------------------------
sub getNameByField
{
	my ($field,$value) = @_; 

	my $dbh = getDbh();

	my $query = "select a.username from authentication a, users b 
		where a.uid = b.uid
		and b.$field = ".$dbh->quote($value);
	
	my $sth = $dbh->prepare($query) ||
			SW::debug("SW::User", "getUid prepare error ".$dbh->errstr,1);

	$sth->execute ||
			SW::debug("SW::User", "getUid execute error ".$dbh->errstr,1);

	return $sth->fetchrow_array;
}


#------------------------------------------------------------
# getNameByEmail - function
#
# Wrapper function that uses getNameByField to retrieve the
# name of a user depending on an email address
#
# Returns the username (scalar)
#------------------------------------------------------------

sub getNameByEmail
{
	my $email = shift;
	return &getNameByField ("email", $email);
}


#------------------------------------------------------------
# getNameById - function
#
# Wrapper function that uses getNameByField to retrieve the
# name of a user depending on a user ID.
#
# Returns the username (scalar)
#------------------------------------------------------------

sub getNameById
{
	my $id = shift;
	return &getNameByField ("uid", $id);
}


#------------------------------------------------------------
# save - method
#
# updates both user info table and user authentication table
# based on current user info
# this is called by the destroyer. (and executed only if the
# object is dirty.
#------------------------------------------------------------


sub save
{
	my $self = shift;

	use Data::Dumper;

	return 0 if (!$self->{_dirty});
	return 1 if ($self->authenticate->guestuser);
	
	#print STDERR "SAVED USER IS DUMPED HERE THEN: " , Dumper %{SW->user};

	# Write data back to database

	if (! $self->{_loaded} )
	{
		print STDERR "ERROR - trying to save user before it's loaded!! will load now..\n";
		$self->load();
	}

	my $dbh = getDbh();

	my @profile;
	if ($self->{_pref}) {
		my $preferences = {
		    'global' => $self->{_pref}->{global},
		    'user'   => $self->{_pref}->{user},
		    'apps'   => $self->{_pref}->{apps},
		};
		@profile = ("profile", $dbh->quote(SW::Util::flatten($preferences)));
	}

	my $query = SW::Util::buildQuery("update", "users", 
							"uid", $self->authenticate->userid,
							"home", $dbh->quote($self->{home}),
							@profile,
							"quota", $dbh->quote($self->{quota}),
							"du",		$dbh->quote($self->{du}),
							"level", $dbh->quote($self->{level}),
							"email", $dbh->quote($self->{email}),
							"locks", $dbh->quote(SW::Util::flatten($self->{locks})),
							);


	my $sth = $dbh->prepare($query) ||
			SW::debug($self,"save: error preparing query $query",1);

	$sth->execute ||
			SW::debug($self,"save: error executing $query : ".$dbh->errstr,1);

	$self->makeUnmodified();

	return;
}


#------------------------------------------------------------
# userNameExists - function
#
# Checks to see if a username (passed as an argument) has
# already been taken.
#
# Returns the UID of the user, or undef if the name hasn't
# been taken.
#------------------------------------------------------------

sub userNameExists
{
	my $sth = getDbh->prepare("select uid from authentication where username ='$_[0]'");
	$sth->execute();
	return $sth->fetchrow_array;
}


#------------------------------------------------------------
# setValue - method
#
# Set a value for user key (ie: email, password, uid..)
#------------------------------------------------------------

sub setValue
{
	my ($self,$key,$value) = @_;

	$self->{$key} = $value;
	$self->makeModified();
}

#------------------------------------------------------------
# getValue - method
#
# Get the value of a user key
#------------------------------------------------------------
sub getValue
{
	if (! $_[0]->{_loaded}) { $_[0]->load(); }
	return $_[0]->{$_[1]};
}


#------------------------------------------------------------
# getGroups - method
#
#------------------------------------------------------------

sub getGroups
{
	my $self = shift;
	return $self->group->byid;
}


#------------------------------------------------------------
# getGroupsByName - method
#
#------------------------------------------------------------

sub getGroupsByName
{
	my $self = shift;
	return $self->group->byname;
}


#------------------------------------------------------------
#  locking functions
#------------------------------------------------------------

sub has_write_lock
{
	my $self = shift;
	my $id = shift;

	if (inArray($id, $self->{locks})) { return $id; } 
	else { return undef; }
}	


sub has_open
{
	my $self = shift;
	my $id = shift;

	return $self->has_write_lock($id);
}

sub add_write_lock
{
	my $self = shift;
	my $id = shift;

	if (inArray($id, $self->{locks})) { return $id; } 
	else { 
		push (@{$self->{locks}}, $id); 
		$self->makeModified();
		return $id; 
	}
}	

sub release_write_lock
{
	my $self = shift;
	my $id = shift;

	if (my $index = inArray($id, $self->{locks}))
	{
		splice (@{$self->{locks}}, $index, 1);
		$self->makeModified();
		return $id;
	} else
	{
		return undef;
	}
}	


#------------------------------------------------------------
#?
#------------------------------------------------------------
sub inGroup
{
	print STDERR 'inGroup deprecated, use $user->group->in_byid or $user->group->in_byname instead\n';
	my $self = shift;
	return $self->group->in_byid(shift);
}
#	my $grp = shift;
#
#	inArray($grp, [values %{$self->getGroups()}]);
#}


#------------------------------------------------------------
# getObjectList - method
#
# returns object IDs for objects owned by this user,
# optionally qualified with a data type argument
#
# optionally take a flag to include ALLGROUPS or qw ( group1 group2 ) groups
# in the search
#
# eventually we'll have to do lookup to the appregistry to check these
# object types
#------------------------------------------------------------

sub getObjectList
{
	my $self = shift;
	my $doctype = shift;
	my $includegroups = shift;

	my $returnedgroups = 0; 
 
	my $dbh = getDbh($self->{dbName});
	my $objects = [];

	# undef doctypes if we want all, just cause the query below
	#  to leave off the where doctype = ? clause
	$doctype = undef if $doctype eq 'ALL_TYPES';

	# we make the groups call first so that the user level privs take precedence over
	# the group level privs
 
	if ($includegroups)
	{   # $objects is passed in and modified by reference
		$objects = $self->getGroupObjectList($doctype, $includegroups);

	}


	my $OID = 0;
	my $ONAME = 1;
	my $TYPE = 2;
	my $PERM = 3;
	my $UID = 4;
	my $GID = 5;
 
	my $query = "select a.id,name,type,perm,userid,groupid from datamap a, dataaccess b, datainfo c";
	$query .= " where a.id = b.id and a.id = c.id and b.userid = " . $self->getUid;
 
	$query .= " and c.type = \"$doctype\" " if $doctype;
 
	my $sth = $dbh->prepare($query) or SW::debug($self,"Error preparing $query : ".$dbh->errstr,2);
	$sth->execute or SW::debug($self,"Error executing $query : ".$dbh->errstr,2);

	# maybe we should re-write this as a hash .. this is a pain in the ass!

	$returnedgroups = @$objects;
 
	while (my $row = $sth->fetch)
	{
		my $obj;
		$obj->{name} = $row->[$ONAME];
		$obj->{type} = $row->[$TYPE];
		$obj->{perm} = $row->[$PERM];
		$obj->{objectid} = $row->[$OID];
		$obj->{userid} = $row->[$UID];
		$obj->{groupid} = $row->[$GID];

		if (($includegroups) && $returnedgroups)
		{
			SW::debug($self,"Running this crazed subroutine ....",5);
			for (my $i=0; $i<@$objects; $i++)
			{
				if ($objects->[$i]->{objectid} == $obj->{objectid})
				{
					$objects->[$i] = $obj;
					last;
				}
			}
		} else {	
			SW::debug($self,"unshifted $obj->{name}",5);
			unshift @$objects, $obj;
		}
	}

	return $objects || []; # without || [], I had strange errors...
}

#------------------------------------------------------------
# getGroupObjectsList - method
#
# Returns object IDs for objects owned by this user's group,
# or by a specified group, optionally qualified with a data
# type argument
#
# optionally take a flag to include ALL or qw(group1 group2)
# groups in the search
#
# eventually we'll have to do lookup to the appregistry to
# check these object types
#------------------------------------------------------------

 sub getGroupObjectList
 {
 	my $self = shift;
 	my $doctype = shift;
 	my $includegroups = shift;
	my $objects = ();  

	# undef doctypes if we want all, just cause the query below
	#  to leave off the where doctype = ? clause
	$doctype = undef if $doctype eq 'ALL_TYPES';

	my @groups;

 	my $dbh = getDbh();

	if ($includegroups eq "ALL_GROUPS")
	{
		@groups = values %{$self->getGroups};
	}
	else   # add some more checking here  later
	{	
		@groups = @$includegroups;
	}

	return unless @groups > 0;

 	my $OID = 0;
 	my $ONAME = 1;
 	my $TYPE = 2;
 	my $PERM = 3;
	my $UID = 4;
	my $GID = 5;

	my $query_chunk = " and ( ";
	for (my $g=0; $g<@groups; $g++)
	{
		$query_chunk .= " b.groupid = ".$groups[$g];
		$query_chunk .= " or " unless ($g == $#groups);
	}
	$query_chunk .= " )";

	my $query = "select a.id,name,type,perm,userid,groupid from datamap a, dataaccess b, datainfo c ";
	$query .= "where a.id = b.id and a.id = c.id $query_chunk ";
 
	$query .= "and c.type = \'$doctype\' " if $doctype;

	SW::debug($self, "getGroupsObjects query $query",5);
 
	my $sth = $dbh->prepare($query) or SW::debug($self,"getGroupObjectListError preparing $query : ".$dbh->errstr,2);
 	
	$sth->execute or SW::debug($self,"getGroupObjectList: Error executing $query : ".$dbh->errstr,2);

 
	while (my $row = $sth->fetch)
	{
		my $obj;
		$obj->{name} = $row->[$ONAME];
		$obj->{type} = $row->[$TYPE];
		$obj->{perm} = $row->[$PERM];
		$obj->{objectid} = $row->[$OID];
		$obj->{userid} = $row->[$UID];
		$obj->{groupid} = $row->[$GID];
		unshift @$objects, $obj;
	}
 
 	return $objects || [];
	# Same thing as in getObjectList, if objects was undef, it
	# automatically undefined objects in getObjectList
	# which fucked the whole thing
}


#------------------------------------------------------------
# canRead - method
#
# tests permissions to read
#------------------------------------------------------------

sub canRead
{
	my $self = shift;
	my $object = shift;

	return $self->testPermission("r", $object->{access});
}

#------------------------------------------------------------
# canWrite - method
#------------------------------------------------------------

sub canWrite
{
	my $self = shift;
	my $object = shift;

	return $self->testPermission("w", $object->{access});
}


#------------------------------------------------------------
# setPref - method
#
# Sets the value associated with a key (first argument) to
# the value passed as the second argument.
#------------------------------------------------------------

sub setPref
{
	my ($self,$key,$value) = @_;

	$self->makeModified();  # Set user value saver on.

	return $self->pref->setUserPref($key,$value);
}


#------------------------------------------------------------
# getPref - method
#
# Gets the value associated with the key passed as argument.
#
# Returns the value.
#------------------------------------------------------------

sub getPref
{
	my ($self,$key) = @_;
	return $self->pref->getUserPref($key);
}


#------------------------------------------------------------
# getSystemPreferences
#------------------------------------------------------------

sub getSystemPreferences
{
	my $self = shift;

	if (ref $self->{profile} eq 'HASH')
	{
		if ($self->{profile}->{preferences})
		{
			if ($self->{profile}->{preferences}->{system})
			{
				return $self->{profile}->{preferences}->{system};
			}
			else
			{
				$self->{profile}->{preferences}->{system} = {};
			}
		}
		else
		{
			$self->{profile}->{preferences} = {};
			$self->{profile}->{preferences}->{system} = {};
		}
	}
	else
	{
		$self->{profile} = {};
		$self->{profile}->{preferences} = {};
		$self->{profile}->{preferences}->{system} = {};
	}

#	$self->{_dirty} = 1;
	return $self->{profile}->{preferences}->{system};
}


#------------------------------------------------------------
# preference - method
#
# Returns a user's system preference
#------------------------------------------------------------

sub preference
{
	my $self = shift;
	my $p = shift;

	my $prefs = $self->getSystemPreferences();

	return $prefs->{$p};
}


sub setDirty
{
	my $self = shift;
	$self->{_dirty} = shift;
}

#------------------------------------------------------------
# knownMembers - function
#
# Returns a hash of known members for a user.
# Known members means members of groups the user is a member
# of.
#------------------------------------------------------------

sub knownMembers
{       
	my $dbh = SW::DB->getDbh();

	my $self = SW->user;

	my $groupList;
        
	my $query = "select groupid from groupmembership where userid = ".SW->user->getUserId;

	my $sth = $dbh->prepare($query) ||
			SW::debug($self,"knownMembers: error preparing query $query",1);

	$sth->execute ||
			SW::debug($self,"knownMembers: error executing query $query",1);

	while (my $row = $sth->fetch)
	{       
		$groupList .= "$row->[0], ";
	}

	$groupList =~ s/, $//;

	my $users = {};

	$query = "select distinct username, a.uid from authentication a, groupmembership b
		where a.uid = b.userid
		and b.status = 1
		and b.groupid in ($groupList)";
	$sth = $dbh->prepare($query) ||
			SW::debug($self,"knownMembers: error preparing query $query",1);

	$sth->execute ||
			SW::debug($self,"knownMembers: error executing query $query",1);

	while (my $row = $sth->fetch)
	{
		# We don't want to put the user in there!
		if ($row->[1] == SW->user->getUserId()) { next; }

		$users->{$row->[1]} = $row->[0];
	}
         
	return $users;
}


#------------------------------------------------------------
# makeModified - method
#
# Sets a dirty value on the calling object, meaning that it
# contains some information not in sync with the database.
#------------------------------------------------------------

sub makeModified
{
	$_[0]->{_dirty} = 1;
}


#------------------------------------------------------------
# makeUnmodified - method
#
# Clears a dirty value on the calling object.  This should
# be done only when we are sure that the contents of the
# object are in sync with the database.
#------------------------------------------------------------

sub makeUnmodified
{
	$_[0]->{_dirty} = 0;
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

        setPref($prefkey,$prefvalue) - sets the User preference '$prefkey' to value '$prefvalue'

        getPref($prefkey) - returns the value of User preference '$prefkey'


=head1 FUNCTIONS
	
	getOtherUserValues - pass a uid and a anon array of keys to retrieve. will return
		values of those keys
	
	userNameExists - pass a username, will return the uid if it exists, undef otherwise

=head1 AUTHOR

Kyle Dawkins, kyle@hbe.ca

=head1 REVISION HISTORY

  $Log: User.pm,v $
  Revision 1.99  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.98  1999/11/11 07:13:24  gozer
  Cookie sends the cookie only if necessary
  Handler returns a 404 when handling the get of a file that isn't on the file server
  User - added the change of username call SW->user->authen->setName("NewName");

  Revision 1.97  1999/10/26 21:00:16  krapht
  Added setDiskUsage

  Revision 1.96  1999/10/18 05:41:21  scott
  adding file locking code

  Revision 1.95  1999/10/15 21:49:56  krapht
  Added makeModified, etc. and cleaned some headers

  Revision 1.94  1999/10/12 18:58:16  fhurtubi
  Added getGroupsByName method

  Revision 1.93  1999/10/06 21:47:23  gozer
  Moved SW::GzipFilter ands SW::SSLfilter to SW::FIlter::SSL and SW::FIlter::Gzip

  Revision 1.92  1999/10/04 20:53:18  gozer
  New way to tell it what modules to use for authen/authz/group/pref

  Revision 1.91  1999/09/30 20:59:12  fhurtubi
  Fixed a bug that was eating the profile field (basically, if user is dirty and preferences
  aren't loaded, that field was undef.

  Revision 1.90  1999/09/30 11:38:52  gozer
  Added the support for cookies

  Revision 1.89  1999/09/28 16:30:13  gozer
  Changed a bit more authentication to have password changing/checking thru swauthd
  Modified SW/Login.pm so it's possible to use it with Challenge-Response or not

  Revision 1.88  1999/09/27 15:16:56  fhurtubi
  Added a new function

  Revision 1.87  1999/09/26 19:29:48  gozer
  Modularized some more

  Revision 1.86  1999/09/23 04:52:32  gozer
  Modified to include the new PasswordReminder

  Revision 1.85  1999/09/22 21:06:07  gozer
  Fixed the User save process

  Revision 1.82  1999/09/22 07:46:38  fhurtubi
  line 235, i had a missing return, just added it.
  also, replaced $self->{user} with SW->user

  Revision 1.81  1999/09/22 01:44:03  scott
  added a setNewUser method so we can create users

  Revision 1.80  1999/09/20 21:16:49  gozer
  Modified {preferences} to {_pref} everywhere

  Revision 1.79  1999/09/20 19:51:18  gozer
  Temp fix for the lost DataValues

  Revision 1.76  1999/09/20 14:30:00  krapht
  Changes in most of the files to use the new way of referring to session,
  user, etc. (SW->user, SW->session).

  Revision 1.75  1999/09/19 20:34:42  gozer
  Documented SW.pm and I changed a few more $self->{master} stuff to SW->master

  Revision 1.74  1999/09/18 16:27:18  gozer
  Fixed the failing sql error, forgot to do a my $sth = , and it was then overwriting the previous $sth :-(

  Revision 1.73  1999/09/17 23:00:11  gozer
  Scott's work on gozer's machine committed by gozer. :-)

  Revision 1.71  1999/09/17 18:03:00  jzmrotchek
  Played arounf with the preferences some.   Now seems to save/load them properly.  There may be problems with accessor methods, though; let me know if you have any, and I'll get them fixed.

  Revision 1.70  1999/09/16 21:40:47  jzmrotchek
  Changed Preferences to be loaded/manipulated using the SW::Preferences module.  Heard this caused problems previously; if it does again, let me know and I'll see what I can do to fix them.

  Revision 1.69  1999/09/15 20:35:39  scott
  fixed trhe deleteObject mehtod

  Revision 1.68  1999/09/15 01:51:38  scott
  debuging a problem iwith load order, memoryizing tables at load time

  Revision 1.67  1999/09/15 01:43:22  fhurtubi
  Added right APPID to user creation new folder

  Revision 1.66  1999/09/14 02:17:48  fhurtubi
  Too many versions going around, this should be stable

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
