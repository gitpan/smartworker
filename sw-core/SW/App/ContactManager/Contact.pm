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

package SW::App::ContactManager::Contact;

#-------------------------------------------------------------
# ContactManager::Contact
# Contact
#
#-------------------------------------------------------------
# $Id: Contact.pm,v 1.7 1999/11/15 18:17:32 gozer Exp $
#-------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA $AUTOLOAD);

use SW::Data;
use Office::vCard;

@ISA = qw(SW::Data);

$VERSION = '0.01';

# constants   Scott added these
#	have a look inside SW::Data::ObjectStore and SW::Data to see what they do

sub TABLE_NAME () {"contacts"}
sub PRIMARY_KEY () {"id"}
sub DATA_TYPE () {"CONTACT"}
sub EVAL_FIELDS () { my $ref = ["vcard"] } 

#-------------------------------------------------------------------
# new  (inherited is SW::Data)
#
# Creates a new instance of a Contact
# Each contact has a user identification code (UID) and a 
# contact identification number (CID).  Changes to the contact(vCard) will
# be made directly into the database.
#
#  called as ContactManager::Contact->load($app, $user, $cid);
#		to retrieve one an existing contact with a known cid ($cid)
#
#  or ContactManager::Contact->new($app,$user);
#		to create a new one
#
#    all the fields contained in the contacts table for given
#		$cid will appear in $self->{storage}->{___}  for instance
#
#-------------------------------------------------------------------

sub new
{
	my ($classname,$app,$id) = @_;

	my $self = $classname->SUPER::new($app,$id,DATA_TYPE);

	$self->{storage}->{vcard} = new Office::vCard();

#       $vcard->importcard(@lines_from_vcard_10); # to load a card, it would be something like this

	return $self;
}


#------------------------------------------------------------
# load ( actually a variation on new, but for clarity sake
#			we'll do it like this )
#------------------------------------------------------------
sub load
{
	my ($classname,$app,$id) = @_;

	my $self = $classname->SUPER::new($app,$id,DATA_TYPE);

	Office::vCard->loadcard ($self->{storage}->{vcard});


	# hack so that we don't update the DB just for loading the card in ..
	tied(%{$self->{storage}})->make_unmodified();

#       $vcard->importcard(@lines_from_vcard_10); # to load a card, it would be something like this

	return $self;
}



#-------------------------------------------------------------
# getCID
#
# Returns the value of the card ID of the contact.
#-------------------------------------------------------------

sub getCID
{
	my $self = shift;
	return $self->getValue('id');
}


#-------------------------------------------------------------
# getUID
#
# Returns the value of the user ID of the contact
#-------------------------------------------------------------

sub getUserID
{
	my $self = shift;
	return SW->user->getUid;
}

#-------------------------------------------------------------
# getTimeStamp
#
# Returns the value of the timestamp of the vcard information
#
# Note that there is no setTimeStamp because the timestamp is
# managed by mySQL, whenever the data in the DB changes.
#-------------------------------------------------------------

sub getTimeStamp
{
	my $self = shift;

	return $self->getValue('timestamp');
}


#------------------------------------------------------------
#  add some error checking to these!!!
#------------------------------------------------------------
sub getValue
{
	my $self = shift;
	my $key = shift;

	if( defined($self->{storage}->{$key}) )
	{
		return $self->{storage}->{$key};
	}
	else {
		return undef;
	}
}



#-------------------------------------------------------------
# setValue
#
# Sets the value of the key to value in the database.
# Returns the value entered, undef if an error occured.
#
# Note that only the user whose ID equals the card UID
# managed by mySQL, whenever the data in the DB changes.
#-------------------------------------------------------------

sub setValue
{
	my $self = shift;
	my $key = shift;
	my $val = shift;

	if( $self->{user} == $self->{storage}->{uid} )
	{
		$self->{storage}->{$key} = $val;
	} else {
		return undef;
	}

}

#------------------------------------------------------------
# overriding userPermissions ... for now we haven't implemented
#		an objectaccess table for Contacts, the permission
#	   is assumed by the list for now.... (actually for now we just
#		blow it wide open .. I'll fix this soon!)
#------------------------------------------------------------
sub userPermissions
{
	my $self = shift;

	return SW::Constants::FULL_ACCESS();
}

#---------------
# DESTROY
#	sneaky little move here ... we'll peek in and see if the
#	object is dirty - if so we copy name, email, tel into the
#	exsposed fields for browse list building
#
#	someone please fill this in with appropriate calls
#	to the vcard methods.
#---------------
sub DESTROY
{
	my $self = shift;

	SW::debug($self,"email - ".SW::Util::flatten($self->{storage}->{vcard}->{email}),5);
	SW::debug($self,"tel - ".SW::Util::flatten($self->{storage}->{vcard}->{phone_numbers}),5);
	
	if (tied (%{$self->{storage}})->is_modified())
	{
		$self->{storage}->{firstName} = $self->name("first");
		$self->{storage}->{lastName} = $self->name("last");
		$self->{storage}->{email} = $self->email(0, "address");
		$self->{storage}->{tel} = $self->telephone(0, "number");
	}
}

 sub AUTOLOAD
 {
	my $self = shift;
 	my $cmdName = $AUTOLOAD;
 
 	$cmdName =~ s/^.*:://;   # discard package info

	#return if  $cmdName =~ /[^A-Z]/;  # make sure we don't forward DESTROY or
												 #  other all caps methods
	return if $cmdName =~ /^DESTROY$/;  # make sure we don't forward DESTROY or
	#											 #  other all caps methods

#	SW::debug($self,"autoloaded $cmdName forwarded to the vCard",5);

#	tied(%{$self->{storage}})->{vcard}->$cmdName(@_); 		
#	tied(%{$self->{storage}->{vcard}})->$cmdName(@_); 		
	$self->{storage}->{vcard}->$cmdName(@_); 		
}

