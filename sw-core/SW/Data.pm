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

package SW::Data;

#------------------------------------------------------------
# SW::Data
# This is the object through which ALL database access
# occurs. 
#
#------------------------------------------------------------
# $Id: Data.pm,v 1.46 1999/11/15 18:17:32 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION $DATA_TYPE_MAP @ISA @SW_EXPORT $activeDataTypes);

use SW::Exporter;

use SW::DB;
use SW::Util;
use SW::Data::ObjectStore::DBI;
use SW;
use DBI;
use SW::Constants;

use SW::Data::Folder;
use SW::Data::Document;
use SW::Data::File;

@ISA = qw(SW::Exporter);

@SW_EXPORT = qw(getInfoFromID getActiveDataTypes deleteObject getRealID);

$VERSION = '0.01';

# change this to override the module and create a new data type

# constants

sub TABLE_NAME () {"objects"}
sub PRIMARY_KEY () {"id"}
sub ACCESS_TABLE_NAME () {"dataaccess"}
sub MAP_TABLE_NAME () {"datamap"}
sub INFO_TABLE_NAME () {"datainfo"}
sub FIELD_NAMES () {}
sub PROTECTED_FIELDS () { my $ref =  ["objectid", "userid", "type", "creator", "appid"] }
sub INFO_FIELDS () { my $ref =  ["id", "type", "creator", "name", "appid"] }
sub EVAL_FIELDS () { my $ref = ["storage"] } 
sub DATA_TYPE () {"GENERIC"}

# states and locking (inspired by apache::session

sub OPEN      	() {1};
sub RELEASE 	() {2};
sub PROMOTE  	() {4};
sub REOPEN   	() {8};
sub CREATE   	() {16};
sub WRITE   	() {32};

#State methods
#
#These methods tweak the state constants.

sub is_open          { $_[0]->{state} & OPEN }
sub is_release     	{ $_[0]->{state} & RELEASE }
sub is_promote      	{ $_[0]->{state} & PROMOTE }
sub is_reopen       	{ $_[0]->{state} & REOPEN }
sub is_create       	{ $_[0]->{state} & CREATE }
sub is_write_locked  { $_[0]->{state} & WRITE }
sub is_read_locked   { ( $_[0]->{state} & WRITE ) ^ WRITE  }   # does this work?
sub is_not_reopen    { ( $_[0]->{state} & REOPEN ) ^ REOPEN  }
sub is_not_create    { ( $_[0]->{state} & CREATE ) ^ CREATE }

sub make_open       { $_[0]->{state} |= OPEN }
sub make_release    { $_[0]->{state} |= RELEASE }
sub make_promote    { $_[0]->{state} |= PROMOTE }
sub make_reopen     { $_[0]->{state} |= REOPEN }
sub make_create     { $_[0]->{state} |= CREATE }
sub make_write_locked      { $_[0]->{state} |= WRITE }

sub make_read_locked       { $_[0]->{state} &= ($_[0]->{state} ^ WRITE) }  
sub make_closed     			{ $_[0]->{state} &= ($_[0]->{state} ^ OPEN) }  

# Maximum name length in the database

my $DATA_TYPE_MAP;
$SW::Data::PreLoaded = 0;


#------------------------------------------------------------
# new
#
# Create an instance of a Data object.  If the data object
# is created with a string identifying an existing object,
# then the system attempts to retrieve that object. If not,
# then the system attempts to create the object.
#------------------------------------------------------------

sub new
{

	my $className = shift;
	my ($app,$datatype,$appid, $lock);
	my ($state, $request_lock, $id);

	preload() unless $SW::Data::PreLoaded;

	my $self = { };

	if (ref($_[0]) eq "HASH") 
	{
		my $args = shift;
		$id = $args->{id};
		$self->{app} = $args->{app};
		$self->{datatype} = $args->{datatype};
		$self->{appid} = $args->{appid};	
		$request_lock = $args->{request_lock};
	}
	else
	{
		($app,$id,$datatype,$appid, $request_lock) = @_;
		$self->{app} = $app;
		$self->{datatype} = $datatype;
		$self->{appid} = $appid;	
	}


	#SW::DB::getDbh = getDbh();

	bless($self, $className);

	if ($id =~ /^[0-9]+$/)   # open / re-open states
	{
		$self->{id} = $id;
		# ! CREATE  is implied	

		# no locking is actually done yet ... we're just establishing
		#  what the desired state is ....
	
		# existing lock
		if (SW->user->has_write_lock($id))
		{
			if ($request_lock eq "WRITE") { $self->make_write_locked(); }
			elsif ($request_lock eq "READ") { $self->make_read_locked(); }
			else { $self->make_write_locked(); }  # keep state of already being locked
		}
		else  # not lock currently there
		{
			if ($request_lock eq "WRITE") { $self->make_write_locked(); }
			elsif ($request_lock eq "READ") { $self->make_read_locked(); }
			else { $self->make_write_locked(); }  # keep state of already being locked
		}		# defaulting to write lock

		if (SW->user->has_open($id)) 
		{ 
			$self->make_reopen(); 
			$self->make_release();
		}

	}
	elsif(!$id)   # create state
	{
		$self->make_create();
		$self->make_write_locked();
		
	# ....
	}
	else  # invalid id state
	{
		SW->set_errcode('INVALID_ID');
###		return undef;
	}

	# createif necessary
	if ($self->is_create())
	{
		if (! $self->create($datatype, $appid))
		{
			SW->set_errcode('CREATE_ERROR');
###			return undef;
		}

		# register the lock in the user's object
		if ($self->is_write_locked)
		{	
			if (! $self->set_write_lock())
			{
				SW->set_errcode('LOCK_ERROR');
###				return undef;
			}
#			SW->user->add_write_lock($self->{id}); 
		}

		# Default permissions
		$self->setUserPermissions(READABLE+WRITABLE);
	}

	if ($self->is_not_create())
	{
		# check permissions

		# attempt lock
		if ($self->is_write_locked)  # WRITE lock
		{	
			if (! $self->set_write_lock())
			{
				SW->set_errcode('LOCK_ERROR');
###				return undef;
			}

			#try to open
			if (! $self->loadobject())
			{
				SW->set_errcode('OPEN_ERROR');
				$self->release_write_lock();
###				return undef;
			}

			SW->user->add_write_lock($self->{id}); 
		}
		
		else    # READ lock
		{
			#try to open
			if (! $self->loadobject())
			{
				SW->set_errcode('OPEN_ERROR');
###				return undef;
			}
		}
	}


	# avoid circular references stopping the object from being saved when it 
	#   goes out of scope
	delete ($self->{app});

	return $self;
}


