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

package Office::vCalendar;

#----------------------------------------------------------------------
# vCalendar                                                            
#  A module to create, parse, and manipulate vCalendar objects in Perl.
#----------------------------------------------------------------------
#  CVS ID tag...                                                       
# $Id: vCalendar.pm,v 1.2 1999/09/06 19:20:02 gozer Exp $         
#----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Office::vCalendar::Event;
use Office::vCalendar::ToDo;
use Office::vCalendar::Journal;

use vars qw($VERSION);
$VERSION=0.01;

sub init_vCalendar {
#--------------------------------------------
# Useage: 
#         $vCalendar->init_vCalendar;
#
# Purpose:
#         Formats a vCalendar object with no
#         initially defined properties other
#         that its data structure.
#--------------------------------------------

    my $warnings;
    my $errors;

    #my %vCalendar = {};
    #my $vCalendar = \%vCalendar;

    my @vevents;
    my $vevents = \@vevents;
    my $event_properties = "class created description dtstart geo last-mod location organizer priority dtstamp seq status ";
    $event_properties   .= "summary transp uid url recurid dtend duration attach attendee categories comment contact ";
    $event_properties   .= "exdate exrule rstatus related resources rdate rrule x-prop";

    my @vtodos;
    my $vtodos = \@vtodos;

    my @vjournals;
    my $vjournals = \@vjournals;



    my $vCalendar = {
	"warnings"          => $warnings,
	"errors"            => $errors,
	"prodid"            => '-//HBE Perl Office::vCalendar//',
	"version"           => '2.0',
	"vevents"           => $vevents,
	"vevent_properties" => $event_properties,
	"vtodos"            => $vtodos,
	"vjournals"         => $vjournals
	};
}

sub new
#------------------------------------------------------
# Useage:  
#         $vCalendar = Office::vCalendar->new($options);
#                     WHERE
#         $options = nothing, 'warnings', 'errors' or 
#                    'warnings errors'
#
# Purpose:
#         Instantiates a new vCalendar object.  The 
#         parameters 'warnings' and 'errors' will turn
#         on warning and error messages respectively.
#------------------------------------------------------
{
   my $classname = shift;
   my $vCalendar = init_vCalendar;
   my $options = shift;
   if (index($options,'warnings')) { 
       $vCalendar->{'warnings'} = 1;
   }
   if (index($options,'errors')) {
       $vCalendar->{'errors'} = 1;
   }
   bless $vCalendar, $classname;
   return $vCalendar;
}


sub loadcalendar
#------------------------------------------------------------
#  takes an existing data structure (slurped in from the
#		database) and blesses it as a vCalendar
#------------------------------------------------------------
{
	my $className = shift;
	my $data = shift;

	bless $data, $className;
	return $data;
}
	
sub new_event {
#--------------------------------------------
# Useage:
#         $vCalendar->new_event;
#
# Purpose:
#         Assigns a new (empty) VEVENT object
#         to the vCalendar object.           
#--------------------------------------------
    my $vCalendar = shift;
    my $event = new Office::vCalendar::Event;
    push (@{$vCalendar->{'vevents'}},$event);
    return $vCalendar;
}


