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

package SW::App::CalendarManager::Calendar;

#-------------------------------------------------------------
#   CalendarManager::Calendar
# Calendar provides the main functions for calendar list
# management.
#-------------------------------------------------------------
# $Id: Calendar.pm,v 1.5 1999/11/15 18:17:32 gozer Exp $
#-------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::Data;
use SW::Util qw(inArray arrayIndex);

@ISA = qw(SW::Data );

$VERSION = '0.01';


#---------------------
# Definitions
#---------------------

sub TABLE_NAME () {"objects"}
sub PRIMARY_KEY () {"id"}
sub DATA_TYPE () {"CALENDAR"}
sub FIELD_NAMES () {}


#-------------------------------------------------------------------
# new
#
# Creates a new instance of a calendar
# If we get parameters, we load the specified calendar
# Because this method calls the Data new method, arguments should
# be the same!
#
# new CalendarManager::Calendar($app, $user, $cid);
#
# If a new calendar is to be created, go like this :
#
# new CalendarManager::Calendar($app, $user, '', $self->DATA_TYPE());
#
# Once a calendar is opened, its data can be automatically
# accessed using $calendar->{storage}->{___} where ___ is the
# name of the column in the database.
#
#-------------------------------------------------------------------

sub new
{
	my ($classname,$app,$user,$id) = @_;
	my $self = $classname->SUPER::new($app,$user,$id,DATA_TYPE);

	return $self;
}

#------------------------------------------------------------
# load (slight variation on new)
#------------------------------------------------------------

sub load 
{
   my ($classname,$app,$user,$id) = @_;
   my $self = $classname->SUPER::new($app,$user,$id);

   return $self;
}

#------------------------------------------------------------------
# addEvent
#
# Adds a bunch of event IDs in the calendar.  The new
# event IDs are passed as an array.
#
# Returns the new length of the array.
#-------------------------------------------------------------------

sub addEvent
{
	my $self = shift;
	my $eid = shift;
	my $year = shift;
	my $month = shift;
	my $day = shift;

	# only add it if it isn't already there	

	if (! inArray($eid, $self->getEventList($year,$month,$day)))
	{
		SW::debug($self,"Adding new event $eid to calendar ".$self->getValue('name'),4);
		push( @{$self->{storage}->{storage}->{$year}->{$month}->{$day}}, $eid);
		# something of a hack, the tied hash isn't catching that this changes it!
		tied(%{$self->{storage}})->make_modified;
	}

}

#------------------------------------------------------------
# moveEvent
#
#  moves the event given by the first event id from this 
#	calendar into the calendar
#	specified by the second id
#------------------------------------------------------------
# 
# sub moveEvent
# {
# 	my $self = shift;
# 	my $eid = shift;
# 	my $otherCalId = shift;
# 
# 	my $otherCal = SW::App::CalendarManager::Calendar->load($self, $self->{user},$otherCalId);
# 
# 	if (! ref($self) eq ref($otherCal))
# 	{	
# 		SW::debug($self, "Error - invalid second argument, must also be of type ".ref($self),2);
# 		return undef;	
# 	}
# 
# 	$otherCal->addEvent($eid);
# 	$self->deleteEventFromListOnly($eid);	
# 
# }

#--------------------------------------------------------------------
# deleteEvent
#
#
# Returns the deleted event, undef if the event eid doesn't exist.
#--------------------------------------------------------------------

sub deleteEvent
{
	my $self = shift;
	my $eid = shift;
	my $year = shift;
	my $month = shift;
	my $day = shift;


	SW::debug($self,"Deleting $eid from events",3);

	my $pos = arrayIndex($eid, $self->{storage}->{storage}->{$year}->{$month}->{$day});

	$self->_deleteEventFromStorage($eid);
	my $newList = $self->getEventList($year, $month, $day);
   splice(@{$newList}, $pos, 1);
	$self->forceWrite();
}


#------------------------------------------------------------
# deleteEventFromListOnly
#------------------------------------------------------------

sub deleteEventFromListOnly
{
	my $self = shift;
	my $eid = shift;
	my $year = shift;
	my $month = shift;
	my $day = shift;

	my $pos = arrayIndex($eid, $self->getEventList($year, $month, $day));

	splice(@{$self->getEventList($year, $month, $day)}, $pos, 1);
	$self->forceWrite();
}


#------------------------------------------------------------
#  _deleteEventFromStorage
#
#  takes one argument of a event id
#
#   internal use only!!
#------------------------------------------------------------