#------------------------------------------------------------
# load
#
#    duplicate constructor specifically for re=materializing
#    existing objects rather than creating new ones
#------------------------------------------------------------

sub load
{
   my $self = shift;

   return $self->new(@_);
}


#------------------------------------------------------------
# create
#------------------------------------------------------------
sub create
{
	my $self = shift;
	my $datatype = $self->{datatype} || shift;
	my $appid = shift || $self->{app}->APP_ID();
	# Creating a new DB entry
	my $userid;	

	$self->{storage} = {};

   $datatype = DATA_TYPE unless $datatype;

	SW::debug($self,"creating object with type $datatype in table ".$self->TABLE_NAME,5);	
	$userid = SW->user->getUid();

	#  tie the storage hash
	tie %{$self->{storage}}, 'SW::Data::ObjectStore::DBI', undef,
		{
			table => $self->TABLE_NAME,
			access_table => $self->ACCESS_TABLE_NAME,
			map_table => $self->MAP_TABLE_NAME,
			info_table => $self->INFO_TABLE_NAME,
			protected => $self->PROTECTED_FIELDS,
			evalFields => $self->EVAL_FIELDS,
			datatype => $datatype,
			user =>  SW->user(),
			dbh => SW::DB::getDbh,
			creator => $userid,
		};

	SW::debug($self,"The new object has objectid $self->{objectid}",5);

	tied (%{$self->{storage}})->setProtectedValue('type',$datatype);
	tied (%{$self->{storage}})->setProtectedValue('appid', $appid);

	$self->{id} = $self->{storage}->{id};
}

#------------------------------------------------------------
# loadobject
#------------------------------------------------------------

sub loadobject
{
	my $self = shift;

	SW::debug($self,"[Data] loading data object ".$self->{id},5);

	tie %{$self->{storage}}, 'SW::Data::ObjectStore::DBI', $self->{id},
		{
			table => $self->TABLE_NAME,
			pkey => $self->PRIMARY_KEY,
         access_table => $self->ACCESS_TABLE_NAME,
         map_table => $self->MAP_TABLE_NAME,
         info_table => $self->INFO_TABLE_NAME,
			protected => $self->PROTECTED_FIELDS,
			evalFields => $self->EVAL_FIELDS,
         user =>  SW->user(),
			dbh => SW::DB::getDbh,
		};

	# determine what privs the user has on this object

	my $permission = $self->getUserPermissions();

	SW::debug($self, "Loaded object $self->{storage}->{name} with permissions ".$self->getPermissionByName($permission),2);

	$self->{id}=$self->{storage}->{id};

}

#------------------------------------------------------------
# close
#------------------------------------------------------------

sub close
{
	my $self = shift;
	my $id = $self->{id};

	if ($self->is_write_locked)
	{
		if (! SW->user->release_write_lock($id))
		{	SW::debug($self,"Error - data object thought it was locked but user didn't have the lock!\n",1); }
	}
	$self->make_closed;
	return $id;
}


#------------------------------------------------------------
# delete
#
# Delete this object (Method call only!!!)
#------------------------------------------------------------

sub delete
{
	my $self = shift;

	SW::debug($self,"[Data] loading document ".$self->{$self->PRIMARY_KEY},5);

	# delete the object from the db (see SW::=Data::ObjectStore->delete() )

	tied(%{$self->{storage}})->delete;
	 
}


#------------------------------------------------------------
# forceWrite
#
# Forces a make_modified on the tied hash....
# this is temporary until I figure out why it's not catching
# on to the fact that I've modified it....
#------------------------------------------------------------

sub forceWrite
{
	my $self = shift;

	tied (%{$self->{storage}})->make_modified;
}

#------------------------------------------------------------
# save - does nothing
#------------------------------------------------------------

sub save
{
	return 1;
}



#------------------------------------------------------------
# setStorage
#------------------------------------------------------------

sub setStorage
{
	my $self=shift;
	my $key=shift;
	my $value=shift;

	return $self->{storage}->{$key} = $value;
}


#------------------------------------------------------------
# getStorage
#------------------------------------------------------------

sub getStorage
{
	my $self=shift;
	my $key=shift;

	return $self->{storage}->{$key};
}

#------------------------------------------------------------
# deleteStorage
#------------------------------------------------------------

sub deleteStorage
{
	my $self=shift;
	my $key = shift;

	if (defined $self->{storage}->{$key})
	{
		return delete $self->{storage}->{$key};
	}

	SW::debug($self,"Attempted to delete non-existant key $key",3);


	return undef;

}

#------------------------------------------------------------
# getObjectId
#------------------------------------------------------------

sub getObjectId
{
	my $self = shift;

	return $self->{storage}->{id};
}



#------------------------------------------------------------
# getType
#------------------------------------------------------------

sub getType
{
	my $self = shift;

	return $self->{storage}->{type};
}

#------------------------------------------------------------
# setType
#------------------------------------------------------------

sub setType
{
	my ($self,$newType) = @_;

	tied(%{$self->{storage}})->setProtectedValue('type',$newType);
}