sub event_set {
#----------------------------------------------------------------------------------------
# Useage:
#         $vCalendar->event_set($eventnum,$property,$property_index.$subproperty,%values);
#                       WHERE                               
#         $eventnum       = index of event
#         $property       = property name
#         $property_index = property index or 'new'
#         $subproperty    = subproperty (always includes "value", may include others.
#         %values         = hashtable of values in the form <valuename> => <value>
#                        OR
#         $vCalendar->event_set($eventnum,$property,%values);     
#                       WHERE
#         $eventnum        = index of event OR 'new'
#         $property        = property name
#         %values          = the values to be set for that property. Allowable key values
#                            are documented elsewhere.  (Or will be, when I get around to
#                            it...
#
# Issues:  
#         Currently doesn't check if you're properly calling the methods for use with
#         none-or-one, none-or-more, or either-or values.  Assumes none-or-one or
#         either-or (but with no exclusivity checking) for the moment.
#
# Purpose:
#         Sets event subtags.  If subproperty is blank, @values should be
#         a complete set of values for the property requested. (This will
#         be more fully documented in a later version).
#----------------------------------------------------------------------------------------

    my $vCalendar = shift;
    my $vevent = shift;
    my $property = shift;
    my $values = shift;

    #----------------------------------------------------------
    # Method overloading check.  This parameter is only used in
    # the case of zero-or-more attributes, and determines which
    # one of them is to be set.
    #----------------------------------------------------------
    if (@_ == 1) {
	my $property_index = shift;
    }

    #--------------------------------------------------------------------
    # Check that $values is being sent in proper hash context.  One of the
    # more common mistakes.
    #---------------------------------------------------------------------
    if (ref($values) eq "HASH") { 
	# Start single-property processing block.
	if (($vevent < $vCalendar->event_count) && ($vevent ne 'new')) {
	    #-----------------------------------------#
	    # Good Case 1: Numeric index within range.#
	    #-----------------------------------------#
	    if ((index $vCalendar->{'vevent_properties'},$property) >= 0) {
		my $callproperty = "\u$property";
		my $outprop = "new Office::vCalendar::Tags::" . $callproperty . "(\$values)";
		my $newprop = eval $outprop;
		$vCalendar->{'vevents'}->[$vevent]->{$property} = $newprop;
	    } elsif (($property ne '') && ($vCalendar->{'errors'})) {
		print STDERR "Error: EVENT has no '" . $property . "' property, and so cannot set it.\n";
	    } else {
		print STDERR "Error: Can't call event_set without specifying a property to set.\n";
	    }
    
	} elsif ($vevent eq 'new') {
	    #---------------------------------------#
	    # Good Case 2: New subtag instantiated. #
	    #---------------------------------------#
	    my $callproperty = "\u$property";
	    my $outprop = "new Office::vCalendar::Tags::" . $callproperty . "(\$values)";
	    my $newprop = eval $outprop;
	    #print "Testit: $testit->{'value'}\n";
	    #print Dumper($testit);
	    my $new_index = $vCalendar->event_count;
	    %{$vCalendar->{'vevents'}->[$new_index]}->{$property} = $values;
	    
	} else {
	    #-----------#
	    # Bad Case. #
	    #-----------#
	    #print "Bad case.\n";
	    if ($vCalendar->{'warnings'} && event_count() < $vevent) {
		print STDERR "Warning: No events currently defined for this calendar.\n";
	    } elsif ($vCalendar->{'errors'}) {
		print STDERR "Warning: Index value used in calling event_set incorrect (value was '" . $vevent . "')\n";
	    }
	}
	# End single-property processing block.
    } else {
	if ($vCalendar->{'errors'}) {
	    print STDERR "Error: Property values (third parameter) passed to event_set not in hash context.\n";
	}
    }
    return $vCalendar;
}


sub event_count {
#-------------------------------------------
# Useage:
#         $vCalendar->event_count;
#
# Purpose:
#         Returns number of events currently 
#         defined for a particular vCalendar
#         object.
#-------------------------------------------
    my $vCalendar = shift;
    my $count;
    if (defined @{$vCalendar->{'vevents'}}) {
	$count =  @{$vCalendar->{'vevents'}};
    } else {
	$count = -1;
    }
    return $count;
}


sub new_todo {
#--------------------------------------------
# Useage:
#         $vCalendar->new_todo;
#
# Purpose:
#         Assigns a new (empty) VTODO object
#         to the vCalendar object.           
#--------------------------------------------
    my $vCalendar = shift;
    my $todo = new Office::vCalendar::ToDo;
    push (@{$vCalendar->{'vtodos'}},$todo);
    return $vCalendar;
}


