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

package SW::App::ContactManager::ContactList;

#-------------------------------------------------------------
# SW::App::ContactManager::ContactList
# ContactList provides the main functions for contact list
# management.
#-------------------------------------------------------------
# $Id: ContactList.pm,v 1.5 1999/09/20 19:51:16 gozer Exp $
#-------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use SW::Data;
use SW::App::ContactManager::Contact;
use SW::Util qw(inArray arrayIndex);

@ISA = qw(SW::Data);

$VERSION = '0.01';


#---------------------
# Definitions
#---------------------

sub TABLE_NAME () {"objects"}
sub PRIMARY_KEY () {"id"}
sub DATA_TYPE () {"CONTACTLIST"}
sub FIELD_NAMES () {}


#-------------------------------------------------------------------
# new
#
# Creates a new instance of a contact list
# If we get parameters, we load the specified contact list
# Because this method calls the Data new method, arguments should
# be the same!
#
# It works exactly like Contact.  The parameters to load a contact
# list from the database are like this :
#
# new SW::App::ContactManager::ContactList($app, $user, $cid);
#
# If a new contact list is to be created, go like this :
#
# new SW::App::ContactManager::ContactList($app, $user, '', 'CONTACTLISTTYPE');
#
# Once a contact list is opened, its data can be automatically
# accessed using $contactlist->{storage}->{___} where ___ is the
# name of the column in the database.
#
#-------------------------------------------------------------------

sub new
{
	my ($classname,$app,$id) = @_;
	my $self = $classname->SUPER::new($app,$id,DATA_TYPE);

	return $self;
}

#------------------------------------------------------------
# load (slight variation on new)
#------------------------------------------------------------

sub load 
{
   my ($classname,$app,$id) = @_;
#   print STDERR "cn $classname app $app user $user id $id\n";
   my $self = $classname->SUPER::new($app,$id,DATA_TYPE);

#   print STDERR "Done the load of ContactList\n";

   return $self;
}

#------------------------------------------------------------------
# addContact
#
# Adds a bunch of card IDs in the contact list.  The new
# card IDs are passed as an array.
#
# Returns the new length of the array.
#-------------------------------------------------------------------

sub addContact
{
	my $self = shift;
	my $cid = shift;

	# only add it if it isn't already there	

	if (! inArray($cid, $self->getContactList()))
	{
		SW::debug($self,"Adding new contact $cid to contact List ".$self->getValue('name'),4);
		push( @{$self->{storage}->{storage}}, $cid);
		# something of a hack, the tied hash isn't catching that this changes it!
		tied(%{$self->{storage}})->make_modified;
	}

}

#------------------------------------------------------------
# moveContact
#
#  moves the card given by the first card id into the list
#	specified by the second card id
#------------------------------------------------------------

sub moveContact
{
	my $self = shift;
	my $cid = shift;
	my $otherListId = shift;

	my $otherList = SW::App::ContactManager::ContactList->load($self, $otherListId);

	if (! ref($self) eq ref($otherList))
	{	
		SW::debug($self, "Error - invalid second argument, must also be of type ".ref($self),2);
		return undef;	
	}

	$otherList->addContact($cid);
	$self->deleteContactFromListOnly($cid);	

}

#--------------------------------------------------------------------
# deleteContact
#
# Removes a contact from the contact list, based on the card ID.
# This one works on a 'one CID' basis.  Doing it for a bunch of
# contacts in an array like addContact would be more complicated.
# It's the first time I use splice, so this function might not be
# perfect.
#
# Returns the deleted contact, undef if the contact CID doesn't exist.
#--------------------------------------------------------------------

sub deleteContact
{
	my $self = shift;
	my $cid = shift;

	SW::debug($self,"Deleting $cid from contacts",3);

	my $pos = arrayIndex($cid, $self->{storage}->{storage});

	$self->_deleteContactFromStorage($cid);
	my $newList = $self->getContactList;
   splice(@{$newList}, $pos, 1);
	$self->forceWrite();
}