#------------------------------------------------------------
# getName
#------------------------------------------------------------

sub getName
{
	my $self = shift;

	return $self->{storage}->{name};
}

#------------------------------------------------------------
# setName
#------------------------------------------------------------

sub setName
{
	my ($self,$name) = @_;

	if($SW::Config::MAX_NAME_LEN)
	{
		$name = substr($name,0,$SW::Config::MAX_NAME_LEN);
	}

	tied(%{$self->{storage}})->setProtectedValue('name',$name);
}


#------------------------------------------------------------
# getAppId
#------------------------------------------------------------

sub getAppId
{
	my $self = shift;

	return $self->{storage}->{appid};
}

#------------------------------------------------------------
# setAppId
#------------------------------------------------------------

sub setAppId
{
	my $self = shift;
	my $value = shift;

	tied(%{$self->{storage}})->setProtectedValue('appid',$value);

}


#-------------------------------------------------------------
# getValue
#-------------------------------------------------------------

sub getValue
{
	my $self = shift;
	my $key = shift;

	if( $self->{storage}->{$key} ) { return $self->{storage}->{$key}; }

	return;
}


#------------------------------------------------------------
# publish
#
# lets you publish an object into a given group with 
# some permission level
#------------------------------------------------------------

sub publish
{
	my $self = shift;
	my $app = shift;
	my $groupname = shift;
	my $priv = shift || (READABLE | WRITABLE);
	my $dbh = SW::DB::getDbh;


	my $user = SW->user();

	my $groups = $user->getGroupsByName();

	# make sure the user who called actually owns it!
#	if (! $self->getValue('creator') eq SW->user->getUid())
#	{
#		SW::debug($self,"Error: publish -  SW->user->getUid() does not own object ".$self->getName,1);
#		return 0;
#	}
	
	if (! defined $groups->{$groupname})
	{
		SW::debug($self,"Error: publish -  group $groupname either does not exist or $user->getName() is not a member",1);
		return 0;
	}

	my $groupid = $groups->{$groupname};

	my $query = "insert into ".$self->ACCESS_TABLE_NAME()."  (id, userid, groupid, perm, owner) ";
	$query .= "values (".$self->getObjectId().",NULL, $groupid, ".$priv.", '0')";
	
	SW::debug($self,"publish query = $query",5);

	my $sth = $dbh->prepare($query) or SW::debug($self,"publish: Error preparing $query : ".$dbh->errstr,2);

	SW::debug($self,"Publishing ".$self->getObjectId()." into the group $groupname with priv $priv",2);

   $sth->execute or SW::debug($self,"publish: Error executing $query : ".$dbh->errstr,2);

	# returns the number of rows, given by the result of $sth->execute	
}

#------------------------------------------------------------
# getUserPermissions - method
#
# Figures out what permissions a user has on the object.
#	
# Returns a numerical value
#
# Implementation loads all the access records pertaining to
# a particular object.  It might be a better idea to do a more
# specific select if we end up with very many objectaccess
# records for each object.
#------------------------------------------------------------

sub getUserPermissions
{
	my $self = shift;
	#my $dbh = SW::DB::getDbh;
	my $perm = 0x00;
	my $userid = SW->user->getUserId();

	my @groups = values %{SW->user->getGroups()};

	if (! $self->{permission})
	{
		my $query = "select * from ".$self->ACCESS_TABLE_NAME()." where ";
		$query .= "id = ".$self->getObjectId;

		SW::debug($self,"permcheck - query $query",5);
		
		my $dbh = getDbh();

		my $sth = $dbh->prepare($query) ||
				SW::debug($self,"Error preparing $query : ".$dbh-> errstr,2);
		$sth->execute ||
				SW::debug($self,"Error executing $query : ".$dbh->errstr,2);

		my $all = $sth->fetchall_arrayref({});

		# first see if there's a user ownership field, if so we assume it's the only
		# one and the one with the highest privilege level
		foreach my $row (@$all)
		{
			if ($row->{userid} == $userid)
			{
				$perm = $row->{perm};
				$self->{permission} = $perm;
				return $perm;
			}
		}	

		# now check group access records and we'll just AND them together
		foreach my $row (@$all)
		{
			if (inArray($row->{groupid}, \@groups))
			{
				$perm &= $row->{perm};
				$self->{permission} = $perm;
			}
		}

	}

	return $self->{permission} || SYSTEM;
}


#------------------------------------------------------------
# setUserPermissions - method
#
# Sets the permissions on the data object to the argument
# passed.  Note that some permissions are not changeable by
# users.  Here are the various permissions available, and
# their meaning :
#
# READ_ONLY
# The user can only read the contents of the file
#
# READ_WRITE
# The user can read or write to this file
#
# FULL_ACCESS
# The user can read, write, move and delete this file
#
# HIDDEN
# The user can hide this file (i.e. it doesn't show up unless
# a special flag is up in the preferences
#
# SYSTEM
# System files are necessary for the good work of the system.
# Therefore, they cannot be written to, moved or deleted.
# A system file is therefore automatically read-only.
#
#
#          IMPORTANT NOTE !!!!
#
# setUserPermissions supposes that the value passed as an
# argument is the total value (i.e. if the system bit is set,
# and a new value for the permissions is passed, without the
# system bit set, the new value will not have the system bit
# set).  It is absolute, and not relative to the old value.
#
# Returns the old permissions, or undef if the permission
# type is not valid or the permissions are not changeable.
#------------------------------------------------------------

