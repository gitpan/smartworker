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

package SW::Util;

#------------------------------------------------------------
# SW::Util
# Re-used functions that different classes can use
#------------------------------------------------------------
# $Id: Util.pm,v 1.39 1999/11/22 17:12:43 fhurtubi Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA @SW_EXPORT);

use SW::Exporter;

use LWP::UserAgent;
use Data::Dumper;
use Digest::MD5 qw(md5_base64 md5_hex);
use CGI;


@ISA = qw(SW::Exporter);

@SW_EXPORT = qw(inArray arrayIndex intersection a_not_in_b parseTimeStamp getDateStr);

$VERSION = '0.02';

#initialize the random generator for random-string generation
srand ( time() ^ ($$ + ($$ << 15)));

#------------------------------------------------------------
# flatten (FUNCTION)
# Flattens a data structure so it can be printed properly
#
# call: $flattenedDataStructure = flatten ($dataStructure);
#
# in:	- Data structure to flatten
#
# out:	- The flattened data structure
#------------------------------------------------------------
sub flatten 
{
	my ($tempvar) = @_;

	use Data::Dumper;
	local $Data::Dumper::Indent=0;
	local $Data::Dumper::Useqq=1;
#	In the Data::Dumper man pages, I was warned that using Terse can lead to some things that will not eval proprely
	local $Data::Dumper::Terse=1;

	return Dumper($tempvar);
}

#provide backward-compatibility just in case someone was using flatten_circular   
*flatten_circular = \&flatten;