sub todo_set {
#--------------------------------------------------------------
# Useage:
#         $vCalendar->todo_set($todonum,$property,$value);
#                       WHERE                               
#         $todonum = index of todo OR 'new'
#         $property = property name
#         $value    = value of property
#
# Purpose:
#         Sets todo subtags.
#---------------------------------------------------------------
    my $vCalendar = shift;
    my $vtodo = shift;
    my $property = shift;
    my @values = @_;
    print "(vCalendar.pm - todo_set) Passed: " . $vtodo . " Counted: " . $vCalendar->todo_count . "\n";
    #print Dumper(@values);
    if ($vtodo < $vCalendar->todo_count) {
	#-----------------------------------------#
	# Good Case 1: Numeric index within range.#
	#-----------------------------------------#
	$vCalendar->{'vtodos'}->[$vtodo]->{$property} = \@values;
    } elsif ($vtodo eq 'new') {
	#---------------------------------------#
	# Good Case 2: New subtag instantiated. #
	#---------------------------------------#
	$vCalendar->new_todo;
	my $todo_number = $vCalendar->todo_count - 1;
	$vCalendar->{'vtodos'}->[$todo_number]->{$property} = \@values;

    } else {
        #-----------#
	# Bad Case. #
	#-----------#
	if ($vCalendar->{'warnings'} && todo_count() < $vtodo) {
	    print STDERR "Warning: No todos currently defined for this calendar.\n";
	} elsif ($vCalendar->{'errors'}) {
	    print STDERR "Warning: Index value used in calling todo_set incorrect (value was '" . $vtodo . "')\n";
	}
    }
    return $vCalendar;
}

sub todo_count {
#-------------------------------------------
# Useage:
#         $vCalendar->todo_count;
#
# Purpose:
#         Returns number of todos currently 
#         defined for a particular vCalendar
#         object.
#-------------------------------------------
    my $vCalendar = shift;
    my $count;
    if (defined @{$vCalendar->{'vtodos'}}) {
	$count =  @{$vCalendar->{'vtodos'}};
    } else {
	$count = -1;
    }
    return $count;
}


sub new_journal {
#--------------------------------------------
# Useage:
#         $vCalendar->new_journal;
#
# Purpose:
#         Assigns a new (empty) VJOURNAL object
#         to the vCalendar object.           
#--------------------------------------------
    my $vCalendar = shift;
    my $journal = new Office::vCalendar::Journal;
    push (@{$vCalendar->{'vjournals'}},$journal);
    return $vCalendar;
}


sub journal_set {
#--------------------------------------------------------------
# Useage:
#         $vCalendar->journal_set($journalnum,$property,$value);
#                       WHERE                               
#         $journalnum = index of journal OR 'new'
#         $property = property name
#         $value    = value of property
#
# Purpose:
#         Sets journal subtags.
#---------------------------------------------------------------
    my $vCalendar = shift;
    my $vjournal = shift;
    my $property = shift;
    my @values = @_;
    print "(vCalendar.pm - journal_set) Passed: " . $vjournal . " Counted: " . $vCalendar->journal_count . "\n";
    #print Dumper(@values);
    if ($vjournal < $vCalendar->journal_count) {
	#-----------------------------------------#
	# Good Case 1: Numeric index within range.#
	#-----------------------------------------#
	$vCalendar->{'vjournals'}->[$vjournal]->{$property} = \@values;
    } elsif ($vjournal eq 'new') {
	#---------------------------------------#
	# Good Case 2: New subtag instantiated. #
	#---------------------------------------#
	$vCalendar->new_journal;
	my $journal_number = $vCalendar->journal_count - 1;
	$vCalendar->{'vjournals'}->[$journal_number]->{$property} = \@values;
    } else {
        #-----------#
	# Bad Case. #
	#-----------#
	if ($vCalendar->{'warnings'} && journal_count() < $vjournal) {
	    print STDERR "Warning: No journals currently defined for this calendar.\n";
	} elsif ($vCalendar->{'errors'}) {
	    print STDERR "Warning: Index value used in calling journal_set incorrect (value was '" . $vjournal . "')\n";
	}
    }
    return $vCalendar;
}