sub _deleteEventFromStorage
{
	my $self = shift;
	my $eid = shift;

	my $event = SW::App::CalendarManager::Event->load($self->{app}, $self->{user}, $eid);

	$event->delete();


}
#------------------------------------------------------------------
# getEventList
#
# Returns an array ref  containing the EIDs of the list, undef if
# the list is empty!!
#------------------------------------------------------------------

sub getEventList
{
	my $self = shift;
	my $year = shift;
	my $month = shift;
	my $day = shift;
	my $list = [];

	if (!$day)
	{
		foreach my $d (keys %{$self->{storage}->{storage}->{$year}->{$month}})
		{
			unshift (@$list, @{$self->{storage}->{storage}->{$year}->{$month}->{$d}});
		}
	}
	else
	{
		$list = $self->{storage}->{storage}->{$year}->{$month}->{$day};
	}

	return $list;
}


#------------------------------------------------------------------
# getNbEvents
#
# Returns the number of events in the array.  Easy
#------------------------------------------------------------------

sub getNbEvents
{
	my $self = shift;
	my $year = shift;
	my $month = shift;
	my $day = shift;

	$self->{storage}->{storage} ? @{$self->{storage}->{storage}->{$year}->{$month}->{$day}} : 0;
}


#---------------------------------------------------------------
# getEventByCID
#
# Searches the calendar for an event whose CID is equal
# to the argument.
#
# Returns the event in scalar context, an array containing
# the position of the event and the event in list context,
# and undef if no event was found.  The position returning
# part of the function was implemented to facilitate the
# deleteEvent function, but it might be useful in some other
# places.
#
# WARNING - WARNING - WARNING - WARNING - WARNING - WARNING!!!
#
# This function will probably not work, because of the way I
# try to fetch the app and the user.  I can't do it like that, but
# I'm not sure how.  I think Scott would know!  Maybe $self->{theApp}
# or something like that.  Same for the other getEventBy*** functions.
#
#---------------------------------------------------------------

 sub getEventByCID
 {
 	my $self = shift;
 	my $eid = shift;
 	my $pos = 0;
 
 	foreach my $ev ( @{$self->{storage}->{storage}} )
 	{
 		if( $ev == $eid )
 		{
 			my $e = SW::App::CalendarManager::Event->load($self->{app}, $self->{user}, $ev);

 			return ($pos, $e);
 
 		}
 
 		$pos++;
 	}
 
 	return undef;
 }


#----------------------------------------------------------
# getEventByPos
#
# See getEventByCID.  Same thing, except that it searches
# through the positions in the calendar.
#
# Returns only a reference to the event, because the
# position is obviously already known!
#----------------------------------------------------------

sub getEventByPos
{
	my $self = shift;
	my $pos = shift;

	my $eid = ${$self->{storage}->{storage}}[$pos];

	my $e = SW::App::CalendarManager::Event->load($self->{app}, $self->{user}, $eid);

	return $e;
}

#---------------
# Return true
#---------------

1;

__END__

=head1 NAME

SW::App::CalendarManager::Calendar - calendar list for maintaining vCalendar-based events

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 METHODS

	new -  Creates a new instance

	addEvent($event_id,$year,$month,$day) - adds an event to the list
	deleteEvent($event_id, $year, $month, $day) - deletes an event from the list 
																	eventually I'll write it smarter so you don't
																	have to specify the date, that's annoying
																	but easy for my for now!

=head1 PARAMETERS


=head1 AUTHOR

Scott Wilson
HBE   scott@hbe.ca
Aug 18/99

=head1 REVISION HISTORY

$Log: Calendar.pm,v $
Revision 1.5  1999/11/15 18:17:32  gozer
Added Liscence on pm files

Revision 1.4  1999/09/11 07:07:35  scott
Made substantial changes to the database schema and data storage models.
Now there's three global tables called datamap, dataaccess, and
datainfo.  These hide the many other more data specific tables
where the infomation is actually stored.

Revision 1.3  1999/09/11 07:06:15  scott
Tweaking these apps so they work with the new datamap model
(actually they don't change at all unless they were being bad
and writing their own SQL).

Revision 1.2  1999/09/07 16:23:18  gozer
Fixed pod syntax errors

Revision 1.1  1999/09/02 20:11:06  gozer
New namespace convention

Revision 1.4  1999/08/27 21:12:37  fhurtubi
Removed call to SW::Data::Contact which has nothing to do there!!

Revision 1.3  1999/08/19 22:33:50  fhurtubi
Removed mentions of Contact (bad copy/paster Scott!!! :)

Revision 1.2  1999/08/19 18:14:47  fhurtubi
fixed missing $'s with year/month/day

Revision 1.1  1999/08/18 17:23:27  scott
Hot off my keyboard!


=head1 SEE ALSO

perl(1).

=cut
