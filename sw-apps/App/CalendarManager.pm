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

#!/usr/bin/perl -I/usr/local/apache/dev/v1

use SW::Util::Prep;

#===================================================================#
#
# CalendarManager.pm v1.0
# CalendarManager for SmartWorker
#
# Author: Frederic Hurtubise (fred@hbe.ca)
#
# Revisions:
#       v1.0    - Automatically create a list on first event creation
#  AUG 20 99    - Add, delete, edit creation
#		- Month scroller (left panel)
#		- Day scroller (upper right panel)
#		- Click on a day to bring up daily calendar
#		- Days that have events are colored on calendar
#		- Link to go back to current day
#		- Default view is from 8am to 8pm, but, if there is
#		  an event starting outside this span, a link to show
#		  full day is provided
#		- Only day events are permitted right now.
#		- Right now, there is no error checking (not checking if
#		  events are overlapping, or if end time is before start
#		  time)
#               - vCalendar compliant
#               - French and English support
#
# Author: Frederic Hurtubise (fred@hbe.ca)
#
#==================================================================#
# $Id: CalendarManager.pm,v 1.5 1999/09/11 07:07:32 scott Exp $
#==================================================================#

#==================================================================#
# DEFINITION
#==================================================================#

package SW::App::CalendarManager;

use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE);

use SW::App::CalendarManager::Text;
use SW::App::CalendarManager::Calendar;
use SW::App::CalendarManager::Event;

use SW::Application;
use SW::Data;
use SW::GUIElement;
use SW::Panel;
use SW::Util::Cal;
use Date::Manip;

@ISA = qw(SW::Application);

#==================================================================#
# CONSTANTS
#==================================================================#

sub APP_ID () {'CALENDARMGR'}
sub DATA_TYPE () {"CALENDAR"}

#==================================================================#
# PROGRAM
#==================================================================#

#------------------------------------------------------------------#
# Create a new object
#------------------------------------------------------------------#
sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);

	# might be a good idea to change the default lang to user pref if existant
	$self->{stringTable} = SW::App::CalendarManager::Text->new();

	$self->buildTable;

# TODO ** Maybe a user preference would be good here
	$self->{currLang} = $self->getLanguage(); # language used to draw UIs

	$self->setValue("name", APP_ID);

	return $self;
} # sub new

#------------------------------------------------------------------#
# Registering the app
#------------------------------------------------------------------#
sub swInitApplication
{
        my $self = shift;

        SW::debug($self, "Registering Application ".APP_ID,2);
        $self->{master}->{appRegistry}->register(APP_ID, DATA_TYPE, "This is the calendar manager app");
}

#-------------------------------------------------------------------#
# Validate the user identity
#-------------------------------------------------------------------#
sub swValidateUser
{
        my $self = shift;

        SW::debug($self,"Validating user - ".$self->{user}->{user});

        return 0 if ($self->{user}->{user} eq "guest");
        return 1;
} # sub swValidateUser

#-------------------------------------------------------------------#
# Dispatches various actions to the right method
#-------------------------------------------------------------------#
sub swDispatcher
#SW TransOrder 15
{
	my $self = shift;

	my $appState = $self->getSessionValue('appState');

	if ($appState eq "") { $self->buildMainDailyUI; }
	else { 
		$self->$appState(); 
		if ($self->{UImsg} ne "") {
			$self->buildMainDailyUI($self->{UImsg});
		}
	}
} # swDispatcher