sub journal_count {
#-------------------------------------------
# Useage:
#         $vCalendar->journal_count;
#
# Purpose:
#         Returns number of journals currently 
#         defined for a particular vCalendar
#         object.
#-------------------------------------------
    my $vCalendar = shift;
    my $count;
    if (defined @{$vCalendar->{'vjournals'}}) {
	$count =  @{$vCalendar->{'vjournals'}};
    } else {
	$count = -1;
    }
    return $count;
}



#------------------------------------#
# Display (content return) routines. #
#------------------------------------#

sub event {
    my $vCalendar = shift;
    my $vevent_output = "";
    #--------------------------------------
    # Base case: Return all vEvent objects. 
    #--------------------------------------
    if (1 == 1) {
	$vevent_output .= "BEGIN:VEVENT\n";

	foreach my $event ($vCalendar->{'vevents'}) {
	    #---------------------------------------------
	    # First display all single-instance type tags.
	    #---------------------------------------------
	    foreach my $zero_or_one (@{$event->[0]->{'zero_or_one'}}) {
		if ($event->[0]->{$zero_or_one} ne "") {
		    #$vevent_output .= "Test:\n";
		    $vevent_output .= fold($event->[0]->{$zero_or_one}->show_tag);
		}
	    }
	    #------------------------------------------------------------
	    # Then all multiple instance type tags.  (Currently disabled)
	    #------------------------------------------------------------
	    foreach my $zero_or_more (@{$event->[0]->{'zero_or_more'}}) {
		if ($event->[0]->{$zero_or_more} ne "") {
		    #$vevent_output .= $zero_or_more . " = " . $event->[0]->{$zero_or_more} . "\n";
		}
	    }
	    #-------------------------------------------------------------
	    # Then all 'either-or' tags.  This is effectively the same as
	    # the zero-or-one type tags, as checking should be done at the
	    # setting level.  It is kept seperate in case this changes.
	    #-------------------------------------------------------------
	    foreach my $either_or (@{$event->[0]->{'either_or'}}) {
		if ($event->[0]->{$either_or} ne "") {
		    $vevent_output .= fold($event->[0]->{$either_or}->show_tag);		    
		}
	    }
	}
    } 
    $vevent_output .= "END:VEVENT\n";
    return $vevent_output;
}

sub event_property {
#----------------------------------------------------------------------------------
# Useage:
#         $vCalendar->event_property($event_index,$tag_name,$tag_property);
#                     WHERE
#         $event_index  = number of the event you want to extract a value from
#         $tag_name     = the name of the tag type you want to extract a value from
#         $tag_property = the name of the property you want to extract
#
# Issues: 
#         This is pretty much only a zero-or-one extractor right now.  Expect
#         overloading to allow for zero-or-many tags later. 
#
# Purpose:
#         Extracts a specific property from a specific tag of a specific event. 
#
#----------------------------------------------------------------------------------
    my $vCalendar    = shift;
    my $event_index  = shift;
    my $tag_name     = shift;
    my $tag_property = shift;
#    my $tag_index   = shift; # Only used for "zero or more" tags.  Not yet implemented.


    my $subprop = $vCalendar->{'vevents'}->[$event_index]->{$tag_name}->{$tag_property};
    return $subprop;
}

sub todo {
    my $vCalendar = shift;
    my $vevent_output = "";
    #--------------------------------------
    # Base case: Return all vEvent objects. 
    #--------------------------------------
    $vevent_output .= "BEGIN:VTODO\n";

    $vevent_output .= "END:VTODO\n";
    return $vevent_output;
}

sub journal {
    my $vCalendar = shift;
    my $vevent_output = "";
    #--------------------------------------
    # Base case: Return all vJournal objects. 
    #--------------------------------------
    $vevent_output .= "BEGIN:VJOURNAL\n";

    $vevent_output .= "END:VJOURNAL\n";
    return $vevent_output;
}