#------------------------------------------------------------
# deleteContactFromListOnly
#------------------------------------------------------------

sub deleteContactFromListOnly
{
	my $self = shift;
	my $cid = shift;

	my $pos = arrayIndex($cid, $self->getContactList());

	splice(@{$self->getContactList()}, $pos, 1);
	$self->forceWrite();
}


#------------------------------------------------------------
#  _deleteContactFromStorage
#
#  takes one argument of a contact id
#
#   internal use only!!
#------------------------------------------------------------

sub _deleteContactFromStorage
{
	my $self = shift;
	my $cid = shift;

	my $contact = SW::App::ContactManager::Contact->new($self->{app}, $cid);

	$contact->delete();

}
#------------------------------------------------------------------
# getContactList
#
# Returns an array ref  containing the CIDs of the list, undef if
# the list is empty!!
#------------------------------------------------------------------

sub getContactList
{
	my $self = shift;
	my $list = $self->{storage}->{storage};
	return $list;
}


#------------------------------------------------------------------
# getNbContacts
#
# Returns the number of contacts in the array.  Easy
#------------------------------------------------------------------

sub getNbContacts
{
	my $self = shift;

	$self->{storage}->{storage} ? @{$self->{storage}->{storage}} : 0;
}


#---------------------------------------------------------------
# getContactByCID
#
# Searches the contact list for a contact whose CID is equal
# to the argument.
#
# Returns the contact in scalar context, an array containing
# the position of the contact and the contact in list context,
# and undef if no contact was found.  The position returning
# part of the function was implemented to facilitate the
# deleteContact function, but it might be useful in some other
# places.
#
# WARNING - WARNING - WARNING - WARNING - WARNING - WARNING!!!
#
# This function will probably not work, because of the way I
# try to fetch the app and the user.  I can't do it like that, but
# I'm not sure how.  I think Scott would know!  Maybe $self->{theApp}
# or something like that.  Same for the other getContactBy*** functions.
#
#---------------------------------------------------------------

 sub getContactByCID
 {
 	my $self = shift;
 	my $cid = shift;
 	my $pos = 0;
 
 	foreach my $contact ( @{$self->{storage}->{storage}} )
 	{
 		if( $contact == $cid )
 		{
 			my $c = SW::App::ContactManager::Contact->load($self->{app}, $contact);

 			return ($pos, $c);
 
 		}
 
 		$pos++;
 	}
 
 	return undef;
 }


#----------------------------------------------------------
# getContactByName  - bad protocol!  use getObjectList (modified
#								when I get around to it) this is very inefficient
#
# See getContactByCID.  Same thing, except that it searches
# through the names in the DB.
#----------------------------------------------------------

#  sub getContactByName
#  {
#  	my $self = shift;
#  	my $name = shift;
#  	my $pos = 0;
#  
#  	foreach my $cid ( @{$self->{storage}->{storage}} )
#  	{
#  		my $c = new SW::App::ContactManager::Contact();
#  		my $n = $c->getValue('name');
#  
#  		if( $n eq $name )
#  		{
#  			return ($pos, $c);
#  		}
#  
#  		$pos++;
#  	}
#  
#  	return undef;
#  }


#----------------------------------------------------------
# getContactByPos
#
# See getContactByCID.  Same thing, except that it searches
# through the positions in the contact list.
#
# Returns only a reference to the contact, because the
# position is obviously already known!
#----------------------------------------------------------

sub getContactByPos
{
	my $self = shift;
	my $pos = shift;

	my $cid = ${$self->{storage}->{storage}}[$pos];

	my $c = SW::App::ContactManager::Contact->load($self->{app}, $cid);

	return $c;
}



#---------------
# Return true
#---------------

1;

__END__

=head1 NAME

SW::App::ContactManager::ContactList - contact list for maintaining vCard-based contacts

=head1 SYNOPSIS