sub setUserPermissions
{
	my ($self,$perms,$caller) = @_;

# set this to READ/WRITE if unset...


	$perms ||= (READABLE & WRITEABLE);

	if(($perms > 8) && ($caller ne "system"))
	{
		# permissions not valid, user can't set these
		return undef;
	}

	my $dbh = getDbh();
	if(!$dbh)
	{
		SW::debug($self,"setUserPermissions: error in getting the database handle",1);
		return undef;
	}

	my $query = "SELECT perm FROM dataaccess WHERE id=$self->{id}";

	my $sth = $dbh->prepare($query) ||
			print STDERR "setUserPermissions: error in preparing query $query\n";

	$sth->execute() ||
			print STDERR "setUserPermissions: error in executing query $query\n";

	my $old_perms = $sth->fetchrow_array();

	$query = "update dataaccess set perm=$perms where id=$self->{id}";

	$sth = $dbh->prepare($query) ||
			print STDERR "setUserPermissions: error in preparing query $query\n"; 

	$sth->execute() ||
			print STDERR "setUserPermissions: error in executing query $query\n";

	return $old_perms;
}


#------------------------------------------------------------
# getPermissionByName - method
#
# Simple function to resolve the numeric permission to its
# string equivalent.
#
# Returns the string equal to the permission level.
#------------------------------------------------------------

sub getPermissionByName
{
	my $self = shift;
	my $perm = shift;

	return $PERMS{$perm};
} 


#------------------------------------------------------------
# getOwnerByName - method
#
# Retrieves the name associated with the user ID of the
# object owner.  The information is extracted from the
# 'authentication' table.
#
# Returns the name.
#------------------------------------------------------------

sub getOwnerByName
{
	my $self = shift;
	#my $dbh = SW::DB::getDbh;
	my $uid = $self->{storage}->{creator};

	my $query = "select username from authentication where uid=$uid";

	my $sth = SW::DB::getDbh->prepare($query);

	$sth->execute() ||
			SW::debug($self,"getOwnerByName: error in execution of query $query");

	my $owner = $sth->fetch();

	return $owner->[0];
}

sub getCreatorFromId
{
	my ($id) = shift;
	my $dbh = getDbh();

	my $query = "select creator from datainfo where id = $id";
	my $sth = $dbh->prepare($query);
	$sth->execute();
	return $sth->fetchrow_array;
}


#-------------------------------------------------------------
# preload
#
#-------------------------------------------------------------

sub preload
{
	print STDERR "$SW::Config::DEFAULT_DB_NAME\n";

	my $dbh = getDbh();
	
	my $q = "select * from datatypes";
	my $sth = $dbh->prepare($q) || warn "Error loading datatype map!! $q ";
	$sth->execute();

	while (my $r = $sth->fetchrow_hashref())	
	{
		my $type = $r->{'datatype'};
		$DATA_TYPE_MAP->{$type}->{table} = $r->{'tbl'};
		$DATA_TYPE_MAP->{$type}->{pkg} = $r->{'pkg'};
		$DATA_TYPE_MAP->{$type}->{hidden} = $r->{'hidden'};
		$DATA_TYPE_MAP->{$type}->{iconuri} = $r->{'iconuri'};
		$DATA_TYPE_MAP->{$type}->{appuri} = $r->{'appuri'};
		$DATA_TYPE_MAP->{$type}->{apppkg} = $r->{'apppkg'};
		print STDERR "$type - $r->{'tbl'}\n";
	}
	$SW::Data::PreLoaded=1;
}

#------------------------------------------------------------
# getTable - function
#
# Takes a data type and gives back a table name.
#------------------------------------------------------------

sub getTable
{
	print STDERR "check table $_[0] is ".$DATA_TYPE_MAP->{$_[0]}->{table}."\n";
	return $DATA_TYPE_MAP->{$_[0]}->{table};
}


#------------------------------------------------------------
# getPkg - function
#
# take a data type and returns a package
#------------------------------------------------------------

sub getPkg
{
	return $DATA_TYPE_MAP->{$_[0]}->{pkg};
}


#------------------------------------------------------------
# getAppPkg - function
#
# Returns the package name of the application used to
# handle the datatype.
#------------------------------------------------------------

sub getAppPkg
{

	return $DATA_TYPE_MAP->{$_[0]}->{apppkg};
}


#------------------------------------------------------------------#
# getActiveDataTypes - function
# returns datatypes that we can use to create new docs
#------------------------------------------------------------------#
sub getActiveDataTypes
{
	if (!$activeDataTypes) { 
		preload() unless $SW::Data::PreLoaded; # this will load the datatypes info

		foreach my $type (keys %{$DATA_TYPE_MAP}) {
			if ($DATA_TYPE_MAP->{$type}->{hidden} eq "false") { 
				push (@{$activeDataTypes}, $type);
			}
		}
	}

	return $activeDataTypes;
} # sub getActiveDataTypes

#-------------------------------------------------------------
# getInfoFromID - function
#
# Queries the database and gathers information about the
# entry related to the ID passed as an argument.
#
# Returns a hash reference, containing the following information:
#
# creator - the ID of the creator of the entry
# name - the name of the entry
# type - the datatype associated with the entry
# id - the ID of the entry
# appid - the string identifying the associated application
#-------------------------------------------------------------

sub getInfoFromID
{
	my $id = shift;

	my $query = "SELECT * FROM datainfo WHERE id=$id";
	my $sth = getDbh()->prepare($query) ||
			print STDERR "Error in preparing query in getNameFromID\n";

	$sth->execute() || print STDERR "Error in executing query in getNameFromID\n";

	my $values = $sth->fetchrow_hashref();
	$sth->finish();

	$query = "SELECT owner FROM dataaccess where id=$id";

	$sth = getDbh()->prepare($query) ||
			print STDERR "Error in preparing query in getInfoFromID\n";

	$sth->execute() ||
			print STDERR "Error in executing query in getInfoFromID\n";

	$values->{owner} = ($sth->fetchrow_array())[0];


	$sth->finish();
 
	$query = "SELECT iconuri, apppkg from datatypes where datatype='$values->{type}'";
	$sth = getDbh()->prepare($query) ||
			print STDERR "Error in preparing query in getInfoFromID\n";

	$sth->execute() ||
			print STDERR "Error in executing query in getInfoFromID\n";

	my $row = $sth->fetch;
	$values->{iconuri} = $row->[0];
	$values->{pkg} = $row->[1];

	$sth->finish();
	return $values;
}


