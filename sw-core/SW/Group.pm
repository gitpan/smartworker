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

package SW::Group;

#------------------------------------------------------------
# SW::Group
# Generic Group Class for SmartWorker group
#------------------------------------------------------------
# $Id: Group.pm,v 1.17 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW;
use SW::Data;
use SW::DB;
use DBI;

$VERSION = '0.01';

sub DESTROY {
	my $self = shift;
	$self->save();
	print STDERR "-----GROUP DESTROYED\n";
}

#------------------------------------------------------------
# new (CONSTRUCTOR)
# Creates the group object
#
# call: $group = new;
#
# in:   - NULL
#
# out:  - The group object
#------------------------------------------------------------
sub new
{
	my $className = shift;
	my $self = { "_dirty" => 0 };
	
	bless $self, $className;

	if (@_ == 1) { 
		$self = $self->populate(@_); 
	} else {
		$self = $self->create(@_);
	}

	return $self;
}

# load is simply a typeglob to new for those of you who prefer to load an existing object instead of creating one
*load = \&new;

#------------------------------------------------------------
# create (METHOD, INTERNAL)
# Create a group in the database and returns the information
#
# call: $group = $self->create ($groupName, $homeFolder, $dontJoin);
#
# in:   - Blessed object
#	- Group name
#	- Home folder (if applicable)
#	- Whether you want to join the group or not (defaut is yes)
#
# out:  - A populated group object
#------------------------------------------------------------
sub create
{
        print STDERR "+++++CREATING NEW GROUP\n";
	my ($self, $groupName, $homeFolder, $joinGroup) = @_;
	$homeFolder ||= 0;
	$joinGroup ||= 1;

	my $dbh = SW::DB->getDbh();

	my $time = &getTime;

	my $query  = "insert into groups (groupname, ownerid, created, home) values (";
	$query .= $dbh->quote($groupName).",". SW->user->getUserId().", '$time', $homeFolder)";        
	my $sth = $dbh->prepare($query) || print STDERR "Error preparing new group query: $query\n";
	$sth->execute || print STDERR "Error executing new group query: $query\n";
        
	$self->{name} = $groupName;
	$self->{GID} = $sth->{'mysql_insertid'};
	$self->{folder} = $homeFolder;
	$self->{owner} = SW->user->getUserId();
	$self->{created} = $time;

	$self = $self->joinGroup(SW->user->getUserId(), 4, 1) unless (!$joinGroup);

        return $self;
}

#------------------------------------------------------------
# populate (METHOD, INTERNAL)
# Populates a group from all information stored in the database
#
# call: $group = $self->populate ($groupId);
#
# in:   - Blessed object
#	- Group ID
#
# out:  - A populated group object
#------------------------------------------------------------
sub populate
{
	my ($self, $GID) = @_;

	my $dbh = SW::DB->getDbh();

	my $query = "select groupname, ownerid, home, created from groups where groupid = $GID";
	my $sth = $dbh->prepare($query) || print STDERR "Error preparing load group query: $query\n";
	$sth->execute || print STDERR "Error executing update load group query: $query\n";
	my $row = $sth->fetch;
	$self->{name} = $row->[0];
	$self->{owner} = $row->[1];
	$self->{folder} = $row->[2];
	$self->{created} = $row->[3];
	$self->{GID} = $GID;	  	

	my $UID = 0;
	my $NAME = 1;
	my $PERM = 2;
	my $STATUS = 3;
	my $JOINED = 4;

	$query = "select userid, username, perm, status, joined from groupmembership a, authentication b where 
		a.groupid = $GID and a.userid = b.uid";
	$sth = $dbh->prepare($query) || print STDERR "Error preparing load group query: $query\n";
	$sth->execute || print STDERR "Error executing update load group query: $query\n";
	while (my $row = $sth->fetch)
	{
		$self->{members}->{$row->[$UID]}->{name} = $row->[$NAME];
		$self->{members}->{$row->[$UID]}->{perm} = $row->[$PERM];
		$self->{members}->{$row->[$UID]}->{status} = $row->[$STATUS];
		$self->{members}->{$row->[$UID]}->{joined} = $row->[$JOINED];
	}	

	return $self;
}

