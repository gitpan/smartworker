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

package SW::Data::Folder;

#------------------------------------------------------------
# SW::Data::Folder
# An overloaded version of SW::Data, providing abstraction
# for database entries considered like directories.
#
#------------------------------------------------------------
# $Id: Folder.pm,v 1.27 1999/11/22 18:17:49 krapht Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::Application;
use SW::Data;


@ISA = qw(SW::Data);

$VERSION = '0.01';


#------------------------------------------------------------
# new - method
#
# Constructor used to create new Folder objects.  Returns
# a reference to the object.
#------------------------------------------------------------

sub new
{
	my $classname = shift;
	my ($app,$objectid,$parentid) = @_;

	# Set the datatype and appid for the file manager

	my $locking_request = ($objectid ? "READ" : "WRITE" );

	my $self = $classname->SUPER::new({
													app => $app,
													id => $objectid,
													datatype => "FOLDER",
													appid => "FILEMGR",
													request_lock => $locking_request,
												}); 

	if(!$objectid)
	{
		if(!$parentid)
		{
			$parentid = -1;
		}

		if($parentid eq "-1") { print STDERR "Created a ROOT folder\n"; }

		$self->addFolder($parentid);
	}

	return $self;
}


#------------------------------------------------------------
# empty
#
# Removes all the 'files' from the folder
#
# TODO : Make it work
#------------------------------------------------------------

sub empty
{
	$_[0]->getContents();
}


#------------------------------------------------------------
# getParent - method
#
# Returns the first entry in the folder, which is the ID
# of its parent folder.  If the folder happens to be a root
# folder, undef is returned.
#
# IN: nothing
# OUT: an integer representing the ID of the parent folder
#------------------------------------------------------------

sub getParent
{
	my $parent = (split(',',$_[0]->getValue('storage')))[0];
	$parent =~ s/^\*//;

	($parent eq "-1") ? ( return undef) : (return $parent);
}


#------------------------------------------------------------
# setParent - method
#
# Sets the value of the parent folder to the ID passed as a
# parameter.
# Returns the new parent ID.
#------------------------------------------------------------

sub setParent
{
	my ($self,$id) = @_;

	my @entries = split(',',$self->getValue('storage'));

	splice(@entries,0,1);

	$id = '*' . $id;

	unshift(@entries,$id);

	$self->setStorage('storage',(join(',',@entries).','));
}


#------------------------------------------------------------
# getContents
#
# Checks the contents of the folder and returns it.
# If a document type is specified, getContents will only
# return documents associated with that document type
#
#
# Returns an array of data object IDs, undef if no document
# was found
#------------------------------------------------------------