#------------------------------------------------------------
# setAttrib - method
#
#------------------------------------------------------------

sub setAttrib
{
	my ($self) = @_;
	my $perms;

	return $perms;
}


#------------------------------------------------------------
# getAttrib - method
#
#------------------------------------------------------------

sub getAttrib
{
	my ($self) = @_;
	my $perms;

	return $perms;
}

#------------------------------------------------------------
# set_write_lock
#------------------------------------------------------------

sub set_write_lock
{
	my $self = shift;
	my $uid = SW->user->getUid();
	my $owner = $self->_get_lock_owner();

	if (!$owner || ($owner == $uid))
	{
		return $self->_set_lock();
	}
	return undef;
}

#------------------------------------------------------------
# release_write_lock
#------------------------------------------------------------

sub release_write_lock
{
	my $self = shift;
	return $self->_clear_lock();	
}


#------------------------------------------------------------
# _get_lock_owner
#------------------------------------------------------------

sub _get_lock_owner
{
	my $self = shift;
	my $dbh = getDbh();
	my $query = "select (lockstat) from datamap where id=".$self->{id};

	my $sth;
	$sth = $dbh->prepare($query);
	if (! $sth) 
	{ 
		SW::debug($self,"sql error on $query :".$dbh->errstr, 1); 
		return undef; 
	}
	$sth->execute();
	my $row = $sth->fetchrow_arrayref;
	return $row->[0];
}

		
#------------------------------------------------------------
# _set_lock
#------------------------------------------------------------

sub _set_lock
{
	my $self = shift;
	my $uid = SW->user->getUid();
	my $dbh = getDbh();
	
   my $query = "update datamap set lockstat=$uid where id=".$self->{id};

	my $sth = SW::DB::getDbh->prepare($query);
	if (! $sth)
	{ 
		SW::debug($self,"sql error on $query :".$dbh->errstr, 1); 
		return undef; 
	}
   return $sth->execute();
}

		
#------------------------------------------------------------
# _clear_lock
#------------------------------------------------------------

sub _clear_lock
{
	my $self = shift;
	my $dbh = getDbh();
	
   my $query = "update datamap set lockstat=NULL where id=".$self->{id};

   my $sth = $dbh->prepare($query);
	if (! $sth)
	{ 
		SW::debug($self,"sql error on $query :".$dbh->errstr, 1); 
		return undef; 
	}
   return $sth->execute();
}


#------------------------------------------------------------
# deleteObject - function
#
# Formerly in SW::User
#
# deleteObject takes a list of ID's as an argument and removes
# all entries in the database related to each ID.  It also
# makes sure the user is the owner of the files being deleted.
#
# Returns the total number of ID's successfully deleted, or
# undef if no ID was removed.
#
# IMPORTANT : Permissions are not checked right now
#
#------------------------------------------------------------
 
sub deleteObject
{
	my $dbh = getDbh();
	my $substring = undef;
	my $nbDeleted = 0;

	my $query = "SELECT * FROM datamap where id in (".join(', ',@_).")";
#	my $query2 = "SELECT perm FROM dataaccess where id in (".join(', ',@ids).")";
#	$query2 .= " and userid=" . SW->user->getUserId();

	my $sth = $dbh->prepare($query) ||
			print STDERR "deleteObject: error in preparing query $query\n";

	$sth->execute() ||
			print STDERR "deleteObject: error in executing query $query\n";

#	my $sth2 = $dbh->prepare($query2) ||
#			print STDERR "deleteObject: error in preparing query $query2\n";

#	$sth2->execute() ||
#			print STDERR "deleteObject: error in executing query $query2\n";

	while (my $r = $sth->fetchrow_hashref())
	{
		$query = "select pkg from datatypes where datatype=".$dbh->quote($r->{dataclass});

		$sth = $dbh->prepare ($query) ||
				print STDERR "deleteObject: error in preparing query $query\n";

		$sth->execute ||
				print STDERR "deleteObject: error in preparing query $query\n";

		my $pkg = $sth->fetchrow_array;

		if($pkg)
		{
			# Call the delete method provided by the package (if there is one)
			eval ("use $pkg");

			# First check if the delete method is provided

			if(${pkg}->can('delete'))
			{
				${pkg}->delete($r->{id});
			}
		}

		# First, let's see if the user has permissions to delete the ID
		# We should now have a corresponding entry in the second query
		# for each object found in the first

#		my $p = ($sth2->fetchrow_array())[0];

#		if(($p & SYSTEM) || ($p & STICKY))
#		{
			# It's either a system file or a file on which the user
			# doesn't have the required permissions
#			next;
#		}

		my $table = SW::Data::getTable($r->{dataclass});

		my $dataid = $r->{dataid};
		my $q1 = "delete from datamap where id=$r->{id}";
		my $q2 = "delete from dataaccess where id=$r->{id}";
		my $q3 = "delete from datainfo where id=$r->{id}";

		$dbh->do($q1) || warn"deleteObject: error in preparing query $query\n";
		$dbh->do($q2) || warn"deleteObject: error in preparing query $query\n";
		$dbh->do($q3) || warn"deleteObject: error in preparing query $query\n";

		# We have to delete access references from the objectaccess table as well
 
		$query = "delete from $table where id=$dataid";

		my $sth = $dbh->prepare($query) ||
					print STDERR "deleteObject: error in preparing query $query\n";

		$sth->execute ||
					print STDERR "deleteObject: error in executing query $query\n";
	
		$nbDeleted++; 
   }

	return $nbDeleted;
}