#------------------------------------------------------------
# save (METHOD, INTERNAL)
# Saves a group in the database (basically, just update the group name)
# This is called by the DESTRUCTOR, but you can call it yourself if you feel like it
# although there is no point
#
# call: $self->save();
#
# in:   - Group Object
#
# out:  - NULL
#------------------------------------------------------------
sub save
{
	my $self = shift;	
	return 0 if (!$self->{_dirty});	

	my $dbh = SW::DB->getDbh();

	my $query  = "update groups set groupname = ".$dbh->quote($self->{groupname})." where groupid = ".$self->{GID};
	my $sth = $dbh->do($query) || print STDERR "Error executing update group query: $query\n";
}

#------------------------------------------------------------
# setName (METHOD)
# Sets the name of a group. I guess this is an alternative to the save method
#
# call: $group->setName ($groupName)
#
# in:   - Group object
#	- New group name
#
# out:  - Group object with new name
#------------------------------------------------------------
sub setName
{
	my $self = shift;
	$self->{name} = shift;
	$self->{_dirty} = 1;
	return $self;
}

#------------------------------------------------------------
# deleteGroup (FUNCTION)
# Deletes a group and all it's members
#
# call: deleteGroup ($groupId);
#
# in:   - Group Id
#
# out:  - Null
#------------------------------------------------------------
sub deleteGroup
{
	my $GID = shift;
	my $dbh = SW::DB->getDbh();

	my $query = "delete from groups where groupid = $GID";
	my $sth = $dbh->do($query) || print STDERR "Error executing delete group query: $query\n";

	$query = "delete from groupmembership where groupid = $GID";
	$sth = $dbh->do($query) || print STDERR "Error executing delete group 2nd query: $query\n";

	return;
}

#------------------------------------------------------------
# joinGroup (METHOD)
# Join a group with certain permissions and status
#
# call: $group = $group->joinGroup($userId, $permissions, $status, $inviter);
#
# in:   - Group object
#	- User id to add to the group
#	- Permissions (0 = guest, 1 = member, 2 = admin)
#	- Status (0 = pending, 1 = joined)
#	- Inviter (the ID of the member who invited the user)
#
# out:  - The group object with the user in the members list
#------------------------------------------------------------------#
sub joinGroup
{
	my ($self, $userId, $perm, $status, $inviter) = @_;

	if (! defined($perm)) { $perm = 1; } # cuz 0 is valid, so i cant go ||= 1
	if (! defined($status)) { $status = 1; } # same here
	$inviter ||= 0;

	my $dbh = SW::DB::getDbh();

	my $time = &getTime;	
	my $query = "insert into groupmembership (groupid, userid, perm, status, joined, inviter) 
		values (".$self->{GID}.", $userId, $perm, $status, '$time', $inviter)";
	my $sth = $dbh->do($query) || print STDERR "Error executing join group query: $query\n";

	$self->{members}->{$userId}->{name} = SW::User::getNameById($userId);
	$self->{members}->{$userId}->{perm} = $perm;
	$self->{members}->{$userId}->{status} = $status;
	$self->{members}->{$userId}->{joined} = $time;

	return $self;
}

#------------------------------------------------------------
# changePermission (METHOD)
# Change the permission a user has over a group (guest, member, admin)
#
# call: $group = $group->changePermission ($userId, $newPermission);
#
# in:   - Group object
#	- User id to change permission
#	- New permission (0 = guest, 1 = member, 2 = admin)
#
# out:  - The group object with updated permissions for this user
#------------------------------------------------------------------#
sub changePermission
{
	my ($self, $userId, $perm) = @_;

	my $dbh = SW::DB->getDbh();

	my $query = "update groupmembership set perm = $perm where groupid = ".$self->{GID}."
		and userid = $userId";
	my $sth = $dbh->do($query) || print STDERR "Error executing changePermission group query: $query\n";

	$self->{members}->{$userId}->{perm} = $perm;

	return $self;
}

