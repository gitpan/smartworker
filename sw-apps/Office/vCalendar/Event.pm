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

package Office::vCalendar::Event;


#print "Event loading...\n";
#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for internal use only!!
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::Something::MyModule
#  Description of my module
#------------------------------------------------------------
#  CVS ID tag...
# $Id: Event.pm,v 1.1 1999/09/02 19:53:55 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);
use Office::vCalendar::Component qw( @zero_or_one_properties @either_or_properties @zero_or_more_properties );


#----------------------------------------------------------------------------------------------------------
# vEvent Properties (tags within vEvent blocks)                                                 
#
# The following are optional, but MUST NOT occur more than once

use Office::vCalendar::Tags::Class;
use Office::vCalendar::Tags::Created; 
use Office::vCalendar::Tags::Description; 
use Office::vCalendar::Tags::Dtstart; 
use Office::vCalendar::Tags::Geo; 
use Office::vCalendar::Tags::Last-mod; 
use Office::vCalendar::Tags::Location; 
use Office::vCalendar::Tags::Organizer; 
use Office::vCalendar::Tags::Priority; 
use Office::vCalendar::Tags::Dtstamp; 
use Office::vCalendar::Tags::Seq; 
use Office::vCalendar::Tags::Status; 
use Office::vCalendar::Tags::Summary; 
use Office::vCalendar::Tags::Transp; 
use Office::vCalendar::Tags::Uid; 
use Office::vCalendar::Tags::Url; 
use Office::vCalendar::Tags::Recurid; 

# either 'dtend' or 'duration' may appear in a 'eventprop', but 'dtend' and 'duration'
# MUST NOT occur in the same 'eventprop'

use Office::vCalendar::Tags::Dtend;
use Office::vCalendar::Tags::Duration;

# the following are optional, and MAY occur more than once
use Office::vCalendar::Tags::Attach;
use Office::vCalendar::Tags::Attendee;
use Office::vCalendar::Tags::Categories; 
use Office::vCalendar::Tags::Comment;
use Office::vCalendar::Tags::Contact;
use Office::vCalendar::Tags::Exdate;
use Office::vCalendar::Tags::Exrule;
use Office::vCalendar::Tags::Rstatus;
use Office::vCalendar::Tags::Related;
use Office::vCalendar::Tags::Resources; 
use Office::vCalendar::Tags::Rdate;
use Office::vCalendar::Tags::Rrule;
use Office::vCalendar::Tags::X_prop;
#----------------------------------------------------------------------------------------------------------

@ISA = qw(Office::vCalendar::Component AutoLoader);

$VERSION = '0.01';


# Preloaded methods go here.

# new_event takes no args or a Link String
sub new {
   #print "Ooh!  A new event!\n";
   my $classname = shift;
   my $property_tags;

   foreach my $property ('categories','class','created','description','dtstart','geo','last-mod',
	    'location','organizer','priority','dtstamp','seq','status',
	    'summary','transp','uid','url','recurid') {
       push(@zero_or_one_properties,$property);
       $property_tags .= $property . " ";
   }

   foreach my $property ('dtend','duration') {
       push(@either_or_properties,$property);
       $property_tags .= $property . " ";
   }

   foreach my $property ('attach','attendee','comment','contact','exdate','exrule',
			 'rstatus','related','resources','rdate','rrule','x-prop') {
       push(@zero_or_more_properties,$property);
       $property_tags .= $property . " ";
   }

   my $self = {
       'type'        => 'EVENT',
       'properties'   => $property_tags,
       # This first group of properties will appear 0-1 times each.
       'zero_or_one'  => \@zero_or_one_properties,
       'class'        => undef,
       'created'      => undef,
       'description'  => undef,
       'dtstart'      => undef,
       'geo'          => undef,
       'last-mod'     => undef,
       'location'     => undef,
       'organizer'    => undef,
       'priority'     => undef,
       'dtstamp'      => undef,
       'seq'          => undef,
       'status'       => undef,
       'summary'      => undef,
       'transp'       => undef,
       'uid'          => undef,
       'url'          => undef,
       'recurid'      => undef,
       # The next two properties are exclusive (i.e. one or the other will always be undef)
       # They will also appear 0-1 times
       'either_or'    => \@either_or_properties,
       'dtend'        => undef,
       'duration'     => undef,
       # The rest of the properties may appear 0+ times, and so should be referred to in an array context.
       'zero_or_more' => \@zero_or_more_properties,
       'attach'       => undef,
       'attendee'     => undef,
       'categories'   => undef,
       'comment'      => undef,
       'contact'      => undef,
       'exdate'       => undef,
       'exrule'       => undef,
       'rstatus'      => undef,
       'related'      => undef,
       'resources'    => undef,
       'rdate'        => undef,
       'rrule'        => undef,
       'x-prop'       => undef,
   };

   bless ($self, $classname);
   return $self;
}


1;    # All perl module must return true at the completion of loading
__END__

=head1 NAME

Office::vCalendar::Event - one line description of the module 

=head1 SYNOPSIS

   Give a simple example of the module's use

=head1 DESCRIPTION


=head1 METHODS

  new -  Creates a new instance
  some_other_function - ([param_name],value) -  detailed description of the use each function

=head1 PARAMETERS

	# well known parameters for this object, normally passed into the contruction as a hash, 
	# or gotten and set using the getValue() and setValue() calls.

  text - 
  image - 

=head1 AUTHOR

John F. Zmrotchel
HBE	zed@hbe.ca
August 9th, 1999

=head1 REVISION HISTORY

  $Log: Event.pm,v $
  Revision 1.1  1999/09/02 19:53:55  gozer
  New Namespace

  Revision 1.2  1999/08/18 21:25:59  jzmrotchek
  Cleaned up some code in the event_set() and event() methods of vCalendar.pm

   

=head1 SEE ALSO

perl(1), Office::vCalendar(3), RFC2445

=cut



print "To do!\n";

1;