#------------------------------------------------------------
# nameExists - function
#
#------------------------------------------------------------

sub nameExists
{
	my ($name, $userid, $datatype) = @_;
	my $dbh = SW::DB->getDbh();

	my $query = "select id from datainfo where name = ".$dbh->quote($name)."
		and type='$datatype' and creator = $userid";

	my $sth = $dbh->prepare($query) or SW::debug("SW::Data","Error preparing $query : ".$dbh->errstr,2);
	$sth->execute or SW::debug("SW::Data","Error executing $query : ".$dbh->errstr,2);
 
	return $sth->fetchrow_array || undef;
}


#------------------------------------------------------------
# getRealID - function
#
# Looks up the datamap table and finds the real ID number
# corresponding to the ID passed as argument.
#
#------------------------------------------------------------

sub getRealID
{
	my ($id) = @_;
	my $dbh = getDbh();

	my $query = "SELECT dataid FROM datamap WHERE id=$id";

	my $sth = $dbh->prepare($query) ||
			print STDERR "getRealID: error preparing query $query\n";

	$sth->execute() ||
			print STDERR "getRealID: error executing query $query\n";

	$id = ($sth->fetchrow_array)[0];

	return $id;
}


#------------------------------------------------------------
# DESTROY
#------------------------------------------------------------

sub DESTROY
{
	my $self = shift;
	print STDERR "Destroying ".ref($self)."with ID $self->{id}";
}		


1;

__END__

=head1 NAME

SW::Data - Class that abstracts the database interface from the developer.

=head1 SYNOPSIS

  use SW::Data;

   # for a new Data object ...

	my $data = new SW::Data ($app, '', DATA_TYPE);

	$data->publish($app, 'GROUP_NAME', 'PRIV_LEVEL');

	$data->setStorage('My_Cars',['Jag','Ford','Merc','Porsche','Acura']);

	my $cars = $data->getStorage('My_Cars');

	$data->deleteStorage('My_Cars');


=head1 DESCRIPTION


This class controls access to objects in the central database(s).  

The system access the database to retrieve the object, and does a privilege check
to see if the current user is allowed to view the data in the requested object. If the
object is not found, or the user doesn't have sufficient permissions, then the
constructor returns "undef".

This call is also used to create new objects if called with an empty string for the object name.

Very closely tied to SW::Data::ObjectStore - these object achieve their database storage via
a system much like Apache::Session, using a tied hash to accerss the data.

Object permissions are defined as follows in SW::Data

	sub READ_ONLY () {1}     -  obvious
	sub READ_WRITE () {2}	 -  no delete (or move? ) privilege
	sub FULL_ACCESS () {3}	 -  incl delete, move, eventually reparent

	note - No access is implied by the lack of a record in the objectaccess tables
				corresponding to the user or group in question.

   Builtin Groups:

	In addition to whatever groups are defined in the database, the following groups
	are defined:

	sub ALL_GROUP () { 0 }     # all registered users
	sub GUEST_GROUP () { -1 }  # absolutely everyone