#------------------------------------------------------------------#
# Builds the main UI, ie: with monthly calendar to the left,
# and daily calendar to the right
#------------------------------------------------------------------#
sub buildMainDailyUI
{
	my $self = shift;
	my $msg = shift; # if this is not empty, we need to print a message 

	$self->deleteSessionValue("appState"); # make sure this isn't a leftover from a callback

	my $mainPanel = $self->getPanel();
	$mainPanel->setValue('name',"SmartWORKER Calendar");

	# its getting on my nerves to have to go from 0 to 1 to get January because of the way date works..so i created a dummy element
	my @months=qw(dummy January February March April May June July August September October November December);
	my @mlen=qw(dummy 31 28 31 30 31 30 31 31 30 31 30 31);
	my @wdays=qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
#	my @periods = qw(Day Week Month Year);
	my @periods = qw(Day Week);
	my @date = localtime(time());  
	$date[4]++; # since months starts at 0 in the time function, I'd like to start at 1 so this can be obvious
	if ($date[5] < 1900) { $date[5] += 1900; } # y2k compliant

	my $selectedYear = $self->getDataValue('year')		||
		$self->getSessionValue('year')			||
		$date[5];
	my $selectedMonth = sprintf ("%02d", $self->getDataValue('month') 	|| # either new value that just got selected
		$self->getSessionValue('month')			|| # or old value that stayed in session
		$date[4]);					   # or first call! (starts at 0, we DONT want that)
	my $selectedDay = sprintf ("%02d", $self->getDataValue('day')		||
		$self->getSessionValue('day')			||
		$date[3]);
	if ($selectedYear < 1900) { $selectedYear += 1900; }

	my $selectedPeriod = $self->getDataValue('period')	|| # defaults to Day
		$self->getSessionValue('period')		||
		"Day";

	if ($self->getDataValue("period") ne "") { $self->setSessionValue("period", $selectedPeriod); }

	my $eventList;
	my $listOfEIDs = ();
	if (@{$self->{user}->getObjectList(DATA_TYPE)} != 0) { # if there is at least one calendar (should have only one anyways)
                $eventList = SW::App::CalendarManager::Calendar->load($self, $self->{user}, 
                        ${$self->{user}->getObjectList(DATA_TYPE)}[0]->{objectid});
		$listOfEIDs = $eventList->getEventList($selectedYear, sprintf("%02d", $selectedMonth), sprintf("%02d", $selectedDay));
	}

	foreach my $EID (@{$listOfEIDs})
	{
		my $event = SW::App::CalendarManager::Event->load($self, $self->{user}, $EID);
                foreach my $key (("summary", "dtstart", "dtend")) # dtend won't be used, but put it here for the future
		{
			$eventList->{events}->{$EID}->{$key} = $event->getValue($key);
		}
		push (@{$eventList->{byHour}->{substr($eventList->{events}->{$EID}->{dtstart}, 9, 2)}}, $EID);
	}
	
	#------------------------------------------------------------------#
	# Some variables, first colors, then date stuff
	#------------------------------------------------------------------#

	my $white = '#ffffff';
	my $black = '#000000';
	my $yellow = '#eeeebb';
	my $blue = '#90a8b8';
	my $pale_gray = '#eeeeee';
	my $dark_gray = '#cccccc';
  
	#------------------------------------------------------------------#
	# Panel definition
	#------------------------------------------------------------------#

	# Left Panel, pretty obvious :)
	my $leftPanel = new SW::Panel::HTMLPanel($self,{ 
		-bgColor	=> $white,
	});
	# Greetings + language
	my $languageSwitcher = new SW::Panel::FormPanel($self,{ 
		-bgColor	=> $black, 
		-align		=> "center",
		-grow_x		=> "false",
	}); 
	# Period switcher
	my $topSwitcher = new SW::Panel::HTMLPanel($self,{ 
		-bgColor	=> $white, 
		-align		=> "center",
	}); 
	# Prev/next month switcher + name
	my $monthSwitcher = new SW::Panel::HTMLPanel($self, { 
		-bgColor	=> $dark_gray, 
		-align		=> 'center'
	});
	# formatted display of all days of the month
	my $monthlyCalendar = new SW::Panel::HTMLPanel($self,{ 
		-bgColor	=> $white, 
		-grow_x		=> 'true', 
		-align		=> 'center',
	});
	# today's date so we can go back to it
	my $todayIs = new SW::Panel::HTMLPanel($self,{ 
		-bgColor	=> $yellow, 
		-align		=> 'center'
	});
	# Now you didn't think I would explain what this is right?
	my $rightPanel = new SW::Panel::HTMLPanel($self,{ 
		-bgColor	=> $white,
	});
	# Prev/next day switcher + name
	my $daySwitcher = new SW::Panel::HTMLPanel($self,{ 
		-bgColor	=> $blue,
		-grow_x		=> "true",
		-align		=> "center",
	});
	# Daily Calendar with current events
	my $dailyCalendar = new SW::Panel::HTMLPanel($self,{ 
		-bgColor	=> $white,
		-grow_x		=> "true",
	});
    
	#------------------------------------------------------------------#
	# This get the selected day, ie: the one we have to show on the daily
	# calendar (also in the monthly calendar!)
	#------------------------------------------------------------------#

	my $userName = $self->{user}->{user};
	$languageSwitcher->addElement(0,0, new SW::GUIElement::Text($self, {
                -text           => $self->{stringTable}->getString("menuWelcome",$self->{currLang})." $userName",
		-textColor	=> $yellow,
		-align		=> "center",
		-attrib		=> "bold",
		-grow_x		=> "true",
        }));

	# list of our defined languages and the GO button to change language
	$languageSwitcher->addElement(0,1, new SW::GUIElement::SelectBox($self, {
		-name            => 'lang',
#		-options        => ['English', 'Français'],
#		-values         => ['en', 'fr'],
		-options        => ['English'],
		-values         => ['en'],
		-selected       => $self->{currLang},
		-align		=> "center",
		}));

	$languageSwitcher->addElement(1,1, new SW::GUIElement::Button($self, {
		-text           => $self->{stringTable}->getString("optionGo",$self->{currLang}),
		-align		=> "center",
	}));

	$leftPanel->addElement(0,0, $languageSwitcher);

	#------------------------------------------------------------------#
	# Prints all the different options to the user (periods)
	#------------------------------------------------------------------#

	my $i = 0;

	foreach my $period (@periods) 
	{
		$topSwitcher->addElement($i,0,new SW::GUIElement::Link($self,{ 
			-text		=> $period, 
			-args		=> {
				period		=> $period,
				day		=> $selectedDay,
				month		=> $selectedMonth,
				year		=> $selectedYear,
			},
			-bgColor	=> ($selectedPeriod eq $period) ? $blue : $white,
		}));
		$i++;
		$topSwitcher->addElement($i, 0,$self->transparentGIF(15,1));
		$i++;
	}

	$leftPanel->addElement(0,1,$topSwitcher);	

	#------------------------------------------------------------------#
	# provides a way to the user to go back to the current day
	#------------------------------------------------------------------#

	# today is part  
  	$todayIs->addElement(0,0,new SW::GUIElement::Text($self,{ 
		-text		=> "Today is ", 
		-textColor	=> $black
	}));
	$todayIs->addElement(1,0,new SW::GUIElement::Link($self,{ 
		-text		=> $months[$date[4]]." $date[3], $date[5]", # this is month, day, year, i didn't use variables
									    # that i created because this is litterally today's
									    # date
		-args		=> {
			day		=> $date[3],
			month		=> $date[4],
			year		=> $date[5],
		},
		-attrib		=> 'bold'
	}));
   
	if ($selectedPeriod eq "Day" || $selectedPeriod eq "Week")
	{

		#------------------------------------------------------------------#
		# Prints previous/next links to switch months and prints selected month
		# we also have to calculate the prev/next month, but this is easy
		#------------------------------------------------------------------#

		$monthSwitcher->addElement(0,0,new SW::GUIElement::Link($self,{ 
			-args		=> {
				day		=> $selectedDay,
				month		=> ($selectedMonth == 1) ? 12 : $selectedMonth - 1,
				year		=> ($selectedMonth == 1) ? $selectedYear - 1 : $selectedYear,
			},
			-image		=> '/sw_lib/calendar/cal-left.gif', 
			-bgColor	=> $dark_gray
		}));
		$monthSwitcher->addElement(1,0,new SW::GUIElement::Text($self,{ 
			-text		=> $months[$selectedMonth]." $selectedYear",
			-bgColor	=> $dark_gray, 
			-textColor	=> $black, 
			-attrib=>'bold'
		}));
		$monthSwitcher->addElement(2,0,new SW::GUIElement::Link($self,{ 
			-args		=> {
				day		=> $selectedDay,
				month		=> ($selectedMonth == 12) ? 1 : $selectedMonth + 1,
				year		=> ($selectedMonth == 12) ? $selectedYear + 1 : $selectedYear,
			},
			-image		=> '/sw_lib/calendar/cal-right.gif', 
			-bgColor	=> $dark_gray
		}));
  
		$leftPanel->addElement(0,2,$monthSwitcher);
    
		#------------------------------------------------------------------#
		# Prints the monthly calendar with the selected day in black and
		# links to jump to other others
		#------------------------------------------------------------------#

		$i = 0;
		foreach my $day (@wdays) 
		{
			$monthlyCalendar->addElement($i,0,new SW::GUIElement::Text($self,{ 
				-text		=> substr($day,0,2), 
				-bgColor	=> $pale_gray, 
				-textColor	=> $black,
				-align		=> "right",
			}));
			$i++;
		}

		# Fill the calendar with the appropriate dates
  
		my $firstWeekDayOfMonth = &Date_DayOfWeek($selectedMonth, 1, $selectedYear);  
		my $lengthOfMonth = $mlen[$selectedMonth];
		my $row = 1;
	  
		for (my $day = 1; $day <= $lengthOfMonth; $day++) 
		{
			if (($day) == $selectedDay) {
				$monthlyCalendar->addElement(($firstWeekDayOfMonth % 7),$row,new SW::GUIElement::Text($self,{ 
					-text		=> $day, 
					-textColor	=> $black, 
					-grow_x		=> "false",
					-align		=> "right",
					-attrib		=> 'bold',
					-bgColor	=> (eval { $eventList->getNbEvents($selectedYear, 
						sprintf("%02d", $selectedMonth), sprintf("%02d", $day)) } > 0) ? $dark_gray : "",
				}));
			} else {
				$monthlyCalendar->addElement(($firstWeekDayOfMonth % 7),$row,new SW::GUIElement::Link($self,{ 
					-text		=> $day,
					-grow_x		=> "false",
					-args		=> {
						day		=> $day,
						month		=> $selectedMonth,
						year		=> $selectedYear,
					},
					-bgColor	=> (eval { $eventList->getNbEvents($selectedYear, 
						sprintf("%02d", $selectedMonth), sprintf("%02d", $day)) } > 0) ? $dark_gray : "",
					-align		=> "right",
				}));
			}
   
			if (((++$firstWeekDayOfMonth) %7) == 0) { $row++; }
		}
  
		$leftPanel->addElement(0,3,$monthlyCalendar);
	
		$leftPanel->addElement(0,4,$todayIs);
	} elsif ($selectedPeriod eq "Month") {
		#------------------------------------------------------------------#
		# Prints previous/next links to switch years and prints selected year
		# we also have to calculate the prev/next year, but this is really easy
		#------------------------------------------------------------------#

		$monthSwitcher->addElement(0,0,new SW::GUIElement::Link($self,{ 
			-args		=> {
				day		=> $selectedDay,
				month		=> $selectedMonth,
				year		=> $selectedYear - 1,
			},
			-image		=> '/sw_lib/calendar/cal-left.gif', 
			-bgColor	=> $dark_gray
		}));
		$monthSwitcher->addElement(1,0,new SW::GUIElement::Text($self,{ 
			-text		=> $selectedYear,
			-bgColor	=> $dark_gray, 
			-textColor	=> $black, 
			-attrib=>'bold'
		}));
		$monthSwitcher->addElement(2,0,new SW::GUIElement::Link($self,{ 
			-args		=> {
				day		=> $selectedDay,
				month		=> $selectedMonth,
				year		=> $selectedYear + 1,
			},
			-image		=> '/sw_lib/calendar/cal-right.gif', 
			-bgColor	=> $dark_gray
		}));
  
		$leftPanel->addElement(0,2,$monthSwitcher);
    
		#------------------------------------------------------------------#
		# Prints all months
		#------------------------------------------------------------------#


# TODO ** be able to call getNbEvents with no day so it returns events per month

		# Fill the calendar with the appropriate dates
  
		my $col = 0;
		my $row = 0;
		for (my $month = "01"; $month <= "12"; $month++) 
		{
			if (sprintf("%02d", $month) eq sprintf("%02d", $selectedMonth)) {
				$monthlyCalendar->addElement($col, $row,new SW::GUIElement::Text($self,{ 
					-text		=> substr($months[$month],0, 3),
					-textColor	=> $black, 
					-grow_x		=> "false",
					-attrib		=> 'bold',
					-bgColor	=> (eval { $eventList->getNbEvents($selectedYear, 
						sprintf("%02d", $selectedMonth)) } > 0) ? $dark_gray : "",
				}));
			} else {
				$monthlyCalendar->addElement($col,$row,new SW::GUIElement::Link($self,{ 
					-text		=> substr($months[$month],0, 3),
					-grow_x		=> "false",
					-args		=> {
						day		=> $selectedDay,
						month		=> $month,
						year		=> $selectedYear,
					},
					-bgColor	=> (eval { $eventList->getNbEvents($selectedYear, 
						sprintf("%02d", $selectedMonth)) } > 0) ? $dark_gray : "",
				}));
			}
   
			$col++;
			if (($month % 3) == 0) { $row++; $col = 0;}
			else {
				$monthlyCalendar->addElement($col, $row,$self->transparentGIF(15,1));
				$col++;
			}
		}
  
		$leftPanel->addElement(0,3,$monthlyCalendar);
	
		$leftPanel->addElement(0,4,$todayIs);
	} elsif ($selectedPeriod eq "Year") {
	}

	if ($selectedPeriod eq "Day") {
		#------------------------------------------------------------------#
		# Prints previous/next day switcher and selected day, we have to
		# calculate those previous/next days also (harder than month but still
		# not bad)
		#------------------------------------------------------------------#
		# calculate previous day;

		my $previousDay;
		my $previousMonth = $selectedMonth;
		my $previousYear = $selectedYear;
	
		if ($selectedDay == 1) {  
			if ($selectedMonth == 1) { # January 1st
				$previousDay = 31;
				$previousMonth = 12;
				$previousYear = $selectedYear - 1;
			} else {
				$previousMonth = $selectedMonth - 1;
				$previousDay = $mlen[$selectedMonth-1]; # get nb of days for that month, -1 is because of array context
			}
		} else {
			$previousDay = $selectedDay - 1;		
		}

		# calculate next day;

		my $nextDay;
		my $nextMonth = $selectedMonth;
		my $nextYear = $selectedYear;
		if ($selectedDay == $mlen[$selectedMonth - 1]) { # if current day = max number of days for this month
			if ($selectedMonth == 12) { # December 31st
				$nextDay = 1; 
				$nextMonth = 1;
				$nextYear = $selectedYear + 1;
			} else {
				$nextDay = 1;
				$nextMonth = $selectedMonth + 1;
			}
		} else {
			$nextDay = $selectedDay + 1;
		}

		$daySwitcher->addElement(0,0,new SW::GUIElement::Link($self,{ 
			-args		=> {
				day		=> $previousDay,
				month		=> $previousMonth,
				year		=> $previousYear,
			},
			-image		=> '/sw_lib/calendar/cal-left.gif', 
			-bgColor	=> $blue,
		}));

		$daySwitcher->addElement(1,0,new SW::GUIElement::Text($self,{ 
			-text		=> wdayToString(&Date_DayOfWeek($selectedMonth, $selectedDay, $selectedYear))." $months[$selectedMonth] ".$selectedDay.', '.$selectedYear,  
			-bgColor	=> $blue, 
			-textColor	=> $black, 
			-fontSize	=> '4', 
			-attrib		=> 'bold',
		}));
		$daySwitcher->addElement(2,0,new SW::GUIElement::Link($self,{ 
			-args		=> {
				day		=> $nextDay,
				month		=> $nextMonth,
				year		=> $nextYear,
			},
			-image		=> '/sw_lib/calendar/cal-right.gif',
			-bgColor	=> $blue}));

		$rightPanel->addElement(0,0,$daySwitcher);
   
		#------------------------------------------------------------------#
		# prints the daily calendar with events and links to add/edit them
		#------------------------------------------------------------------#

		$rightPanel->addElement(0, 1, new SW::GUIElement::Link($self, {
			-text		=> "Add an event",
			-args		=> {
				day		=> $selectedDay,
				month		=> $selectedMonth,
				year		=> $selectedYear,
			},
			-signal		=> "buildEditEvent",
		}));

		my $startHour;
		my $endHour;
		if ($self->getSessionValue("display") eq "ALL") {
			$startHour = "01";
			$endHour = 23;
		} else { 
			$startHour = "08";
			$endHour = 19;
		}

		my @hours= ("00",$startHour..$endHour);
  	
		my $row = 3;
		my $eventCount = 0;
		foreach my $hour (@hours) {
			if ($hour eq "00" && $endHour == 19) { } # dont print this section
			else {
				$rightPanel->addElement(0,$row,new SW::GUIElement::Text($self,{ 
					-text		=> "${hour}:00", 
					-grow_y		=> "true",
					-valign		=> "top",
					-bgColor	=> (($row % 2) == 0) ? $pale_gray : $dark_gray,
				}));
			}

			my $printed = 0;
			foreach my $event (sort eval { @{$eventList->{byHour}->{$hour}} })
			{
				$eventCount++;
				sub extractTime
				{
					my $dtTime = shift;
					my $hour = substr ($dtTime, 9, 2);
					my $mins = substr ($dtTime, 11, 2);

					return "${hour}:${mins}";
				}

				my $name = $eventList->{events}->{$event}->{summary};
				my $from = extractTime($eventList->{events}->{$event}->{dtstart});
				my $to = extractTime($eventList->{events}->{$event}->{dtend});

				if ($from eq "00:00" && $to eq "23:59") {
	
					$rightPanel->addElement(0,2,new SW::GUIElement::Text($self,{ 
						-text		=> "&nbsp;", 
						-grow_y		=> "true",
						-valign		=> "top",
						-bgColor	=> $yellow,
					}));
					$rightPanel->addElement(1,2,new SW::GUIElement::Link($self, {
						-text	=> ($name ne "") ? $name : "Event",
						-args		=> {
							day		=> $selectedDay,
							month		=> $selectedMonth,
							year		=> $selectedYear,
							EID		=> $event,
						},
						-signal		=> "buildEditEvent",
						-bgColor	=> $yellow,
					}));
					next;
				} elsif ($hour eq "00" && $endHour == 19) { $eventCount--; next; } 
	
				$rightPanel->addElement(1,  $row, new SW::GUIElement::Text($self, {
					-text		=> "[$from to $to]",
					-bgColor        => (($row % 2) == 0) ? $pale_gray : $dark_gray,
				}));
				$rightPanel->addElement(2,  $row, new SW::GUIElement::Link($self, {
					-text		=> ($name ne "") ? "$name" : "Event",
					-args		=> {
						day		=> $selectedDay,
						month		=> $selectedMonth,
						year		=> $selectedYear,
						EID		=> $event,
					},
					-signal		=> "buildEditEvent",
					-bgColor	=> (($row % 2) == 0) ? $pale_gray : $dark_gray
				}));
				$row++;
				$printed++;
			}

			if ($printed eq 0 && ($hour ne "00" || $endHour != 19)) { 
					$row++; 
			} # dont print this section
		}

		$rightPanel->addElement(0, $row, new SW::GUIElement::Link($self, {
			-text		=> "Add an event",
			-args		=> {
				day		=> $selectedDay,
				month		=> $selectedMonth,
				year		=> $selectedYear,
			},
		-signal		=> "buildEditEvent",
		}));

		if ((eval { $eventList->getNbEvents($selectedYear, sprintf("%02d", $selectedMonth), sprintf("%02d", $selectedDay)) }
			> $eventCount) || $self->getSessionValue("display")) {
			$rightPanel->addElement(3, $row, new SW::GUIElement::Link($self, {
				-text	=> ($self->getSessionValue("display")) ? "Day events only" : "Hidden events",
				-args	=> {
					display	=> ($self->getSessionValue("display") eq "ALL") ? "" : "ALL",
					day		=> $selectedDay,
					month		=> $selectedMonth,
					year	=> $selectedYear,				
				},
				-align	=> "right",
				-signal	=> "executeChangeDisplay"
			}));
		}
	} elsif ($selectedPeriod eq "Week") {
		#------------------------------------------------------------------#
		# Prints previous/next week switcher and selected week, we have to
		# calculate those previous/next week also (harder than month but still
		# not bad)
		#------------------------------------------------------------------#
		# calculate previous/next week;

		# Date::Manip doesn't like my 0's in front of days/month less than 10 :((
		my $tmpSelectedDay = ($selectedDay >= 10) ? $selectedDay : substr($selectedDay, 1, 1);
		my $tmpSelectedMonth = ($selectedMonth >= 10) ? $selectedMonth : substr($selectedMonth, 1, 1);

		my $dow = &Date_DayOfWeek($tmpSelectedMonth,$tmpSelectedDay,$selectedYear); # get selected day Day of Week
		my $prevDate = &Date_GetPrev("$tmpSelectedMonth $tmpSelectedDay $selectedYear", $dow, 0, 0, 0, 0); # one week ago
		my $nextDate = &Date_GetNext("$tmpSelectedMonth $tmpSelectedDay $selectedYear", $dow, 0, 0, 0, 0); # in one week

		$daySwitcher->addElement(0,0,new SW::GUIElement::Link($self,{ 
			-args		=> {
				day		=> substr($prevDate, 6, 2),
				month		=> substr($prevDate, 4, 2),
				year		=> substr($prevDate, 0, 4),
			},
			-image		=> '/sw_lib/calendar/cal-left.gif', 
			-bgColor	=> $blue,
		}));

		# ok, when we first called Date_GetPrev, we passed the same day of week as the current selected day so we could
		# get one week from now. To print a nice header, we need to find what day is in 6 days (end of week), so we want 
		# to get the next day matching current day of the week - 1
		if ($dow == 1) { $dow = 7; } 
		else { $dow--; }

		my $sixDays = &Date_GetNext("$tmpSelectedMonth $tmpSelectedDay $selectedYear", $dow, 0, 0, 0, 0); # in one week
		my $firstYear = (substr($prevDate, 0, 4) eq substr($sixDays, 0, 4)) ? "" : substr($prevDate, 0, 4);

		my $weekDates = "$months[$selectedMonth] $selectedDay $firstYear - $months[substr($sixDays, 4, 2)] ".
			substr($sixDays, 6, 2)." ".substr($sixDays, 0, 4);
		$daySwitcher->addElement(1,0,new SW::GUIElement::Text($self,{ 
			-text		=> $weekDates,
			-bgColor	=> $blue, 
			-textColor	=> $black, 
			-fontSize	=> '4', 
			-attrib		=> 'bold',
		}));
		$daySwitcher->addElement(2,0,new SW::GUIElement::Link($self,{ 
			-args		=> {
				day		=> substr($nextDate, 6, 2),
				month		=> substr($nextDate, 4, 2),
				year		=> substr($nextDate, 0, 4),
			},
			-image		=> '/sw_lib/calendar/cal-right.gif',
			-bgColor	=> $blue,
		}));

		$rightPanel->addElement(0,0,$daySwitcher);
   
		#------------------------------------------------------------------#
		# prints the weekly calendar with events and links to add/edit them
		#------------------------------------------------------------------#

		my $currDay = sprintf("%02d", $tmpSelectedDay);
		my $currMonth = $tmpSelectedMonth;
		my $currYear = $selectedYear;
		$dow = &Date_DayOfWeek($tmpSelectedMonth,$tmpSelectedDay,$selectedYear); # get selected day Day of Week
		my $row = 1;
		for (my $i = 1; $i <= 7; $i++) # for the next 7 days	
		{
			$rightPanel->addElement(0, $row, new SW::GUIElement::Text ($self, {
				-text		=> "$months[$currMonth] $currDay $currYear",
				-bgColor	=> $yellow,
				-attrib		=> "bold",
			}));
			$rightPanel->addElement(1, $row, new SW::GUIElement::Link($self, {
				-text		=> "Add an event",
				-args		=> {
					day		=> $currDay,
					month		=> $currMonth,
					year		=> $currYear,
				},
				-bgColor	=> $yellow,
				-signal		=> "buildEditEvent",
			}));

			$row++;

			my @hours= ("00".."23");
  	
			# clear events
			for (my $x = "00"; $x <= "23"; $x++)
			{
				@{$eventList->{byHour}->{$x}} = ();
			}

			$listOfEIDs = $eventList->getEventList($currYear, sprintf("%02d", $currMonth), sprintf("%02d", $currDay));
			foreach my $EID (@{$listOfEIDs})
			{
				my $event = SW::App::CalendarManager::Event->load($self, $self->{user}, $EID);
		                foreach my $key (("summary", "dtstart", "dtend")) # dtend won't be used, but put it here for the future
				{
					$eventList->{events}->{$EID}->{$key} = $event->getValue($key);
				}
				push (@{$eventList->{byHour}->{substr($eventList->{events}->{$EID}->{dtstart}, 9, 2)}}, $EID);
			}

			my $printed = 0;
			foreach my $hour (@hours) 
			{
				foreach my $event (sort eval { @{$eventList->{byHour}->{$hour}} })
				{
					sub extractTime
					{
						my $dtTime = shift;
						my $hour = substr ($dtTime, 9, 2);
						my $mins = substr ($dtTime, 11, 2);
	
						return "${hour}:${mins}";
					}

					my $name = $eventList->{events}->{$event}->{summary};
					my $from = extractTime($eventList->{events}->{$event}->{dtstart});
					my $to = extractTime($eventList->{events}->{$event}->{dtend});
	
					$rightPanel->addElement(0,  $row, new SW::GUIElement::Text($self, {
						-text		=> ($from eq "00:00" && $to eq "23:59") ? "All day" : "[$from to $to]",
						-bgColor        => $pale_gray,
					}));

					$rightPanel->addElement(1,  $row, new SW::GUIElement::Link($self, {
						-text		=> ($name ne "") ? "$name" : "Event",
						-args		=> {
							day		=> $currDay,
							month		=> $currMonth,
							year		=> $currYear,
							EID		=> $event,
						},
						-signal		=> "buildEditEvent",
						-bgColor	=> $pale_gray,
					}));
					$row++;
					$printed++;
				}
			}
		
			if ($printed == 0) {
				$rightPanel->addElement(0,$row,new SW::GUIElement::Text($self,{ 
					-text		=> "&nbsp;", 
					-grow_x		=> "true",
					-valign		=> "top",
					-bgColor	=> $pale_gray,
				}));
				$row++;
			}

			$dow++;
			if ($dow > 7) { $dow = 1; } # so when we go to sunday, we jump back to monday (monday = 1, sunday = 7)
			my $nextDate = &Date_GetNext("$tmpSelectedMonth $tmpSelectedDay $selectedYear", $dow, 0, 0, 0, 0); 
			
			$currDay = substr($nextDate, 6, 2);
			$currMonth = substr($nextDate, 4, 2);
			$currYear = substr($nextDate, 0, 4);		
		}
	} elsif ($selectedPeriod eq "Month") { 
	} elsif ($selectedPeriod eq "Year") {
	}

	$self->deleteSessionValue("display"); # goes back to normal view automatically

	$mainPanel->addElement(0,0,$leftPanel);
	$mainPanel->addElement(1,0,$rightPanel);

	if ($msg !~ /^\s*$/) { # if not empty, cuz maybe cancelState put a " " in there
		my $msgPanel = new SW::Panel::HTMLPanel($self, { 
			-bgColor	=> $dark_gray, 
			-align		=> 'center'
		});
		$msgPanel->addElement(0, 0, new SW::GUIElement::Text($self, {
			-text		=> $msg,
			-attrib		=> 'bold',
			-align		=> "center",
		}));

		$mainPanel->addElement(0, 1, $msgPanel);
	}
	$mainPanel->setValue('jsLib', ["calendarManager.js"]);
} # buildMainDailyUI

