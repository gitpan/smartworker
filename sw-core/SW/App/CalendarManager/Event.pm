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

package SW::App::CalendarManager::Event;

#-------------------------------------------------------------
# SW::App::CalendarManager::Event
#  Event
#
#-------------------------------------------------------------
# $Id: Event.pm,v 1.6 1999/11/15 18:17:32 gozer Exp $
#-------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA $AUTOLOAD);

use SW::Data;
use Office::vCalendar;

@ISA = qw(SW::Data);

$VERSION = '0.01';

# constants   Scott added these
#	have a look inside SW::Data::ObjectStore and SW::Data to see what they do

sub TABLE_NAME () {"events"}
sub PRIMARY_KEY () {"id"}
sub DATA_TYPE () {"EVENT"}
sub EVAL_FIELDS () { my $ref = ["vcalendar"] } 

# There is still much work to do here, especially concerning the database
# access method.
#

#-------------------------------------------------------------------
# new  (inherited from SW::Data)
#
# Creates a new instance of an event
# Each contact has a user identification code (UID) and a 
# contact identification number (eID).  Changes to the contact(vCalendar) will
# be made directly into the database.
#
#  called as CalendarManager::Event->load($app, $user, $cid);
#		to retrieve one an existing contact with a known cid ($cid)
#
#   or CalendarManager::Event->new($app,$user);
#		to create a new one
#
#    all the fields contained in the events table for given
#		$eid will appear in $self->{storage}->{___}  for instance
#
#-------------------------------------------------------------------

sub new
{
	my ($classname,$app,$user,$id) = @_;

	my $self = $classname->SUPER::new($app,$user,$id,DATA_TYPE);

	print STDERR "got back from the new of data, creating a vcalendar..\n";

	$self->{storage}->{vcalendar} = new Office::vCalendar();

	return $self;
}


#------------------------------------------------------------
# load ( actually a variation on new, but for clarity sake
#			we'll do it like this )
#------------------------------------------------------------
sub load
{
	my ($classname,$app,$user,$id) = @_;

	my $self = $classname->SUPER::new($app,$user,$id,DATA_TYPE);

	Office::vCalendar->loadcalendar ($self->{storage}->{vcalendar});


	# hack so that we don't update the DB just for loading the card in ..
	tied(%{$self->{storage}})->make_unmodified();

	return $self;
}



#-------------------------------------------------------------
# getEID
#
# Returns the value of the card ID of the contact.
#-------------------------------------------------------------

sub getEID
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
	return $self->{user}->getUid;
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
#		an objectaccess table for Events, the permission
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

	print STDERR "DESTROYing Event\n";


	SW::debug($self,"summary - ".SW::Util::flatten($self->{storage}->{vcalendar}->{summary}),5);
	SW::debug($self,"dtstart - ".SW::Util::flatten($self->{storage}->{vcalendar}->{dtstart}),5);
	SW::debug($self,"dtend - ".SW::Util::flatten($self->{storage}->{vcalendar}->{dtend}),5);
	
	if (tied (%{$self->{storage}})->is_modified())
	{
		$self->{storage}->{summary} = $self->event_property(0,'summary','value');
		$self->{storage}->{dtstart} = $self->event_property(0,'dtstart','value');
		$self->{storage}->{dtend} = $self->event_property(0,'dtend','value');
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
	$self->{storage}->{vcalendar}->$cmdName(@_); 		
}

#---------------
# Return true
#---------------

1;

__END__

=head1 NAME

SW::App::ContactManager::Event - SmartWorker wrapper implementing to give a vCalendar some storage capabilities

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

 Scott Wilson
 scott@hbe.ca
Aug 18/99

=head1 REVISION HISTORY

$Log: Event.pm,v $
Revision 1.6  1999/11/15 18:17:32  gozer
Added Liscence on pm files

Revision 1.5  1999/09/11 07:07:35  scott
Made substantial changes to the database schema and data storage models.
Now there's three global tables called datamap, dataaccess, and
datainfo.  These hide the many other more data specific tables
where the infomation is actually stored.

Revision 1.4  1999/09/11 07:06:15  scott
Tweaking these apps so they work with the new datamap model
(actually they don't change at all unless they were being bad
and writing their own SQL).

Revision 1.3  1999/09/07 16:23:18  gozer
Fixed pod syntax errors

Revision 1.2  1999/09/02 20:38:13  fhurtubi
For vCard stuff, I added Office::vCard and for groupManager, I've added SW::App::

Revision 1.1  1999/09/02 20:11:06  gozer
New namespace convention

Revision 1.4  1999/08/19 22:33:50  fhurtubi
Removed mentions of Contact (bad copy/paster Scott!!! :)

Revision 1.3  1999/08/19 20:53:25  fhurtubi
Bug hunter :) put dtend instead of dtstart

Revision 1.2  1999/08/19 16:38:37  fhurtubi
Modified new->vCalendar to new->Parse::vCalendar

Revision 1.1  1999/08/18 17:23:27  scott
Hot off my keyboard!


=head1 SEE ALSO

perl(1).

=cut