#------------------------------------------------------------
# buildQuery (FUNCTION)    
# Builds a query string to perform a given action
# Assumes that only a basic select * will be performed, or,
# in the case of an update, only the uid field will be
# used in the where clause.
#                
# call: $query = buildQuery ($action, $table, @args);
#                
# in:   - Action (insert, select, update, delete)
#       - Table (to do the query on)
#	- Arguments (array containing name-value pairs)
#
# out:  - A built SQL query that is ready to be executed
#
# todo: - the delete action isn't done yet
#------------------------------------------------------------
sub buildQuery
{
	my ($action, $table, @args) = @_;

	my $query = "";

	if ($action =~ /INSERT/i)
	{
		$query .= "insert into $table ";

		my @names = ();
		my @values = ();

		for (my $i=0; $i<=$#args; $i++)
		{
			if ($i%2 == 0) {
				push (@names, $args[$i]);
			} else {
				push (@values, $args[$i]);
			}
		}

		$query .= "(".join(",", @names).") values (".join(",", @values).")";
	} elsif ($action =~ /SELECT/i) {
		$query = "select * from $table where ";

		my @pairs = ();
		my $uid;

		for (my $i=0; $i<=$#args; $i+=2)
		{
			push (@pairs, "$args[$i]=$args[$i+1]");
		}
	
		$query .= join(" and ", @pairs);
	} elsif ($action =~ /UPDATE/i) {
		$query .= "update $table set ";

		my @pairs = ();
		my $uid;

		for (my $i=0; $i<=$#args; $i+=2)
		{
			if ($args[$i] ne "uid")	{
				push (@pairs, "$args[$i]=$args[$i+1]");
			} else {
				$uid = $args[$i+1];
			}
		}
	
		$query .= join(",", @pairs)." where uid=$uid";

		if (!$uid) {
			$query = "No UID specified";
		}
	} elsif ($action =~ /DELETE/i) {
	} else {
	}

	return $query;
}

#------------------------------------------------------------
# translate (FUNCTION)    
# Given a string, source language, and target languages,
# this will attempt to use some online translation
# services
#                
# call: %translations = translate ($string, $sourceLanguage, @targetLanguages);
#                
# in:   - The string to translate 
#       - The source language
#       - The target languages
#
# out:  - A hash containg languages as keys and translated strings as values
#
# todo: - Return a reference instead of a hash and change all code that might have used this
#------------------------------------------------------------
sub translate
{
	my ($text, $fromLanguage, @toLanguages) = @_;

	my %results;
	my $service = "GO";

	# set up the results array

	$results{$fromLanguage} = $text;

	my $serviceInfo = $SW::Config::TRANSLATORS{$service};

	my $etext = CGI::escape($text);

	my $ua = new LWP::UserAgent;
	$ua->agent("SmartWorker/".$SW::Config::VERSION." ".$ua->agent);

	my $req = new HTTP::Request POST => $serviceInfo->{url};
 
	$req->content_type("application/x-www-form-urlencoded");

	foreach my $l (@toLanguages)
	{
		$req->content("input_type=text&urltext=$etext&lp=".$fromLanguage."_".$l."&text=$etext&doit=done");
		
		my $res = $ua->request($req);

		if ($res->is_success) {
			my $content = $res->content;

			# extract the translation
			
			my $junk1;
			my $transtext;
			my $junk2;
			my $start;
			my $end;

			$start = $serviceInfo->{start};
			$end = $serviceInfo->{end};

			#($junk1, $junk2) = split(/$end/, $content);
			#($junk1, $transtext) = split(/$start/, $junk1);

			($junk1, $junk2) = split(/$start/i, $content, 2);
			($transtext, $junk2) = split(/$end/i, $junk2, 2);

			$results{$l} = $transtext;
		}	
	}

	return %results;
}

#------------------------------------------------------------
# sendMail (FUNCTION)
# Sends email
#
# call: sendMail ($to, $from, $subject, $body);
#
# in:	- To address
#	- From address
#	- Message subject
#	- Message body
#
# out:	- NULL
#------------------------------------------------------------
sub sendMail
{
	my ($to, $from, $subject, $body) = @_;

	open (MAIL, $SW::Config::SENDMAIL_CMD);
	print MAIL "To: $to\n";
	print MAIL "From: $from\n";
	print MAIL "Subject: $subject\n\n";
	print MAIL $body;
	close (MAIL);
}

#------------------------------------------------------------
# parseTimeStamp (FUNCTION)
# Given a timestamp SQL field, returns a date structure with all elements
#                
# call: $date = parseTimeStamp ($timestamp);
#                
# in:   - A timestamp
#	- Whether to keep the leading zeros or not
#
# out:  - A hash ref containing year, month, day, hours, min and secs
#------------------------------------------------------------
sub parseTimeStamp
{
	my ($string, $keepZeros) = @_;

	my $date = {
		year	=> substr($string,0,4),
		month	=> substr($string,4,2),
		day	=> substr($string,6,2),
		hours	=> substr($string,8,2),
		min	=> substr($string,10,2),
		secs	=> substr($string,12,2),
	};

	# Remove the zeros at the start of these values

	if (!$keepZeros) { 
		$date->{month} =~ s/^0//;
		$date->{day} =~ s/^0//;
	}

	return $date;
}

#------------------------------------------------------------
# cmpDates (FUNCTION)
# This function is passed two arguments which are both
# refs to hashes, as returned by parseTimeStamp, and
# returns 1 if the first is more recent, 0 if they are equal,
# and -1 if the second is more recent.
#
# call: $whichIsMoreRecent = cmpDates ($firstDate, $secondDate);
#
# in:   - First date to compare
#       - Second date to compare
#
# out:  - 1 if first is more recent, 0 if equal, -1 if second is more recent
#------------------------------------------------------------
sub cmpDates
{
	my ($first, $second) = shift;

	return ($first->{year} <=> $second->{year}       ||
		$first->{month} <=> $second->{month}     ||
		$first->{day} <=> $second->{day}         ||
		$first->{hours} <=> $second->{hours}     ||
		$first->{min} <=> $second->{min}         ||
		$first->{secs} <=> $second->{secs}     
	);
}

#------------------------------------------------------------
# getDateStr (FUNCTION)
# Gets a date argument like the one returned by parseTimeStamp and
# returns a string representing a human-readable form of the
# date.
#
# call: $humanizedDate = getDateStr ($date);
#
# in:   - A date in the parseTimeStamp format
#
# out:  - A human-readable date
#
# todo: - Tokenize the date so it can be multilingual
#------------------------------------------------------------
sub getDateStr
{
	my $date = shift;
	my $dateStr = "";

	my %months = (
		1	=> "January",
		2	=> "February",
		3	=> "March",
		4	=> "April",
		5	=> "May",
		6	=> "June",
		7	=> "July",
		8	=> "August",
		9	=> "September",
		10	=> "October",
		11	=> "November",
		12	=> "December",
	);

	my $mon = $date->{month};

	$dateStr .= $months{$mon} . " " . $date->{day} . ", ";
	$dateStr .= $date->{year} . " \@ " . $date->{hours} . ":" . $date->{min};

	return $dateStr;
}

#------------------------------------------------------------
# inArray (FUNCTION)
# Checks if an item is in an array or not
#
# call: $isInArray = inArray ($item, $arrayRef);
#
# in:   - The item we are looking for in the array
#       - The array ref we are looking in
#
# out: 	- 1 if the item is in the array, undef otherwise
#------------------------------------------------------------
sub inArray
{
	my ($item, $array) = @_;

	foreach my $el (@$array)
	{
		return 1 unless $item ne $el;
	}
	return undef;
}

#------------------------------------------------------------
# arrayIndex (FUNCTION)
# Takes an item and tries to find it's position in an array
#
# call: $arrayPosition = arrayIndex ($item, $arrayRef);
#
# in:   - The item we are looking for in the array
#       - The array ref we are looking in
#
# out:  - The position in the array at which the item first appears, 0 otherwise
#------------------------------------------------------------
sub arrayIndex
{
	my ($item, $array) = @_;
	my $count = 0;

	foreach my $el (@$array)
	{
		last unless $item ne $el;
		$count++;
	}
	return $count;
}

#------------------------------------------------------------
# intersection (FUNCTION)
# Takes two arrays and forms a third one with their intersection
#
# call: $intersectedList = intersection ($arrayRefA, $arrayRefB);
#
# in:   - First array ref
#	- Second array ref
#
# out:  - An array ref containing the intersection of the first 2
#------------------------------------------------------------
sub intersection
{
	my ($lista, $listb) = @_;
	my (%union, %isect);
	foreach my $e (@$lista, @$listb) { $union{$e}++	&& $isect{$e}++ };
	my @isect = keys %isect;
	return \@isect;
}

#------------------------------------------------------------
# a_not_in_b (FUNCTION)
# Takes two arrays and form a third one with all the elements that are
# in the first one but not in the second one
#
# call: $allNotThere = a_not_in_b ($arrayRefA, $arrayRefB);
#
# in:   - First array ref (the one we keep elements from)
#       - Second array ref (the one that is used to remove elements from the first array)
#
# out:  - An array ref containing all elements from the first list that aren't in the second list
#
# todo: - Name of function not standard to SW :)
#------------------------------------------------------------
sub a_not_in_b
{
	my ($lista, $listb) = @_;
	my (%in, %out);
	foreach my $e (@$listb) { $out{$e}++ };
	foreach my $e (@$lista) { ($in{$e} = 1) unless $out{$e}  };

	my @keepers = keys %in;
	return \@keepers;
}

#------------------------------------------------------------
# buildArgString (FUNCTION)
# Builds an argument string (URL) from a list of strings 
# i.e. buildArgString("hello=rere","this=that");
# returns "?hello=rere&this=that"
#
# call: $argString = buildArgString ($stringA, $stringB, ...);
#
# in:   - An undefinite number of strings (a string being "key=values")
#
# out:  - A string containing the built argument string (URL)
#------------------------------------------------------------
sub buildArgString {
	return unless grep $_, @_; #nothing to do..
	return "?" . join '&', ( grep $_, @_);
}


#------------------------------------------------------------
# randomString (FUNCTION)
# Returns an almost pseudo-random string for your crypto needs
#
# call: $randomizedString = randomString();
#
# in:   - NULL
#
# out:  - A MD5 randomized string
#------------------------------------------------------------
sub randomString 
{
	return md5_hex(rand);
}

#------------------------------------------------------------------#
# removeFromArray (FUNCTION)
# Returns an array without the element (all instances) we want to remove
#
# Call: - removeFromArray ($arrayRef, $element)
#
# In: 	- Array ref
#	- the element to remove
#
# Out: 	- Array ref without the element
#------------------------------------------------------------------#
sub removeFromArray
{
	my ($arrayRef, $valueToRemove) = @_;
        
	@{$arrayRef} = grep { $_ ne $valueToRemove } @{$arrayRef};
        
	return $arrayRef;
}
1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

	SW::Util - SmartWorker miscellaneous utility functions

=head1 SYNOPSIS

	use SW::Util;

=head1 DESCRIPTION

	These are functions that are commonly used by different SW components.

=head1 FUNCTIONS

	flatten 	- $flattenedDataStructure = flatten ($dataStructure);
			- Flattens a data structure so it can be printed properly

	buildQuery	- $query = buildQuery ($action, $table, @args);
			- Builds a query string to perform a given action

	translate	- %translations = translate ($string, $sourceLanguage, @targetLanguages);
			- Translates a string given a source language and some target languages

	sendMail	- sendMail ($to, $from, $subject, $body);
			- Sends email

	parseTimeStamp	- $date = parseTimeStamp ($timestamp);
			- Given a timestamp SQL field, returns a date structure with all elements

	cmpDates	- $whichIsMoreRecent = cmpDates ($firstDate, $secondDate);
			- Compares two dates (in parseTimeStamp format) to find which one is more recent

	getDateStr	- $humanizedDate = getDateStr ($date);
			- Returns a human-readable date string based on a parseTimeStamp format date

	inArray		- $isInArray = inArray ($item, $arrayRef);
			- Checks if an item is in an array or not
	
	arrayIndex	- $arrayPosition = arrayIndex ($item, $arrayRef);
			- Takes an item and tries to find it's position in an array

	intersection	- $intersectedList = intersection ($arrayRefA, $arrayRefB);
			- Takes two arrays and forms a third one with their intersection

	a_not_in_b	- $allNotThere = a_not_in_b ($arrayRefA, $arrayRefB);
			- Takes two arrays and form a third one with all the elements that are in A but not in B

	buildArgString	- $argString = buildArgString ($stringA, $stringB, ...);
			- Builds an argument string (URL) from a list of key-value strings

	randomString	- $randomizedString = randomString();
			- Returns an almost pseudo-random string for your crypto needs

	removeFromArray	- $arrayRef = removeFromArray ($arrayRef, $element);
			- Returns an array without the element (all instances) we want to remove

=head1 METHODS

	none

=head1 AUTHOR

	Kyle Dawkins, kyle@hbe.ca

=head1 REVISION HISTORY

	$Log: Util.pm,v $
	Revision 1.39  1999/11/22 17:12:43  fhurtubi
	Added the removeFromArray function that removes one element (all instances)
	from an array (array ref)
	
	Revision 1.38  1999/11/15 18:17:33  gozer
	Added Liscence on pm files
	
	Revision 1.37  1999/11/12 22:09:47  krapht
	Removed useless forgotten STDERR prints
	
	Revision 1.36  1999/11/12 15:18:23  fhurtubi
	One comma too many in the export line
	
	Revision 1.35  1999/11/11 22:45:29  krapht
	Used SW::Exporter instead of the normal Exporter.
	
	Revision 1.34  1999/11/11 07:13:24  gozer
	Cookie sends the cookie only if necessary
	Handler returns a 404 when handling the get of a file that isn't on the file server
	User - added the change of username call SW->user->authen->setName("NewName");
	
	Revision 1.33  1999/11/10 20:01:27  fhurtubi
	Updated documentation
	
	Revision 1.32  1999/09/30 11:31:48  gozer
	2 new fonctions
	randomString returns what it says (well, pseudo)
	buildArgString (@list) builds a 'correct' HTML query string all the time ;-)

	Revision 1.31  1999/09/20 15:01:36  krapht
	Removed getRequest from Panel, and removed that useless "All done" in Util

	Revision 1.30  1999/09/20 14:30:00  krapht
	Changes in most of the files to use the new way of referring to session,
	user, etc. (SW->user, SW->session).

	Revision 1.29  1999/09/11 08:44:36  gozer
	Made a whole bunch of little kwirps.
	Fixed Handler to deal correctly with SW_App_Namespace without defaulting to SW::App when the var is set
	Fixed the bug that made Login.pm create an empty hidden argument on every login attempt
	Added a whole bunch of modules preloading in sw-perl-startup, good speed improvment
	Fixed a few warning here and there.  Only one missing the sweep.  Application.pm and AUTOLOAD warning ?!?
	Changed the SW::Util::flatten and circular_flatten to succesfully use Data::Dumper ;-} (-180 lines of code)
	Gone to bed very late

	Revision 1.28  1999/09/11 07:07:23  scott
	Made substantial changes to the database schema and data storage models.
	Now there's three global tables called datamap, dataaccess, and
	datainfo.  These hide the many other more data specific tables
	where the infomation is actually stored.

	Revision 1.27  1999/09/03 01:05:36  scott
	Mods so we can remove the site specific configurations info
	(SW::Config) from the framework.

	Revision 1.26  1999/09/01 01:26:46  krapht
	Hahahahha, removed this %#*(!&()*$& autoloader shit!

	Revision 1.25  1999/08/30 16:32:25  krapht
	Can't remember what I fixed in there!

	Revision 1.24  1999/08/28 04:42:18  fhurtubi
	Added the quote bypass (\\")

	Revision 1.23  1999/08/18 16:58:07  krapht
	Added some more stuff in the getDateStr function!

	Revision 1.22  1999/08/18 16:49:42  krapht
	Added a small function to transform a date into a readable date string
	This function needs some work for date formatting, weekdays, etc.

	Revision 1.21  1999/08/16 14:34:00  scott
	oops, bug fix

	Revision 1.20  1999/08/15 02:05:42  scott
	Moved the sendmail string into SW::Config with the site specific
	config info

	Revision 1.19  1999/08/14 17:32:14  scott
	removed a useless debugging msg

	Revision 1.18  1999/08/13 19:54:49  krapht
	The count variable at lines 551 and 553 needed a $ before its name

	Revision 1.17  1999/08/13 19:42:08  scott
	added arrayIndex to return an item's index within an array

	Revision 1.16  1999/08/13 16:58:45  krapht
	Added some doc for parseTimeStamp

	Revision 1.15  1999/08/13 16:56:12  scott
	added some docs (still could use more!)

	Revision 1.14  1999/08/13 16:54:13  scott
	added inArray method   takes ($item, $array_ref)  and returns true
	if the item is in the array

	Revision 1.13  1999/08/12 22:10:31  krapht
	Added a date comparing function called cmpDates, goes well with parseTimeStamp
	Might need some work, though!

	Revision 1.12  1999/08/12 19:35:36  krapht
	Added a TimeStamp parsing function

	Revision 1.11  1999/08/10 14:14:18  scott
	removed a stupid debug message

	Revision 1.10  1999/07/21 14:29:52  krapht
	No real changes, just updating!!

	Revision 1.9  1999/07/19 13:29:19  scott
	Lots of clean-up work, debugged and improved the desctructor calling of all
	copmonents so none should be left lingering after the transaction completes.

	This in turn solved the session problem (destructor wasn't being called
	because it was persisting past the end of the transaction)

	Revision 1.8  1999/07/08 15:45:27  scott
	oops - should have done these separately ...
	
	Working on changes to the database code for users, groups, and objects

	as well as debugging and signals

	Revision 1.7  1999/04/20 05:04:45  kiwi
	Added numerous hard-coded strings like paths to java applet code
	or where to find media like images

	Revision 1.6  1999/04/13 16:39:25  scott
	bug fixes in flatter

	implemented SW::Util::flatten_circular which is like flatten but keeps all processed
	object references in a hash so they only get processed once

	some presently unused display serialization code

	Revision 1.5  1999/04/07 20:45:56  kiwi
	Added "translate" function to query online language translators and
	return the results.

	Revision 1.4  1999/03/27 21:51:22  kiwi
	Added "buildQuery" method for rapidly building SQL strings from
	argument lists.  It's limited to basic queries but it works well and saves
	time

	Revision 1.3  1999/03/19 22:42:40  kiwi
	Added stub for an SQL statement generator.

	Revision 1.2  1999/02/17 17:08:53  kiwi
	Altered class to use hierarchical parent/child app relationships

	Revision 1.1  1999/02/12 22:32:51  kiwi
	Created SW::Util package to encapsulate commonly used functions


=head1 SEE ALSO

	perl(1).

=cut