#==================================================================#
# CALLBACKS
#==================================================================#

sub buildEditEventWrapper
#SW Callback buildEditEvent 10
{
	my $self = shift;
	$self->setSessionValue("appState", "buildEditEvent");
} # sub buildEditEventWrapper

sub executeEditEventWrapper
#SW Callback executeEditEvent 10
{
	my $self = shift;
	$self->setSessionValue("appState", "executeEditEvent");
} # sub executeEditEventWrapper

sub executeDeleteEventWrapper
#SW Callback executeDeleteEvent 10
{
	my $self = shift;
	$self->setSessionValue("appState", "executeDeleteEvent");
} # sub executeDeleteEventWrapper

sub executeChangeDisplay
#SW Callback executeChangeDisplay 10
{
	my $self = shift;
SW::debug ($self, "CHANGING DISPLAY TO: ".$self->getDataValue("display"), 3);
	if ($self->getDataValue("display") eq "ALL") { $self->setSessionValue("display", "ALL"); }
	else { $self->deleteSessionValue("display"); }
} # sub executeChangeDisplay

sub cancelStateWrapper
#SW Callback cancelState 10
{
	my $self = shift;
	$self->setSessionValue("appState", "executeCancelState");
} # sub cancelStateWrapper

#SW end

#==================================================================#
# INTERNAL METHODS
#==================================================================#

