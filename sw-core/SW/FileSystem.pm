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

package SW::FileSystem;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# $Id: FileSystem.pm,v 1.2 1999/11/15 18:17:32 gozer Exp $
#------------------------------------------------------------


use strict;
use vars qw(@ISA $VERSION @SW_EXPORT);

use SW;

use SW::Exporter;

@ISA = qw(SW::Exporter);

@SW_EXPORT = (openFile closeFile readFromFile writeToFile setLock releaseLock);



#------------------------------------------------------------
# new - method
#
#------------------------------------------------------------

sub new
{
	my ($classname) = @_;

	# Empty hash for now
	# Data gets entered as users log on

	my $self = {};

	bless($self,$classname);

	return $self;
}


#------------------------------------------------------------
# setRoot - method
#
# Sets the current value of the root id
#------------------------------------------------------------

sub setRoot
{
	my ($self,$id) = @_;
	my $uid = SW->user->getUid();

	if(exists($self->{$uid}))
	{
		$self->{$uid}->{root} = $id;
	}

}


#------------------------------------------------------------
# getRoot - method
#
# Returns the value of the root folder, or undef if it
# doesn't exist.
#------------------------------------------------------------

sub getRoot
{
	my ($self) = @_;
	my $uid = SW->user->getUid();

	if(exists($self->{$uid}))
	{
		return $self->{$uid}->{root};
	}

	return;
}


#------------------------------------------------------------
# setWd - method
#
# Sets the working directory to the one passed as argument.
#
# Returns the value of the new path, or undef if the path is
# invalid or no argument has been provided.
#------------------------------------------------------------

sub setWd
{
	my ($self,$path) = @_;
	my $uid = SW->user->getUid();
	my $new;


	if(!$path)
	{
		return undef;
	}

	if(substr($path,1,0) eq '/')
	{
		# We are dealing with an absolute path


	}
	else # Relative path
	{



	}

	$self->{$uid}->{wd} = $new;
}


#------------------------------------------------------------
# getWd - method
#
# Returns the ID of the working directory.
#------------------------------------------------------------

sub getWd
{
	my ($self) = @_;
	my $uid = SW->user->getUid();

	if(exists($self->{$uid}))
	{
		return $self->{$uid}->{wd};
	}

	return;
}


#------------------------------------------------------------
# setMask - method
#
# setMask requires one argument, a value corresponding to
# the bitmask for file creation.  This value will be the
# value assigned to all files that will be created by the
# application after the call to setMask.
#
# Returns the new value of the bitmask.
#------------------------------------------------------------

sub setMask
{
	my ($self,$mask) = @_;
	my $uid = SW->user->getUid();

	if(exists($self->{$uid}))
	{
		return $self->{$uid}->{mask} = $mask;
	}

	return;
}


#------------------------------------------------------------
# getMask - method
#
# Returns the current value of the bitmask used when files
# are created, or undef if it doesn't exist.
#------------------------------------------------------------

sub getMask
{
	my ($self) = @_;
	my $uid = SW->user->getUid();

	if(exists($self->{$uid})
	{
		return $self->{$uid}->{mask};
	}

	return;
}


#------------------------------------------------------------
# getQuota - method
#
#------------------------------------------------------------

sub getQuota
{
	my ($self) = @_;
	my $uid = SW->user->getUid();

	return $self->{$uid}->{quota};
}


#------------------------------------------------------------
# createFile - method
#
# Creates a new file without opening it.
#------------------------------------------------------------

sub createFile
{
	my ($self,$name,$perms) = @_;

	my $file = new SW::Data($self, "");

	if(!$file)
	{
		return;
	}

	$file->setName($name);
	$file->setUserPermissions($perms);

	return $file;
}


#------------------------------------------------------------
# openFile - method
#
# This method provides a standard way of opening database
# entries.
#
# Returns a value associated with the opened file (sorta
# like a file descriptor :)
#------------------------------------------------------------

sub openFile
{
	my ($filename,$perms) = @_;




	return $fd;
}


#------------------------------------------------------------
# closeFile - method
#
# This method must be called after an application is
# finished using a file.  It makes sure no locks are still
# on the file, cleanup, etc.
#
#------------------------------------------------------------

sub closeFile
{
	my ($filename) = @_;

}


#------------------------------------------------------------
# readFromFile - method
#
# Read
#
#
#------------------------------------------------------------

sub readFromFile
{
	my ($self,$fd,$buf,$sz) = @_;





}


#------------------------------------------------------------
# writeToFile - method
#
# Writes the data contained in buf to the file pointed to by
# fd, up to a maximum of sz (if provided).
#
#------------------------------------------------------------

sub writeToFile
{
	my ($self,$fd,$buf,$sz) = @_;



}


#------------------------------------------------------------
# setLock - method
#
# This method tries to set a lock on a specified entry in the
# database.
#
# Returns 1 if the lock was set, or 0 if there is already a
# lock.
#------------------------------------------------------------

sub setLock
{
	my $self = shift;


	return 1;
}


#------------------------------------------------------------
# removeLock - method
#
# This method removes a lock that the user
#
# Returns 1 if the lock was removed, or 0 if there was no
# lock, or if the lock is not owned by the caller.
#------------------------------------------------------------

sub removeLock
{
	my $self = shift;

	my $query = "SELECT lock FROM DATAMAP";

	return 1;
}


#------------------------------------------------------------
# _registerUser - method
#
# INTERNAL USE ONLY
#
# Puts a new user entry in the filesystem so that information
# on this user's current path, root, etc. can be kept inside
# fs.
#------------------------------------------------------------

sub _registerUser
{
	my ($self,) = @_;

	my $uid = SW->user->getUid();

	$self->{$uid} = {
						root	=> SW->user->getHome(),
						wd		=> SW->user->getHome(),
#						quota	=> Not implemented,
	};

	return $self->{$uid};
}


#------------------------------------------------------------
# _getNewFd - method
#
# INTERNAL USE ONLY
#------------------------------------------------------------

sub _getNewFd
{



}



#------------------------------------------------------------
# _getIdFromFilename - method
#
# INTERNAL USE ONLY
#
# Makes a search through the user's filesystem to find the
# ID of the file with the name passed as argument.
#
# Returns the ID of the file, or undef if the file was not
# found.
#------------------------------------------------------------

sub _getIdFromFilename
{
	my ($fn) = @_;

	my $root = SW->user->getHome();

	my $f = new SW::Data::Folder($self,$root);
	$f->getFolders();

	


}


1;

__END__

=head1 NAME
 
SW::FileSystem
 
=head1 SYNOPSIS
 

 
=head1 DESCRIPTION

A module that provides an interface similar to a filesystem between the
SmartWorker applications and the database access.
 
 
=head1 METHODS
 
	new -  Creates a new instance

	setWd - set the current working directory
	getWd - get the value of the current working directory

	openFile - open a file
	readFromFile - read information from an opened file
	writeToFile - write information to an opened file
	closeFile - close an opened file

	setLock - put a lock on a file
	releaseLock - remove a lock on a file
	_registerUser - add a user entry in the filesystem info table




 
=head1 PARAMETERS
 
 
=head1 AUTHOR
 
Jean-Francois Brousseau
HBE   krapht@hbe.ca
August 11/99
 
=head1 REVISION HISTORY

$Log: FileSystem.pm,v $
Revision 1.2  1999/11/15 18:17:32  gozer
Added Liscence on pm files

Revision 1.1  1999/10/12 21:32:34  krapht
Mostly a skeleton version of a filesystem interface for applications
Many easy functions written, need to work on the difficult part (open file
caching and stuff)



=head1 SEE ALSO

perl(1)

=cut