#---------------
# Return true
#---------------

1;

__END__

=head1 NAME

ContactManager::Contact - SmartWorker wrapper implementing to give a vCard some storage capabilities

=head1 SYNOPSIS

	my $contact = new SW::Contact($self, $user);
	$contact->set_addr(0, "CITY", "Barcelona");

=head1 DESCRIPTION

 	Wrapper bringing a vCard into smartworker to provide data storage capabilities to it.

=head1 METHODS

	new -  Creates a new instance
	getUID - Returns the value of the user ID
	getCID - Returns the value of the card ID


=head1 PARAMETERS

	

=head1 AUTHOR

Jean-Francois Brousseau
HBE   krapht@hbe.ca
July 21/99

=head1 REVISION HISTORY

$Log: Contact.pm,v $
Revision 1.7  1999/11/15 18:17:32  gozer
Added Liscence on pm files

Revision 1.6  1999/09/20 19:51:16  gozer
Temp fix for the lost DataValues

Revision 1.5  1999/09/11 07:07:38  scott
Made substantial changes to the database schema and data storage models.
Now there's three global tables called datamap, dataaccess, and
datainfo.  These hide the many other more data specific tables
where the infomation is actually stored.

Revision 1.4  1999/09/11 07:06:17  scott
Tweaking these apps so they work with the new datamap model
(actually they don't change at all unless they were being bad
and writing their own SQL).

Revision 1.3  1999/09/07 16:23:19  gozer
Fixed pod syntax errors

Revision 1.2  1999/09/02 20:38:16  fhurtubi
For vCard stuff, I added Office::vCard and for groupManager, I've added SW::App::

Revision 1.1  1999/09/02 20:11:07  gozer
New namespace convention

Revision 1.2  1999/08/30 00:02:39  scott
debugging

Revision 1.1  1999/08/27 21:21:23  fhurtubi
Moved these files from /SW/Data/ to /apps/ContactManager and removed calls
to SW::Data::

Revision 1.27  1999/08/17 15:45:34  scott
disabled the permission checking on the individual contacts for now...

Revision 1.26  1999/08/13 22:55:51  scott
fixed evil bug in Contact.pm AUTOLOAD

Revision 1.25  1999/08/13 21:55:10  scott
oops!  changed autoloaded to only block DESTROY

Revision 1.24  1999/08/13 18:22:29  fhurtubi
Fixed email method call in DESTROY

Revision 1.23  1999/08/13 17:09:46  scott
commented out debugging

Revision 1.22  1999/08/13 16:27:01  scott
Added a little hack to take the data structure read in from the
db and re-bless it into a vCard

Revision 1.21  1999/08/13 16:02:51  scott
Bug fixes with ContactList

Revision 1.20  1999/08/13 14:51:05  scott
implemented the vcard calls with some autoload tricks I discovered I actually don't need ...
oh well - it works anyhow

Revision 1.19  1999/08/13 14:39:09  scott
added ISA vcard back in

Revision 1.18  1999/08/13 14:32:52  scott
Bug fixes on database access, and getting ContactManager working

Revision 1.17  1999/08/12 21:06:19  fhurtubi
Added vCard functions in DESTROY

Revision 1.16  1999/08/12 20:02:01  scott
fixed DESTROY  -> tied

Revision 1.15  1999/08/12 19:44:02  scott
Fixed a dumb bug in protected() that was stopping data from being written in the db

Revision 1.14  1999/08/12 14:45:20  fhurtubi
Little bug correction

Revision 1.13  1999/08/11 15:32:36  fhurtubi
fixed a my

Revision 1.12  1999/08/11 05:50:55  scott
Changed Contact so that it inherits both SW::Data and vcard.
A bit more is yet to be done to make sure that he vcard methods are
writing directly into the tied has ($self->{storage})

Contains a cool hack I in DESTROY. Peeks into the tied hash to see if it's changed.
and if so, it copies the values for the common browse list fields
into their respective db fields

Revision 1.11  1999/08/09 13:59:13  fhurtubi
Corrected some syntax bugs

Revision 1.10  1999/07/30 19:24:26  krapht
New version of Contact by Scott, ContactList changed appropriately.
Both still need a little work, but it is minor.

Revision 1.9  1999/07/29 17:04:24  krapht
Minor changes!

Revision 1.8  1999/07/29 16:09:23  krapht
Major changes, especially on DB access, simplified.  Removed the setvCard
function because changes will be brought on single parts of it.

Revision 1.6  1999/07/28 20:55:35  krapht
Being rewritten!!  Not accurate!

Revision 1.5  1999/07/25 02:22:20  scott
Scott added some ocnstant declarations for primary key and table name

Revision 1.4  1999/07/22 18:25:50  krapht
Small changes, mostly experimental!


=head1 SEE ALSO

perl(1).

=cut