sub executeCancelState
{
	my $self = shift;

	$self->deleteSessionValue('appState');
	$self->{UImsg} = " "; # up in dispatcher, i check if string is empty, space is to make sure we go in buildMainDailyUI
	delete $self->{data}->{EID}; # just to make sure this doesn't hang around
} # sub executeCancelState

sub buildEditEvent
{
	my $self = shift;

	$self->deleteSessionValue("appState");

	my $white = '#ffffff';
	my $black = '#000000';
	my $yellow = '#eeeebb';
	my $blue = '#90a8b8';
	my $pale_gray = '#eeeeee';
	my $dark_gray = '#cccccc';
	my @months=qw(dummy January February March April May June July August September October November December);

	my $mainPanel = $self->getPanel();
	$mainPanel->setValue('name',"SmartWORKER Calendar");

	my $selectedDay = $self->getDataValue("day");	
	my $selectedMonth = $self->getDataValue("month");	
	my $selectedYear = $self->getDataValue("year");	
	my $selectedWeekDay = wdayToString(&Date_DayOfWeek($selectedMonth, $selectedDay, $selectedYear));
	my $startHour = 12;
	my $startMins = "00";
	my $endHour = 12;
	my $endMins = 00;

	my $EID = $self->getDataValue("EID"); # if present, we edit, otherwise, we add

	$self->setSessionValue("appState", "executeEditEvent");
	$self->setSessionValue("EID", $EID);
	$self->setSessionValue("eventDATE", "$selectedYear".sprintf("%02d",$selectedMonth).sprintf("%02d",$selectedDay));

	my $vCalendar = ($EID) ? SW::App::CalendarManager::Event->load ($self, $self->{user}, $EID) : undef;
	if ($EID) {
		my $dtStart = $vCalendar->event_property(0, "dtstart", "value");
		my $dtEnd = $vCalendar->event_property(0, "dtend", "value");

		($startHour, $startMins) = $self->parseTime($dtStart);
		($endHour, $endMins) = $self->parseTime($dtEnd);
	}

	my $editPanel = new SW::Panel::FormPanel($self,{ 
		-bgColor	=> $white,
		-name		=> "editPanel",
	});

	$editPanel->addElement(0,0,new SW::GUIElement::Text($self,{ 
		-text		=> (($EID) ? "Editing" : "Adding")." an event for $selectedWeekDay $months[$selectedMonth] $selectedDay $selectedYear",
		-bgColor	=> $blue, 
		-textColor	=> $black, 
		-fontSize	=> '4', 
		-attrib		=> 'bold',
	}));
	$editPanel->addElement(0, 1,$self->transparentGIF(10,1));
	$editPanel->addElement(0, 2,new SW::GUIElement::Text($self,{
		-text		=> "Start time",
	}));
	$editPanel->addElement(1,2, $self->selectableHours("start", $startHour, $startMins));
	$editPanel->addElement(2, 2,new SW::GUIElement::Text($self, {
                -text 	=> qq{<a href="javascript:setAllDay()">All Day Event</a>},
        }));

	$editPanel->addElement(0, 3,new SW::GUIElement::Text($self,{
		-text		=> "End time",
	}));
	$editPanel->addElement(1,3, $self->selectableHours("end", $endHour, $endMins));

	$editPanel->addElement(0, 4,new SW::GUIElement::Text($self,{
		-text		=> "Summary",
	}));

	$editPanel->addElement(1, 4,new SW::GUIElement::TextBox($self,{
		-name		=> "_SAVE_summary",
		-text		=> ($EID) ? quote($vCalendar->event_property(0, "summary", "value")) : "",
		-width		=> 50,
	}));

	$editPanel->addElement(0, 5,new SW::GUIElement::Text($self,{
		-text		=> "Description",
	}));
	$editPanel->addElement(1, 5,new SW::GUIElement::TextArea($self,{
		-name		=> "_SAVE_description",
		-text		=> ($EID) ? $vCalendar->event_property(0, "description", "value") : "",
		-width		=> 50,
		-height		=> 3,
	}));

	$editPanel->addElement(0, 6,new SW::GUIElement::Text($self,{
		-text		=> "Category",
	}));
	$editPanel->addElement(1, 6, new SW::GUIElement::SelectBox ($self, {
		-name            => '_SAVE_categories',
		-options	=> ['BUSINESS', 'SPORTS', 'FAMILY'],
		-selected	=> ($EID) ? $vCalendar->event_property(0, "categories", "value") : "",
	}));	
	
	# Blank line
	$editPanel->addElement(0,7, $self->transparentGIF(10,1));  

        # Save / Cancel buttons
	$editPanel->addElement(0, 8, new SW::GUIElement::Button ($self, {
		-text           => $self->{stringTable}->getString("optionSave",$self->{currLang}),
		-signal         => "executeEditEvent",
	}));
	$editPanel->addElement(1, 8, new SW::GUIElement::Button ($self, {
		-text           => $self->{stringTable}->getString("optionCancel",$self->{currLang}),
		-signal         => "cancelState",
	}));

	if ($EID) { 
		$editPanel->addElement(2, 8, new SW::GUIElement::Button ($self, {
			-text           => "Delete",
			-signal         => "executeDeleteEvent",
		}));
	}
	
	$mainPanel->addElement(0,0, $editPanel);
	$mainPanel->setValue('jsLib', ["calendarManager.js"]);

	$self->setSessionValue("year", $selectedYear);
	$self->setSessionValue("month", sprintf("%02d", $selectedMonth));
	$self->setSessionValue("day", sprintf("%02d", $selectedDay));
} # sub buildEditEvent

