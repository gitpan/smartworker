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

package Office::vCalendar::Journal;


#print "Journal loading...\n";
#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for internal use only!!
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::Something::MyModule
#  Description of my module
#------------------------------------------------------------
#  CVS ID tag...
# $Id: Journal.pm,v 1.1 1999/09/02 19:53:55 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);
use Office::vCalendar::Component;

@ISA = qw(Office::vCalendar::Component);

$VERSION = '0.01';


# Preloaded methods go here.

# new takes no args or a Link String
sub new
{
   my $classname = shift;

   my $self = {
       'type'    => 'JOURNAL',
   };

   bless ($self, $classname);
   return $self;
}


1;    # All perl module must return true at the completion of loading
__END__

=head1 NAME

Office::vCalendar::Journal - one line description of the module 

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

  $Log: Journal.pm,v $
  Revision 1.1  1999/09/02 19:53:55  gozer
  New Namespace

  Revision 1.2  1999/08/18 21:25:59  jzmrotchek
  Cleaned up some code in the event_set() and event() methods of vCalendar.pm

   

=head1 SEE ALSO

perl(1), Office::vCalendar(3), RFC2445

=cut



print "To do!\n";

1;