You want fries wit that!!!
Cheeseburger!  Wanna hotdog?


=head1 DESCRIPTION

 
=head1 METHODS

	new -  Creates a new instance

	addContact($contact_info) - adds a contact to the list
	deleteContact() - deletes a contact from the list

=head1 PARAMETERS


=head1 AUTHOR

Jean-Francois Brousseau
HBE   krapht@hbe.ca
July 21/99

=head1 REVISION HISTORY

$Log: ContactList.pm,v $
Revision 1.5  1999/09/20 19:51:16  gozer
Temp fix for the lost DataValues

Revision 1.4  1999/09/11 07:07:38  scott
Made substantial changes to the database schema and data storage models.
Now there's three global tables called datamap, dataaccess, and
datainfo.  These hide the many other more data specific tables
where the infomation is actually stored.

Revision 1.3  1999/09/11 07:06:18  scott
Tweaking these apps so they work with the new datamap model
(actually they don't change at all unless they were being bad
and writing their own SQL).

Revision 1.2  1999/09/07 16:23:19  gozer
Fixed pod syntax errors

Revision 1.1  1999/09/02 20:11:07  gozer
New namespace convention

Revision 1.3  1999/08/27 21:24:51  fhurtubi
Ok, I should really test my mods before committing them :) Was missing a SW::Data::xxx
call

Revision 1.2  1999/08/27 21:22:54  fhurtubi
Fixed a typo

Revision 1.1  1999/08/27 21:21:23  fhurtubi
Moved these files from /SW/Data/ to /apps/ContactManager and removed calls
to SW::Data::

Revision 1.24  1999/08/20 01:58:31  scott
small bug fix

Revision 1.23  1999/08/14 00:21:26  scott
ContactList - move, delete, edit all work!!!!

DBIStore - bug fixes

Revision 1.22  1999/08/13 20:22:53  scott
implemented deleteContact, _deleteContactFromStorage (name?) deleteContactFromListOnly
and moveContact

Revision 1.21  1999/08/13 16:48:35  scott
hang on - doesn't work

Revision 1.20  1999/08/13 16:02:51  scott
Bug fixes with ContactList

Revision 1.19  1999/08/13 14:32:52  scott
Bug fixes on database access, and getting ContactManager working

Revision 1.18  1999/08/12 19:44:02  scott
Fixed a dumb bug in protected() that was stopping data from being written in the db

Revision 1.17  1999/08/11 15:55:35  fhurtubi
Removed getName / setName

Revision 1.16  1999/08/11 15:27:04  scott
Small bug fixes on the code I wrote last night

Revision 1.15  1999/08/10 15:46:38  fhurtubi
Fixed bugs with calls to getName() that weren't needed

Revision 1.14  1999/08/05 21:46:54  krapht
Couple of changes, mostly doc for Fred while I'm gone.

Revision 1.13  1999/08/04 20:45:31  krapht
Removed the loadContact function, which was useless

Revision 1.12  1999/08/04 19:45:40  krapht
Added a getNbContacts function to get the number of contacts in a list

Revision 1.11  1999/07/30 20:00:31  krapht
Added a getContactByPos function!

Revision 1.10  1999/07/30 19:51:35  krapht
Added the possibility to push many CIDs on the list with addContact

Revision 1.9  1999/07/30 19:24:26  krapht
New version of Contact by Scott, ContactList changed appropriately.
Both still need a little work, but it is minor.

Revision 1.8  1999/07/28 22:25:00  fhurtubi
Fixed little bugs

Revision 1.7  1999/07/28 22:13:47  krapht
Removed the Autoloader part

Revision 1.6  1999/07/28 21:37:13  krapht
Removed updateContact, added methods to change the name of the contact list

Revision 1.5  1999/07/28 20:55:35  krapht
Being rewritten!!  Not accurate!

Revision 1.4  1999/07/22 18:25:50  krapht
Small changes, mostly experimental!


=head1 SEE ALSO

perl(1).

=cut
