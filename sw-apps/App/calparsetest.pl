#!/usr/bin/perl

use Parse::vCalendar;
use Parse::vCalendar::Event;
use Data::Dumper;


$vcal = new Parse::vCalendar;


#$thingme = new Parse::vCalendar::Event;
#$thingme2 =  new Parse::vCalendar::Event;
#$vcal->new_event($thingme);
#$vcal->new_event($thingme2);
$vcal->new_event;

#print "Event Count: " . $vcal->event_count . "\n";

$todo_thing = new Parse::vCalendar::ToDo;
$vcal->new_todo($todo_thing);

$vcal->new_journal;
$vcal->new_journal;
$vcal->new_journal;

#$vcal->event_set(0,"class",{'value' => 'English 101'});
$attributes = {
    'value' => 'fred',
};
#$vcal->event_set(0,"duckbilled platypus",$attributes);
#$vcal->event_set(0,"created",{'value' => 'some day'});

#$vcal->event_set(0,'organizer',{'value' => 'Me'}); 
#$vcal->event_set(0,'description',{'value' => 'This is a description.  Can you tell?'});
#$vcal->event_set('new','description',{'value' => "Another description"});

$vcal->event_set(0,'dtstart',{'value' => "Now!"});

$vcal->event_set(0,'dtend',{'value' => "Then!"});

$vcal->event_set(0,'summary',{'value' => "Yadda yadda yadda, rhubarb rhubarb turnip turnip."});

$vcal->event_set(0,'description',{'value' => "Which describes how you're feeling all the time,  which describes how you're feeling how you're feeling all the time, he says I'm feeling fine, but that doesn't really rhyme with overseas..."});

#$vcal->event_set(0,'categories',{'value' => "WORK HOME POTATO"});
$vcal->event_set(0,'categories',{'value' => ["WORK","HOME","POTATO"]});

$vcal->event_set(0,'summary','bibble');

#print Dumper($vcal->{'vevents'}->[0]);
#print Dumper($vcal);

print $vcal->calendar;


print "--- Here ends the calendar, and begins the rest of the tests ---\n";

#print $vcal->event(1);

print $vcal->event_property(0,'dtstart','value') . "\n";


print "DTS:" . $vcal->event_property(0,'dtstart','value') . "\n";

#print "Boo! " . $vcal->{'vevents'}->[0]->{'class'} . " Eek!\n";
if (defined($vcal->{'vevents'}->[0]->{'dtstart'})) { print "Defined\n"; } else { print "Nope.\n";}


#print Dumper($vcal->{'vevents'});