#------------------------------------------------------------
# leaveGroup (METHOD)
# ** This might need some rewriting as it is not really what you can call a well written method
#
# Removes a user from a group, this method can be called from a group object or from another 
# blessed object
#
# call: $group = $group->leaveGroup ($userId);
# call: leaveGroup ($blessedObject, $userId, $groupId);
#
# in:   - Group object (or blessed object that has nothing to do, sorry, this is all the best I could
#			come up with)
#	- User id to remove
#	- Group id (depending on how the method is called)
#
# out:  - Updated group object in both cases even if in the 2nd way it is not used
#------------------------------------------------------------

sub leaveGroup
{
	my $self = shift;
	my $userId = shift;
	my $GID = $self->{GID} || shift;

	my $dbh = SW::DB->getDbh();
	my $query = "delete from groupmembership where groupid = $GID and userid = $userId";
	my $sth = $dbh->do($query) || print STDERR "Error executing leaveGroup group query: $query\n";

	delete $self->{members}->{$userId};	

	return $self;
}

#------------------------------------------------------------
# getUserInfo (FUNCTION)
# Returns the status and permission for a certain member of a group
#
# call: $userInfo = getUserInfo ($groupId, $userId);
#
# in:   - Group Id
#	- User Id
#
# out:  - A hash ref of the group related user info
#------------------------------------------------------------------#
sub getUserInfo
{
	my $GID = shift;
	my $userId = shift;

	my $dbh = SW::DB->getDbh();
	my $query = "select status, perm from groupmembership where groupid = $GID and userid = $userId";
	my $sth = $dbh->prepare($query) || print STDERR "Error preparing getInviter group query: $query\n";
	$sth->execute || print STDERR "Error executing update getInviter group query: $query\n";

	return $sth->fetchrow_hashref;
}

#------------------------------------------------------------
# inviteToGroup (METHOD)
# Invite a user to join a group, the user gets a status of 0 (pending)
#
# call: $group = $group->inviteToGroup ($userId, $permission);
# 
# in:   - User Id to invite
#       - permission the user should have
#
# out:  - Updated group object containing the new user
#------------------------------------------------------------------#
sub inviteToGroup
{   
	my ($self, $userId, $perm) = @_;

	$self = $self->joinGroup ($userId, $perm, 0, SW->user->getUserId());

	return $self;
} 

#------------------------------------------------------------
# joinInvitedGroup (METHOD)
# ** This might need some rewriting as it is not really what you can call a well written method
#
#
# Make the user join the group he was invited to (change status from 0 to 1)
#
# call: $group = $group->joinInvitedGroup ();
# call: joinInvitedGroup ($blessedObject, $groupId);
#
# in:   - Group object (or blessed object that has nothing to do here)
#       - Group id (only if called in the 2nd form)
#
# out:  - Updated group object (even if it's not usefull in the 2nd form)
#------------------------------------------------------------------#
sub joinInvitedGroup
{
	my $self = shift;
	my $GID = $self->{GID} || shift;

	my $dbh = SW::DB->getDbh();
	my $query = "update groupmembership set status = 1 where groupid = $GID
		and userid = ".SW->user->getUserId();
	my $sth = $dbh->do($query) || print STDERR "Error executing joinInvitedGroup group query: $query\n";

	$self->{members}->{SW->user->getUserId()}->{status} = 1;
	return $self;
}