sub executeDeleteEvent
{
	my $self = shift;
	my $EID = $self->getSessionValue("EID");

	my $eventList = SW::App::CalendarManager::Calendar->load($self, $self->{user}, 
                        ${$self->{user}->getObjectList(DATA_TYPE)}[0]->{objectid});
	$eventList->deleteEvent($EID, $self->getSessionValue("year"), sprintf("%02d", $self->getSessionValue("month")), 
		sprintf("%02d", $self->getSessionValue("day")));

	my $msg = "The event was deleted";
	$self->{UImsg} = $msg;
} # sub executeDeleteEvent

sub executeEditEvent
{
	my $self = shift;
	my $msg; # error or results goes there

	my $EID = $self->getSessionValue("EID");

	my $eventList;

	my $calendar_list = $self->{user}->getObjectList(DATA_TYPE);
	print STDERR "result from get object list ".SW::Util::flatten($calendar_list)."\n";


	if (@{$calendar_list} == 0) { # no Calendar (eventList), let's create one
		print STDERR "creating a new calendar\n";
 		$eventList = SW::App::CalendarManager::Calendar->new($self, $self->{user}, '');
		$eventList->setName("Master Calendar");
		$eventList->setAppId($self->APP_ID);
	} else { # just load it (load the first one)
		print STDERR "loading calendars\n";
 		$eventList = SW::App::CalendarManager::Calendar->load($self, $self->{user}, 
			${$self->{user}->getObjectList(DATA_TYPE)}[0]->{objectid});
	}


	print STDERR "loading / creating new event....\n";
   my $vCalendar = ($EID) ? SW::App::CalendarManager::Event->load($self, $self->{user}, $EID) :
		SW::App::CalendarManager::Event->new($self, $self->{user});
	if (!$EID) {
		$EID = $vCalendar->getEID();
		$vCalendar->new_event;
	}

	my @timeArray;
	foreach my $keyName (sort {$a cmp $b} keys %{$self->findDataKey("_SAVE") || {}})
	{
		my $keyNameCopy = $keyName;
		my $value;

		$keyNameCopy =~ s/^_SAVE_//;

		if ($keyNameCopy =~ s/^TIME_//) {
			$keyNameCopy =~ s/_([^_]+)$//;
			my $partOfTime = $1;
			
			if ($partOfTime eq "FINAL") { 
				my $timeValue = $self->getSessionValue("eventDATE");
				$timeValue .= "T";
				$timeValue .= join ("", @timeArray);
				$timeValue .= $self->getDataValue("$keyName");
				for (my $x = @timeArray + 1; $x < 3; $x++) { #3 parts in time (hhmmss), we want to fill this 
									     #with 00, the + 1 is for adding the current value
					$timeValue .= "00";
					
				}
				@timeArray = ();

				$vCalendar->event_set(0, "$keyNameCopy", { "value" => "$timeValue", });
			} else {
				push (@timeArray, $self->getDataValue("$keyName"));
			}
		} else {
			$vCalendar->event_set(0, $keyNameCopy, { "value" => $self->getDataValue("$keyName"), });
		}
	}

	SW::debug($self,"Trying to add it to the list.... ...",1);
	print STDERR "Trying to add it to the list.... ...\n";
	$self->getSessionValue("eventDATE") =~ /^(\d{4})(\d{2})(\d{2})$/;
	$eventList->addEvent($EID, $1, $2, $3); # (year, month, day)

	$self->setSessionValue("year", $1);
	$self->setSessionValue("month", $2);
	$self->setSessionValue("day", $3);

   SW::debug($self,"About to force write ...",1);
   $vCalendar->forceWrite();

	$msg = "Save successful";
	print STDERR "save successful \n";

	
	$self->{UImsg} = $msg;

	return undef;
} # sub executeEditEvent