sub getContents
{
	my @entries = split(',',$_[0]->getValue('storage'));

	splice(@entries,0,1); # Remove the parent entry

	foreach (@entries) { $_ =~ s/^\*//; }

	(@entries) ? (return @entries) : (return);
}


#------------------------------------------------------------
# getFolders
#
# Returns an array containing the folder IDs of the children
# folders.
#------------------------------------------------------------

sub getFolders
{
	my $self = shift;
	my @tmp;

	my @entries = split(',',$self->getValue('storage'));

	splice(@entries,0,1); # Remove the parent entry

	foreach (@entries)
	{
		if($_ =~ /^\*/)
		{
			$_ =~ s/\*//;
			push(@tmp,$_);
		}
	}

	return @tmp;
}


#------------------------------------------------------------
# getDocuments
#
# Returns an array containing the document IDs of the
# children documents.
#------------------------------------------------------------

sub getDocuments
{
	my $self = shift;
	my @tmp;

	my @entries = split(',',$self->getValue('storage'));

	foreach (@entries)
	{
		if($_ !~ /^\*/)
		{
			push(@tmp,$_);
		}
	}

	return @tmp;
}


#------------------------------------------------------------
# addDocument & addFolder
#
# addDocument adds a document to the current document entries
# in the folder.
#
# addFolder adds a folder the same way as addDocument.
#
# The main difference is that folders have a star prefix, for
# faster sorting and identification.
#
#------------------------------------------------------------

sub addDocument
{
	my $self = shift;

	foreach (@_)
	{
		$self->{storage}->{storage} .= $_ . ",";
	}
}


sub addFolder
{
	my $self = shift;

	foreach (@_)
	{
		$self->{storage}->{storage} .= '*'.$_.',';
	}
}



#------------------------------------------------------------
# unlinkEntry
#
# This function looks for a document ID in the folder.  If
# the ID is found, the entry is removed from the folder, but
# the actual document is not removed from the database.
#
# See deleteDocument for complete removal
#------------------------------------------------------------

sub unlinkEntry
{
	my ($self,$docid) = @_;

	my @docs = split(',',$self->{storage}->{storage});

	for(my $i=0;$i<@docs;$i++)
	{
		if(($docs[$i] eq $docid) || ($docs[$i] eq "*$docid"))
		{
			splice(@docs,$i,1);
			$self->{storage}->{storage} = join(',',@docs) . ',';

			last;
		}
	}

}

sub delete 
{
	return 1;
}


#------------------------------------------------------------
# deleteEntry - method (possibly recursive)
#
# This function performs a recursive deletion of all entries
# in all folders contained in the base folder, or a single
# delete on the document.
#
# To be used with care, as it will easily purge a whole tree.
#------------------------------------------------------------

sub deleteEntry
{
	my ($self,$docid) = @_;

	my $inf = SW::Data::getInfoFromID($docid);

	if(!$inf) { return undef; }  # Couldn't find info on ID, not a good sign

	print STDERR "######## in deleteEntry: we are about to delete id $docid\n";


	# If there was a problem removing its contents, we should at least remove
	# the ID before, so it doesn't appear to the user, and he can't generate
	# an error by clicking on it and trying to retrieve undefined values
	# JF

	$self->unlinkEntry($docid);

	if($inf->{type} eq "FOLDER") # Must work recursively
	{
		print STDERR "### It's a folder, so we empty it first\n";

		my $f = new SW::Data::Folder($self->{app},$docid);

		if(!$f)
		{
			print STDERR "######### Hmmmmm, error opening f, weird!\n";
			return undef;
		}

		my @folders = $f->getFolders();

		# Get rid of the files first

		print STDERR "####### Getting rid of these IDs : " . join(',',$f->getDocuments())."\n";

		if ($f->getDocuments()) {
			SW::Data::deleteObject($f->getDocuments());
		}

		# Now go up in the tree to remove all useless stuff

		foreach (@folders)
		{
			print STDERR "########### Calling deleteEntry for ID $_\n";
			$f->deleteEntry($_);
		}

		# We cleaned the folder, we can now delete it
	}

	if(!SW::Data::deleteObject($docid))
	{
		return undef;
	}

}


#------------------------------------------------------------
# hide
#
# This function does a lot of stuff
#
#------------------------------------------------------------

sub hide
{
	my $self = shift;

	return 0;
}


#------------------------------------------------------------
# fileExists - method
#
# Retrives information from the contents of the folder and
# checks if the string passed as argument is already used as
# a filename in the folder.
#
# Returns 0 if the filename wasn't found, or 1 if it was
# found.
#------------------------------------------------------------

sub fileExists
{
	my ($self,$name,$type) = @_;

	foreach($self->getFolders(),$self->getDocuments())
	{
		my $info = SW::Data::getInfoFromID($_);

		if(($info->{name} eq $name) && ($info->{type} eq $type))
		{
			return 1;
		}
	}

	return 0;
}


#------------------------------------------------------------
# sortByName
#
# Does a permanent sort on the folders and the documents by
# alphabetical order
#------------------------------------------------------------

sub sortByName
{
	my $self = shift;

	my @tmp_f = $self->getFolders();
	my @tmp_d = $self->getDocuments();

	foreach (@tmp_f)
	{




	}

	foreach (@tmp_d)
	{



	}

	$self->{storage}->{storage} = join(',',@tmp_f) . join(',',@tmp_d) . ',';

}


#------------------------------------------------------------
# sortByDate
#
# Does a permanent sort on the folders and the documents by
# timestamp, from more recent to older
#------------------------------------------------------------

sub sortByDate
{
	my $self = shift;

}



1;

__END__

=head1 NAME

SW::Data::Folder - data abstraction to simulate directories

=head1 SYNOPSIS

	my $cwd = new SW::Data::Folder($folderName);

=head1 DESCRIPTION

This class implements folder objects used for a virtual filesystem
mapped on top of the database entries.  Folders are simply a list of
IDs, the first being the ID of the parent folder, and the other ones
of the folders contained.  IDs preceded with a star sign are for
other folders, and regular IDs are for documents.

Folders can be used to build a tree hierarchy resembling that of a
regular operating system.

=head1 METHODS

 new - Creates a new instance

 setParent - sets the ID of the parent folder
 getParent - returns the ID of the parent folder

 getContents - returns a list IDs of the files contained in the folder

 getFolders - returns a list of all the IDs of the folders only
 getDocuments - returns a list of all the IDs of the documents only

 addFolder - adds the folder ID to the list of its contents
 addDocument - adds the document ID to the list of its contents 

 unlinkEntry - removes the ID of the document from the list of the folder
 without removing the information from the database

 deleteEntry - removes the ID of the document from the list of the folder
 and performs a cleanup of the information associated with the ID in the
 database

 fileExists - checks to see if a certain file is already present in the
 folder

 sortByDate - makes a sort on the IDs depending on the creation date
 of each entry
=back

=head1 AUTHOR

 Jean-Francois Brousseau <krapht@hbe.ca>
 HBE Software
 Aug 26/99

=head1 REVISION HISTORY

  $Log: Folder.pm,v $
  Revision 1.27  1999/11/22 18:17:49  krapht
  Added some documentation

  Revision 1.25  1999/10/26 19:07:20  krapht
  Removed the splicing shit in new

  Revision 1.24  1999/10/25 21:32:32  scott
  *** empty log message ***

  Revision 1.22  1999/10/18 05:41:23  scott
  adding file locking code

  Revision 1.21  1999/10/05 16:28:28  fhurtubi
  Added a sub delete { return 1; } method to work with Data.pm deleteObject

  Revision 1.20  1999/10/04 22:47:01  fhurtubi
  Fixed 2 little bugs

  Revision 1.19  1999/10/04 20:48:13  krapht
  Added fileExists, to check if a file with the same name and type already
  exists.

  Revision 1.18  1999/09/29 21:25:43  krapht
  Added error handling (so it stops crashing the server), new functions, blablabla

  Revision 1.17  1999/09/23 19:47:45  krapht
  Fixed problems with read-only value when modifying @_

  Revision 1.16  1999/09/23 15:45:22  krapht
  Changed the values in new so datatype = FOLDER and appid = FILEMGR
  by default

  Revision 1.15  1999/09/23 15:36:33  krapht
  Minor fixes

  Revision 1.14  1999/09/22 21:41:36  krapht
  Changed the way Folders are stored (parentid first)

  Revision 1.13  1999/09/21 23:25:39  krapht
  Changed getContents so it strips the star before a folder ID.

  Revision 1.12  1999/09/21 22:58:56  krapht
  Removed a debugging message and fixed a thing (not sure what, though)!

  Revision 1.11  1999/09/20 14:30:45  krapht
  Changes to use the new method of getting session, user, etc.

  Revision 1.10  1999/09/15 21:32:54  fhurtubi
  Fixed query in DBIStore, Changed LOTS of things in File.pm (and this is
  not over yet). Removed a buggy line in Folder

  Revision 1.9  1999/09/14 02:24:31  krapht
  Fixed a bug in getContents, it didn't remove the star before folder IDs

  Revision 1.8  1999/09/13 18:17:12  krapht
  Added new methods : getFolders, getDocuments, etc.

  Revision 1.7  1999/09/08 16:19:04  krapht
  First official working version?  Changed code in some of the methods.  It
  seems to work OK.

  Revision 1.6  1999/09/01 01:26:48  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.5  1999/08/30 20:23:15  krapht
  Removed the Exporter stuff

  Revision 1.4  1999/08/29 22:56:16  krapht
  Added some new functions in there

  Revision 1.3  1999/08/27 21:43:10  krapht
  Fixed a small bug.  Was registered as a SW::Application (thanks to the
  template : ), but is really SW::Data

  Revision 1.2  1999/08/27 19:57:55  krapht
  No idea what I changed in there!

  Revision 1.1  1999/08/26 23:21:07  krapht
  New class for dealing with folders


=head1 SEE ALSO

perl(1).

=cut