#------------------------------------------------------------
# getInviter (FUNCTION)
# Returns username and email of the user that invited the current user to join a group
#
# call: $inviter = getInviter($groupId);
# 
# in:   - Group Id
#
# out:  - A hash ref of the inviter info (username and email)
#------------------------------------------------------------------#
sub getInviter
{
	my $GID = shift;

	my $dbh = SW::DB->getDbh();
	my $query = "select b.username, a.email from users a, authentication b, groupmembership c
		where c.userid = ".SW->user->getUserId." and c.groupid = $GID
		and a.uid = c.inviter and b.uid = c.inviter";
	my $sth = $dbh->prepare($query) || print STDERR "Error preparing getInviter group query: $query\n";
	$sth->execute || print STDERR "Error executing update getInviter group query: $query\n";
	my $row = $sth->fetch();
	
	my $infos = {};
	$infos->{name} = $row->[0];
	$infos->{email} = $row->[1];

	return $infos;
}

#------------------------------------------------------------
# renameGroup (FUNCTION)
# Renames a group
#
# call: renameGroup ($groupId, $groupName);
# 
# in:   - Group Id
#       - New Group Name
#
# out:  - NULL
#------------------------------------------------------------------#
sub renameGroup
{
	my ($GID, $name) = @_;

	my $dbh = SW::DB->getDbh();
	my $query = "update groups set groupname=".$dbh->quote($name)." where groupid = $GID";
	my $sth = $dbh->do($query) || print STDERR "Error preparing renameGroup query: $query\n";
	
	return 1;
}

#------------------------------------------------------------
# getGroupIdFromHomeId (FUNCTION)
# Returns value of the group id associated with a home id
#
# call: $groupId =  getGroupIdFromHomeId ($homeId);
#
# in:   - Home id
#
# out:  - Group Id
#------------------------------------------------------------------#
sub getGroupIdFromHomeId
{
	my $homeId = shift;

	my $dbh = SW::DB->getDbh();
	my $query = "select groupid from groups where home=$homeId";
	my $sth = $dbh->prepare($query) || print STDERR "Error preparing getGroupIdFromHomeId query: $query\n";
	$sth->execute || print STDERR "Error executing update getGroupIdFromHomeId query: $query\n";

	return $sth->fetchrow_array;
}

#------------------------------------------------------------
# checkForInvitation (FUNCTION)
# Checks whether a user has been invited to a group (check for status = 0)
#
# call: $beenInvited =  checkForInvitation();
#
# in:   - NULL
#       
# out:  - Number of groups the user has been invited to (only those with status = 0)
#-----------------------------------------------------------
sub checkForInvitation
{
	my $dbh = SW::DB->getDbh();
	my $query = "select count(1) from groupmembership where status=0 and userid=".SW->user->getUserId();
	my $sth = $dbh->prepare($query) || print STDERR "Error preparing checkForInvitation query: $query\n";
	$sth->execute || print STDERR "Error executing update checkForInvitation query: $query\n";

	return $sth->fetchrow_array;
}

#------------------------------------------------------------
# getInvitedGroups (FUNCTION)
# Returns an array ref of hash ref of all groups the user has been invited to
#
# call: $groups = getInvitedGroups();
#
# in:   - NULL
#       
# out:  - Array ref of invited groups (each array element contains a hash ref
#		of groupid, name and permission)
#------------------------------------------------------------------#
sub getInvitedGroups
{
	my $dbh = SW::DB->getDbh();

	my $groups = [];

	my $query = "select a.groupid, b.groupname, a.perm from groupmembership a, groups b
		where userid=".SW->user->getUserId()." and status = 0 and a.groupid = b.groupid";
	my $sth = $dbh->prepare($query) || print STDERR "Error preparing getInvitedGroups query: $query\n";
	$sth->execute || print STDERR "Error executing update getInvitedGroups query: $query\n";
	while (my $row = $sth->fetch)
	{
		my $group = {};	
		$group->{groupid} = $row->[0];
		$group->{name}	= $row->[1];
		$group->{perm} = $row->[2];
		push (@{$groups}, $group);
	}

	return $groups;
}