#------------------------------------------------------------------#
# In order to efficiently have spacing between rows, I created this  
# method to put a transparentGIF of width x height between rows
# This is created from a 10x10 transparent GIF
#------------------------------------------------------------------#
sub transparentGIF      
{
        my $self = shift;
        my $width = shift || 10;
        my $height = shift || 10;
                
        my $transparentGIF = new SW::GUIElement::Image($self, {
                -url            => "/sw_lib/images/transparent.gif",
                -border         => '0',
                -width          => $width,
                -height         => $height,
        });

        return ($transparentGIF);
} # sub transparentGIF

sub selectableHours
{
	my $self = shift;
	my $type = shift; # either end or start
	my $selectedHour = shift; 
	my $selectedMins = shift;	

	my $white = '#ffffff';

	my $selectableHours = new SW::Panel::HTMLPanel($self,{ 
		-bgColor	=> $white,
	});
	$selectableHours->addElement(0,0,new SW::GUIElement::SelectBox($self,{
		-name		=> "_SAVE_TIME_dt${type}_0",
		-options	=> ["00".."23"],
		-selected	=> $selectedHour,
	}));
	$selectableHours->addElement(1,0,new SW::GUIElement::Text($self,{
		-text		=> "h",
	}));
	$selectableHours->addElement(2,0,new SW::GUIElement::SelectBox($self,{
		-name		=> "_SAVE_TIME_dt${type}_FINAL",
		-options	=> ["00".."59"],
		-selected	=> $selectedMins,
	}));
	
	return $selectableHours;
} # sub selectableHours