# comment (all)
# completed (1)
# contact (all)
# created (all)
# description (all)
# dtend (1)
# dtstamp (all)
# dtstart (all)
# due (1)
# duration (2)
# exdate (all)
# exrule (all)
# geo (2)
# last-mod (all)
# location (2)
# organizer (all)
# percent (1)
# priority (2)
# rdate (all)
# recurid (all)
# related (all)
# resources (2)
# rrule (all)
# rstatus (all)
# seq (all)
# status (all)
# summary (all)
# transp (1)
# uid (all)
# url (all)
# x-prop (all)



sub calendar {
    my $vCalendar = shift;
    my $output = "";

    $output .= "BEGIN:VCALENDAR\n";
    $output .= "VERSION:" . $vCalendar->{'version'} .  "\n";
    $output .= "PRODID:" . $vCalendar->{'prodid'} . "\n";

    for (my $x = 0; $x <= ($vCalendar->event_count - 1); $x++) {
	$output .= $vCalendar->event($x);
    }
#    for (my $x = 0; $x <= ($vCalendar->todo_count - 1); $x++) {
#	$output .= $vCalendar->todo($x);
#    }
#    for (my $x = 0; $x <= ($vCalendar->journal_count - 1); $x++) {
#	$output .= $vCalendar->journal($x);
#    }

    $output .= "END:VCALENDAR\n";

    return $output;
}

sub fold {
    my @inlines = split(/\n/,shift);
    my $shortline;
    my $outline;
    
    foreach my $line (@inlines) {
	my $foldswitch = 'N';
	if (length($line) > 75) {
	    $foldswitch = 'Y';
	    while (length($line) > 75) {
		$shortline = substr($line,0,75);
		$line = substr($line,75);
		$outline .= $shortline . "\n ";
	    }
	}
	$outline .= $line;
	$outline .= "\n";
    }
    
    return $outline;
}

sub unfold {
#---------------------------------#
# Useage:                         #
#      unfold(@lines_to_unfold);  #
#                                 #
# Purpose:                        #
#      'Unfolds' multiple-line    #
#      single entry vCard fields  #
#      in the manner described in #
#      RFC 2426.                  #
#---------------------------------#
    my @inlines = @_;
    my $outline = "";
    my @outlines;

    foreach my $line (@inlines) {
	$line =~ s/\n$//;
	if ($line =~ /^ /) {
	    $line =~ s/^ //;
	    $outline .= $line;
	} else {
	    #$outline .= "\n";
	    push(@outlines,$outline);
	    $outline = $line;
	}
    }
    return(@outlines);
}



1;    # All perl module must return true at the completion of loading
__END__

=head1 NAME

Office::vCalendar.pm - A module to create, parse, and manipulate vCalendar objects.

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

John F. Zmrotchek
HBE	zed@hbe.ca
Jan 12/99

=head1 REVISION HISTORY
  $Log: vCalendar.pm,v $
  Revision 1.2  1999/09/06 19:20:02  gozer
  Switched package to vCalendar so MakeMaker recurses subdirs correctly

  Revision 1.1  1999/09/02 19:53:51  gozer
  New Namespace

  Revision 1.6  1999/08/19 21:39:38  jzmrotchek
  Minor bugfixes, error checking and cleanup.  (affects event_set)

  Revision 1.5  1999/08/19 16:39:28  jzmrotchek
  Removed an annoying "print" statement bug. :P

  Revision 1.4  1999/08/19 16:05:25  jzmrotchek
  Added some internal docs for vCalendar.pm.   Folks should be able to make
  heads or tails of the module by reading the code now.

  Revision 1.3  1999/08/18 21:25:49  jzmrotchek
  Cleaned up some code in the event_set() and event() methods of vCalendar.pm

  Revision 1.2  1999/08/18 17:29:57  scott
  added the loadvalendar method for bootstrapping an event out
  from the database

  Revision 1.1  1999/08/18 15:47:39  jzmrotchek
  Ladies and gentlemen, the first version of the Office::vCalendar module is now online.

=head1 SEE ALSO

perl(1), vCard(3), RFC2445

=cut