#------------------------------------------------------------
# getGroupNameFromHomeId (FUNCTION)
# Returns value of group name associated with a home id
#
# call: $groupName =  getGroupNameFromHomeId ($homeId);
#
# in:   - Home id
#       
# out:  - Group Name
#-----------------------------------------------------------
sub getGroupNameFromHomeId
{
	my $homeId = shift;

	my $dbh = SW::DB->getDbh();
	my $query = "select groupname from groups where home=$homeId";
	my $sth = $dbh->prepare($query) || print STDERR "Error preparing getGroupNameFromHomeId query: $query\n";
	$sth->execute || print STDERR "Error executing update getGroupNameFromHomeId query: $query\n";

	return $sth->fetchrow_array;
}

#------------------------------------------------------------
# getHomeIdFromGroupId (FUNCTION)
# Returns value of home id associated with a group id
#       
# call: $homeId =  getHomeIdFromGroupId ($groupId);
#       
# in:   - Group Id
#
# out:  - Home Id
#------------------------------------------------------------------#
sub getHomeIdFromGroupId
{
	my $GID = shift;
	my $dbh = getDbh();

	my $query = "select home from groups where groupid = $GID";
	my $sth = $dbh->prepare($query) or
		SW::debug("SW::Group","delete, Error preparing query - $query\n\t".$dbh->errstr,3);
         
	$sth->execute or SW::debug("SW::Group","delete, Error executing query - $query\n\t".$dbh->errstr,3);
	return $sth->fetchrow_array;
}

#------------------------------------------------------------
# getTime (FUNCTION, INTERNAL)
# Returns a timestamp lookalike 
#
# call: $time = getTime();
#
# in:   - NULL
#
# out:  - Timestamp
#-----------------------------------------------------------
sub getTime
{
	my @date = localtime(time);
	my $year = $date[5] + 1900; 
	$date[4]++;
	my $mon = sprintf("%02d", $date[4]);
	my $mday = sprintf("%02d", $date[3]);
	my $hour = sprintf("%02d", $date[2]);
	my $min = sprintf("%02d", $date[1]); 
	my $sec = sprintf("%02d", $date[0]); 

	my $time = "$year$mon$mday$hour$min$sec";
	
	return $time;
}


1;
__END__

=head1 NAME

	SW::Group - SmartWorker Group Base Class


=head1 SYNOPSIS

	use SW::Group;
	$group = new SW::Group ("groupName", $homeId, 1);
		This will create group groupName with home id set as $homeId and you will be a member of the group
	$group = load SW::Group (10);
		This will load the group with id 10

=head1 DESCRIPTION

	All sorts of functions that allow a user to join/leave/create/edit/delete
	groups. 


=head1 FUNCTIONS

	deleteGroup	- deleteGroup ($groupId);
			- Deletes a group and all it's members

	getUserInfo	- $userInfo = getUserInfo ($groupId, $userId);
			- Returns the status and permission for a certain member of a group
	
	getInviter	- $inviter = getInviter($groupId);
			- Returns username and email of the user that invited the current user to join a group

	renameGroup	- renameGroup ($groupId, $groupName);
			- Renames a group

	getGroupIdFromHomeId	- $groupId =  getGroupIdFromHomeId ($homeId);
				- Returns value of the group id associated with a home id
	
	checkForInvitation	- $beenInvited =  checkForInvitation();
				- Checks whether a user has been invited to a group (check for status = 0)

	getInvitedGroups	- $groups = getInvitedGroups();
				- Returns an array ref of hash ref of all groups the user has been invited to

	getGroupNameFromHomeId	- $groupName =  getGroupNameFromHomeId ($homeId);
				- Returns value of group name associated with a home id

	getHomeIdFromGroupId	- $homeId =  getHomeIdFromGroupId ($groupId);
				- Returns value of home id associated with a group id 

	getTime		- $time = getTime();
			- Returns a timestamp lookalike