sub parseTime
{
	my $self = shift;
	my $time = shift;

	my $hour = substr ($time, 9, 2);
	my $mins = substr ($time, 11, 2);

	return ($hour, $mins);
}
# sub parseTime

sub quote
{
	my $string = shift;
	$string =~ s/"/&quot;/g;
	return $string;
} # sub quote

1; # true

__END__

=head1 NAME

Calendar.pm - A Calendar utily

=head1 SYNOPSIS

   Give a simple example of the module's use

=head1 DESCRIPTION

  
=head1 METHODS
  

=head1 PARAMETERS


=head1 AUTHOR
   
Frederic Hurtubise
HBE      fred@hbe.ca
August 16/99

=head1 REVISION HISTORY

  $Log: CalendarManager.pm,v $
  Revision 1.5  1999/09/11 07:07:32  scott
  Made substantial changes to the database schema and data storage models.
  Now there's three global tables called datamap, dataaccess, and
  datainfo.  These hide the many other more data specific tables
  where the infomation is actually stored.

  Revision 1.4  1999/09/11 07:06:07  scott
  Tweaking these apps so they work with the new datamap model
  (actually they don't change at all unless they were being bad
  and writing their own SQL).

  Revision 1.3  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors

  Revision 1.2  1999/09/05 02:18:50  gozer
  Renamed -ref to -name and -targer to -signal

  Revision 1.1  1999/09/02 20:11:05  gozer
  New namespace convention

  Revision 1.8  1999/08/30 21:45:42  fhurtubi
  Removed exporter call

  Revision 1.7  1999/08/30 03:08:29  fhurtubi
  Removed french support for now as the language code isnt in the app yet.
  Removed month/year display as it's not done yet either.
  Added Weekly support

  Revision 1.6  1999/08/28 04:44:37  fhurtubi
  Added the fullday event button

  Revision 1.5  1999/08/20 02:40:40  fhurtubi
  Added documentation

  Revision 1.4  1999/08/19 22:33:20  fhurtubi
  Full working version!! (daily calendar only). We can now add/retrieve/delete events..
  Of course, this is very basic (there is no checking of overlapping events nor events
  that ends before the start time), but the idea is there

  Revision 1.3  1999/08/18 23:25:14  fhurtubi
  Small changes

  Revision 1.2  1999/08/18 17:29:12  scott
  renamming

  Revision 1.1  1999/08/18 15:41:45  scott
  Renaming Calendar.pm to CalendarMAnager.pm

  Revision 1.6  1999/08/17 18:32:23  fhurtubi
  UI for edit/add event is done, fixed little bugs in date manipulation. This
  version uses the new dispatcher feature that we should be implementing in all
  apps

  Revision 1.5  1999/08/16 22:42:11  fhurtubi
  First version of this daily calendar app. Right now, you can't add / read
  events, but at least, you can surf around in the days/months (click on the
  arrows, it's really cool)

        
=head1 SEE ALSO
        
perl(1).