=head2 STATES

	CREATE	(always write locked)
	OPEN_READ	(no lock for now)
	OPEN_WRITE  (attempt to write lock or fail)
	REOPEN_READ	(re-open an already opened file - no locking for now)
	REOPEN_WRITE (re-open a file this user already has locked)
	REOPEN_PROMOTE	(attempt to promote the lock from read to write on reopen)
	REOPEN_RELEASE (release the write lock on re-opening a file we've already locked)

=head2 RETURN VALUES

	SUCCESS			opened successfully
	INVALID_ID		bad id
	PERM_ERROR		permission denied
	LOCK_ERROR		Failed to write lock 
	ERROR				Unknown other error

=head2 INTERNAL REPRESENTATION

	|-write/read-|-create-|-reopen-|-promote-|-release-|-isopen-|

=head1 METHODS

	new -

	delete - Method call to destroy the current object from the database!  (calls
				tied($self->{storage})->delete();  To delete objects by objectid
				(one or many) see SW::User::DeleteObject()
				
	create - internal: creates a new object in the database
	
	load - internal: loads an object in from the database
	
	accessors.....
	
	getObjectId - returns the unique identifier for the object
	
	getName - returns the objectName
	
	setName - set the object's name
	
	getType - returns the data type associated with this object
	
	setType - set the data type of this object.

	setStorage - takes a key name and a value and stores them into the $self->{storage}
							tied hash for serialization into the database

	getStorage - takes a key and returns corresponding value out of the {storage} hash

	deleteStorage - takes a key and deletes the corresponding value out of the {storage} hash

	publish - take this object and make it available to a group.  Called with the current app,
				 the NAME of the desired group, and the desired Priviledge level name (see above)
				Note that this may be called as many times as is necessary.  For example you 
				might call it once to give all registered users READ_WRITE access and guest users
				READ_ONLY access.


=head1 AUTHOR

Kyle Dawkins, kyle@hbe.ca

=head1 REVISION HISTORY

  $Log: Data.pm,v $
  Revision 1.46  1999/11/15 18:17:32  gozer
  Added Liscence on pm files

  Revision 1.45  1999/11/12 22:18:58  krapht
  Removed annoying STDERR print statements in setUserPermissions

  Revision 1.44  1999/11/12 21:34:01  krapht
  Fixed a bug in setType (wasn't casting to hash), and removed some shifts...
  Removed the older close() version

  Revision 1.43  1999/11/11 20:38:42  fhurtubi
  For some reason, in a debug message, it was mentionning OD::Workspace, changed that

  Revision 1.42  1999/11/08 16:38:15  krapht
  Fixed the ojectid typo

  Revision 1.41  1999/11/05 19:06:08  fhurtubi
  You can publish to other groups now..(just commented out those lines)

  Revision 1.40  1999/11/05 18:09:32  gozer
  Removed a few $self->{dbh} and changed to getDbh()

  Revision 1.39  1999/11/04 21:34:39  krapht
  Added getRealID to get the id in the actual tables through datamap

  Revision 1.38  1999/10/26 22:35:05  krapht
  Put a SYSTEM bitmask in getUserPermissions

  Revision 1.37  1999/10/26 00:16:54  fhurtubi
  Ok, removed the file locking again as it is not working...

  Revision 1.36  1999/10/25 21:49:46  fhurtubi
  getCreatorFromId was removed!

  Revision 1.35  1999/10/25 21:32:52  scott
  File locking changes

  Revision 1.31  1999/10/18 05:41:21  scott
  adding file locking code

  Revision 1.30  1999/10/13 21:31:59  krapht
  Added a little checking in deleteObject.  The function tried to call the
  delete method of the package even if it didn't exist...which caused lots
  of problems.

  Revision 1.29  1999/10/13 19:39:29  krapht
  Added getAppPkg to get the package of the app related to a datatype

  Revision 1.28  1999/10/12 18:29:44  fhurtubi
  Added the nameExists FUNCTION. Given a filename, userid and filetype, returns
  and id if such file exists already

  Changed the way getGroups is called...instead of by id, its by name

  Revision 1.27  1999/10/08 21:30:27  krapht
  Fixed a blatant error from me in new (was resetting permissions even if the object
  already existed).  Oups.

  Revision 1.26  1999/10/07 18:09:52  krapht
  Added debugging statements in setUserPermissions, and put default perms in
  new

  Revision 1.25  1999/10/05 16:29:42  fhurtubi
  Modified deleteObject to remove the FOLDER check

  Revision 1.24  1999/10/04 22:44:02  fhurtubi
  Added a hack so folders arent getting deleting for ever and ever (amen)

  Revision 1.23  1999/10/04 20:42:28  fhurtubi
  Added code to delete datatypes objects (eg: when deleting a contact list, we have
  to delete the contacts too)

  Revision 1.22  1999/09/29 21:27:28  krapht
  Moved deleteObject in Data, and added some user checking (not finished, so commented)

  Revision 1.21  1999/09/28 16:50:05  fhurtubi
  Changed appuri to apppkg in the getInfoFromId function

  Revision 1.20  1999/09/26 21:10:05  krapht
  Added some protection to prevent the creation of new entries if the objectid
  is not a valid number, but still not empty!

  Revision 1.19  1999/09/22 19:34:58  fhurtubi
  Added a new function (getActiveDataTypes) that returns data types that aren't
  hidden (to use in the new document creation)

  Revision 1.18  1999/09/22 07:47:37  fhurtubi
  Added a getDataTypes function that returns available datatypes to create a new doc

  Revision 1.17  1999/09/21 00:23:33  gozer
  MOdified some more stuff to SW->user and SW->session

  Revision 1.16  1999/09/20 14:30:00  krapht
  Changes in most of the files to use the new way of referring to session,
  user, etc. (SW->user, SW->session).

  Revision 1.15  1999/09/17 23:00:11  gozer
  Scott's work on gozer's machine committed by gozer. :-)

  Revision 1.14  1999/09/17 21:54:24  scott
  FIxed some problems with the dataaccess table

  Revision 1.13  1999/09/17 19:37:08  krapht
  Removed getNameFromID, which is obsolete because of getInfoFromID

  Revision 1.12  1999/09/17 16:35:17  krapht
  Added getInfoFromID, to retrieve info without having to load a Data
  object.

  Revision 1.11  1999/09/16 22:55:05  krapht
  Finally came out of my laziness and wrote setUserPermissions to work!

  Revision 1.10  1999/09/15 21:31:26  fhurtubi
  Changed the insert queries that were missing the column names and
  other stuff..

  Revision 1.9  1999/09/15 01:50:53  scott
  fixing delete

  Revision 1.8  1999/09/14 02:16:40  fhurtubi
  Changed $app->{dbh} to SW::DB->getDbh (in one place only, we have to replace
  that everywhere!!!)

  Revision 1.7  1999/09/14 02:00:02  krapht
  I fixed the bug, and it should work now

  Revision 1.6  1999/09/14 01:53:47  krapht
  Added getNameFromID, to retrieve the name from an objectid.
  What's funny is that I'm writing that text and just thought of a bug,
  but I can't go back to change it.  Wait for version 2

  Revision 1.5  1999/09/13 22:53:41  krapht
  Added the SW::Data::File line to include File

  Revision 1.4  1999/09/13 15:00:57  scott
  lots of changes, sorry this is bad documentation :-(

  Revision 1.3  1999/09/12 11:19:11  krapht
  Added lines to use Folder and Document

  Revision 1.2  1999/09/11 08:04:13  scott
  Final fixes on the file cvs barfed all over

  Revision 1.1  1999/09/11 07:49:58  scott
  First attempt at replacing the file cvs fucked up

  Revision 1.56  1999/09/10 16:36:18  krapht
  Added a code line to truncate names to 20 characters in the DB

  Revision 1.55  1999/09/06 17:59:02  krapht
  Added getOwnerByName, which returns the name of the owner of the data object
  as written in the authentication table.

  Revision 1.54  1999/09/05 03:41:33  scott
  changed creator from username to uid

  Revision 1.53  1999/09/03 01:05:36  scott
  Mods so we can remove the site specific configurations info
  (SW::Config) from the framework.

  Revision 1.52  1999/09/01 21:29:25  scott
  added setStorage, getStorage, deletStorage

  Revision 1.51  1999/09/01 20:00:11  scott
  fixed a bug in Data causing extra objectaccess records

  Revision 1.50  1999/09/01 01:26:46  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.49  1999/08/30 20:23:11  krapht
  Removed the Exporter stuff

  Revision 1.48  1999/08/27 21:42:38  krapht
  Changed some minor stuff in there!

  Revision 1.47  1999/08/18 23:25:51  fhurtubi
  Destroy bug tracking

  Revision 1.46  1999/08/18 02:58:26  scott
  fixes for publish / permission methids

  Revision 1.45  1999/08/17 16:06:46  scott
  Object permissions now work

  you can check them using a combination of $dataobject->userPermissions();

  and $dataobject->getPermissionByName(perm);

  I haven't actually hooked it up to block writing based on these yet
  but that's coming soon!

  Revision 1.44  1999/08/16 22:03:29  krapht
  Rechanged the bug with inArray, which was actually with getGroups!

  Revision 1.43  1999/08/16 21:53:03  krapht
  Changed a scalar to an ARRAY ref for the call to inArray

  Revision 1.42  1999/08/16 18:59:36  scott
  changed permission declarations

  Revision 1.41  1999/08/16 18:18:39  scott
  Added the publish method for making an object avaible to a given
  group....  (and added a bunch of docs about it...)

  Revision 1.40  1999/08/13 20:22:16  scott
  minor fixes (I think!)

  Revision 1.39  1999/08/13 17:07:22  scott
  added forceWrite() which is a bit of a hack to call make_modified()
  on the tied hash because it's not figuring out that we've changed it in
  all bu tthe simplest cases.

  Revision 1.38  1999/08/13 16:02:40  scott
  Bug fix adding $self->  before TABLE_NAME etc...

  Revision 1.37  1999/08/13 14:33:24  scott
  Removed some annoying debugging from DB and bug fixes and tweaking in Data

  Revision 1.36  1999/08/12 19:43:53  scott
  Fixed a dumb bug in protected() that was stopping data from being written in the db

  Revision 1.35  1999/08/12 14:54:11  scott
  Working on null object problem

  Revision 1.34  1999/08/12 13:52:14  scott
  Fixed a typo that was stopping the laod() method from working

  Revision 1.33  1999/08/11 22:37:57  krapht
  Changed some minor stuff

  Revision 1.32  1999/08/11 15:58:58  fhurtubi
  Fixed subroutine names that were copied/pasted badly :)

  Revision 1.31  1999/08/11 15:53:34  scott
  fixed a bug in seTName
  added getAppId, setAppId

  Revision 1.30  1999/08/11 15:27:00  scott
  Small bug fixes on the code I wrote last night

  Revision 1.29  1999/08/11 15:18:46  krapht
  Added a getValue function

  Revision 1.28  1999/08/11 05:48:38  scott
  Several changes - organized the data new into several ddifferent
  methods and pruned out a bunch of the multiple database and
  parent-child object relationships for now.  This will get written
  back in eventually, but not today :-)

  Revision 1.27  1999/08/10 14:44:17  scott
  Fixed a problem (I think!) so we don't get multiple owner records created
  in the objectaccess table

  Revision 1.26  1999/08/09 21:39:08  scott
  Oops!  That'll teach me to check in without running it!

  Revision 1.25  1999/08/09 21:35:39  scott
  added a delete() method call

  Revision 1.24  1999/08/04 19:26:37  krapht
  Added a getName function in User.pm so we can use $self->{user}->getName
  instead of $self->{user}->{user} now

  Revision 1.23  1999/07/25 02:34:13  scott
  Major updates, changed SW::Data to behave much like SW::Session( Apache::Session)

  Revision 1.22  1999/07/22 18:25:32  krapht
  Removed a very strange line : use SW::Data;  Recursive????

  Revision 1.21  1999/07/21 14:29:52  krapht
  No real changes, just updating!!

  Revision 1.20  1999/04/30 19:35:44  kiwi
  Added some documentation

  Revision 1.19  1999/04/20 05:01:49  kiwi
  Added the "setProperty" function.

  Revision 1.18  1999/04/17 21:28:20  kiwi
  Added the getProperty function

  Revision 1.17  1999/04/14 20:27:04  kiwi
  Fixed parent selection code

  Revision 1.16  1999/04/14 19:46:16  scott
  Fixed some missing dbh->quote 's in save()

  Revision 1.15  1999/04/13 19:22:58  kiwi
  Changed "0" to "guest" in anonymous object creation.

  Revision 1.14  1999/04/13 19:08:16  kiwi
  *** empty log message ***

  Revision 1.13  1999/04/13 16:48:37  kiwi
  Minor fixes to handling data

  Revision 1.12  1999/04/13 16:34:41  scott
  Bug fix in Kyle's anonymous object creation code - fixed to properly accept
  null parent?

  Revision 1.11  1999/04/09 20:31:03  kiwi
  Changed setParent to allow NULL parents

  Revision 1.10  1999/04/07 20:45:36  kiwi
  Added anonymous data objects that aren't owned by anybody.

  Revision 1.9  1999/03/30 23:17:30  kiwi
  Finished the basic virtual file system functions.  Objects are now
  created in a context, with parent/child relationships.

  Revision 1.8  1999/03/29 20:58:31  kiwi
  Started to build hierarchical "virtual file system" concept

  Revision 1.7  1999/03/27 21:50:52  kiwi
  Implemented accessor methods for most properties.
  Added save/load facility

  Revision 1.6  1999/03/19 22:42:05  kiwi
  Fixed up saving to allow for object creation.

  Revision 1.5  1999/03/18 00:00:10  kiwi
  Fixed a stupid typo

  Revision 1.4  1999/03/17 23:17:34  kiwi
  Altered class to correctly locate objects from multiple databases.

  Revision 1.3  1999/03/16 00:23:17  kiwi
  *** empty log message ***

  Revision 1.2  1999/02/17 17:08:32  kiwi
  Altered class to use hierarchical parent/child app relationships

  Revision 1.1  1999/02/12 22:31:50  kiwi
  Create the Data class to abstract the workings of the DB


=head1 SEE ALSO

perl(1).

=cut