=head1 METHODS

	create		- $group = $self->create ($groupName, $homeFolder, $dontJoin);
			- Create a group in the database and returns the information
	
	populate	- $group = $self->populate ($groupId);
			- Populates a group from all information stored in the database

	save		- $group->save();
			- Saves a group in the database (basically, just update the group name)

	setName		- $group->setName ($groupName);
			- Sets the name of a group. I guess this is an alternative to the save method

	joinGroup	- $group = $group->joinGroup($userId, $permissions, $status, $inviter);
			- Join a group with certain permissions and status

	changePermission 	- $group = $group->changePermission ($userId, $newPermission);
				- Change the permission a user has over a group (guest, member, admin)
	
	leaveGroup	- $group = $group->leaveGroup ($userId);
			  or
			  leaveGroup ($blessedObject, $userId, $groupId);
			- Removes a user from a group

	inviteToGroup	- $group = $group->inviteToGroup ($userId, $permission);
			- Invite a user to join a group, the user gets a status of 0 (pending)

	joinInvitedGroup	- $group = $group->joinInvitedGroup ();
				  or
				  joinInvitedGroup ($blessedObject, $groupId);
				- Make the user join the group he was invited to (change status from 0 to 1)

	
=head1 AUTHOR

	Fred Hurtubise, 
	fred@hbe.ca
	1999


=head1 REVISION HISTORY

	$Log: Group.pm,v $
	Revision 1.17  1999/11/15 18:17:33  gozer
	Added Liscence on pm files
	
	Revision 1.16  1999/11/11 20:39:37  fhurtubi
	Documented and made a lot of cleanup. No mention of workspace now, but folder and home instead
	
	Revision 1.15  1999/11/05 21:59:24  scott
	insertid   ->  mysql_insertid

	Revision 1.14  1999/10/27 17:46:00  scott
	fixed double quotes thing

	Revision 1.13  1999/10/26 20:45:20  fhurtubi
	Changed a method call (getWorkspaceId)

	Revision 1.12  1999/10/26 17:13:48  fhurtubi
	Bogus queries are now fixed

	Revision 1.11  1999/10/25 13:46:28  fhurtubi
	Added the getInvitedGroup function and replaced the GID call with anoptional shift

	Revision 1.10  1999/10/04 22:44:34  fhurtubi
	Added a rename function that is used when renaming a workspace

	Revision 1.9  1999/09/27 15:17:42  fhurtubi
	Reflects changes made to the GroupsBrowser (this module is object-oriendted now)

	Revision 1.8  1999/09/22 07:48:35  fhurtubi
	Added a getWorkspaceAndFolder method based on a given groupid. THis retrieves
	the ws id in the home field of the groups table, loads the ws, get the folder
	associated to it, load that folder and returns both objects. This implies you
	will play with both objects

	Revision 1.7  1999/09/20 20:43:13  krapht
	It works!!  It works!!  We fixed the problem we had with session.
	_insertSignal had problems, it was setting appState as a global, but it
	really is a private value for each app.

	Revision 1.6  1999/09/20 14:30:00  krapht
	Changes in most of the files to use the new way of referring to session,
	user, etc. (SW->user, SW->session).

	Revision 1.5  1999/09/11 08:44:36  gozer
	Made a whole bunch of little kwirps.
	Fixed Handler to deal correctly with SW_App_Namespace without defaulting to SW::App when the var is set
	Fixed the bug that made Login.pm create an empty hidden argument on every login attempt
	Added a whole bunch of modules preloading in sw-perl-startup, good speed improvment
	Fixed a few warning here and there.  Only one missing the sweep.  Application.pm and AUTOLOAD warning ?!?
	Changed the SW::Util::flatten and circular_flatten to succesfully use Data::Dumper ;-} (-180 lines of code)
	Gone to bed very late

	Revision 1.4  1999/09/10 16:21:13  fhurtubi
	new methods and removed some

	Revision 1.3  1999/09/04 21:40:48  fhurtubi
	Fully documented!

	Revision 1.2  1999/09/02 23:21:41  fhurtubi
	Added methods that are used by the GroupManager

	Revision 1.1  1999/09/02 19:15:30  fhurtubi
	First draft of the Group methods. No objects involved here as it is only basic accesses to the database


=head1 SEE ALSO

	perl(1).

=cut
