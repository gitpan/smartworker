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

package Office::vCard;

#-------------------------------------------------------------------------#
# vCard Perl Module v 0.3                                                 #
#                                                                         #
# Author: John F. Zmrotchek                                               #
# Date: July 20th, 1999                                                   #
#                                                                         #
# Description:                                                            #
#	Allows creation and manipulation of vCard objects in Perl.        #
#                                                                         #
# Issues:                                                                 #
#	- Supports a mixed subset of the 2.1 and 3.0  specifications at   #
#         present, mostly updated to 3.0 standard at this point. Should   #
#         2.1 be back-supported for compatibility?                        #
#       - Does not handle "from file" object loading.                     #
#       - Does not handle "from DB" object loading                        #
#       - Does not handle "to file" object storage                        #
#       - Does not handle "to DB" object storage                          #
#       - SHOULD it handle the above?  With the passed-array 'parse'      #
#         method, the actual reading/writing from/to DB/file can be       #
#         transparently passed on to the app, and left nicely out of      #
#         this module, which is already getting weighty as is.            #  
#         In the meantime, we've got the import_card() method to get      #
#         vCards from external apps which do the getting of the cards     #
#         from files or DBs.  IMHO, this is probably a Better Way of      #
#         doing things, as it decouples file and database functionality   #
#         from a module whose definition really doesn't call for them.    #
#       - parse_begin, parse_version, parse_agent, parse_end not yet      #
#         implemented.  Shouldn't hurt the situtation much (as they're    #
#         set to defaults in the case of all but 'agent' subobjects)      #
#         but will probably require later work.                           #
#                                                                         #
# Revision History:                                                       #
#       Aug. 12th, 1999 - Minor tweakings and bugfixes on various         #
#                         methods.                                        #
#                       - Added grouping functionality for EMAIL and      #
#                         PHONE tags.  Anything else will wait for the    #
#                         next revision, or for when we figure out a need #
#                         for them.                                       #
#       Aug. 11th, 1999 - Hokay... We're back to where we were on Aug.    #
#                         2nd, but now the module should be mod_perl      #
#                         safe.  The only major change (as mentioned in   #
#                         the notes for yesterday) is the change of       #
#                         import() to importcard().                       #
#                       - There's also a new method called init_vcard     # 
#                         which is used when calling new() isn't an       #
#                         option.  This may still be a little buggy, so   #
#                         caveat emptor.                                  #
#                       - SOME parse routines now handle grouping. As per #
#                         the RFC, tags may be given grouping prefixes    #
#                         such as "WORK.".  Though the generic parse      # 
#                         routine deals with this, it doesn't always      #
#                         do anything with the value after it's parsed.   #
#                         Only the ADR tag supports it thus far: more     #
#                         to come tomorrow.                               #
#       Aug. 10th, 1999 - As per Scott, changed around the bit at the     #
#                         front so that it was enclosed in a method,      #
#                         vCard_struct. This is to prevent scoping        #
#                         issues when this gets used in conjunction       #
#                         with mod_perl.                                  #
#                       - Started work on somewhat kludgy methods in      #
#                         the form 'set_<tagname>_type, which allows      #
#                         prefixing of tags with grouping types, which    #
#                         will allow tags of the form 'HOME.ADR:...' to   #
#                         be produced as per the RFC specs.  It'll also   #
#                         make Fred's work simpler. :)                    #
#                       - Got to thinking about in in bed, couldn't       #
#                         sleep, and so logged in and burned the 3am      #
#                         oil.  Fixed LOTS of bugs, and renamed the       #
#                         import() method to importcard() to avoid        #
#                         it automagically running on script init.        #
#       Aug. 2nd,  1999 - Added to POD again.                             #
#                       - More 'by field' return method overloading,      #
#                         this time for ADR, TEL, EMAIL, LOGO and SOUND   #
#                         tags.                                           #
#       July 30th, 1999 - Wrote a bunch of POD docs for the parse_*       #
#                         methods written yesterday.                      #
#                       - Did some minor corrective surgery on a few      #
#                         methods; mostly debugging.                      #
#                       - Added code to return specific fields from       #
#                         NAME and PHOTO tags.  Continuing the process    #
#                         with other tag types as well.                   #
#       July 29th, 1999 - Same shtuff, different day. See yesterday.      #
#                       - Completed parse_* methods, with the few         #
#                         exceptions listed in the 'issues' section       #
#                         above.                                          #   
#       July 28th, 1999 - More 'parse_*' stuff.                           #
#                       - More modifying output routines to give          #
#                         warnings about uninitialized values and         #
#                         return blank strings rather than tags with      #
#                         empty value fields.                             #
#       July 27th, 1999 - Continued work on 'parse_*' routines. There's   #
#                         a lot of them.                                  # 
#                       - Modified "nickname_set" to allow a 'new'        #
#                         argument to be passed.  This was to allow for   #
#                         vCards with multiple NICKNAME tags, which       #
#                         is actually an incorrect format.  But we're     #
#                         going to be generous with our parsing.          #
#                       - Modified various output routines so that they   #
#                         would return nothing if there were no set       #
#                         values for that attribute.  It will also        #
#                         return a warning for that case if $warnings     #
#                         is set.                                         #
#       July 26th, 1999 - Started writing in support for parsing vCard    #
#                         information from external sources (the          #
#                         'import', 'parse' and various tag-specific      #
#                         parsing ('parse_<tagname>') methods.            #
#       July 23rd, 1999 - Added in PRODID, REV, UID, URL, CLASS and KEY   #
#                         tag support.                                    #
#                       - Added in methods for display of tags grouped    #
#                         by function, and a "show all Vcard" method      #
#                       - !!Tentatively!! changed VERSION tag default     #
#                         to 3.0; needs testing though.                   #
#       July 22nd, 1999 - Finished GEO tag support                        #
#                       - Added in TITLE, ROLE, ORG, CATEGORIES, NOTE,    #
#                         SORT-STRING tag supoprt                         #
#       July 21st, 1999 - Added "warnings" and "errors" trapping to       #
#                         warning and error message generators.           #
#                       - Finished BDAY, EMAIL tag support                #
#                       - Added in LABEL, MAILER and partial TZ support   #
#	July 20th, 1999 - Update to v0.2                                  #
#                       - Added in FN, NICKNAME, partial BDAY, PHOTO,     #
#                         LOGO and SOUND tag support.                     #
#                       - Updated ADR and EMAIL tag output to v3.0 spec   #
#                       - added warning & error switch capability, but    #
#                         haven't implemented it for messages yet         #
#       (July 14th-20 changes were not tracked)                           #
#	July 14th, 1999 - Module first created                            #
#                                                                         #
#       $Id: vCard.pm,v 1.4 1999/10/10 19:52:05 fhurtubi Exp $          #
#-------------------------------------------------------------------------#

use vars qw($VERSION);
$VERSION='0.08';
use strict;

sub BEGIN {
#---------------------------------------------------------------#
# This currently isn't used, but is kept for completeness sake. #
#---------------------------------------------------------------#
	1;
}

sub vCard_struct {
#-------------------------------------------------------------------------------------#
# This section initializes the attributes dealt with, and defines their data formats. #
# It was originally based on the Versit vCard 2.1 specification, but was updated to   #
# the 3.0 specification to match RFC 2426.                                            #
#-------------------------------------------------------------------------------------#


#-------------------------------------------------------#
# BEGIN:VCARD	- This begins a vCard or a nested vCard #
# END:VCARD	- This is the vCard end tag             #
#-------------------------------------------------------#
    my %vCard;
    $vCard{'begin'}		= "BEGIN:VCARD";
    $vCard{'2.1'}		= "VERSION:2.1";
    $vCard{'3.0'}		= "VERSION:3.0";
    $vCard{'end'}		= "END:VCARD";
    my $vCard_tags		 = \%vCard;

    #my $version = "2.1"; # Kludge to avoid -w warnings for the moment. ######## REPLACE WHEN V3.0 COMPATIBILITY ADDED ######
    my $version = "3.0";  # This is TENTATIVE.  I like to think that it's up to snuff, but some bits may still require tweaking. Caveat emptor!

#---------------------------------#
# Formatted Name tag:             #
#                                 #
# FN:<formatted name> (OPTIONAL)  #
#---------------------------------#
    my $formatted_name = "";

#-------------------------------------------------------------------------------#
# Name tag:                                                                     #
#                                                                               #
# N:<lastname,0>;<firstname,1>;<middle names,2>;<name prefix,3>;<name suffix,4> #
#-------------------------------------------------------------------------------#
    my @name = ('','','','','');
    my $name = \@name;

    my $name_tag = "N";

    my %name;
    $name{'last'}	= 0;
    $name{'first'}	= 1;
    $name{'middle'}	= 2;
    $name{'prefix'}	= 3;
    $name{'suffix'}	= 4;
    my $name_element = \%name;


#-----------------------------------#
# Nickname tag:                     #
# NICKNAME:<name1>,<name2>,<etc...> #
#-----------------------------------#
    my @nicknames;
    my $nicknames = \@nicknames;

#--------------------------------------------------------------#
# Photograph tag:                                              #
#                                                              #
# PHOTO;VALUE=uri:<uri>                                        #
#	- OR -                                                 #
# PHOTO;ENCODING=b;TYPE=<file mimetype>:<base64 encoded info>  #
#--------------------------------------------------------------#
    my @photographs;
    my $photographs = \@photographs; 

    my %photo_elements;
    $photo_elements{'type'} = 0;
    $photo_elements{'value'} = 1;
    my $photo_elements = \%photo_elements;

#--------------------------------------------------------------------#
# Birthday tag:                                                      #
#                                                                    #
# BDAY:<birthday>                                                    #
# 	where format for <birthday> is either yyyymmdd or yyyy-mm-dd #
#--------------------------------------------------------------------#
    my $birthday = '';

#----------------------------------------------------------------------------------------------------------------------#
# Address tag:                                                                                                         #
#                                                                                                                      #
# ADR<;type(;type;type...),0>:<address,1>;<x-address,2>;<street,3>;<locality,4>;<region,5>;<postal code,6>;<country,7> #
#	Where <type> is one or more of the following:                                                                  #
#		INTL (default), DOM, POSTAL (default), PARCEL (default), HOME, WORK (default)                          #
#----------------------------------------------------------------------------------------------------------------------#
    my @default_addr_types	= ('INTL','POSTAL','PARCEL','WORK');
    #my @addr 		= (\@default_addr_types,'','','','','','','');
    my @addr;
    my $addr = \@addr;


# The following allows for multiple addresses 
#############################################
#push (my @address_list,$addr);
    my @address_list;
    my $address_list = \@address_list;

# The following allows for a "by name" access to the array elements.
####################################################################
    my %addr;
    $addr{'types'}	= 0;
    $addr{'addr'}	= 1;
    $addr{'xaddr'}	= 2;
    $addr{'street'}	= 3;
    $addr{'locale'}	= 4;
    $addr{'region'}	= 5;
    $addr{'code'}	= 6;
    $addr{'country'}    = 7;
    $addr{'grouping'}   = 8;
    my $addr_element = \%addr;

#------------------------------------------------------------------------------------------------#
# Mailing Label tag:                                                                             #
#                                                                                                #
# LABEL;TYPE=<comma delimited typelist>:<\n delimited  formatted mailing label in 8bit encoding> #
#	where <typelist> is one or more of the following:                                        #
#		INTL (default), DOM, POSTAL (default), PARCEL (default), HOME, WORK (default     #
#------------------------------------------------------------------------------------------------#
    my @default_label_types	= ('INTL','POSTAL','PARCEL','WORK');
    my @labels;
    my $labels = \@labels;

#------------------------------------------------------------------------------------------------------#
# Telephone tag:                                                                                       #
#                                                                                                      #
# TEL;<type(;type;type...),0>:<number>                                                                 #
#	Where <type> is one or more of the following:                                                  #
#		PREF, WORK, HOME, VOICE (default), FAX, MSG, CELL, PAGER, BBS, MODEM, CAR, ISDN, VIDEO #
#------------------------------------------------------------------------------------------------------#
    my @default_phone_types	= ('VOICE');
#my @phone 	= (\@default_phone_types,'');
    my @phone;
    my $phone = \@phone;

    my @phone_numbers;
    my $phone_numbers = \@phone_numbers;

    my %phone;
    $phone{'types'}    = 0;
    $phone{'number'}   = 1;
    $phone{'grouping'} = 2;
    my $phone_element = \%phone;

#-------------------------------------------------------------------------------------------------------#
# Email tag:                                                                                            #
#                                                                                                       #
# EMAIL;<type,0>:<address,1>                                                                            #
#	Where <type> is one of the following:                                                           #
#		AOL, Applelink, ATTMail, CIS, eWorld, INTERNET (default), IBMMail, MCIMail, Powershare, #
#		PRODIGY, TLX, X400                                                                      #
#-------------------------------------------------------------------------------------------------------#
#my @email = ('INTERNET','');
    my @default_email_types = ('INTERNET');

    my @email;
    my $email = \@email;

# The following allows for multiple email addresses.
####################################################
#push (my @email_addresses,$email);
    my @email_addresses;
    my $email_addresses = \@email_addresses;

# The following allows for "by name" access to email fields.
############################################################
    my %email;
    $email{'types'}		= 0;
    $email{'address'}	= 1;
    my $email_elements = \%email;

#-----------------------------#
# Mailer (Email handler) tag: #
#                             #
# MAILER:<mailer name>        #
#-----------------------------#
    my $mailer = "";

#----------------------------------------------------------------------#
# Time Zone tag:                                                       #
#                                                                      #
# TZ:<UTC-offset>                                                      #
#	- or -                                                         #
# TZ:<single text value>                                               #
#                                                                      #
# Ex:                                                                  #
#        TZ:-05:00                                                     #
#        TZ;VALUE=text:-05:00; EST; Raleigh/North America              #
#        ;This example has a single value, not a structure text value. #
#----------------------------------------------------------------------#
    my $TZ = '00:00';	# Default is no offset from UTC.  Change this???

#-----------------------------------------------------------------#
# Geographical Coordinates tag:                                   #
#                                                                 #
# GEO:<latitude as float>;<longitude as float>                    #
#                                                                 #
# NOTE: Conversion formula from degrees/minutes/seconds to float: #
#	decimal = degrees + minutes/60 + seconds/3600             #
#-----------------------------------------------------------------#  
    my %geo;
    $geo{'longitude'} = '0';
    $geo{'latitude'}  = '0';
    my $geo = \%geo;

#---------------------------#
# Organizational Title tag: #
#                           #
# TITLE:<title>             #
#---------------------------#
    my @titles;
    my $titles = \@titles;

#--------------------------#
# Organizational Role tag: #
#                          #
# ROLE:<role>              #
#--------------------------#
    my @roles;
    my $roles = \@roles;

#-------------------------------------------------------------#
# Logos tag:                                                  #
#                                                             #
# LOGO;VALUE=uri:<uri>                                        #
#	- OR -                                                #
# LOGO;ENCODING=b;TYPE=<file mimetype>:<base64 encoded info>  #
#-------------------------------------------------------------#
    my @logos;
    my $logos = \@logos; 

    my %logo_elements;
    $logo_elements{'type'} = 0;
    $logo_elements{'value'} = 1;
    my $logo_elements = \%logo_elements;


#---------------------------------------------------------------#
# Agents tag:                                                   #
#                                                               #
# This is real hairy.  It's basically a vCard embedded within a #
# vCard.  Initializing it as a blank array for now.             #
#                                                               #
# NOTE: !!!!!!!!!!! NEEDS WORK !!!!!!!!!!!!                     #
#---------------------------------------------------------------#
    my @agents;
    my $agents = \@agents;

#-------------------------------------------------------------#
# Organizations tag:                                          #
#                                                             #
# ORG:<organization name>                                     #
#-------------------------------------------------------------#
    my @organizations;
    my $organizations = \@organizations; 

#--------------------------------------------#
# Categories tag:                            #
#                                            #
# CATEGORIES:<category 1>,<category 2>,<etc> #
#--------------------------------------------#
    my $categories;

#-------------#
# Note tag:   #
#             #
# NOTE:<note> #
#-------------#
    my @notes;
    my $notes = \@notes;

#--------------------#
# Revision Date tag: #
#                    #           
# REV:<date-time>    #
#	- OR -       #
# REV:<date>         #
#--------------------#
    my $revision_date = '';

#-----------------------------------------------#
# Sort String Key tag:                          #
#                                               #
# SORT-STRING:<string key, usually 'last name') #
#-----------------------------------------------#
    my $sort_string = '';

#-------------------------------------------------------------#
# Sound bites tag:                                            #
#                                                             #
# SOUND;VALUE=uri:<uri>                                       #
#	- OR -                                                #
# SOUND;ENCODING=b;TYPE=<file mimetype>:<base64 encoded info> #
#-------------------------------------------------------------#
    my @sounds;
    my $sounds = \@sounds; 

    my %sound_elements;
    $sound_elements{'type'} = 0;
    $sound_elements{'value'} = 1;
    my $sound_elements = \%sound_elements;


#---------------------------#
# Universal Identifier tag: #
#                           #
# UID:<UID value>           #
#---------------------------#
    my $UID = '';	# Note that the default isn't very unique.

#-----------#
# URL tag:  #
#           #
# URL:<uri> #
#-----------#
    my @urls;
    my $urls = \@urls;

#---------------------#
# Security Class tag: #
#                     #
# CLASS:<class>       #
#---------------------#
    my $class = 'PUBLIC';	# By default set the document public. !!!!!!!!! Should we? !!!!!!!!!

#--------------------------------------#
# Public Key/Certificate tag:          #
#                                      #
# KEY;ENCODING=b:<base 64 encoded key> #
#--------------------------------------#
    my @key = ('','');
    my $key = \@key;		

#-------------------------------------------------------------#
# These two variables are used to enable warnings and errors. #
#-------------------------------------------------------------#
    my $warnings = '0';	# Enable warnings by setting to 1
    my $errors	 = '0';  # Enable errors by setting to 1


#---------------------------------------------------------------#
# Here's where all the subtypes are assembled into the nuclear  #
# sprawling chaos that is the vCard object, which isn't half as #
# hairy as it looks once you get to know it. :)                 #
#---------------------------------------------------------------#
    my $vCard = {
	"basetags"		=> $vCard_tags,		# These are the BEGIN,END and VERSION tags

	"formatted_name"	=> $formatted_name,	# The FN element
	"name"			=> $name,		# This is the N (Name) element properties
	"nicknames"		=> $nicknames,		# The array of nickname elements
	"photographs"		=> $photographs,		# The array of photograph elements
	"birthday"		=> $birthday,		# This is the birthday element.

	"address_list"		=> $address_list,	# This is the array of ADR (ADdRess) subobjects.
	"labels"		=> $labels,		# This is the array of formatted mailing labels.
	
	"phone_numbers"		=> $phone_numbers,	# This is the array ofTEL (TELephone number) subobjects.
	"email_addresses"	=> $email_addresses,	# This is the array of EMAIL subobjects.
	"mailer"		=> $mailer,		# This is the email software used by the vCard holder

	"geo"			=> $geo,		# The hash of geographical coordinates
	"TZ"			=> $TZ,			# The time zone information of the vCard holder

	"titles"		=> $titles,		# The array of organizational titles of the vCard holder
	"roles"			=> $roles,		# The array of organizational roles of the vCard holder
	"logos"			=> $logos,		# The array of organizational logos of the vCard holder
	"agents"		=> $agents,		# The (*shudder*) array of the vCard holder's agents 
	"organizations"		=> $organizations,	# The array of organizations/units/subunits of the holder

	"categories"		=> $categories,		# Information categories the vCard belongs to
	"notes"			=> $notes,		# Notes included on the card
	"prodid"		=> "HBE vCard.pm",	# Product creating the vCard object.  (Until better speced)	
	"revision"		=> $revision_date,	# Date of last revision.
	"sort-string"		=> $sort_string,	# String to perform sort routines on (usually lastname)
	"sounds"		=> $sounds,		# Array of sound objects (encoded or referenced)
	"UID"			=> $UID,		# Unique vCard identifier.
	"URLs"			=> $urls,		# Array of associated URL objects
	"version" 		=> $version,		# vCard spec version number (Curr. 2.1,  changing to 3.0)

	"class"			=> $class,		# Security class(es) of vCard
	"key"			=> $key,		# Public keys/certificate of vCard holder

	# No extended types are defined at the present time.	

	"name_elements"		=> $name_element,	# This is the reference table for by-name lookups of name properties.
	"photo_elements"        => $photo_elements,     # This is the reference table for by-name lookups of photo properties.
	"address_elements"	=> $addr_element,	# This is the reference table for by-name lookups of address properties.
	"phone_elements"	=> $phone_element,	# This is the reference table for by-name lookups of phone # properties.
	"email_elements"	=> $email_elements,	# This is the reference table for by-name lookups of email properties.
	"logo_elements"         => $logo_elements,	# This is the reference table for by-name lookups of logo properties.
	"sound_elements"        => $sound_elements,	# This is the reference table for by-name lookups of sound properties.
	"warnings"              => $warnings,
        "errors"                => $errors,
	};
    return $vCard;
}



#==================================#
#          OBJECT METHODS          #
#==================================#

sub init_vCard {
    my $vCard = vCard_struct; 
    return $vCard;
}

sub new {
#--------------------------------------------------------------------------------#
# Useage:                                                                        #
# 	use vCard;                                                               #
#       $vcard = new vCard;                                                      #
#		OR                                                               #
#	$vcard = new vCard($options)                                             #
# Purpose:                                                                       #
# 	Instantiates a new vCard object.                                         #
# 	In nomine Pater, et Filius, et Spiritus Sancti...                        #
#       In the second case, takes a space delimited list of options (consisting  #
#       of either "warnings", "errors" or both) to enable error and warning      #
#       messaging.                                                               #
#--------------------------------------------------------------------------------#
    my $classname = shift;
    my $options;
    unless ($options = shift) {$options = ''};

    my $vCard = &init_vCard;

    if (index($options,"errors") != -1) {
	$vCard->{'errors'} = 1;
    }
    if (index($options,"warnings") != -1) {
	$vCard->{'warnings'} = 1;
    }
    
    bless $vCard, $classname;
    return $vCard;
}


#------------------------------------------------------------
# loadcard - takes an existing data structure (eg from the database)
#	             and blesses it into a vCard object
#------------------------------------------------------------

sub loadcard
{
	my $classname = shift;
	my $data = shift;

	bless $data, $classname;
	return $data;
}



sub importcard {
    my $vCard = shift;
    my @parselines = @_;

    if (@parselines > 0) {
	my @outlines = $vCard->unfold(@parselines);
	shift @outlines;
	shift @outlines;
	my $outlines = \@outlines;

	$vCard->parse(\@outlines);
    } else {
	if ($vCard->{'warnings'}) {
	    print STDERR "Warning: Nothing to import.\n";
	}
    }
    return $vCard;
}

sub parse {
    my $vCard = shift;
    my $parselines = shift;
    my @parselines = @$parselines;

    foreach my $line (@parselines) {
	my ($type,@info) = split(/\:/,$line);
	my $info = "";
	my $grouping = "";
	my $as_is_info = "";
	foreach my $info_item (@info) {
	    $info .= $info_item;
	    $as_is_info .= ":" . $info_item;
	}
	$as_is_info =~ s/^://;
	my @type_bites = split(/\;/,$type);
	if (index($type_bites[0],'.') ne -1) {
	    $grouping = substr($type_bites[0],0,index($type_bites[0],'.'));
	    $type_bites[0] = substr($type_bites[0],index($type_bites[0],'.')+1);
	}
	$type = shift @type_bites;
	my $subtype = '';
	if ($type eq "BEGIN") {
	    #$vCard->parse_begin;
	} elsif ($type eq "FN") {
	    $vCard->parse_fn($info);
	} elsif ($type eq "N") {
	    $vCard->parse_name($info);
	} elsif ($type eq "NICKNAME") {
	    $vCard->parse_nickname($info);
	} elsif ($type eq "PHOTO") {
	    $vCard->parse_photo(\@type_bites,$info);
	} elsif ($type eq "BDAY") {
	    $vCard->parse_birthday($info);
	} elsif ($type eq "ADR") {
	    $vCard->parse_address(\@type_bites,$info,$grouping);
	} elsif ($type eq "LABEL") {
	    $vCard->parse_label(\@type_bites,$info);
	} elsif ($type eq "TEL") {
	    $vCard->parse_telephone(\@type_bites,$info,$grouping);
	} elsif ($type eq "EMAIL") {
	    $vCard->parse_email(\@type_bites,$info,$grouping);
	} elsif ($type eq "MAILER") {
	    $vCard->parse_mailer($info);
	} elsif ($type eq "TZ") {
	    $vCard->parse_tz($as_is_info);
	} elsif ($type eq "GEO") {
	    $vCard->parse_geo($info);
	} elsif ($type eq "TITLE") {
	    $vCard->parse_title($info);
	} elsif ($type eq "ROLE") {
	    $vCard->parse_role($info);
	} elsif ($type eq "LOGO") {
	    $vCard->parse_logo(\@type_bites,$info);
	} elsif ($type eq "AGENT") {
	    # Run around screaming and hide in the corner, 
	    # is my first suggestion...
	    #$vCard->parse_agent;
	} elsif ($type eq "ORG") {
	    $vCard->parse_org($info);
	} elsif ($type eq "CATEGORIES") {
	    $vCard->parse_categories($info);
	} elsif ($type eq "NOTE") {
	    $vCard->parse_note($info);
	} elsif ($type eq "PRODID") {
	    $vCard->parse_prodid($info);
	} elsif ($type eq "REV") {
	    $vCard->parse_revisiondate($info);
	} elsif ($type eq "SORT-STRING") {
	    $vCard->parse_sort_string($info);
	} elsif ($type eq "SOUND") {
	    $vCard->parse_sound(\@type_bites,$info);
	} elsif ($type eq "UID") {
	    $vCard->parse_UID($info);
	} elsif ($type eq "URL") {
	    $vCard->parse_URL($info);
	} elsif ($type eq "VERSION") {
	    #$vCard->parse_version;
	} elsif ($type eq "CLASS") {
	    $vCard->parse_class($info);
	} elsif ($type eq "KEY") {
            $vCard->parse_key(\@type_bites,$info);
        } elsif ($type eq "END") {
	    #$vCard->parse_end;
        } else {
	    if ($vCard->{'warnings'}) {
	         print STDERR "Warning: Line of unknown type ($type) passed to 'parse'\n";
	    }

        }
    }

    return $vCard;
}

sub parse_begin {
    1;
}

sub header {
#------------------------------------#
# Useage:                            #
#	$vcard->header;              #
#                                    #
# Purpose:                           #
#	Returns a "BEGIN:VCARD" tag. #
#------------------------------------#
    my $vCard = shift;
    my $returnvalue = $vCard->{'basetags'}->{'begin'} . "\n";
    return $returnvalue;
}


sub parse_version {
    #------------------------------------------#
    # Blank for the moment.  Defaults to V3.0. #
    #------------------------------------------#
}

sub version {
#--------------------------------------------------#
# Useage:                                          #
#	$vcard->version                            #
#                                                  #
# Purpose:                                         #
#	Returns a vCard VERSION specification tag. #
#--------------------------------------------------#
    my $vCard = shift;
    my $returnvalue = "";
    if ($vCard->{'version'} == "2.1") {
	$returnvalue .= "VERSION:2.1\n";
    } elsif ($vCard->{'version'} == "3.0") {
	$returnvalue .= "VERSION:3.0\n";
    } else {
	if ($vCard->{'warnings'}) {
	    print STDERR "Warning: Card version number ('" . $vCard->{'$version'} . "') not supported.\n";
	}
	$returnvalue = "";
    }
    return $returnvalue;
}


sub fn {
#---------------------------------------#
# Useage:                               #
#	$vcard->fn                      #
#                                       #
# Purpose:                              #
#	Returns formatted name (FN) tag #
#---------------------------------------#
	my $vCard = shift;
	my $fn = '';
	if ($vCard->{formatted_name} ne '') {
	    $fn = "FN:";
	    $fn .= $vCard->{formatted_name} . "\n";
	} else {
	    if ($vCard->{'warnings'}) {
		print STDERR "Warning: No value currently assigned to FN tag.\n";
	    }
	}
	return &fold($fn);
}

sub parse_fn {
#--------------------------------------------#
# Useage:                                    #
#       $vcard->parse_fn($fn_line)           #
#               where                        #
#       $fn_line = a vCard FN formatted line #
#                                            #
# Purpose:                                   #
#       Translates a formatted FN line into  #
#       a Perl vCard object FN line.         #
#--------------------------------------------#
    my $vCard = shift;
    my $fn = shift;
    $vCard->fn_set($fn);
    return $vCard;
}

sub fn_set {
#-------------------------------------------------------------------#
# Useage:                                                           #
#	$vcard->fn_set($formatted_name)                             #
#		where                                               #
#	$formatted_name = the formatted name of the person.  (Duh!) #
#                                                                   #
# Purpose:                                                          #
# 	Sets the FN tag for this vCard.                             #
#                                                                   #
# Returns Subobjects: n/a                                           #
#-------------------------------------------------------------------#
	my $vCard = shift;
	my $formatted_name = shift;
	$vCard->{formatted_name} = $formatted_name;
	return $vCard;
}


sub name {
#--------------------------------------------------#
# Useage:                                          #
#	$vcard->name;                              #
#           - OR -                                 #
#       $vcard($fieldname);                        #
#                                                  #
# Purpose:                                         # 
#	Returns name (NAME) tag in the first case, #
#       or a specific field of the NAME tag in the #
#       second case.                               #
#                                                  #
# Returns subobjects: Yes                          #
#--------------------------------------------------#
	my $vCard = shift;
	my $returnvalue = '';
	if (@_ == 0) {
	    if (($vCard->{'name'}->[0] ne '') || ($vCard->{'name'}->[1] ne '') ) {
		$returnvalue = "N:";
		$returnvalue .= $vCard->{'name'}->[0] . ";";	
		$returnvalue .= $vCard->{'name'}->[1] . ";";	
		$returnvalue .= $vCard->{'name'}->[2] . ";";	
		$returnvalue .= $vCard->{'name'}->[3] . ";";	
		$returnvalue .= $vCard->{'name'}->[4];	
		$returnvalue .= "\n";
		# N:<lastname,0>;<firstname,1>;<middle names,2>;<name prefix,3>;<name suffix,4>
		&fold($returnvalue);
	    } else {
		if ($vCard->{'warnings'}) { print STDERR "Warning: No values current assigned to N (name) tag.\n"; }
	    }
	} elsif (@_ == 1) {
	    my $fieldname = shift;
	    if ($vCard->{'name_elements'}->{$fieldname} ne '') {
		$returnvalue = $vCard->{'name'}->[$vCard->{'name_elements'}->{$fieldname}];
	    } else {
		if ($vCard->{'errors'}) {
		    print STDERR "Error: NAME tag has no '" . $fieldname . "' property.\n";
		}
	    }
	} else {
	    if ($vCard->{'errors'}) {
		print STDERR "Error: Too many parameters passed to name().";
		print STDERR "(Expected 0 or 1, got " . @_ . ")\n";
	    }
	}
	return $returnvalue;	
}

sub parse_name {
#----------------------------------------------#
# Useage:                                      #
#       $vcard->parse_name($name_line)         #
#               where                          #
#       $name_line = a vCard N formatted line  #
#                                              #
# Purpose:                                     #
#       Translates a formatted N line into     #
#       a Perl vCard object N line.            #
#----------------------------------------------#
    my $vCard = shift;
    my $nameinfo = shift;
    my @namefields = split(/;/,$nameinfo);
    &name_set($vCard,$namefields[0],$namefields[1],$namefields[2],$namefields[3],$namefields[4]);
    return $vCard;
}

sub name_set {
#---------------------------------------------------------------------------------------#
# Useage:                                                                               #
#	$vcard->(<lastname>,<firstname>,<middlename>,<prefix>,<suffix>)                 #
#				OR                                                      #
#	$vcard->(<fieldname>,<value>) where fieldname = first,last,middle,prefix,suffix #
#				                                                        #
# Purpose:                                                                              # 
#	Modifies name information on vCard.                                             #
#---------------------------------------------------------------------------------------#
	my $vCard = shift;
	my @values = @_;
	if (@values == 5) {  
		#-----------------------------------------------------#
		# Case 1: All name values assigned in one fell swoop. #
		#-----------------------------------------------------#
		my $lastname 	= @_->[0];
		my $firstname	= @_->[1];
		my $middlename	= @_->[2];
		my $prefix	= @_->[3];
		my $suffix	= @_->[4];
		$vCard->{'name'}->[0] = $lastname;
		$vCard->{'name'}->[1] = $firstname;
		$vCard->{'name'}->[2] = $middlename;
		$vCard->{'name'}->[3] = $prefix;
		$vCard->{'name'}->[4] = $suffix;
	} elsif (@values == 2) {
		#-----------------------------------------------------#
		# Case 2: A single specified name value gets changed. #
		#-----------------------------------------------------#
		my ($namefield,$value) = @values;
		if ($vCard->{name_elements}->{$namefield} ne '') {
			my $element_number = $vCard->{name_elements}->{$namefield};
			$vCard->{'name'}->[$element_number] = $value;
		} else {
			if ($vCard->{'errors'}) {
				print STDERR "Error: Couldn't change name element. ";
				print STDERR "(No such name element - '$namefield').\n";
			}
		}
	} else {
		#------------------------------------------------#
		# Error Case: Wrong number of parameters passed. #
		#------------------------------------------------#
		if ($vCard->{'errors'}) {
			print STDERR "Error: Couldn't process requested name info change. ";
			print STDERR "(2 or 5 parameters expected, " . @values . " parameters passed)\n";
		}
	}
	return $vCard;
}

sub nickname {
#--------------------------------------#
# Useage:                              #
#	$vcard->nickname;              #
#		OR                     #
#	$vcard->nickname($num)         #
#	       WHERE                   #
#       $num = nickname object index   #
#                                      #
# Purpose:                             # 
#	Returns all NICKNAME tags in   #
#	the first form, and a specific #
#	address tag in the second.     #
#                                      #
# Returns Subobjects: Yes              #
#--------------------------------------#
	my $vCard = shift;
	if (@_ == 0) {
		#---------------------------------------------------------------#
		# Case 1: No parameters passed, return all NICKNAME subobjects. #
		#---------------------------------------------------------------#
		my $nickname_list = "NICKNAME:";
		if (@{$vCard->{nicknames}} > 0) {
			foreach my $nickname (@{$vCard->{nicknames}}) {
				$nickname_list .= $nickname . ",";	
			}
			$nickname_list =~ s/,$/\n/;
			return &fold($nickname_list);
		} else {
			if ($vCard->{'warnings'}) {
				print STDERR "Warning: No nicknames (NICKNAME) currently assigned to this vCard.\n";
			}
			return '';
		}
	} elsif (@_ == 1) {
		#--------------------------------------------------------------------#
		# Case 2: One parameter passed, return specified NICKNAME subobject. #
		#--------------------------------------------------------------------#
		my $nickname_index = shift;
		my @nicknames = @{$vCard->{nicknames}};
		my $max_index = @nicknames - 1;
		if ($nickname_index !~ /\D/ && $nickname_index <= ($max_index)) {
			#---------------------------------------------------#
			# Good Case: Number passed, and within array range. #
			#---------------------------------------------------#
			my $nickname_list = "";
			my $nickname = $vCard->{nicknames}->[$nickname_index];
			$nickname_list .= "NICKNAME:";		
			$nickname_list .= $nickname->[0];	
			$nickname_list .= "\n";
			return &fold($nickname_list);
		} else {
			#-----------------------------------------------------#
			# Bad Case: Non number or out of range number passed. #
			#-----------------------------------------------------#
			if ($nickname_index =~ /\D/) {
				#------------------------------------------------#
				# Bad Case Type 1: Non numeric parameter passed. #
				#------------------------------------------------#
				if ($vCard->{'errors'}) {
					print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
					print STDERR "('" . $nickname_index . "') passed to 'nickname'.\n";
				}
			} else {
				#----------------------------------------------------------------------#
				# Bad Case Type 2: Parameter out of range of NICKNAME subobject array. #
				#----------------------------------------------------------------------#
				if ($vCard->{'errors'}) {
					print STDERR "Error: Parameter passed to 'nickname' out of range. ";
					print STDERR "('" . $nickname_index . "' when max is '" . $max_index . "')\n"; 
				}
			}
			return "";
		}
	} else {
		#-------------------------------------------------#
		# Error case.  Wrong number of parameters passed. #
		#-------------------------------------------------#
		if ($vCard->{'errors'}) {	
			print STDERR "Error: Wrong number of parameters passed to 'nickname'. ";
			print STDERR "(Expected 0 or 1 parameters, got " . @_ . ")\n";
		}
		return "";
	}
}

sub parse_nickname {
#--------------------------------------------------------#
# Useage:                                                #
#       $vcard->parse_nickname($nickname_line)           #
#               where                                    #
#       $nickname_line = a vCard NICKNAME formatted line #
#                                                        #
# Purpose:                                               #
#       Translates a formatted NICKNAME line into        #
#       a Perl vCard object N line.                      #
#--------------------------------------------------------#
    my $vCard = shift;
    my $nicknameinfo = shift;
    my @nicknames = split(/,/,$nicknameinfo);
    foreach my $nn (@nicknames) {
	&nickname_set($vCard,'NEW',$nn);
    }
    return $vCard;
}


sub nickname_set {
#---------------------------------------------------------------------------------------------------------
# Useage:                                                                                                #
#                                                                                                        #
# $vcard->nickname_set($nickname_list);                                                                  #
#	where	$nickname_list = valid comma delimited list of nicknames                                 #
#              - OR -                                                                                    #
# $vcard->nickname_set('new',$nickname_list);                                                            #
#                                                                                                        #
# Purpose:                                                                                               #
#	Sets the nickname list in the first form, and adds a nickname to list in the second.             #
#--------------------------------------------------------------------------------------------------------#
	my $vCard = shift;
	if (@_ == 1) {
	    my @nicknames =  split(/\,/,shift);
            @{$vCard->{nicknames}} = (); # instead of undef, otherwise, was getting errors later
	    foreach my $nickname (@nicknames) {
		push (@{$vCard->{nicknames}},$nickname);
	    }
	} elsif (@_ == 2) {
	    my $new = shift;
	    my $nickname = shift;
	    if ($new eq "NEW") {
		push (@{$vCard->{nicknames}},$nickname);
	    } else {
		if ($vCard->{'errors'}) { print STDERR "Error: First parameter passed to 'nickname' not 'NEW'\n"; }
	    }
	} else {
	    if ($vCard->{'errors'}) { 
		print STDERR "Error: Wrong number of parameters passed to 'nickname'. ";
		print STDERR "(Expected 0 or 1, got " . @_ . ")\n";
	    }
	}
	return $vCard;
}

sub photo {
#-------------------------------------#
# Useage:                             #
#	$vcard->photo;                #
#		OR                    #
#	$vcard->photo($num)           #
#	       WHERE                  #
#       $num = photo object index     #
#               OR                    #
#       $vcard->photo($num,$field)    #
#              WHERE                  #
#       $field = 'type' or 'value'    #
#                                     #
# Purpose:                            # 
#	Returns all PHOTO tags in the #
#	first form, and a specific    #
#	photograph tag in the second. #
#-------------------------------------#
	my $vCard = shift;
	if (@_ == 0) {
		#------------------------------------------------------------#
		# Case 1: No parameters passed, return all PHOTO subobjects. #
		#------------------------------------------------------------#
		my $photo_list = "";
		foreach my $photo (@{$vCard->{photographs}}) {
			$photo_list .= "PHOTO;";			
			if ($photo->[0] eq "URL") {
				$photo_list .= "VALUE=uri:";
			} else {
				$photo_list .= "ENCODING=b;TYPE=" . $photo->[0] . ":"; 
			}
			$photo_list .= $photo->[1];	
			$photo_list .= "\n";
		# PHOTO;VALUE=uri:<uri>                                        
		#	- OR -                                                 
		# PHOTO;ENCODING=b;TYPE=<file mimetype>:<base64 encoded info>  
		}
		return &fold($photo_list);
	} elsif (@_ == 1) {
		#-----------------------------------------------------------------#
		# Case 2: One parameter passed, return specified PHOTO subobject. #
		#-----------------------------------------------------------------#
		my $photo_index = shift;
		my @photographs = @{$vCard->{photographs}};
		my $max_index = @photographs - 1;
		if ($photo_index !~ /\D/ && $photo_index <= ($max_index)) {
			#---------------------------------------------------#
			# Good Case: Number passed, and within array range. #
			#---------------------------------------------------#
			my $photo = $vCard->{photographs}->[$photo_index];
			my $photo_list = '';
			if ($photo->[0] eq "URL") {
				$photo_list .= "VALUE=uri:";
			} else {
				$photo_list .= "ENCODING=b;TYPE=" . $photo->[0] . ":"; 
			}
			$photo_list .= $photo->[1];	
			$photo_list .= "\n";
			return &fold($photo_list);
		} else {
		    #-----------------------------------------------------#
		    # Bad Case: Non number or out of range number passed. #
                    #-----------------------------------------------------#
		    if ($photo_index =~ /\D/) {
                        #------------------------------------------------#
			# Bad Case Type 1: Non numeric parameter passed. #
			#------------------------------------------------#
			if ($vCard->{'errors'}) {
			    print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
				print STDERR "('" . $photo_index . "') passed to 'photo'.\n";
			}
		} else {
			#-------------------------------------------------------------------#
			# Bad Case Type 2: Parameter out of range of PHOTO subobject array. #
			#-------------------------------------------------------------------#
			if ($vCard->{'errors'}) {
			    print STDERR "Error: Parameter passed to 'photo' out of range. ";
			    print STDERR "('" . $photo_index . "' when max is '" . $max_index . "')\n"; 
			}
		    }
		    return "";
		}
	} elsif (@_ == 2) {
            #----------------------------------#
	    # Specific subparameter requested. #
	    #----------------------------------#
	    my $photo_index = shift;
	    my $fieldname = shift;
	    my @photographs = @{$vCard->{photographs}};
	    my $max_index = @photographs - 1;
	    if ($photo_index !~ /\D/ && $photo_index <= ($max_index)) {
                #---------------------------------------------------#
		# Good Case: Number passed, and within array range. #
		#---------------------------------------------------#
		if ($fieldname eq 'type' || $fieldname eq 'value') {
		    #----------------------------------------#
		    # Good case: Field types requested exist #
		    #----------------------------------------#
		    my $field_value = $vCard->{'photographs'}->[$photo_index]->[$vCard->{'photo_elements'}->{$fieldname}];
		    return($field_value);
		} else {
		    if ($vCard->{'errors'}) {
			print STDERR "Error: Field '$fieldname' is not a PHOTO tag field.\n";
		    }
		    return "";
		}
	    } else {
		#-----------------------------------------------------#
		# Bad Case: Non number or out of range number passed. #
		#-----------------------------------------------------#
		if ($photo_index =~ /\D/) {
			#------------------------------------------------#
			# Bad Case Type 1: Non numeric parameter passed. #
			#------------------------------------------------#
			if ($vCard->{'errors'}) {
				print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
				print STDERR "('" . $photo_index . "') passed to 'photo'.\n";
			}
		} else {
			#-------------------------------------------------------------------#
			# Bad Case Type 2: Parameter out of range of PHOTO subobject array. #
			#-------------------------------------------------------------------#
			if ($vCard->{'errors'}) {
			    print STDERR "Error: Parameter passed to 'photo' out of range. ";
			    print STDERR "('" . $photo_index . "' when max is '" . $max_index . "')\n"; 
			}
		    }
		return "";
	    }
	} else {
            #-------------------------------------------------#
	    # Error case.  Wrong number of parameters passed. #
	    #-------------------------------------------------#
	    if ($vCard->{'errors'}) {
		print STDERR "Error: Wrong number of parameters passed to 'photo'. ";
		print STDERR "(Expected 0, 1 or 2 parameters, got " . @_ . ")\n";
	    }
	    return "";
	}
}

sub parse_photo {
#---------------------------------------------------#
# Useage:                                           #
#       $vcard->parse_photo($photo_line)            #
#               where                               #
#       $photo_line = a vCard PHOTO formatted line  #
#                                                   #
# Purpose:                                          #
#       Translates a formatted PHOTO line into      #
#       a Perl vCard object PHOTO line.             #
#---------------------------------------------------#
    my $vCard = shift;
    my $photoinfo = shift;
    my @photofields = @{$photoinfo};

    my $photo_value = shift;
	if (@photofields == 1) {
	    #-----------------------------#
	    # Case 1: URL type photo tag. #
	    #-----------------------------#
	    &photo_set($vCard,"NEW",$photo_value);
	} elsif (@photofields == 2) {
	    #-----------------------------------------------#
	    # Case 2: Base64 encoded inline type photo tag. #
	    #-----------------------------------------------#
 	    my ($typetag,$photo_type) = split(/=/,$photofields[1]);

	    &photo_set($vCard,"NEW",$photo_type,$photo_value);
	} else {
	    # Error Case: Improper number of aatributes listed in tag.
	    if ($vCard->{'errors'}) { 
		print STDERR "Error: PHOTO tag contains improper formatting. (Offending subtags: ";
		print STDERR $photoinfo . ")\n";	   
	    }
	}
	return $vCard;
# PHOTO;VALUE=uri:<uri>                                        #
#	- OR -                                                 #
# PHOTO;ENCODING=b;TYPE=<file mimetype>:<base64 encoded info>  #
}

sub photo_set {
#----------------------------------------------------------------------------------------------------------------#
# Useage:                                                                                                        #
#                                                                                                                #
# $vcard->photo_set($photo_index,$photo_url);                                                                    #
#	where 	$photo_index = # in photo list to modify, or 'NEW' to create a new subobject                     #
#		$photo_url = fully qualified URL pointing towards photo object                                   #
#			--- OR ---                                                                               #
# $vcard->photo_set($photo_index,$photo_type,$base64_encoded_image)                                              #
#	where 	$photo_index 		= # in photo list to modify, or 'NEW' to create a new subobject          #
#		$photo_type  		= the type of image file                                                 #   
#		$base64_encoded_image	= either scalar value, or for type list, space delimited  list of values #
#                                                                                                                #
# Purpose:                                                                                                       #
#                                                                                                                #
# 
#----------------------------------------------------------------------------------------------------------------#
	my $vCard = shift;
	if (@_ == 2) {
		#-------------------------------------#
		# Case 1: Specific/new photo from URL #
		#-------------------------------------#
		my ($photo_index,$photo_url) = @_;
		if ($photo_index eq "NEW") {
			my @new_photo = ('URL',$photo_url);	
			my $new_photo = \@new_photo;
			$vCard->{photographs}->[@{$vCard->{photographs}}]  = $new_photo ;
		} elsif ($photo_index < @{$vCard->{photographs}}) {
			$vCard->{photographs}->[$photo_index]->[0] = 'URL';
			$vCard->{photographs}->[$photo_index]->[1] = $photo_url;
		} else {
			if ($vCard->{'errors'}) {
				print STDERR "Error: No such photograph entry. ";
				print STDERR "(Entry '" . $photo_index . "' requested, max entry is '" . @{$vCard->{photographs}} . "')\n";
			}
		}
	} elsif (@_ == 3) {
		#------------------------------------------#
		# Case 2: Specific/new base64 inline photo #
		#------------------------------------------#
		my ($photo_index,$photo_type,$base64_encoded_image) = @_;
		if ($photo_index eq "NEW") {
			my @new_photo = ($photo_type,$base64_encoded_image);	
			my $new_photo = \@new_photo;
			$vCard->{photographs}->[@{$vCard->{photographs}}]  = $new_photo ;
		} elsif ($photo_index < @{$vCard->{photographs}}) {
			$vCard->{photographs}->[$photo_index]->[0] = $photo_type;
			$vCard->{photographs}->[$photo_index]->[1] = $base64_encoded_image;
		} else {
			if ($vCard->{'errors'}) {
				print STDERR "Error: No such photograph entry. ";
				print STDERR "(Entry '" . $photo_index . "' requested, max entry is '" . @{$vCard->{photographs}} . "')\n";
			}
		}
	} else {
		#----------------------------------------------------#
		# Error Case: Incorrect number of parameters passed. #
		#----------------------------------------------------#
		if ($vCard->{'errors'}) {
			print STDERR "Error: Incorrect number of parameters passed to 'photo_set'. ";
			print STDERR "(Expected 2 or 3 parameters, got " . @_ . ")\n";
		}
	}
	return "$vCard";
} # end photo_set



sub birthday {
#-----------------------------------#
# Useage:                           #
#	$vcard->birthday            #
#                                   #
# Purpose:                          #
#	Returns birthday (BDAY) tag #
#-----------------------------------#
	my $vCard = shift;
	my $bday = "BDAY:";
	$bday .= $vCard->{birthday} . "\n";
	return &fold($bday);
}

sub parse_birthday {
#------------------------------------------------------#
# Useage:                                              #
#       $vcard->parse_birthday($birthday_line)         #
#               where                                  #
#       $birthday_line = a vCard BDAY formatted line   #
#                                                      #
# Purpose:                                             #
#       Translates a formatted BDAY line into a Perl   # 
#       vCard object BDAY line.                        #
#------------------------------------------------------#
    my $vCard = shift;
    my $bday = shift;
    &birthday_set($vCard,$bday);
    return $vCard;
}


sub birthday_set {
#------------------------------------------------------------#
# Useage:                                                    #
#	$vcard->birthday_set($date)                          #
#	 	where $date is either yyyymmdd or yyyy-mm-dd #
#                                                            #
# Purpose:                                                   #
#	Sets the value of the BDAY tag.                      #
#------------------------------------------------------------#
	my $vCard = shift;
	my $bday  = shift;
	$vCard->{birthday} = $bday;
	# BDAY:<birthday>                                                    
	return $vCard;
}

sub address {
#-----------------------------------------#
# Useage:                                 #
#	$vcard->address;                  #
#		OR                        #
#	$vcard->address($num)             #
#	       WHERE                      #
#       $num = address object index       #
#               OR                        #
#       $vcard->address($num,$attr)       #
#              WHERE                      #
#       $attr = one of "types',           #
#               'addr', 'xaddr', 'street',# 
#               'locale', 'region', 'code'#
#               'country' or 'grouping'   #
# Purpose:                                # 
#	Returns all ADR tags in the       #
#	first form, a specific            #
#	address tag in the second,        #
#       and a specific attribute of       #
#       a specific tag in the third.      #
#-----------------------------------------#
	my $vCard = shift;
	if (@_ == 0) {
		#----------------------------------------------------------#
		# Case 1: No parameters passed, return all ADR subobjects. #
		#----------------------------------------------------------#
		my $address_list = "";
		my $adr_count = 0;
		if (@{$vCard->{address_list}} > 0) {
		    foreach my $adr (@{$vCard->{address_list}}) {
			my $address_type_list = "";
			my $address_ok = "N";
			for (my $field = 1; $field <= 7; $field++) {
 			    if ($adr->[$field] ne "") {
				$address_ok = "Y";
			    }
			}
			if ($address_ok eq "Y") {
			    if ($adr->[8] ne '') {
				$address_list .= $adr->[8];
				$address_list .= ".";
			    }
			    $address_list .= "ADR;TYPE=";
			    foreach my $addrtype (@{$adr->[0]}) {
				$address_type_list .= $addrtype . "," ;
			    }
			    $address_type_list =~ s/,$//;
			    $address_list .= $address_type_list . ":";		
			    $address_list .= $adr->[1] . ";";	
			    $address_list .= $adr->[2] . ";";	
			    $address_list .= $adr->[3] . ";";	
			    $address_list .= $adr->[4] . ";";
			    $address_list .= $adr->[5] . ";";
			    $address_list .= $adr->[6] . ";";
			    $address_list .= $adr->[7];
			    $address_list .= "\n";
			} else {
			    if ($vCard->{'warnings'}) { print STDERR "Warning: All fields empty for address (ADR) tag " . $adr_count . ".\n";}
			}
			$adr_count++;
		    }
			# ADR<;type(;type;type...),0>:<address,1>;<x-address,2>;<street,3>;<locality,4>;<region,5>;<postal code,6>;<country,7> 
		}
		
		return &fold($address_list);
	    } elsif (@_ == 1) {
		#---------------------------------------------------------------#
		# Case 2: One parameter passed, return specified ADR subobject. #
		#---------------------------------------------------------------#
		my $adr_index = shift;
		my @addresses = @{$vCard->{address_list}};
		my $max_index = @addresses - 1;
		if ($adr_index !~ /\D/ && $adr_index <= ($max_index)) {
		    #---------------------------------------------------#
		    # Good Case: Number passed, and within array range. #
		    #---------------------------------------------------#
		    my $address_list = "";
		    my $adr = $vCard->{address_list}->[$adr_index];
		    my $address_ok = "N";
		    for (my $field = 1; $field <= 7; $field++) {
			if ($adr->[$field] ne "") {
			    $address_ok = "Y";
			}
		    }
		    if ($address_ok eq "Y") {
			if ($adr->[8] ne "") {
			    $address_list .= $adr->[8] . ".";
			}
			$address_list .= "ADR";
			my $address_type_list = "";
			foreach my $addrtype (@{$adr->[0]}) {
			    $address_type_list .= ";TYPE=" . $addrtype;
			}
			$address_list .= $address_type_list . ":";		
			$address_list .= $adr->[1] . ";";	
			$address_list .= $adr->[2] . ";";	
			$address_list .= $adr->[3] . ";";	
			$address_list .= $adr->[4] . ";";
			$address_list .= $adr->[5] . ";";
			$address_list .= $adr->[6] . ";";
			$address_list .= $adr->[7];
			$address_list .= "\n";
		    } else {
			if ($vCard->{'warnings'}) { print STDERR "Warning: All fields empty for address tag requested.\n";}
		    }
		    return &fold($address_list);
		} else {
			#-----------------------------------------------------#
			# Bad Case: Non number or out of range number passed. #
			#-----------------------------------------------------#
			if ($adr_index =~ /\D/) {
				#------------------------------------------------#
				# Bad Case Type 1: Non numeric parameter passed. #
				#------------------------------------------------#
				if ($vCard->{'errors'}) {
					print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
					print STDERR "('" . $adr_index . "') passed to 'address'.\n";
				}
			} else {
				#---------------------------------------------------------------------#
				# Bad Case Type 2: Parameter out of range of ADRress subobject array. #
				#---------------------------------------------------------------------#
				if ($vCard->{'errors'}) {
					print STDERR "Error: Parameter passed to 'address' out of range. ";
					print STDERR "('" . $adr_index . "' when max is '" . $max_index . "')\n"; 
				}
			}
			return "";
		}
	    } elsif (@_ == 2) {
		    #----------------------------------#
		    # Specific subparameter requested. #
		    #----------------------------------#
		    my $address_index = shift;
		    my $fieldname = shift;
		    my @address = @{$vCard->{address_list}};
		    my $max_index = @address - 1;
		    if ($address_index !~ /\D/ && $address_index <= ($max_index)) {
			#---------------------------------------------------#
			# Good Case: Number passed, and within array range. #
			#---------------------------------------------------#
			if ($vCard->{'address_elements'}->{$fieldname} ne '') {
			    #----------------------------------------#
			    # Good case: Field types requested exist #
			    #----------------------------------------#
			    my $field_value = $vCard->{'address_list'}->[$address_index]->[$vCard->{'address_elements'}->{$fieldname}];
			    return($field_value);
			} else {
			    if ($vCard->{'errors'}) {
				print STDERR "Error: Field '$fieldname' is not an ADDRESS tag field.\n";
			    }
			    return "";
			}
		    } else {
			#-----------------------------------------------------#
			# Bad Case: Non number or out of range number passed. #
			#-----------------------------------------------------#
			if ($address_index =~ /\D/) {
			    #------------------------------------------------#
			    # Bad Case Type 1: Non numeric parameter passed. #
			    #------------------------------------------------#
			    if ($vCard->{'errors'}) {
				print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
				print STDERR "('" . $address_index . "') passed to 'address'.\n";
			    }
			} else {
			    #---------------------------------------------------------------------#
			    # Bad Case Type 2: Parameter out of range of ADDRESS subobject array. #
			    #---------------------------------------------------------------------#
			    if ($vCard->{'errors'}) {
				print STDERR "Error: Parameter passed to 'address' out of range. ";
				print STDERR "('" . $address_index . "' when max is '" . $max_index . "')\n"; 
			    }
			}
			return "";
		    }
	} else {
		#-------------------------------------------------#
		# Error case.  Wrong number of parameters passed. #
		#-------------------------------------------------#
		if ($vCard->{'errors'}) {
			print STDERR "Error: Wrong number of parameters passed to 'address'. ";
			print STDERR "(Expected 0, 1 or 2 parameters, got " . @_ . ")\n";
		}
		return "";
	}
}

sub parse_address {
#---------------------------------------------------#
# Useage:                                           #
#       $vcard->parse_address($address_line)        #
#               where                               #
#       $address_line = a vCard ADR formatted line  #
#                                                   #
# Purpose:                                          #
#       Translates a formatted ADR line into        #
#       a Perl vCard object ADR line.               #
#---------------------------------------------------#
    my $vCard = shift;
    my $addrtypes = shift;
    my $adrinfo = shift;
    my @adrfields = split(/;/,$adrinfo);
    @{$addrtypes}[0] =~ s/TYPE=//;
    my $grouping = shift;
    &address_set($vCard,"NEW",@{$addrtypes},$adrfields[0],$adrfields[1],$adrfields[2],$adrfields[3],
		 $adrfields[4],$adrfields[5],$adrfields[6],$grouping);
#    $vCard->{address_grouping}->[@{$vCard->{address_list}}+1]) = $grouping;
    return $vCard;
}


sub address_set {
#---------------------------------------------------------------------------------------------------------
# Useage:                                                                                                #
#                                                                                                        #
# $vcard->address_set($addr_index,$addr_types,$addr,$xaddr,$locality,$region,$postal,$country,$grouping);#
#	where 	$addr_index = # in address list to modify, or 'NEW' to create a new subobject            #
#		$addr_types = valid space delimited list of address type info                            #
#		$addr	    = street address                                                             #
#		$xaddr      = extended street address                                                    #
#		$locality   = address locality (i.e. city)                                               #
#		$region     = address region (i.e. province)                                             #
#               $postal     = address postal code	                                                 #
#               $country    = address country                                                            #
#               $grouping   = a tag grouping header                                                      #
#			--- OR ---                                                                       #
# $vcard->address_set($addr_index,$fieldname,$value)                                                     #
#	where 	$fieldname  = valid address property fieldname                                           #
#		$value	    = either scalar value, or for type list, space delimited  list of values     #
#			--- OR ---                                                                       #
# Either of the above commands with the $addr_index field excluded from the list of parameters.          #
#                                                                                                        #
# Purpose:                                                                                               #
#                                                                                                        #
# 	In the first form, sets the values for all properties of the address kept in the address_list    #
#       array at position $addr_index.                                                                   #
#       In the second form, sets the values for a specific property of a specific address.               #
#       The third form is a shorthand; in cases where there is only one address, it will obliviate the   #
#       need to type in an $addr_index value.  Note that this means it will apply any changes to         #
#       address_list[0], regardless of how many address_list elements there are, so its use is           #
#       recommended only in cases where there is only one address element present.                       #
#--------------------------------------------------------------------------------------------------------#
	my $vCard = shift;

	if (@_ == 10) {
		#-------------------------------------------#
		# Case 1: Specific address, set all values. #
		#-------------------------------------------#
		my ($addr_index,$typelist,$addr,$xaddr,$street,$locality,$region,$postal,$country,$grouping) = @_;
		my @typelist = split(/ /,$typelist);
		if ($addr_index eq "NEW") {
			my @new_address = (\@typelist,$addr,$xaddr,$street,$locality,$region,$postal,$country,$grouping);
			my $new_address = \@new_address;
			$vCard->{address_list}->[@{$vCard->{address_list}}]  = $new_address ;
		} elsif ($addr_index < @{$vCard->{address_list}}) {
			$vCard->{address_list}->[$addr_index]->[0] = \@typelist;		
			$vCard->{address_list}->[$addr_index]->[1] = $addr;
			$vCard->{address_list}->[$addr_index]->[2] = $xaddr;
			$vCard->{address_list}->[$addr_index]->[3] = $street;
	                $vCard->{address_list}->[$addr_index]->[4] = $locality;
	                $vCard->{address_list}->[$addr_index]->[5] = $region;
	                $vCard->{address_list}->[$addr_index]->[6] = $postal;
	                $vCard->{address_list}->[$addr_index]->[7] = $country;
	                $vCard->{address_list}->[$addr_index]->[8] = $grouping;
		} else {
			if ($vCard->{'errors'}) {
				print STDERR "Error: No such address entry. ";
				print STDERR "(Entry '" . $addr_index . "' requested, max entry is '" . @{$vCard->{address_list}} . "')\n";
			}
		}
	} elsif (@_ == 3) {
		#-------------------------------------------#
		# Case 2: Specific address, set one value.  #
		#-------------------------------------------#
		my ($addr_index,$property,$value) = @_;
		if ($addr_index < @{$vCard->{address_list}} ) {
			if ($vCard->{address_elements}->{$property} ne '') {
				my $element_number = $vCard->{address_elements}->{$property};
				$vCard->{'address_list'}->[$addr_index]->[$element_number] = $value;
			} else {
				if ($vCard->{'errors'}) {
					print STDERR "Error: Couldn't change address element. ";
					print STDERR "(No such name element - '$property').\n";
				}
			}
		} else {
			if ($vCard->{'errors'}) {
				print STDERR "Error: No such address entry. ";
				print STDERR "(Entry '" . $addr_index . "' requested, max entry is '" . @{$vCard->{address_list}} . "')\n";
			}
		}
	} elsif (@_ == 9) {
		#-------------------------------------------#
		# Case 3: Default address, set all values.  #
		#-------------------------------------------#
		my ($typelist,$addr,$xaddr,$street,$locality,$region,$postal,$country,$grouping) = @_;
		my @typelist = split(/ /,$typelist);
		$vCard->{address_list}->[0]->[0] = \@typelist;		
		$vCard->{address_list}->[0]->[1] = $addr;
		$vCard->{address_list}->[0]->[2] = $xaddr;
		$vCard->{address_list}->[0]->[3] = $street;
                $vCard->{address_list}->[0]->[4] = $locality;
                $vCard->{address_list}->[0]->[5] = $region;
                $vCard->{address_list}->[0]->[6] = $postal;
                $vCard->{address_list}->[0]->[7] = $country;
                $vCard->{address_list}->[0]->[8] = $grouping;
	} elsif (@_ == 2) {
		#----------------------------------------#
		# Case 4: Default address, set one value #
		#----------------------------------------#
		my ($property,$value) = @_;
		#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
		# ADD $addr_index range checking code here! #
		#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
		if ($vCard->{address_elements}->{$property} ne '') {
			my $element_number = $vCard->{address_elements}->{$property};
			$vCard->{'address_list'}->[0]->[$element_number] = $value;
		} else {
			if ($vCard->{'errors'}) {
				print STDERR "Error: Couldn't change address element. ";
				print STDERR "(No such name element - '$property').\n";
			}
		}
	} else {
		#----------------------------------------------------#
		# Error Case: Incorrect number of parameters passed. #
		#----------------------------------------------------#
		if ($vCard->{'errors'}) {
			print STDERR "Error: Incorrect number of parameters passed. ";
			print STDERR "(Expected 2, 3, 9 or 10 parameters, got " . @_ . ")\n";
		}
	}
	return "$vCard";
}


sub label {
#---------------------------------------#
# Useage:                               #
#	$vCard->label                   #
#		OR                      #
#	$vCard->label($label_index)     #
#                                       #
# Purpose:                              #
#	In the first case, returns all  #
#	formatted mailing LABEL tags.   #
#	In the second case, returns the #
#	specified LABEL tag requested.  #
#---------------------------------------#
	my $vCard = shift;
	my $label_list = '';
	if (@_ == 0) {
	#----------------------------------#
	# Case 1: Print all mailing labels #
	#----------------------------------#
		foreach my $label (@{$vCard->{labels}}) {
			my $label_type_list = "";
			$label_list .= "LABEL;TYPE=";
			foreach my $labeltype (@{$label->[0]}) {
				$label_type_list .= $labeltype . ",";
			}
			$label_type_list =~ s/,$//;
			$label_list .= $label_type_list . ":";		
			my $reformatted_label = $label->[1];
			$reformatted_label =~ s/\n/\\n/g;
			$label_list .= $reformatted_label;	
			$label_list .= "\n";
		# LABEL;TYPE=(type,type...,0>:<label,1>  
		}
		return &fold($label_list);
	} elsif (@_ == 1) {
	#---------------------------------------#
	# Case 2: Print specified mailing label #
	#---------------------------------------#
		my $label_index = shift;
		my @labels = @{$vCard->{labels}};
		my $max_index = @labels - 1;
		if ($label_index !~ /\D/ && $label_index <= ($max_index)) {
			#---------------------------------------------------#
			# Good Case: Number passed, and within array range. #
			#---------------------------------------------------#
			my $label_list = "LABEL;TYPE=";
			my $label = $vCard->{labels}->[$label_index];
			my $label_type_list = '';
			foreach my $labeltype (@{$label->[0]}) {
				$label_type_list .= $labeltype .",";
			}
			$label_list .= $label_type_list . ":";		
			my $reformatted_label = $label->[1];
			$reformatted_label =~ s/\n/\\n/g;
			$label_list .= $reformatted_label . ";";	
			$label_list .= "\n";
			return &fold($label_list);
		} else {
			#-----------------------------------------------------#
			# Bad Case: Non number or out of range number passed. #
			#-----------------------------------------------------#
			if ($label_index =~ /\D/) {
				#------------------------------------------------#
				# Bad Case Type 1: Non numeric parameter passed. #
				#------------------------------------------------#
				if ($vCard->{'errors'}) {
					print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
					print STDERR "('" . $label_index . "') passed to 'label'.\n";
				}
			} else {
				#-------------------------------------------------------------------#
				# Bad Case Type 2: Parameter out of range of LABEL subobject array. #
				#-------------------------------------------------------------------#
				if ($vCard->{'errors'}) {
					print STDERR "Error: Parameter passed to 'label' out of range. ";
					print STDERR "('" . $label_index . "' when max is '" . $max_index . "')\n"; 
				}
			}
			return "";
		}
	} else {
	#-----------------------------------------------#
	# Error case: Wrong number of parameters passed #
	#-----------------------------------------------#
		if ($vCard->{'errors'}) {
			print STDERR "Error: Wrong number of parameters passed to 'label'. ";
			print STDERR "(Expected 0 or 1 parameters, got " . @_ . ")\n";
		}
		return '';
	}
}

# LABEL:<\n delimited  formatted mailing label in 8bit encoding> #

sub parse_label {
#---------------------------------------------------#
# Useage:                                           #
#       $vcard->parse_label($label_line)            #
#               where                               #
#       $label_line = a vCard LABEL formatted line  #
#                                                   #
# Purpose:                                          #
#       Translates a formatted LABEL line into      #
#       a Perl vCard object LABEL line.             #
#---------------------------------------------------#
    my $vCard = shift;
    my $labeltypes = shift;
    my $labelinfo = shift;
    @{$labeltypes}[0] =~ s/TYPE=//;
    &label_set($vCard,"NEW",@{$labeltypes},$labelinfo);
    return $vCard;
}

sub label_set {
#---------------------------------------------------------------------------------------------------------
# Useage:                                                                                                #
#                                                                                                        #
# $vcard->label_set($label_index,$label_types,$label_number);                                            #
#	where 	$label_index  = # of element in label list to modify, or NEW to create a new object      #
#		$label_types  = valid space delimited list of label type info                            #
#		$label_number = label number                                                             #
#			--- OR ---                                                                       #
# $vcard->label_set($label_types,$label_number);                                                         #
#                                                                                                        #
# Purpose:                                                                                               #
#                                                                                                        #
#       In the first form, sets the values for a specific labels array element.                          #
#       In the second form, sets the values of the default (labels[0]) element.                          #
#	In either case, providing a blank $label_types parameter will result in the default values       #
#       being assigned.                                                                                  #
#--------------------------------------------------------------------------------------------------------#
	my $vCard = shift;
	if (@_ == 3) {
		#---------------------------------------#
		# Case 1: Specific lable properties set #
		#---------------------------------------#
		my ($label_index,$typelist,$label) = @_;
		my @typelist;
		if ($typelist ne '') {
			@typelist = split(/ /,$typelist);
		} else {
			foreach my $default (@{$vCard->{'default_label_types'}}) {
				push(@typelist,$default);
			}
		}
		if ($label_index eq "NEW") {
			my @new_label = (\@typelist,$label);
			my $new_label = \@new_label;
			$vCard->{labels}->[@{$vCard->{labels}}]  = $new_label ;
		} elsif ($label_index < (@{$vCard->{labels}} - 1)) {
			$vCard->{labels}->[$label_index]->[0] = \@typelist;		
			$vCard->{labels}->[$label_index]->[1] = $label;
		} else {
			if ($vCard->{'errors'}) {
				print STDERR "Error: No such label entry. ";
				print STDERR "(Entry '" . $label_index . "' requested, max entry is '" . @{$vCard->{labels}} . "')\n";
			}
		}

	} elsif (@_ == 2) {
		#--------------------------------------#
		# Case 2: Default label properties set #
		#--------------------------------------#
		my ($typelist,$label) = @_;
		my @typelist;
		if ($typelist ne '') {
			@typelist = split(/ /,$typelist);
		} else {
			foreach my $default (@{$vCard->{'default_label_types'}}) {
				push(@typelist,$default);
			}
		}
		$vCard->{labels}->[0]->[0] = \@typelist;		
		$vCard->{labels}->[0]->[1] = $label;

	} else {
		#----------------------------------------------------#
		# Error Case: Incorrect number of parameters passed. #
		#----------------------------------------------------#
		if ($vCard->{'errors'}) {
			print STDERR "Error: Incorrect number of parameters passed to 'label_set'. ";
			print STDERR "(Expected 1 or 2 parameters, got " . @_ . ")\n";
		}
	}
	return $vCard;
}


sub telephone {
#-------------------------------------#
# Useage:                             #
#	$vcard->telephone;            #
#		OR                    #
#	$vcard->telephone($num)       #
#	       WHERE                  #
#       $num = telephone object index #
#               OR                    #
#       $vcard->telephone($num,$param)#
#              WHERE                  #
#       $param is a valid telephone   #
#        number parameter (one of:    #
#        'types' or 'number')         #
#                                     #
# Purpose:                            # 
#	Returns all TEL tags in the   #
#	first form, and a specific    #
#	telephone tag in the second.  #
#-------------------------------------#
	my $vCard = shift;
	if (@_ == 0) {
		#----------------------------------------------------------#
		# Case 1: No parameters passed, return all TEL subobjects. #
		#----------------------------------------------------------#
		my $tel_list = "";
		foreach my $tel (@{$vCard->{phone_numbers}}) {
			my $tel_type_list = "";
			if ($tel->[2] ne "") {
			    $tel_list .= $tel->[2];
			    $tel_list .= ".";
			}
			$tel_list .= "TEL;TYPE=";
			foreach my $teltype (@{$tel->[0]}) {
				$tel_type_list .= $teltype . ",";
			}
			$tel_type_list =~ s/,$//;
			$tel_list .= $tel_type_list . ":";		
			$tel_list .= $tel->[1];	
			$tel_list .= "\n";
		# TEL;TYPE=<type(,type,type...),0>:<number> 
		}
		return &fold($tel_list);
	} elsif (@_ == 1) {
		#---------------------------------------------------------------#
		# Case 2: One parameter passed, return specified TEL subobject. #
		#---------------------------------------------------------------#
		my $tel_index = shift;
		my @tels = @{$vCard->{phone_numbers}};
		my $max_index = @tels - 1;
		if ($tel_index !~ /\D/ && $tel_index <= ($max_index)) {
			#---------------------------------------------------#
			# Good Case: Number passed, and within array range. #
			#---------------------------------------------------#
			my $tel_list = "";
			my $tel = $vCard->{phone_numbers}->[$tel_index];
			if ($tel->[2] ne "") {
			    $tel_list .= $tel->[2];
			    $tel_list .= ".";
			}
			$tel_list .= "PHONE;TYPE=";
			my $tel_type_list = '';
			foreach my $teltype (@{$tel->[0]}) {
				$tel_type_list .= $teltype .",";
			}
			$tel_list =~ s/,$//;
			$tel_list .= $tel_type_list . ":";		
			$tel_list .= $tel->[1] . ";";	
			$tel_list .= "\n";
			return &fold($tel_list);
		} else {
			#-----------------------------------------------------#
			# Bad Case: Non number or out of range number passed. #
			#-----------------------------------------------------#
			if ($tel_index =~ /\D/) {
				#------------------------------------------------#
				# Bad Case Type 1: Non numeric parameter passed. #
				#------------------------------------------------#
				if ($vCard->{'errors'}) {
					print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
					print STDERR "('" . $tel_index . "') passed to 'telephone'.\n";
				}
			} else {
				#---------------------------------------------------------------------#
				# Bad Case Type 2: Parameter out of range of ADRress subobject array. #
				#---------------------------------------------------------------------#
				if ($vCard->{'errors'}) {
					print STDERR "Error: Parameter passed to 'address' out of range. ";
					print STDERR "('" . $tel_index . "' when max is '" . $max_index . "')\n"; 
				}
			}
			return "";
		}
	    } elsif (@_ == 2) {
		    #------------------------------------------#
		    # Case 3, specific subparameter requested. #
		    #------------------------------------------#
		    my $phone_index = shift;
		    my $fieldname = shift;
		    my @phone = @{$vCard->{phone_numbers}};
		    my $max_index = @phone - 1;
		    if ($phone_index !~ /\D/ && $phone_index <= ($max_index)) {
			#---------------------------------------------------#
			# Good Case: Number passed, and within array range. #
			#---------------------------------------------------#
			if (($fieldname eq 'types') || ($fieldname eq 'number')) {
			    #----------------------------------------#
			    # Good case: Field types requested exist #
			    #----------------------------------------#
			    my $field_value = $vCard->{'phone_numbers'}->[$phone_index]->[$vCard->{'phone_elements'}->{$fieldname}];
			    return($field_value);
			} else {
			    if ($vCard->{'errors'}) {
				print STDERR "Error: Field '$fieldname' is not an PHONE tag field.\n";
			    }
			    return "";
			}
		    } else {
			#-----------------------------------------------------#
			# Bad Case: Non number or out of range number passed. #
			#-----------------------------------------------------#
			if ($phone_index =~ /\D/) {
			    #------------------------------------------------#
			    # Bad Case Type 1: Non numeric parameter passed. #
			    #------------------------------------------------#
			    if ($vCard->{'errors'}) {
				print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
				print STDERR "('" . $phone_index . "') passed to 'phone'.\n";
			    }
			} else {
			    #-------------------------------------------------------------------#
			    # Bad Case Type 2: Parameter out of range of PHONE subobject array. #
			    #-------------------------------------------------------------------#
			    if ($vCard->{'errors'}) {
				print STDERR "Error: Parameter passed to 'phone' out of range. ";
				print STDERR "('" . $phone_index . "' when max is '" . $max_index . "')\n"; 
			    }
			}
			return "";
		    }
	} else {
		#-------------------------------------------------#
		# Error case.  Wrong number of parameters passed. #
		#-------------------------------------------------#
		if ($vCard->{'errors'}) {
			print STDERR "Error: Wrong number of parameters passed to 'telephone'. ";
			print STDERR "(Expected 0 or 1 parameters, got " . @_ . ")\n";
		}
		return "";
	}
}

sub parse_telephone {
#---------------------------------------------------#
# Useage:                                           #
#       $vcard->parse_phone($phone_line)            #
#               where                               #
#       $phone_line = a vCard PHONE formatted line  #
#                                                   #
# Purpose:                                          #
#       Translates a formatted PHONE line into      #
#       a Perl vCard object PHONE line.             #
#                                                   #
# WARNING:  This documentation is out of date. It   #
#           will be replaced as soon as is          #
#           convenient.                             #
#---------------------------------------------------#
    my $vCard = shift;
    my $phonetypes = shift;
    my $phoneinfo = shift;
    my $grouping = shift;
    @{$phonetypes}[0] =~ s/TYPE=//;
    &telephone_set($vCard,"NEW",@{$phonetypes},$phoneinfo,$grouping);
    return $vCard;
}



sub telephone_set {
#---------------------------------------------------------------------------------------------------------
# Useage:                                                                                                #
#                                                                                                        #
# $vcard->telephone_set($tel_index,$tel_types,$tel_number,$grouping);                                    #
#	where 	$tel_index  = # of element in telephone list to modify, or NEW to create a new object    #
#		$tel_types  = valid space delimited list of telephone type info                          #
#		$tel_number = telephone number                                                           #
#               $grouping   = tag grouping prefix                                                        #
#			--- OR ---                                                                       #
# $vcard->telephone_set($tel_types,$tel_number);                                                         #
#                                                                                                        #
# Purpose:                                                                                               #
#                                                                                                        #
#       In the first form, sets the values for a specific phone_numbers array element.                   #
#       In the second form, sets the values of the default (phone_numbers[0]) element.                   #
#--------------------------------------------------------------------------------------------------------#
    my $vCard = shift;
    if (@_ == 4) {
	#-----------------------------------------#
	# Case 1: Specific phone # properties set #
	#-----------------------------------------#
	my ($tel_index,$typelist,$tel_number,$grouping) = @_;
	my @typelist = split(/ /,$typelist);
	if ($tel_index eq "NEW") {
	    my @new_telephone = (\@typelist,$tel_number,$grouping);
	    my $new_telephone = \@new_telephone;
	    $vCard->{phone_numbers}->[@{$vCard->{phone_numbers}}]  = $new_telephone ;
	} elsif ($tel_index < (@{$vCard->{phone_numbers}} - 1)) {
	    $vCard->{phone_numbers}->[$tel_index]->[0] = \@typelist;		
	    $vCard->{phone_numbers}->[$tel_index]->[1] = $tel_number;
	    $vCard->{phone_numbers}->[$tel_index]->[2] = $grouping;	    
	} else {
	    if ($vCard->{'errors'}) {
		print STDERR "Error: No such telephone entry. ";
		print STDERR "(Entry '" . $tel_index . "' requested, max entry is '" . @{$vCard->{phone_numbers}} . "')\n";
	    }
	}
    } elsif (@_ == 3) {
# FRED WAS HERE, AUG 13th 1999! >-
	my ($index, $type, $value) = @_;

	if ($vCard->{'phone_elements'}->{$type} ne '') {
		my $element_number = $vCard->{phone_elements}->{$type};
		$vCard->{'phone_numbers'}->[$index]->[$element_number] = $value;
	}
#	#----------------------------------------#
#	# Case 2: Default phone # properties set #
#	#----------------------------------------#
#	my ($typelist,$tel_number) = @_;
#	my @typelist = split(/ /,$typelist);
#	$vCard->{phone_numbers}->[0]->[0] = \@typelist;		
#	$vCard->{phone_numbers}->[0]->[1] = $tel_number;
# FRED WAS HERE, AUG 13th 1999! -<
    } else {
	#----------------------------------------------------#
	# Error Case: Incorrect number of parameters passed. #
	#----------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Incorrect number of parameters passed to 'telephone'. ";
	    print STDERR "(Expected 2 or 4 parameters, got " . @_ . ")\n";
	}
    }
    return "$vCard";
}


sub email {
#-------------------------------------# 
# Useage:                             #  
#	$vcard->email;                #  
#		OR                    #  
#	$vcard->email($num)           #
#	       WHERE                  #
#       $num = email object index     #
#               OR                    #
#       $vcard->email($num,"value")   #
#               OR                    #
#       $vcard->email($num,"types")   #
#                                     #
# Purpose:                            # 
#	Returns all EMAIL tags in the #
#	first form, and a specific    #
#	email tag in the second. The  #
#       third form returns the value  #
#       only. The fourth form simply  #
#       returns the type(s) of email  #
#       addresses for that subobject. #
#-------------------------------------#
    my $vCard = shift;
    if (@_ == 0) {
	#----------------------------------------------------------#
	# Case 1: No parameters passed, return all ADR subobjects. #
	#----------------------------------------------------------#
	my $email_list = "";
	if (@{$vCard->{email_addresses}} > 0) {
	    foreach my $email (@{$vCard->{email_addresses}}) {
		my $email_type_list = "";
		if ($email->[2] ne "") {
		    $email_list .= $email->[2];
		    $email_list .= ".";
		}
		$email_list .= "EMAIL;TYPE=";
		foreach my $emailtype (@{$email->[0]}) {
		    $email_type_list .= $emailtype . ",";
		}
		$email_type_list =~ s/,$//;
		$email_list .= $email_type_list . ":";		
		$email_list .= $email->[1];	
		$email_list .= "\n";
	    }
	    # EMAIL;<type,0>:<address,1>
	} else {
	    if ($vCard->{'warnings'}) { print STDERR "Warning: No email addresses defined for this card.\n"; }
	}
	return &fold($email_list);
    } elsif (@_ == 1) {
	#---------------------------------------------------------------#
	# Case 2: One parameter passed, return specified TEL subobject. #
	#---------------------------------------------------------------#
	my $email_index = shift;
	my @emails = @{$vCard->{email_addresses}};
	my $max_index = @emails - 1;
	if ($email_index !~ /\D/ && $email_index <= ($max_index)) {
	    #---------------------------------------------------#
	    # Good Case: Number passed, and within array range. #
	    #---------------------------------------------------#
	    my $email_list = "";
	    my $email = $vCard->{email_addresses}->[$email_index];
	    if ($email->[2] ne "") {
		$email_list .= $email->[2];
		$email_list .= ".";
	    }
	    $email_list .= "EMAIL;TYPE=";
	    my $email_type_list = '';
	    foreach my $emailtype (@{$email->[0]}) {
		$email_type_list .= $emailtype . ",";
	    }
	    $email_type_list =~ s/,$//;
	    $email_list .= $email_type_list . ":";		
	    $email_list .= $email->[1] . ";";	
	    $email_list .= "\n";
	    return &fold($email_list);
	} else {
	    #-----------------------------------------------------#
	    # Bad Case: Non number or out of range number passed. #
	    #-----------------------------------------------------#
	    if ($email_index =~ /\D/) {
		#------------------------------------------------#
		# Bad Case Type 1: Non numeric parameter passed. #
		#------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
		    print STDERR "('" . $email_index . "') passed to 'email'.\n";
		}
	    } else {
		#-------------------------------------------------------------------#
		# Bad Case Type 2: Parameter out of range of EMAIL subobject array. #
		#-------------------------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Parameter passed to 'email' out of range. ";
		    print STDERR "('" . $email_index . "' when max is '" . $max_index . "')\n"; 
		}
	    }
	    return "";
	}
    } elsif (@_ == 2) {
	#------------------------------------------#
	# Case 3, specific subparameter requested. #
	#------------------------------------------#
	my $email_index = shift;
	my $fieldname = shift;
	my @email = @{$vCard->{email_addresses}};
	my $max_index = @email - 1;
	if ($email_index !~ /\D/ && $email_index <= ($max_index)) {
	    #---------------------------------------------------#
	    # Good Case: Number passed, and within array range. #
	    #---------------------------------------------------#
	    if (($fieldname eq 'types') || ($fieldname eq 'address')) {
		#----------------------------------------#
		# Good case: Field types requested exist #
		#----------------------------------------#
		my $field_value = $vCard->{'email_addresses'}->[$email_index]->[$vCard->{'email_elements'}->{$fieldname}];
		return($field_value);
	    } else {
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Field '$fieldname' is not an EMAIL tag field.\n";
		}
		return "";
	    }
	} else {
	    #-----------------------------------------------------#
	    # Bad Case: Non number or out of range number passed. #
	    #-----------------------------------------------------#
	    if ($email_index =~ /\D/) {
		#------------------------------------------------#
		# Bad Case Type 1: Non numeric parameter passed. #
		#------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
		    print STDERR "('" . $email_index . "') passed to 'email'.\n";
		}
	    } else {
		#-------------------------------------------------------------------#
		# Bad Case Type 2: Parameter out of range of EMAIL subobject array. #
		#-------------------------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Parameter passed to 'email' out of range. ";
		    print STDERR "('" . $email_index . "' when max is '" . $max_index . "')\n"; 
		}
	    }
	    return "";
	}
    } else {
	#-------------------------------------------------#
	# Error case.  Wrong number of parameters passed. #
	#-------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Wrong number of parameters passed to 'email'. ";
	    print STDERR "(Expected 0 or 1 parameters, got " . @_ . ")\n";
	}
	return "";
    }
}

sub parse_email {
#---------------------------------------------------#
# Useage:                                           #
#       $vcard->parse_email($email_line)            #
#               where                               #
#       $email_line = a vCard EMAIL formatted line  #
#                                                   #
# Purpose:                                          #
#       Translates a formatted EMAIL line into      #
#       a Perl vCard object EMAIL line.             #
#---------------------------------------------------#
    my $vCard = shift;
    my $emailtypes = shift;
    my $emailinfo = shift;
    @{$emailtypes}[0] =~ s/TYPE=//;
    my $grouping = shift;
    &email_set($vCard,"NEW",@{$emailtypes},$emailinfo,$grouping);
    return $vCard;
}


sub email_set {
#---------------------------------------------------------------------------------------------------------
# Useage:                                                                                                #
#                                                                                                        #
# $vcard->email_set($email_index,$email_types,$email_addr,$grouping);                                    #
#	where 	$email_index  = # of element in email list to modify, or NEW to create a new object      #
#		$email_types  = valid space delimited list of email type info                            #
#		$email_addr   = email address                                                            #
#               $grouping     = grouping tag prefix
#			--- OR ---                                                                       #
# $vcard->email_set($email_types,$email_addr);                                                           #
#                                                                                                        #
# Purpose:                                                                                               #
#                                                                                                        #
#       In the first form, sets the values for a specific email_addresses array element.                 #
#       In the second form, sets the values of the default (email_addresses[0]) element.                 #
#--------------------------------------------------------------------------------------------------------#
    my $vCard = shift;
    if (@_ == 4) {
	#-----------------------------------------------#
	# Case 1: Specific email address properties set #
	#-----------------------------------------------#
	my ($email_index,$typelist,$email_addr,$grouping) = @_;
	my @typelist = split(/ /,$typelist);
	if ($email_index eq "NEW") {
	    my @new_email = (\@typelist,$email_addr,$grouping);
	    my $new_email = \@new_email;
	    $vCard->{email_addresses}->[@{$vCard->{email_addresses}}]  = $new_email ;
	} elsif ($email_index < @{$vCard->{email_addresses}} ) {
	    $vCard->{email_addresses}->[$email_index]->[0] = \@typelist;		
	    $vCard->{email_addresses}->[$email_index]->[1] = $email_addr;
	    $vCard->{email_addresses}->[$email_index]->[2] = $grouping;
	} else {
	    if ($vCard->{'errors'}) {
		print STDERR "Error: No such email entry. ";
		print STDERR "(Entry '" . $email_index . "' requested, max entry is '" . @{$vCard->{email_addresses}} . "')\n";
			}
	}
# FRED WAS HERE AUGUST 13th 1999 ->
#    } elsif (@_ == 2) {
#	#----------------------------------------------#
#	# Case 2: Default email address properties set #
#	#----------------------------------------------#
#	my ($typelist,$email_addr) = @_;
#	my @typelist = split(/ /,$typelist);
#	$vCard->{email_addresses}->[0]->[0] = \@typelist;		
#	$vCard->{email_addressess}->[0]->[1] = $email_addr;
    } elsif (@_ == 3) {
        my ($index, $type, $value) = @_;

        if ($vCard->{'email_elements'}->{$type} ne '') {
                my $element_number = $vCard->{email_elements}->{$type};
                        $vCard->{'email_addresses'}->[$index]->[$element_number] = $value;
        }
# FRED WAS HERE AUGUST 13th 1999 <-
    } else {
	#----------------------------------------------------#
	# Error Case: Incorrect number of parameters passed. #
	#----------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Incorrect number of parameters passed to 'email_set'. ";
	    print STDERR "(Expected 2 or 3 parameters, got " . @_ . ")\n";
	}
    }
    return $vCard;
}


sub mailer {
#------------------------------------------#
# Useage:                                  #
#	$vcard->mailer                     #
#                                          #
# Purpose:                                 #
#	Returns email program (MAILER) tag #
#------------------------------------------#
    my $vCard = shift;

    my $mailer = "";
    if ($vCard->{'mailer'} ne '') {
	$mailer = "MAILER:";
	$mailer .= $vCard->{mailer} . "\n";
    } else {
	if ($vCard->{'warnings'}) { print STDERR "Warning: No mailer (MAILER) value set for this card.\n"; }
    }
    return &fold($mailer);
    my $vCard = shift;
}

sub parse_mailer {
#----------------------------------------------------#
# Useage:                                            #
#       $vcard->parse_mailer($mailer_line)           #
#               where                                #
#       $mailer_line = a vCard MAILER formatted line #
#                                                    #
# Purpose:                                           #
#       Translates a formatted MAILER line into      #
#       a Perl vCard object MAILER line.             #
#----------------------------------------------------#
    my $vCard = shift;
    my $mailer = shift;
    &mailer_set($vCard,$mailer);
    return $vCard;
}

sub mailer_set {
#-------------------------------------------------------------------#
# Useage:                                                           #
#	$vcard->mailer_set($mailer)                                 #
#		where                                               #
#	$mailer = the email client used by the cardholder           #
#                                                                   #
# Purpose:                                                          #
# 	Sets the MAILER tag for this vCard.                         #
#-------------------------------------------------------------------#
    my $vCard = shift;
    my $mailer = shift;
    $vCard->{mailer} = $mailer;
    return $vCard;
}

sub tz {
#---------------------------------------#
# Useage:                               #
#	$vcard->tz                      #
#                                       #
# Purpose:                              #
#	Returns time zone (TZ) tag      #
#---------------------------------------#
    my $vCard = shift;
    my $tz = '';
    if ($vCard->{'TZ'} ne "0:0") {
	$tz = "TZ:";
	$tz .= $vCard->{TZ}."\n";
    } else {
	if ($vCard->{'warnings'}) {
	    print STDERR "Warning: Default value of 0:0 not displayed. ";
	    print STDERR "(If value is actually 0:0, set to 00:00 to enable display)\n";
	}
    }
    return &fold($tz);
}

sub parse_tz {
#--------------------------------------------#
# Useage:                                    #
#       $vcard->parse_tz($tz_line)           #
#               where                        #
#       $tz_line = a vCard TZ formatted line #
#                                            #
# Purpose:                                   #
#       Translates a formatted TZ line into  #
#       a Perl vCard object TZ line.         #
#--------------------------------------------#
    my $vCard = shift;
    my $tz = shift;
    &tz_set($vCard,$tz);
    return $vCard;
}


sub tz_set {
#-------------------------------------------------------------------#
# Useage:                                                           #
#	$vcard->tz_set($timezone_info)                              #
#		where                                               #
#       $timezone_info is either an offset from UTC (-05:00)        #
#		- OR -                                              #
#       $vcard->tz_set("VALUE",$textstring)                         #
#               where                                               #
#       $textstring is a textstring value                           #
#       (i.e. -05:00; EST; Raleigh/North America)                   #
#                                                                   #
# Purpose:                                                          #
# 	Sets the TZ tag for this vCard, either with a UTC offset    #
#       in its first form, or with a textstring descriptive in the  #
#       second form.                                                #
#-------------------------------------------------------------------#
    my $vCard = shift;
    if (@_ == 1) {
	$vCard->{TZ} =  shift;
    } elsif (@_ == 2) {
	my $value_tag = shift;
	my $value = shift;
	if ($value_tag eq "VALUE") {
	    $vCard->{TZ} = ";" . $value_tag . "=text:" . $value;
	} else {
	    if ($vCard->{'warnings'}) {
		print STDERR "Warning: TZ expected VALUE parameter, got " . $value_tag . ". ";
		print STDERR "(TZ value set to '" .  $value_tag . "=text:" . $value . "')\n";
	    }
	}
    } else {
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Wrong number of parameters passed to 'tz_set'. ";
	    print STDERR "(Expected 1 or 2 arguments, got '" . @_ . "')\n";
	}
    }
    return $vCard;
}

sub geo {
#------------------------------------------------#
# Useage:                                        #
#	$vcard->geo                              #
#                                                #
# Purpose:                                       #
#	Returns geographic coordinates (GEO) tag #
#------------------------------------------------#
    my $vCard = shift;
    my $geo = "GEO:";
    $geo .= $vCard->{geo}->{longitude};
    $geo .= ";";
    $geo .= $vCard->{geo}->{latitude};
    $geo .= "\n";
    return &fold($geo);
}

sub parse_geo {
#----------------------------------------------#
# Useage:                                      #
#       $vcard->parse_geo($geo_line)           #
#               where                          #
#       $geo_line = a vCard GEO formatted line #
#                                              #
# Purpose:                                     #
#       Translates a formatted GEO line into   #
#       a Perl vCard object GEO line.          #
#----------------------------------------------#
    my $vCard = shift;
    my $geo = shift;
    my ($long,$lat) = split(/\;/,$geo);
    &geo_set($vCard,$long,$lat);
    return $vCard;
}

sub geo_set {
#------------------------------------------------------------------------------------#
# Useage:                                                                            #
#	$vCard->geo_set($longitude,$latitude)                                        #
#		where                                                                #
#	$longitude and $latitude are space delimited degrees, minutes, seconds lists #
#	(i.e. "125 47 23")                                                           #
#                                                                                    #
# Purpose:                                                                           #
#	Sets the geographical coordinate (GEO) tag                                   #
#------------------------------------------------------------------------------------#
    my $vCard = shift;

# FRED WAS HERE AUGUST 13th 1999 >-
#    my @longitude = split(/ /,shift);
#    my @latitude  = split(/ /,shift);
    
#    my $longitude = $longitude[0] + $longitude[1]/60 + $longitude[2]/3600;
#    my $latitude  = $latitude[0] + $latitude[1]/60 + $latitude[2]/3600;
    
#    $vCard->{geo}->{longitude} = $longitude;
#    $vCard->{geo}->{latitude}  = $latitude;

     ($vCard->{geo}->{longitude}, $vCard->{geo}->{latitude}) = split (/;/, shift);

# FRED WAS HERE AUGUST 13th 1999 -<
    return $vCard;
}

sub title {
#-------------------------------------# 
# Useage:                             #  
#	$vcard->title;                #  
#		OR                    #  
#	$vcard->title($num)           #
#	       WHERE                  #
#       $num = title object index     #
#                                     #
# Purpose:                            # 
#	Returns all TITLE tags in the #
#	first form, and a specific    #
#	title tag in the second.      #
#-------------------------------------#
    my $vCard = shift;
    my $title_list = "";
    if (@_ == 0) {
	#------------------------------------------------------------#
	# Case 1: No parameters passed, return all TITLE subobjects. #
	#------------------------------------------------------------#
	if (@{$vCard->{titles}} > 0) {
	    foreach my $title (@{$vCard->{titles}}) {
		$title_list .= "TITLE:";
		$title_list .= $title;	
		$title_list .= "\n";
	    }
	} else {
	    if ($vCard->{'warnings'}) {
		print STDERR "Warning: No title (TITLE) values set for this card.\n";
	    }
	}
	# TITLE;<title,0>
	return &fold($title_list);
    } elsif (@_ == 1) {
	#-----------------------------------------------------------------#
	# Case 2: One parameter passed, return specified TITLE subobject. #
	#-----------------------------------------------------------------#
	my $title_index = shift;
	my @titles = @{$vCard->{titles}};
	my $max_index = @titles - 1;
	if ($title_index !~ /\D/ && $title_index <= ($max_index)) {
	    #---------------------------------------------------#
	    # Good Case: Number passed, and within array range. #
	    #---------------------------------------------------#
	    my $title_list = "";
	    my $title = $vCard->{titles}->[$title_index];
	    $title_list .= "TITLE:";
	    $title_list .= $title;	
	    $title_list .= "\n";
	    return &fold($title_list);
	} else {
	    #-----------------------------------------------------#
	    # Bad Case: Non number or out of range number passed. #
	    #-----------------------------------------------------#
	    if ($title_index =~ /\D/) {
		#------------------------------------------------#
		# Bad Case Type 1: Non numeric parameter passed. #
		#------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
		    print STDERR "('" . $title_index . "') passed to 'title'.\n";
		}
	    } else {
		#-------------------------------------------------------------------#
		# Bad Case Type 2: Parameter out of range of TITLE subobject array. #
		#-------------------------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Parameter passed to 'title' out of range. ";
		    print STDERR "('" . $title_index . "' when max is '" . $max_index . "')\n"; 
		}
	    }
	    return "";
	}
    } else {
	#-------------------------------------------------#
	# Error case.  Wrong number of parameters passed. #
	#-------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Wrong number of parameters passed to 'title'. ";
	    print STDERR "(Expected 0 or 1 parameters, got " . @_ . ")\n";
	}
	return "";
    }
}

sub parse_title {
#---------------------------------------------------#
# Useage:                                           #
#       $vcard->parse_title($title_line)            #
#               where                               #
#       $title_line = a vCard TITLE formatted line  #
#                                                   #
# Purpose:                                          #
#       Translates a formatted TITLE line into      #
#       a Perl vCard object TITLE line.             #
#---------------------------------------------------#
    my $vCard = shift;
    my $titleinfo = shift;
    &title_set($vCard,"NEW",$titleinfo);
    return $vCard;
}

sub title_set {
#---------------------------------------------------------------------------------------------------------
# Useage:                                                                                                #
#                                                                                                        #
# $vcard->title_set($title_index,$title);                                                                #
#	where 	$title_index  = # of element in title list to modify, or NEW to create a new object      #
#		$title        = title                                                                    #
#			--- OR ---                                                                       #
# $vcard->title_set($title);                                                                             #
#                                                                                                        #
# Purpose:                                                                                               #
#                                                                                                        #
#       In the first form, sets the values for a specific titles array element.                          #
#       In the second form, sets the values of the default (titles[0]) element.                          #
#--------------------------------------------------------------------------------------------------------#
    my $vCard = shift;
    if (@_ == 2) {
	#---------------------------------------#
	# Case 1: Specific title properties set #
	#---------------------------------------#
	my ($title_index,$title) = @_;
	if ($title_index eq "NEW") {
	    $vCard->{titles}->[@{$vCard->{titles}}]  = $title ;
	} elsif ($title_index < @{$vCard->{titles}} ) {
	    $vCard->{@{$vCard->{titles}}}->[$title_index] = $title;		
	} else {
			if ($vCard->{'errors'}) {
			    print STDERR "Error: No such title entry. ";
			    print STDERR "(Entry '" . $title_index . "' requested, max entry is '" . @{$vCard->{titles}} .  "')\n";
			}
		    }
    } elsif (@_ == 1) {
	#--------------------------------------#
	# Case 2: Default title properties set #
	#--------------------------------------#
	my $title = shift;
	$vCard->{titles}->[0] = $title;		
    } else {
	#----------------------------------------------------#
	# Error Case: Incorrect number of parameters passed. #
	#----------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Incorrect number of parameters passed to 'title_set'. ";
	    print STDERR "(Expected 1 or 2 parameters, got " . @_ . ")\n";
	}
    }
    return $vCard;
}

sub role {
#------------------------------------# 
# Useage:                            #  
#	$vcard->role;                #  
#		OR                   #  
#	$vcard->role($num)           #
#	       WHERE                 #
#       $num = role object index     #
#                                    #
# Purpose:                           # 
#	Returns all ROLE tags in the #
#	first form, and a specific   #
#	role tag in the second.      #
#------------------------------------#
    my $vCard = shift;
    if (@_ == 0) {
	#-----------------------------------------------------------#
	# Case 1: No parameters passed, return all ROLE subobjects. #
	#-----------------------------------------------------------#
	my $role_list = "";
	foreach my $role (@{$vCard->{roles}}) {
	    $role_list .= "ROLE:";
	    $role_list .= $role;	
	    $role_list .= "\n";
	    # ROLE;<role,0>
	}
	return &fold($role_list);
    } elsif (@_ == 1) {
	    #----------------------------------------------------------------#
	# Case 2: One parameter passed, return specified ROLE subobject. #
	#----------------------------------------------------------------#
	my $role_index = shift;
	my @roles = @{$vCard->{roles}};
	my $max_index = @roles - 1;
	if ($role_index !~ /\D/ && $role_index <= ($max_index)) {
	    #---------------------------------------------------#
	    # Good Case: Number passed, and within array range. #
	    #---------------------------------------------------#
	    my $role_list = "";
	    my $role = $vCard->{roles}->[$role_index];
	    $role_list .= "ROLE:";
	    $role_list .= $role;	
	    $role_list .= "\n";
	    return &fold($role_list);
	} else {
	    #-----------------------------------------------------#
	    # Bad Case: Non number or out of range number passed. #
	    #-----------------------------------------------------#
	    if ($role_index =~ /\D/) {
		#------------------------------------------------#
		# Bad Case Type 1: Non numeric parameter passed. #
		#------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
		    print STDERR "('" . $role_index . "') passed to 'title'.\n";
		}
	    } else {
		#-------------------------------------------------------------------#
		# Bad Case Type 2: Parameter out of range of ROLE subobject array. #
		#-------------------------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Parameter passed to 'role' out of range. ";
		    print STDERR "('" . $role_index . "' when max is '" . $max_index . "')\n"; 
		    }
	    }
	    return "";
	}
    } else {
	#-------------------------------------------------#
	# Error case.  Wrong number of parameters passed. #
	#-------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Wrong number of parameters passed to 'role'. ";
	    print STDERR "(Expected 0 or 1 parameters, got " . @_ . ")\n";
	}
	return "";
    }
}    


sub parse_role {
#-------------------------------------------------#
# Useage:                                         #
#       $vcard->parse_role($role_line)            #
#               where                             #
#       $role_line = a vCard ROLE formatted line  #
#                                                 #
# Purpose:                                        #
#       Translates a formatted ROLE line into     #
#       a Perl vCard object ROLE line.            #
#-------------------------------------------------#
    my $vCard = shift;
    my $roleinfo = shift;
    &role_set($vCard,"NEW",$roleinfo);
    return $vCard;
}

sub role_set {
#--------------------------------------------------------------------------------------------------------#
# Useage:                                                                                                #
#                                                                                                        #
# $vcard->role_set($role_index,$role);                                                                   #
#	where 	$role_index  = # of element in role list to modify, or NEW to create a new object        #
#		$role        = role                                                                      #
#			--- OR ---                                                                       #
# $vcard->role_set($role);                                                                               #
#                                                                                                        #
# Purpose:                                                                                               #
#                                                                                                        #
#       In the first form, sets the values for a specific rolees array element.                          #
#       In the second form, sets the values of the default (roles[0]) element.                           #
#--------------------------------------------------------------------------------------------------------#
    my $vCard = shift;
    if (@_ == 2) {
	#--------------------------------------#
	# Case 1: Specific role properties set #
	#--------------------------------------#
	my ($role_index,$role) = @_;
	if ($role_index eq "NEW") {
	    $vCard->{roles}->[@{$vCard->{roles}}]  = $role ;
	} elsif ($role_index < @{$vCard->{roles}} ) {
	    $vCard->{$@{$vCard->{roles}}}->[$role_index]->[0] = $role;		
	} else {
	    if ($vCard->{'errors'}) {
		print STDERR "Error: No such role entry. ";
		print STDERR "(Entry '" . $role_index . "' requested, max entry is '" . @{$vCard->{roles}} .  "')\n";
	    }
	}
    } elsif (@_ == 1) {
	#-------------------------------------#
	# Case 2: Default role properties set #
	#-------------------------------------#
	my $role = shift;
	$vCard->{roles}->[0] = $role;		
    } else {
	#----------------------------------------------------#
	# Error Case: Incorrect number of parameters passed. #
	#----------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Incorrect number of parameters passed to 'role_set'. ";
	    print STDERR "(Expected 1 or 2 parameters, got " . @_ . ")\n";
	}
    }
    return $vCard;
}


sub logo {
#-------------------------------------#
# Useage:                             #
#	$vcard->logo;                 #
#		OR                    #
#	$vcard->logo($num)            #
#	       WHERE                  #
#       $num = logo object index      #
#                                     #
# Purpose:                            # 
#	Returns all LOGO tags in the  #
#	first form, and a specific    #
#	logo tag in the second.       #
#-------------------------------------#
    my $vCard = shift;
    if (@_ == 0) {
	#-----------------------------------------------------------#
	# Case 1: No parameters passed, return all LOGO subobjects. #
	#-----------------------------------------------------------#
	my $logo_list = "";
	foreach my $logo (@{$vCard->{logos}}) {
	    $logo_list .= "LOGO;";			
	    if ($logo->[0] eq "URL") {
		$logo_list .= "VALUE=uri:";
	    } else {
		$logo_list .= "ENCODING=b;TYPE=" . $logo->[0] . ":"; 
	    }
	    $logo_list .= $logo->[1];	
	    $logo_list .= "\n";
	    # LOGO;VALUE=uri:<uri>                                        
	    #	- OR -                                                 
	    # LOGO;ENCODING=b;TYPE=<file mimetype>:<base64 encoded info>  
	}
	return &fold($logo_list);
    } elsif (@_ == 1) {
	#----------------------------------------------------------------#
	# Case 2: One parameter passed, return specified LOGO subobject. #
	#----------------------------------------------------------------#
	my $logo_index = shift;
	my @logos = @{$vCard->{logos}};
	my $max_index = @logos - 1;
	if ($logo_index !~ /\D/ && $logo_index <= ($max_index)) {
	    #---------------------------------------------------#
	    # Good Case: Number passed, and within array range. #
	    #---------------------------------------------------#
	    my $logo = $vCard->{logos}->[$logo_index];
	    my $logo_list = '';
	    if ($logo->[0] eq "URL") {
		$logo_list .= "VALUE=uri:";
	    } else {
		$logo_list .= "ENCODING=b;TYPE=" . $logo->[0] . ":"; 
	    }
	    $logo_list .= $logo->[1];	
	    $logo_list .= "\n";
	    return &fold($logo_list);
	} else {
	    #-----------------------------------------------------#
	    # Bad Case: Non number or out of range number passed. #
	    #-----------------------------------------------------#
	    if ($logo_index =~ /\D/) {
		#------------------------------------------------#
		# Bad Case Type 1: Non numeric parameter passed. #
		#------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
		    print STDERR "('" . $logo_index . "') passed to 'logo'.\n";
		}
	    } else {
		#------------------------------------------------------------------#
		# Bad Case Type 2: Parameter out of range of LOGO subobject array. #
		#------------------------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Parameter passed to 'logo' out of range. ";
		    print STDERR "('" . $logo_index . "' when max is '" . $max_index . "')\n"; 
		}
	    }
	    return "";
	}
    } elsif (@_ == 2) {
	#----------------------------------#
	# Specific subparameter requested. #
	#----------------------------------#
	my $logo_index = shift;
	my $fieldname = shift;
	my @logos = @{$vCard->{logos}};
	my $max_index = @logos - 1;
	if ($logo_index !~ /\D/ && $logo_index <= ($max_index)) {
	    #---------------------------------------------------#
	    # Good Case: Number passed, and within array range. #
	    #---------------------------------------------------#
	    if ($fieldname eq 'type' || $fieldname eq 'value') {
		#----------------------------------------#
		# Good case: Field types requested exist #
		#----------------------------------------#
		my $field_value = $vCard->{'logos'}->[$logo_index]->[$vCard->{'logo_elements'}->{$fieldname}];
		return($field_value);
	    } else {
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Field '$fieldname' is not a LOGO tag field.\n";
		}
		return "";
	    }
	} else {
	    #-----------------------------------------------------#
	    # Bad Case: Non number or out of range number passed. #
	    #-----------------------------------------------------#
	    if ($logo_index =~ /\D/) {
		#------------------------------------------------#
		# Bad Case Type 1: Non numeric parameter passed. #
		#------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
		    print STDERR "('" . $logo_index . "') passed to 'logo'.\n";
		}
	    } else {
		#-------------------------------------------------------------------#
		# Bad Case Type 2: Parameter out of range of LOGO subobject array. #
		#-------------------------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Parameter passed to 'logo' out of range. ";
		    print STDERR "('" . $logo_index . "' when max is '" . $max_index . "')\n"; 
		}
	    }
	    return "";
	}
    } else {
		#-------------------------------------------------#
	# Error case.  Wrong number of parameters passed. #
	#-------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Wrong number of parameters passed to 'logo'. ";
	    print STDERR "(Expected 0 or 1 parameters, got " . @_ . ")\n";
	}
		return "";
    }
} # end logo

sub parse_logo {
#---------------------------------------------------#
# Useage:                                           #
#       $vcard->parse_logo($logo_line)              #
#               where                               #
#       $logo_line = a vCard LOGO formatted line    #
#                                                   #
# Purpose:                                          #
#       Translates a formatted LOGO line into       #
#       a Perl vCard object LOGO line.              #
#---------------------------------------------------#
    my $vCard = shift;
    my $logoinfo = shift;
    my @logofields = @{$logoinfo};
    
    my $logo_value = shift;
    if (@logofields == 1) {
	#-----------------------------#
	# Case 1: URL type logo tag.  #
	#-----------------------------#
	&logo_set($vCard,"NEW",$logo_value);
    } elsif (@logofields == 2) {
	#-----------------------------------------------#
	# Case 2: Base64 encoded inline type logo tag. #
	#-----------------------------------------------#
	my ($typetag,$logo_type) = split(/=/,@logofields[1]);
	
	&logo_set($vCard,"NEW",$logo_type,$logo_value);
    } else {
	# Error Case: Improper number of aatributes listed in tag.
	if ($vCard->{'errors'}) { 
	    print STDERR "Error: LOGO tag contains improper formatting. (Offending subtags: ";
	    print STDERR $logoinfo . ")\n";	   
	}
    }
    return $vCard;
# LOGO;VALUE=uri:<uri>                                        #
#	- OR -                                                 #
# LOGO;ENCODING=b;TYPE=<file mimetype>:<base64 encoded info>  #
}


sub logo_set {
#----------------------------------------------------------------------------------------------------------------#
# Useage:                                                                                                        #
#                                                                                                                #
# $vcard->logo_set($logo_index,$logo_url);                                                                       #
#	where 	$logo_index = # in logo list to modify, or 'NEW' to create a new subobject                       #
#		$logo_url = fully qualified URL pointing towards logo object                                     #
#			--- OR ---                                                                               #
# $vcard->logo_set($logo_index,$logo_type,$base64_encoded_image)                                                 #
#	where 	$logo_index 		= # in logo list to modify, or 'NEW' to create a new subobject           #
#		$logo_type  		= the type of image file                                                 #   
#		$base64_encoded_image	= base64 encoded image file                                              #
#                                                                                                                #
# Purpose:                                                                                                       #
#                                                                                                                #
#
#----------------------------------------------------------------------------------------------------------------#
    my $vCard = shift;
    if (@_ == 2) {
	#------------------------------------#
	# Case 1: Specific/new logo from URL #
	#------------------------------------#
	my ($logo_index,$logo_url) = @_;
	if ($logo_index eq "NEW") {
	    my @new_logo = ('URL',$logo_url);	
	    my $new_logo = \@new_logo;
	    $vCard->{logos}->[@{$vCard->{logos}}]  = $new_logo ;
	} elsif ($logo_index < @{$vCard->{logos}}) {
	    $vCard->{logos}->[$logo_index]->[0] = 'URL';
	    $vCard->{logos}->[$logo_index]->[1] = $logo_url;
	} else {
	    if ($vCard->{'errors'}) {
		print STDERR "Error: No such logo entry. ";
		print STDERR "(Entry '" . $logo_index . "' requested, max entry is '" . @{$vCard->{logos}} . "')\n";
	    }
	}
    } elsif (@_ == 3) {
	#-----------------------------------------#
	# Case 2: Specific/new base64 inline logo #
	#-----------------------------------------#
	my ($logo_index,$logo_type,$base64_encoded_image) = @_;
	if ($logo_index eq "NEW") {
	    my @new_logo = ($logo_type,$base64_encoded_image);	
	    my $new_logo = \@new_logo;
	    $vCard->{logos}->[@{$vCard->{logos}}]  = $new_logo ;
	} elsif ($logo_index < @{$vCard->{logos}}) {
	    $vCard->{logos}->[$logo_index]->[0] = $logo_type;
	    $vCard->{logos}->[$logo_index]->[1] = $base64_encoded_image;
	} else {
	    if ($vCard->{'errors'}) {
		print STDERR "Error: No such logo entry. ";
		print STDERR "(Entry '" . $logo_index . "' requested, max entry is '" . @{$vCard->{logos}} . "')\n";
	    }
	}
    } else {
	#----------------------------------------------------#
	# Error Case: Incorrect number of parameters passed. #
	#----------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Incorrect number of parameters passed to 'logo_set'. ";
	    print STDERR "(Expected 2 or 3 parameters, got " . @_ . ")\n";
	}
    }
    return "$vCard";
} # end logo_set

sub agent {
#-------------------------------------------------------------------#
# Postponed until we can figure out how to do recursion painlessly. #
#-------------------------------------------------------------------#
    my $vCard = shift;

    return &fold();
}

sub agent_set {
#-------------------------------------------------------------------#
# Postponed until we can figure out how to do recursion painlessly. #
#-------------------------------------------------------------------#
    my $vCard = shift;

    return $vCard;
}

sub org {
#-------------------------------------# 
# Useage:                             #  
#	$vcard->org;                  #  
#		OR                    #  
#	$vcard->org($num)             #
#	       WHERE                  #
#       $num = org object index       #
#                                     #
# Purpose:                            # 
#	Returns all ORG tags in the   # 
#	first form, and a specific    #
#	org tag in the second.        #
#-------------------------------------#
    my $vCard = shift;
    if (@_ == 0) {
	#----------------------------------------------------------#
	# Case 1: No parameters passed, return all ORG subobjects. #
	#----------------------------------------------------------#
	my $org_list = "";
	foreach my $org (@{$vCard->{organizations}}) {
	    $org_list .= "ORG:";
	    $org_list .= $org;	
	    $org_list .= "\n";
	    # ORG;<organization,0>
	}
	return &fold($org_list);
    } elsif (@_ == 1) {
	#---------------------------------------------------------------#
	# Case 2: One parameter passed, return specified ORG subobject. #
	#---------------------------------------------------------------#
	my $org_index = shift;
	my @orgs = @{$vCard->{organizations}};
	my $max_index = @orgs - 1;
	if ($org_index !~ /\D/ && $org_index <= ($max_index)) {
	    #---------------------------------------------------#
	    # Good Case: Number passed, and within array range. #
	    #---------------------------------------------------#
	    my $org_list = "";
	    my $org = $vCard->{organizations}->[$org_index];
	    $org_list .= "ORG:";
	    $org_list .= $org;	
	    $org_list .= "\n";
	    return &fold($org_list);
	} else {
	    #-----------------------------------------------------#
	    # Bad Case: Non number or out of range number passed. #
	    #-----------------------------------------------------#
	    if ($org_index =~ /\D/) {
		#------------------------------------------------#
		# Bad Case Type 1: Non numeric parameter passed. #
		#------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
		    print STDERR "('" . $org_index . "') passed to 'org'.\n";
		}
	    } else {
		#-----------------------------------------------------------------#
		# Bad Case Type 2: Parameter out of range of ORG subobject array. #
		#-----------------------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Parameter passed to 'org' out of range. ";
		    print STDERR "('" . $org_index . "' when max is '" . $max_index . "')\n"; 
		}
	    }
	    return "";
	}
    } else {
	#-------------------------------------------------#
	# Error case.  Wrong number of parameters passed. #
	#-------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Wrong number of parameters passed to 'org'. ";
	    print STDERR "(Expected 0 or 1 parameters, got " . @_ . ")\n";
	}
	return "";
    }
}

sub parse_org{
#-----------------------------------------------#
# Useage:                                       #
#       $vcard->parse_org($org_line)            #
#               where                           #
#       $org_line = a vCard ORG formatted line  #
#                                               #
# Purpose:                                      #
#       Translates a formatted ORG line into    #
#       a Perl vCard object ORG line.           #
#-----------------------------------------------#
    my $vCard = shift;
    my $orginfo = shift;
    &org_set($vCard,"NEW",$orginfo);
    return $vCard;
}

sub org_set {
#--------------------------------------------------------------------------------------------------------#
# Useage:                                                                                                #
#                                                                                                        #
# $vcard->org_set($org_index,$org);                                                                      #
#	where 	$org_index  = # of element in org list to modify, or NEW to create a new object          #
#		$org        = org                                                                        #
#			--- OR ---                                                                       #
# $vcard->org_set($org);                                                                                 #
#                                                                                                        #
# Purpose:                                                                                               #
#                                                                                                        #
#       In the first form, sets the values for a specific organizations array element.                   #
#       In the second form, sets the values of the default (organizations[0]) element.                   #
#--------------------------------------------------------------------------------------------------------#
    my $vCard = shift;
    if (@_ == 2) {
	#--------------------------------------#
	# Case 1: Specific role properties set #
	#--------------------------------------#
	my ($org_index,$org) = @_;
	if ($org_index eq "NEW") {
	    $vCard->{organizations}->[@{$vCard->{organizations}}]  = $org ;
	} elsif ($org_index < @{$vCard->{organizations}} ) {
	    $vCard->{organizations}->[$org_index]->[0] = $org;		
	} else {
	    if ($vCard->{'errors'}) {
		print STDERR "Error: No such role entry. ";
		print STDERR "(Entry '" . $org_index . "' requested, max entry is '" . @{$vCard->{organizations}} .  "')\n";
	    }
	}
    } elsif (@_ == 1) {
	#------------------------------------#
	# Case 2: Default org properties set #
	#------------------------------------#
	my $org = shift;
	$vCard->{organizations}->[0] = $org;		
    } else {
	#----------------------------------------------------#
	# Error Case: Incorrect number of parameters passed. #
	#----------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Incorrect number of parameters passed to 'org_set'. ";
	    print STDERR "(Expected 1 or 2 parameters, got " . @_ . ")\n";
	}
    }
    return $vCard;
}

sub categories {
#-------------------------------------------#
# Useage:                                   #
#	$vcard->categories                  #
#                                           #
# Purpose:                                  #
#	Returns categories (CATEGORIES) tag #
#-------------------------------------------#
    my $vCard = shift;
    my $categories;
    if ($vCard->{categories} ne '') {
	$categories = "CATEGORIES:";
	$categories .= $vCard->{categories} . "\n";
    } else {
	if ($vCard->{'warnings'}) {
	    print STDERR "Warning: No category values current assigned for this card.\n";
	}
    }
    return &fold($categories);
}

sub parse_categories {
#---------------------------------------------------------#
# Useage:                                                 #
#       $vcard->parse_category($category_line)            #
#               where                                     #
#       $category_line = a vCard CATEGORY formatted line  #
#                                                         #
# Purpose:                                                #
#       Translates a formatted CATEGORY line into         #
#       a Perl vCard object CATEGORY line.                # 
#---------------------------------------------------------#
    my $vCard = shift;
    my $categoryinfo = shift;
    &categories_set($vCard,$categoryinfo);
    return $vCard;
}


sub categories_set {
#--------------------------------------------------------------------#
# Useage:                                                            #
#	$vcard->categories_set($categories)                          #
#		where                                                #
#	$categories = comma delimited list of information categories #
#                                                                    #
# Purpose:                                                           #
# 	Sets the CATEGORIES tag for this vCard.                      #
#--------------------------------------------------------------------#
    my $vCard = shift;
    my $categories = shift;
    $vCard->{categories} = $categories;
    return $vCard;
}

sub note {
#-------------------------------------# 
# Useage:                             #  
#	$vcard->note;                 #  
#		OR                    #  
#	$vcard->note($num)            #
#	       WHERE                  #
#       $num = note object index      #
#                                     #
# Purpose:                            # 
#	Returns all NOTE tags in the  # 
#	first form, and a specific    #
#	note tag in the second.       #
#-------------------------------------#
    my $vCard = shift;
    if (@_ == 0) {
	#----------------------------------------------------------#
	# Case 1: No parameters passed, return all ORG subobjects. #
	#----------------------------------------------------------#
	my $note_list = "";
	foreach my $note (@{$vCard->{notes}}) {
	    $note_list .= "NOTE:";
	    $note_list .= $note;	
	    $note_list .= "\n";
	    # NOTE;<noteanization,0>
	}
	return &fold($note_list);
    } elsif (@_ == 1) {
	#---------------------------------------------------------------#
	# Case 2: One parameter passed, return specified NOTE subobject. #
	#---------------------------------------------------------------#
	my $note_index = shift;
	my @notes = @{$vCard->{notes}};
	my $max_index = @notes - 1;
	if ($note_index !~ /\D/ && $note_index <= ($max_index)) {
	    #---------------------------------------------------#
	    # Good Case: Number passed, and within array range. #
	    #---------------------------------------------------#
	    my $note_list = "";
	    my $note = $vCard->{notes}->[$note_index];
	    $note_list .= "NOTE:";
	    $note_list .= $note;	
	    $note_list .= "\n";
	    return &fold($note_list);
	} else {
	    #-----------------------------------------------------#
	    # Bad Case: Non number or out of range number passed. #
	    #-----------------------------------------------------#
	    if ($note_index =~ /\D/) {
		#------------------------------------------------#
		# Bad Case Type 1: Non numeric parameter passed. #
		#------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
		    print STDERR "('" . $note_index . "') passed to 'note'.\n";
		}
	    } else {
		#-----------------------------------------------------------------#
		# Bad Case Type 2: Parameter out of range of NOTE subobject array. #
		#-----------------------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Parameter passed to 'note' out of range. ";
		    print STDERR "('" . $note_index . "' when max is '" . $max_index . "')\n"; 
		}
	    }
	    return "";
	}
    } else {
	#-------------------------------------------------#
	# Error case.  Wrong number of parameters passed. #
	#-------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Wrong number of parameters passed to 'note'. ";
	    print STDERR "(Expected 0 or 1 parameters, got " . @_ . ")\n";
	}
		return "";
    }
}

sub parse_note {
#------------------------------------------------#
# Useage:                                        #
#       $vcard->parse_note($note_line)           #
#               where                            #
#       $note_line = a vCard NOTE formatted line #
#                                                #
# Purpose:                                       #
#       Translates a formatted NOTE line into    #
#       a Perl vCard object NOTE line.           #
#-----------------------------------0------------#
    my $vCard = shift;
    my $noteinfo = shift;
    &note_set($vCard,"NEW",$noteinfo);
    return $vCard;
}


sub note_set {
#--------------------------------------------------------------------------------------------------------#
# Useage:                                                                                                #
#                                                                                                        #
# $vcard->note_set($note_index,$note);                                                                   #
#	where 	$note_index  = # of element in note list to modify, or NEW to create a new object        #
#		$note        = note                                                                      #
#			--- OR ---                                                                       #
# $vcard->role_set($role);                                                                               #
#                                                                                                        #
# Purpose:                                                                                               #
#                                                                                                        #
#       In the first form, sets the values for a specific notes array element.                           #
#       In the second form, sets the values of the default (notes[0]) element.                           #
#--------------------------------------------------------------------------------------------------------#
    my $vCard = shift;
    if (@_ == 2) {
	#--------------------------------------#
	# Case 1: Specific role properties set #
	#--------------------------------------#
	my ($note_index,$note) = @_;
	if ($note_index eq "NEW") {
	    $vCard->{notes}->[@{$vCard->{notes}}]  = $note ;
	} elsif ($note_index < @{$vCard->{notes}} ) {
	    $vCard->{notes}->[$note_index]->[0] = $note;		
	} else {
	    if ($vCard->{'errors'}) {
		print STDERR "Error: No such note entry. ";
		print STDERR "(Entry '" . $note_index . "' requested, max entry is '" . @{$vCard->{notes}} .  "')\n";
	    }
	}
    } elsif (@_ == 1) {
	#-------------------------------------#
	# Case 2: Default note properties set #
	#-------------------------------------#
		my $note = shift;
		$vCard->{notes}->[0] = $note;		
	    } else {
		#----------------------------------------------------#
		# Error Case: Incorrect number of parameters passed. #
		#----------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Incorrect number of parameters passed to 'note_set'. ";
		    print STDERR "(Expected 1 or 2 parameters, got " . @_ . ")\n";
		}
	    }
    return $vCard;
}

sub prodid {
#-------------------------------------------#
# Useage:                                   #
#	$vcard->prodid                      #
#                                           #
# Purpose:                                  #
#	Returns product ID (PRODID) tag     #
#-------------------------------------------#
    my $vCard = shift;
    my $prodid = '';
    if ($vCard->{prodid} ne '') {
	$prodid = "PRODID:";
	$prodid .= $vCard->{prodid} . "\n";
    } else {
	print STDERR "Warning: No values set for generating product ID (PRODID) tag.\n";
    }
    return &fold($prodid);
}

sub parse_prodid {
#-------------------------------------------------------#
# Useage:                                               #
#       $vcard->parse_prodid($prodid_line)              # 
#               where                                   #
#       $prodid_line = a vCard PRODID formatted line    #
#                                                       #
# Purpose:                                              #
#       Translates a formatted PRODID line into         #
#       a Perl vCard object PRODID line.                # 
#-------------------------------------------------------#
    my $vCard = shift;
    my $prodidinfo = shift;
    &prodid_set($vCard,$prodidinfo);
    return $vCard;
}

sub prodid_set {
#------------------------------------------------------#
# Useage:                                              #
#       $vCard->prodid_set($prodid);                   #
#            where                                     #
#       $prodid   = ID of the product producing the    #
#                   vCard.                             #
#                                                      #
# Purpose:                                             #
#       Enables setting of PRODID tag.                 #
#                                                      #
# Developer's Question:                                #
#       Should it be user-settable? I've left it so as #
#       to engender maximum felxibility, but frankly,  #
#       if this is done for a specific product, perhaps#
#       this method should be either commented out or  #
#       overloaded?                                    #
#------------------------------------------------------#
    my $vCard = shift;
    my $prodid = shift;
    $vCard->{prodid} = $prodid;
    return $vCard;
}

sub revisiondate {
#-------------------------------------------#
# Useage:                                   #
#	$vcard->revisiondate                #
#                                           #
# Purpose:                                  #
#	Returns revision date (REV) tag     #
#-------------------------------------------#
    my $vCard = shift;
    my $rev = '';
    if ($vCard->{revisiondate} ne '') {
	$rev = "REV:";
	$rev .= $vCard->{revisiondate};
	#$rev .= "\n";
    } else {
	if ($vCard->{'warnings'}) {
	    print STDERR "Warning: No revisiondate value (REV) set for this card.\n";
	}
    }
    return &fold($rev);
}

sub parse_revisiondate {
#----------------------------------------------------------------#
# Useage:                                                        #
#       $vcard->parse_revisiondate($revisiondate_line)           # 
#               where                                            #
#       $revisiondate_line = a vCard REVISIONDATE formatted line #
#                                                                #
# Purpose:                                                       #
#       Translates a formatted REVISIONDATE line into            #
#       a Perl vCard object REVISIONDATE line.                   # 
#----------------------------------------------------------------#
    my $vCard = shift;
    my $revisiondateinfo = shift;
    &revisiondate_set($vCard,$revisiondateinfo);
    return $vCard;
}


sub revisiondate_set {
#-------------------------------------------------------#
# Useage:                                               #
#       $vCard->revisiondate_set($revdate);             #
#            where                                      #
#       $revdate  = date of last revision of this vCard #
#                                                       #
# Purpose:                                              #
#       Enables setting of REV tag.                     #
#                                                       #
# Developer's Question:                                 #
#       This should be format-checked in the app.       #
#-------------------------------------------------------#
    my $vCard = shift;
    my $revisiondate = shift;
    $vCard->{revisiondate} = $revisiondate;
    return $vCard;
}

sub sort_string {
#---------------------------------------------#
# Useage:                                     #
#	$vcard->sort_string                   #
#                                             #
# Purpose:                                    #
#	Returns sort string (SORT-STRING) tag #
#---------------------------------------------#
    my $vCard = shift;
    my $sort_string = "SORT-STRING:";
    $sort_string .= $vCard->{sort-string} . "\n";
    return &fold($sort_string);
}

sub parse_sort_string {
#--------------------------------------------------------------#
# Useage:                                                      #
#       $vcard->parse_sort_string($sort_string_line)           # 
#               where                                          #
#       $sort_string_line = a vCard SORT_STRING formatted line #
#                                                              #
# Purpose:                                                     #
#       Translates a formatted SORT_STRING line into           #
#       a Perl vCard object SORT_STRING line.                  # 
#--------------------------------------------------------------#
    my $vCard = shift;
    my $sort_stringinfo = shift;
    &sort_string_set($vCard,$sort_stringinfo);
    return $vCard;
}



sub sort_string_set {
#------------------------------------------------------------------------------#
# Useage:                                                                      #
#	$vcard->sort_string_set($formatted_name)                               #
#		where                                                          #
#	$sort_string = string sorts are to be performed on (usually 'lastname' #
#                                                                              #
# Purpose:                                                                     #
# 	Sets the SORT-STRING tag for this vCard.                               #
#------------------------------------------------------------------------------#
    my $vCard = shift;
    my $sort_string = shift;
    $vCard->{sort-string} = $sort_string;
    return $vCard;
}

sub sound {
#-------------------------------------#
# Useage:                             #
#	$vcard->sound;                #
#		OR                    #
#	$vcard->sound($num)           #
#	       WHERE                  #
#       $num = sound object index     #
#                                     #
# Purpose:                            # 
#	Returns all SOUND tags in the #
#	first form, and a specific    #
#	sound bite tag in the second. #
#-------------------------------------#
    my $vCard = shift;
    if (@_ == 0) {
	#------------------------------------------------------------#
	# Case 1: No parameters passed, return all SOUND subobjects. #
	#------------------------------------------------------------#
	my $sound_list = "";
		foreach my $sound (@{$vCard->{sounds}}) {
		    $sound_list .= "SOUND;";			
		    if ($sound->[0] eq "URL") {
			$sound_list .= "VALUE=uri:";
		    } else {
			$sound_list .= "ENCODING=b;TYPE=" . $sound->[0] . ":"; 
		    }
		    $sound_list .= $sound->[1];	
		    $sound_list .= "\n";
		    # SOUND;VALUE=uri:<uri>                                        
		    #	- OR -                                                 
		    # SOUND;ENCODING=b;TYPE=<file mimetype>:<base64 encoded info>  
		}
	return &fold($sound_list);
    } elsif (@_ == 1) {
	#-----------------------------------------------------------------#
	# Case 2: One parameter passed, return specified PHOTO subobject. #
	#-----------------------------------------------------------------#
	my $sound_index = shift;
	my @sounds = @{$vCard->{sounds}};
	my $max_index = @sounds - 1;
	if ($sound_index !~ /\D/ && $sound_index <= ($max_index)) {
	    #---------------------------------------------------#
	    # Good Case: Number passed, and within array range. #
	    #---------------------------------------------------#
	    my $sound = $vCard->{sounds}->[$sound_index];
	    my $sound_list = '';
	    if ($sound->[0] eq "URL") {
		$sound_list .= "VALUE=uri:";
	    } else {
		$sound_list .= "ENCODING=b;TYPE=" . $sound->[0] . ":"; 
	    }
	    $sound_list .= $sound->[1];	
	    $sound_list .= "\n";
	    return &fold($sound_list);
	} else {
	    #-----------------------------------------------------#
	    # Bad Case: Non number or out of range number passed. #
	    #-----------------------------------------------------#
	    if ($sound_index =~ /\D/) {
		#------------------------------------------------#
		# Bad Case Type 1: Non numeric parameter passed. #
		#------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
		    print STDERR "('" . $sound_index . "') passed to 'sound'.\n";
		}
	    } else {
		#-------------------------------------------------------------------#
		# Bad Case Type 2: Parameter out of range of SOUND subobject array. #
		#-------------------------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Parameter passed to 'sound' out of range. ";
		    print STDERR "('" . $sound_index . "' when max is '" . $max_index . "')\n"; 
		}
	    }
	    return "";
	}
    } elsif (@_ == 2) {
	#----------------------------------#
	# Specific subparameter requested. #
	#----------------------------------#
	my $sound_index = shift;
	my $fieldname = shift;
	my @sounds = @{$vCard->{sounds}};
	my $max_index = @sounds - 1;
	if ($sound_index !~ /\D/ && $sound_index <= ($max_index)) {
	    #---------------------------------------------------#
	    # Good Case: Number passed, and within array range. #
	    #---------------------------------------------------#
	    if ($fieldname eq 'type' || $fieldname eq 'value') {
		#----------------------------------------#
		# Good case: Field types requested exist #
		#----------------------------------------#
		my $field_value = $vCard->{'sounds'}->[$sound_index]->[$vCard->{'sound_elements'}->{$fieldname}];
		return($field_value);
	    } else {
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Field '$fieldname' is not a SOUND tag field.\n";
		}
		return "";
	    }
	} else {
	    #-----------------------------------------------------#
	    # Bad Case: Non number or out of range number passed. #
	    #-----------------------------------------------------#
	    if ($sound_index =~ /\D/) {
		#------------------------------------------------#
		# Bad Case Type 1: Non numeric parameter passed. #
		#------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
		    print STDERR "('" . $sound_index . "') passed to 'sound'.\n";
		}
	    } else {
		#-------------------------------------------------------------------#
		# Bad Case Type 2: Parameter out of range of SOUND subobject array. #
		#-------------------------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Parameter passed to 'sound' out of range. ";
		    print STDERR "('" . $sound_index . "' when max is '" . $max_index . "')\n"; 
		}
	    }
		return "";
	}
    } else {
	#-------------------------------------------------#
	# Error case.  Wrong number of parameters passed. #
	#-------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Wrong number of parameters passed to 'sound'. ";
	    print STDERR "(Expected 0 or 1 parameters, got " . @_ . ")\n";
	}
	return "";
    }
} # end sound

sub parse_sound {
#---------------------------------------------------#
# Useage:                                           #
#       $vcard->parse_sound($sound_line)            #
#               where                               #
#       $sound_line = a vCard SOUND formatted line  #
#                                                   #
# Purpose:                                          #
#       Translates a formatted SOUND line into      #
#       a Perl vCard object SOUND line.             #
#---------------------------------------------------#
    my $vCard = shift;
    my $soundinfo = shift;
    my @soundfields = @{$soundinfo};
    my $sound_value = shift;
    if (@soundfields == 1) {
	#-----------------------------#
	# Case 1: URL type sound tag. #
	#-----------------------------#
	&sound_set($vCard,"NEW",$sound_value);
    } elsif (@soundfields == 2) {
	#-----------------------------------------------#
	# Case 2: Base64 encoded inline type sound tag. #
	#-----------------------------------------------#
	my ($typetag,$sound_type) = split(/=/,@soundfields[1]);
	
	&sound_set($vCard,"NEW",$sound_type,$sound_value);
    } else {
	# Error Case: Improper number of aatributes listed in tag.
	if ($vCard->{'errors'}) { 
	    print STDERR "Error: SOUND tag contains improper formatting. (Offending subtags: ";
		print STDERR $soundinfo . ")\n";	   
	}
    }
    return $vCard;
# SOUND;VALUE=uri:<uri>                                        #
#	- OR -                                                 #
# SOUND;ENCODING=b;TYPE=<file mimetype>:<base64 encoded info>  #
}


sub sound_set {
#----------------------------------------------------------------------------------------------------------------#
# Useage:                                                                                                        #
#                                                                                                                #
# $vcard->sound_set($sound_index,$sound_url);                                                                    #
#	where 	$sound_index = # in sound list to modify, or 'NEW' to create a new subobject                     #
#		$sound_url = fully qualified URL pointing towards sound object                                   #
#			--- OR ---                                                                               #
# $vcard->sound_set($sound_index,$sound_type,$base64_encoded_sound)                                              #
#	where 	$sound_index 		= # in sound list to modify, or 'NEW' to create a new subobject          #
#		$sound_type  		= the type of sound file                                                 #   
#		$base64_encoded_sound	= base64 encoded sound file                                              #
#                                                                                                                #
# Purpose:                                                                                                       #
#                                                                                                                #
#
#----------------------------------------------------------------------------------------------------------------#
    my $vCard = shift;
    if (@_ == 2) {
	#-------------------------------------#
	# Case 1: Specific/new sound from URL #
	#-------------------------------------#
	my ($sound_index,$sound_url) = @_;
	if ($sound_index eq "NEW") {
	    my @new_sound = ('URL',$sound_url);	
	    my $new_sound = \@new_sound;
	    $vCard->{sounds}->[@{$vCard->{sounds}}]  = $new_sound ;
		} elsif ($sound_index < @{$vCard->{sounds}}) {
		    $vCard->{sounds}->[$sound_index]->[0] = 'URL';
		    $vCard->{sounds}->[$sound_index]->[1] = $sound_url;
		} else {
		    if ($vCard->{'errors'}) {
			print STDERR "Error: No such sound entry. ";
			print STDERR "(Entry '" . $sound_index . "' requested, max entry is '" . @{$vCard->{sounds}} . "')\n";
		    }
		}
    } elsif (@_ == 3) {
	#------------------------------------------#
	# Case 2: Specific/new base64 inline sound #
	#------------------------------------------#
	my ($sound_index,$sound_type,$base64_encoded_sound) = @_;
	if ($sound_index eq "NEW") {
	    my @new_sound = ($sound_type,$base64_encoded_sound);	
	    my $new_sound = \@new_sound;
	    $vCard->{sounds}->[@{$vCard->{sounds}}]  = $new_sound ;
	} elsif ($sound_index < @{$vCard->{sounds}}) {
	    $vCard->{sounds}->[$sound_index]->[0] = $sound_type;
	    $vCard->{sounds}->[$sound_index]->[1] = $base64_encoded_sound;
	} else {
	    if ($vCard->{'errors'}) {
		print STDERR "Error: No such sound entry. ";
		print STDERR "(Entry '" . $sound_index . "' requested, max entry is '" . @{$vCard->{sounds}} . "')\n";
	    }
	}
    } else {
	#----------------------------------------------------#
	# Error Case: Incorrect number of parameters passed. #
	#----------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Incorrect number of parameters passed to 'sound_set'. ";
		    print STDERR "(Expected 2 or 3 parameters, got " . @_ . ")\n";
		}
	    }
    return "$vCard";
} # end sound_set

sub UID {
#--------------------------------------#
# Useage:                              #
#	$vcard->UID                    #
#                                      #
# Purpose:                             #
#	Returns universal ID (UID) tag #
#--------------------------------------#
    my $vCard = shift;
    my $UID = '';
    if ($vCard->{UID} ne '') {
	$UID = "UID:";
	$UID .= $vCard->{UID} . "\n";
    } else {
	if ($vCard->{'warnings'}) {
	    print STDERR "Warning: No UID value currently set for this card.\n"
	    }
    }
    return &fold($UID);
}

sub parse_UID {
#-------------------------------------------------#
# Useage:                                         #
#       $vcard->parse_UID($UID_line)              # 
#               where                             #
#       $UID_line = a vCard UID formatted line    #
#                                                 #
# Purpose:                                        #
#       Translates a formatted UID line into      #
#       a Perl vCard object UID line.             # 
#-------------------------------------------------#
    my $vCard = shift;
    my $UIDinfo = shift;
    &UID_set($vCard,$UIDinfo);
    return $vCard;
}


sub UID_set {
#-------------------------------------------------#
# Useage:                                         #
#	$vcard->UID_set($UID)                     #
#		where                             #
#	$UID = universal ID number for this vCard #
#                                                 #
# Purpose:                                        #
# 	Sets the UID tag for this vCard.          #
#-------------------------------------------------#
    my $vCard = shift;
    my $UID = shift;
    $vCard->{UID} = $UID;
    return $vCard;
}

sub URL {
#-----------------------------------# 
# Useage:                           #  
#	$vcard->URL;                #  
#		OR                  #  
#	$vcard->URL($num)           #
#	       WHERE                #
#       $num = URL object index     #
#                                   #
# Purpose:                          # 
#	Returns all URL tags in the #
#	first form, and a specific  #
#	URL tag in the second.      #
#-----------------------------------#
    my $vCard = shift;

    if (@_ == 0) {
	#----------------------------------------------------------#
	# Case 1: No parameters passed, return all ADR subobjects. #
	#----------------------------------------------------------#
	my $URL_list = "";
	foreach my $URL (@{$vCard->{URLs}}) {
	    my $URL_type_list = "";
	    $URL_list .= "URL:";
	    $URL_list .= $URL;	
	    $URL_list .= "\n";
	    # URL:<url,0>
	}
	return &fold($URL_list);
    } elsif (@_ == 1) {
	#---------------------------------------------------------------#
	# Case 2: One parameter passed, return specified TEL subobject. #
	#---------------------------------------------------------------#
	my $URL_index = shift;
	my @URLs = @{$vCard->{URLs}};
	my $max_index = @URLs - 1;
	if ($URL_index !~ /\D/ && $URL_index <= ($max_index)) {
	    #---------------------------------------------------#
	    # Good Case: Number passed, and within array range. #
	    #---------------------------------------------------#
	    my $URL_list = "URL:";
	    my $URL = $vCard->{URLs}->[$URL_index]->[0];
	    $URL_list .= $URL;	
	    $URL_list .= "\n";
	    return &fold($URL_list);
	} else {
	    #-----------------------------------------------------#
	    # Bad Case: Non number or out of range number passed. #
	    #-----------------------------------------------------#
	    if ($URL_index =~ /\D/) {
		#------------------------------------------------#
		# Bad Case Type 1: Non numeric parameter passed. #
		#------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Non numeric, non integer and/or non positive value parameter ";
		    print STDERR "('" . $URL_index . "') passed to 'URL'.\n";
		}
	    } else {
		#-------------------------------------------------------------------#
		# Bad Case Type 2: Parameter out of range of URL subobject array. #
		#-------------------------------------------------------------------#
		if ($vCard->{'errors'}) {
		    print STDERR "Error: Parameter passed to 'URL' out of range. ";
		    print STDERR "('" . $URL_index . "' when max is '" . $max_index . "')\n"; 
		}
	    }
	    return "";
	}
    } else {
	#-------------------------------------------------#
	# Error case.  Wrong number of parameters passed. #
	#-------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Wrong number of parameters passed to 'URL'. ";
	    print STDERR "(Expected 0 or 1 parameters, got " . @_ . ")\n";
		}
	return "";
    }
}

sub parse_URL {
#-----------------------------------------------#
# Useage:                                       #
#       $vcard->parse_URL($URL_line)            #
#               where                           #
#       $URL_line = a vCard URL formatted line  #
#                                               #
# Purpose:                                      #
#       Translates a formatted URL line into    #
#       a Perl vCard object URL line.           #
#-----------------------------------------------#
    my $vCard = shift;
    my $URLinfo = shift;
    &URL_set($vCard,"NEW",$URLinfo);
    return $vCard;
}


sub URL_set {
#-----------------------------------------------------------------------------------------------------#
# Useage:                                                                                             #
#                                                                                                     #
# $vcard->URL_set($URL_index,$URL);                                                                   #
#	where 	$URL_index  = # of element in URL list to modify, or NEW to create a new object       #
#		$URL        = URL                                                                     #
#			--- OR ---                                                                    #
# $vcard->URL_set($URL);                                                                              #
#                                                                                                     #
# Purpose:                                                                                            #
#                                                                                                     #
#       In the first form, sets the values for a specific URLs array element.                         #
#       In the second form, sets the values of the default (URLs[0]) element.                         #
#-----------------------------------------------------------------------------------------------------#
    my $vCard = shift;
    if (@_ == 2) {
	#--------------------------------------#
	# Case 1: Specific role properties set #
	#--------------------------------------#
	my ($URL_index,$URL) = @_;
print STDERR "URL = $URL index = $URL_index";
print STDERR "@{$vCard->{URLs}}";
	if ($URL_index eq "NEW") {
	    $vCard->{URLs}->[@{$vCard->{URLs}}]->[0]  = $URL ;
	} elsif ($URL_index < @{$vCard->{URLs}} ) {
	    $vCard->{URLs}->[$URL_index]->[0] = $URL;		
	} else {
	    if ($vCard->{'errors'}) {
		print STDERR "Error: No such URL entry. ";
		print STDERR "(Entry '" . $URL_index . "' requested, max entry is '" . @{$vCard->{URLs}} .  "')\n";
	    }
	}
    } elsif (@_ == 1) {
	#-------------------------------------#
	# Case 2: Default URL properties set #
	#-------------------------------------#
	my $URL = shift;
	$vCard->{URLs}->[0] = $URL;		
    } else {
	#----------------------------------------------------#
	# Error Case: Incorrect number of parameters passed. #
	#----------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Incorrect number of parameters passed to 'URL_set'. ";
	    print STDERR "(Expected 1 or 2 parameters, got " . @_ . ")\n";
	}
    }
    return $vCard;
}

sub class {
#------------------------------------------#
# Useage:                                  #
#	$vcard->class                      #
#                                          #
# Purpose:                                 #
#	Returns security class (CLASS) tag #
#------------------------------------------#
    my $vCard = shift;
    my $class = "CLASS:";
    $class .= $vCard->{class} . "\n";
    return &fold($class);
}

sub parse_class{
#--------------------------------------------------#
# Useage:                                          #
#       $vcard->parse_class($class_line)           #
#               where                              #
#       $class_line = a vCard class formatted line #
#                                                  #
# Purpose:                                         #
#       Translates a formatted class line into     #
#       a Perl vCard object class line.            #
#--------------------------------------------------#
    my $vCard = shift;
    my $classinfo = shift;
    &class_set($vCard,$classinfo);
    return $vCard;
}

sub class_set {
#----------------------------------------------#
# Useage:                                      #
#	$vcard->class_set($class)              #
#		where                          #
#	$class = security class for this vCard #
#                                              #
# Purpose:                                     #
# 	Sets the class tag for this vCard.     #
#----------------------------------------------#
    my $vCard = shift;
    my $class = shift;
    $vCard->{class} = $class;
    return $vCard;
}


sub key {
#-----------------------------------#
# Useage:                           #
#	$vcard->key;                #
#                                   #
# Purpose:                          # 
#       Returns the public key or   #
#       security certificate of the #
#       vCard holder.               # 
#-----------------------------------#
    my $vCard = shift;
    my $key_list = "";
    if (($vCard->{key}->[1] ne '')) {
	$key_list .= "KEY;ENCODING=b";
	if ($vCard->{key}->[0] ne '') {
	    $key_list .= ";TYPE=" . $vCard->{key}->[0];
	}
	$key_list .= ":" . $vCard->{key}->[1];
    } else {
	$key_list = '';
    }
    # KEY;ENCODING=b:<base64 encoded info>
    #	- OR -                                                 
    # KEY;ENCODING=b;TYPE=<file mimetype>:<base64 encoded info>  
    return &fold($key_list);
}

sub parse_key {
#-------------------------------------------------#
# Useage:                                         #
#       $vcard->parse_key($key_line)              #
#               where                             #
#       $key_line = a vCard KEY formatted line    #
#                                                 #
# Purpose:                                        #
#       Translates a formatted KEY line into      #
#       a Perl vCard object KEY line.             #
#-------------------------------------------------#
    my $vCard = shift;
    my $keyinfo = shift;
    my @keyfields = @{$keyinfo};
    my $key_value = shift;
    if (@keyfields == 1) {
	#-----------------------------#
	# Case 1: URL type key tag.   #
	#-----------------------------#
	&key_set($vCard,$key_value);
    } elsif (@keyfields == 2) {
	#-----------------------------------------------#
	# Case 2: Base64 encoded inline type key tag.   #
	#-----------------------------------------------#
	my ($typetag,$key_type) = split(/=/,@keyfields[1]);
	
	&key_set($vCard,$key_type,$key_value);
    } else {
	# Error Case: Improper number of attributes listed in tag.
	if ($vCard->{'errors'}) { 
	    print STDERR "Error: KEY tag contains improper formatting. (Offending subtags: ";
	    print STDERR $keyinfo . ")\n";	   
	}
    }
    return $vCard;
}


sub key_set {
#-----------------------------------------------------------------------------------------------#
# Useage:                                                                                       #
#                                                                                               #
# $vcard->key_set($base64_encoded_key);                                                         #
#	where 	$$base64_encoded_key    = base64 encoded key                                    #
#			--- OR ---                                                              #
# $vcard->key_set($key_type,$base64_encoded_key)                                                #
#	where 	$key_type  		= the type of key                                       #   
#		$base64_encoded_key	= base64 encoded key                                    #
#                                                                                               #
# Purpose:                                                                                      #
#       Sets the value (and type, in the second case) of the public key/certificate (KEY) tag   #
#-----------------------------------------------------------------------------------------------#
    my $vCard = shift;
    undef $vCard->{key};
    if (@_ == 1) {	    
	#-------------------------------------------------#
	# Case 1: Specific/new key in base64 without type #
	#-------------------------------------------------#
	my $base64_encoded_key = shift;
	$vCard->{key}->[1] = $base64_encoded_key;
    } elsif (@_ == 2) {
	#----------------------------------------#
	# Case 2: Specific/new base64 inline key #
	#----------------------------------------#
	my ($key_type,$base64_encoded_key) = @_;
	$vCard->{key}->[0] = $key_type;
	$vCard->{key}->[1] = $base64_encoded_key;
    } else {
	#----------------------------------------------------#
	# Error Case: Incorrect number of parameters passed. #
	#----------------------------------------------------#
	if ($vCard->{'errors'}) {
	    print STDERR "Error: Incorrect number of parameters passed to 'key_set'. ";
	    print STDERR "(Expected 2 or 3 parameters, got " . @_ . ")\n";
	}
    }
}

sub footer {
#----------------------------------#
# Useage:                          #
#	$vcard->footer;            #
#                                  #
# Purpose:                         #
#	Returns a "END:VCARD" tag. #
#----------------------------------#
    my $vCard = shift;    
    return $vCard->{'basetags'}->{'end'} . "\n";
}

sub identification_group {
#-----------------------------------------#
# Useage:                                 #
#       $vcard->identification_group      #
#                                         # 
# Purpose:                                #
#       Returns all 'identification' tags #
#       (FN, N, NICKNAME, PHOTO and BDAY) #
#-----------------------------------------#
    my $vCard = shift;
    
    my $id_list = "";
    $id_list .= fn($vCard);
    $id_list .= name($vCard);
    $id_list .= nickname($vCard);
    $id_list .= photo($vCard);
    $id_list .= birthday($vCard);
    
    return($id_list);
}

sub delivery_group {
#-----------------------------------#
# Useage:                           #
#       $vcard->delivery_group      #
#                                   #
# Purpose:                          #
#       Returns all 'delivery' tags #
#       (ADR, LABEL)                #
#-----------------------------------#
    my $vCard = shift;
    
    my $delivery_list = "";
    $delivery_list .= address($vCard);
    $delivery_list .= label($vCard);
    
    return($delivery_list);
}

sub telecomm_group {
#-----------------------------------#
# Useage:                           #
#       $vcard->telecomm_group      #
#                                   #
# Purpose:                          #
#       Returns all 'telecomm' tags #
#       (TEL, EMAIL, MAILER)        #
#-----------------------------------#
    my $vCard = shift;
    
    my $telecomm_list = "";
    $telecomm_list .= telephone($vCard);
    $telecomm_list .= email($vCard);
    $telecomm_list .= mailer($vCard);

    return($telecomm_list);

}

sub geographical_group {
#---------------------------------------#
# Useage:                               #
#       $vcard->geographical_group      #
#                                       #
# Purpose:                              #
#       Returns all 'geographical' tags #
#       (TZ, GEO)                       #
#---------------------------------------#
    my $vCard = shift;
    
    my $geographical_list = "";
    $geographical_list .= tz($vCard);
    $geographical_list .= geo($vCard);
    
    return($geographical_list);
}

sub organizational_group {
#-----------------------------------------#
# Useage:                                 #
#       $vcard->organizational_group      #
#                                         #
# Purpose:                                #
#       Returns all 'organizational' tags #
#       (TITLE,ROLE,LOGO,AGENT,ORG)       #
#-----------------------------------------#
    my $vCard = shift;
    
    my $organizational_list = "";
    $organizational_list .= title($vCard);
    $organizational_list .= role($vCard);
    $organizational_list .= logo($vCard);
    $organizational_list .= agent($vCard);
    $organizational_list .= org($vCard);
    
    return($organizational_list);
}

sub explanatory_group {
#----------------------------------------------------------------------#
# Useage:                                                              #
#       $vcard->explanatory_group                                      #
#                                                                      #
# Purpose:                                                             #
#       Returns all 'explanatory' tags                                 #
#       (CATEGORIES,NOTE,PRODID,REV,SORT-STRING,SOUND,UID,URL,VERSION) #
#----------------------------------------------------------------------#
    my $vCard = shift;
    
    my $explanatory_list = "";
    $explanatory_list .= categories($vCard);
    $explanatory_list .= note($vCard);
    $explanatory_list .= prodid($vCard);
    $explanatory_list .= revisiondate($vCard);
    $explanatory_list .= sort_string($vCard);
    $explanatory_list .= sound($vCard);
    $explanatory_list .= UID($vCard);
    $explanatory_list .= URL($vCard);
    $explanatory_list .= version($vCard);

    return($explanatory_list);
}

sub security_group {
#-----------------------------------#
# Useage:                           #
#       $vcard->security_group      #
#                                   #
# Purpose:                          #
#       Returns all 'security' tags #
#       (CLASS, KEY)                #
#-----------------------------------#
    my $vCard = shift;
    
    my $security_list = "";
    $security_list .= class($vCard);
    $security_list .= key($vCard);
    
    return($security_list);
}

sub all {
#-----------------------------------#
# Useage:                           #
#       $vcard->all                 #
#                                   #
# Purpose:                          #
#       Returns all vCard tags      #
#-----------------------------------#
    my $vCard = shift;
    my $full_card = "";
    
    $full_card .= $vCard->header();
    $full_card .= identification_group($vCard);
    $full_card .= delivery_group($vCard);    
    $full_card .= telecomm_group($vCard);
    $full_card .= geographical_group($vCard);
    $full_card .= organizational_group($vCard);
    $full_card .= explanatory_group($vCard);
    $full_card .= security_group($vCard);

    $full_card .= footer($vCard);

    return($full_card);

}

sub strip_taginfo {
#----------------------------------------------#
# Useage:                                      #
#       $vcard->strip_taginfo($formatted_tag)  #
#                - WHERE -                     #
#       $formatted_tag = a formatted vCard tag #
#                                              #
# Purpose:                                     #
#       Removes everything but the values      #
#       from a particular tag.                 #
#----------------------------------------------#
    my $vCard = shift;
    my $full_tag = shift;
    my $value_tag = substr($full_tag,(index($full_tag,':')+1));
    $value_tag =~ s/\n$//;
    $value_tag =~ s/^;$//; # in particular, for geo get method
    return $value_tag;
}

sub build_fn {
	my $vCard = shift;

	my $fn = $vCard->name('prefix')." ".$vCard->name('first')." ".$vCard->name('middle')." ".$vCard->name('last')." ".$vCard->name('suffix');
	$fn =~ s/  / /g; # remove extra space
	$vCard->fn_set($fn);

	return $vCard;
} # build_fn

sub build_label {
	my $vCard = shift;
	my $param = shift;
	my $startAddress = 0; 
	my $stopAddress = 0;
	
	if ($param eq "ALL") {
		$startAddress = 0;
		$stopAddress = $#{$vCard->{address_list}}; # last position of array
	} elsif ($param =~ /^\d+$/) {
		$startAddress = $stopAddress = $param
	} else {
		if ($vCard->{'errors'}) {
			print STDERR "Error: Parameter passed to 'build_Label' out is wrong ($param)";
		}
		return "";
	}

	for (my $idx = $startAddress; $idx <= $stopAddress; $idx++)
	{
		my $label;
		foreach my $arg (("street", "_locale", "region", "country", "code"))
		{
			my $tmp_arg = $arg;
			my $newlinechar = "\n";
			if ($tmp_arg =~ s/^_//) { $newlinechar = ", "; } # so we can have another element on same line
			my $value = $vCard->address($idx, $tmp_arg);

			if ($value ne "") { $label .= "$value$newlinechar"; } 
			else { next; }
		}
	
		my $type = ($#{$vCard->{labels}} >= $idx) ? $idx : "NEW"; # if label exist, use index, otherewise create new entry
		$vCard->label_set($type, $vCard->address($idx, "types"), $label);
	}

	return $vCard;
} # build_label

sub DESTROY {
    my $vCard = shift;
    undef $vCard;
    return $vCard;
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


1;

__END__

=head1 NAME

vCard.pm - A module to create, manipulate and parse vCard information as Perl  objects.




=head1 SYNOPSIS

    use vCard;

    $vCard = new vCard;

    $vCard->importcard(@array_of_vCard_lines);
    $vCard->parse(@array_of_unfolded_vCard_lines);

    $vCard->header;

    $vCard->strip_taginfo($formatted_tag);

    $vCard->fn;
    $vCard->parse_fn($fn_info);
    $vCard->fn_set($formatted_name);

    $vCard->name;
    $vCard->name($name_field);      
    # Where namefield is one of 'last','first','suffix','prefix' or 'middle'
    $vCard->parse_name($name_info);
    $vCard->name_set(<lastname>,<firstname>,<middlename>,<prefix>,<suffix>);                 
    $vCard->name_set(<fieldname>,<value>); 

    $vCard->nickname;            
    $vCard->nickname($num); 
    $vCard->parse_nickname($nickname_info);  
    $vCard->nickname_set($nickname_list);
 
    $vCard->photo;                
    $vCard->photo($num);
    $vCard->photo($num,$photograph_field)
    # Where $photograph_field is one of 'type' or 'value'
    $vCard->parse_photo(\@photo_type_info,$photo_info);
    $vCard->photo_set($photo_index,$photo_url);
    $vCard->photo_set($photo_index,$photo_type,$base64_encoded_image);

    $vCard->birthday;
    $vCard->parse_birthday($birthday_info);
    $vCard->birthday_set($date);
          
    $vCard->identification_group;


    $vCard->address;
    $vCard->address($num);
    $vCard->address($num,$field);      
    # Where field is one of 'addr','xaddr','street','locale','region','code','country'
    $vCard->parse_address(\@address_type_info,$address_info);
    $vCard->address_set($addr_index,$addr_types,$addr,$xaddr,$locality,$region,$postal,$country,$grouping);
    $vCard->address_set($addr_index,$fieldname,$value);

    $vCard->label;
    $vCard->parse_label(\@label_type_info,$label_info);
    $vCard->label($label_index);
    $vCard->label_set($label_index,$label_types,$label_number);
    $vCard->label_set($label_types,$label_number);

    $vCard->delivery_group;


    $vCard->telephone;
    $vCard->telephone($num);
    $vCard->telephone($num,$field);      
    # Where field is one of 'types' (returns arrayref) or 'number'
    $vCard->parse_telephone(\@tel_type_info,$tel_info);
    $vCard->telephone_set($tel_index,$tel_types,$tel_number);
    $vCard->telephone_set($tel_types,$tel_number);

    $vCard->email;
    $vCard->email($num);
    $vCard->email($num,$field);      
    # Where field is one of 'types' (returns arrayref) or 'address'
    $vCard->parse_email(\@email_type_info,$email_info);
    $vCard->email_set($email_index,$email_types,$email_number);
    $vCard->email_set($email_types,$email_addr);

    $vCard->mailer;
    $vCard->parse_mailer($mailer_info);
    $vCard->mailer_set($mailer);

    $vCard->telecomm_group;


    $vCard->tz;
    $vCard->parse_tz($tz_info);
    $vCard->tz_set($timezone_info);
    $vCard->tz_set("VALUE",$textstring);

    $vCard->geo;
    $vCard->parse_geo($geo_info);
    $vCard->get_set($longitude,$latitude);

    $vCard->geographical_group;


    $vCard->title;
    $vCard->title($num);
    $vCard->parse_title($title_info);
    $vCard->title_set($title_index,$title);
    $vCard->title_set($title);

    $vCard->role;
    $vCard->role($num);
    $vCard->parse_role($role_info);
    $vCard->role_set($role_index,$role);
    $vCard->role_set($role);

    $vCard->logo;
    $vCard->logo($num);
    $vCard->logo($num,$field);      
    # Where field is one of 'type' (returns arrayref) or 'value'
    $vCard->parse_role($role_info);
    $vCard->logo_set($logo_index,$logo_url);
    $vCard->logo_set($logo_index,$logo_type,$base64_encoded_image);

    # Agent methods have been deliberately left out until I'm willing
    # to deal with the recursion issues involved.  It's just damned annoying,
    # folks...  Especially since the vCard can be represented as a single-line
    # tag field instead of in the usual format.  Wait for the next major revision
    # for this one, I have a feeling.

    $vCard->org;
    $vCard->org($num);
    $vCard->parse_org($org_info);
    $vCard->org_set($org_index,$org);
    $vCard->org_set($org);

    $vCard->organizational_group;

    $vCard->categories;
    $vCard->parse_categories($category_info);
    $vCard->categories_set($command_delimited_categories_list);

    $vCard->note;
    $vCard->note($num);
    $vCard->parse_note($note_info);
    $vCard->note_set($note_index,$note);
    $vCard->note_set($note);

    $vCard->prodid;
    $vCard->parse_prodid($product_id_info);
    $vCard->prodid_set($prodid);

    $vCard->revisiondate;
    $vCard->parse_revisiondate($revision_date_info); 
    $vCard->revisiondate_set($revdate);

    $vCard->sort_string;
    $vCard->parse_sort_string($sort_string_info);
    $vCard->sort_string_set($formatted_name);

    $vCard->sound;
    $vCard->sound($num);
    $vCard->sound($num,$field);      
    # Where field is one of 'type' (returns arrayref) or 'value'
    $vCard->parse_sound(\@sound_type_info,$sound_info);
    $vCard->sound_set($sound_index,$sound_url);
    $vCard->sound_set($sound_index,$sound_type,$base64_encoded_sound);

    $vCard->UID;
    $vCard->parse_UID($UID_info);
    $vCard->UID_set($UID);

    $vCard->URL;
    $vCard->URL($num);
    $vCard->parse_URL($URL_info);
    $vCard->URL_set($URL_index,$URL);
    $vCard->URL_set($URL);

    $vCard->version;

    $vCard->explanatory_group;


    $vCard->class;
    $vCard->parse_class($class_info);
    $vCard->class_set($class);

    $vCard->key;
    $vCard->parse_key(\@key_type_info,$key_info);
    $vCard->key_set($base64_encoded_key);
    $vCard->key_set($key_type,$base64_encoded_key);

    $vCard->security_group;


    $vCard->all;


    $vCard->footer;

  (UNDER CONSTRUCTION - Don't believe everything you read yet, kids, but this section's close...)
   Give a simple example of the module's use

=head1 DESCRIPTION

  The vCard module allows a Perl script to create and manipulate vCard objects as Perl
  data structures.  The number of methods listed above may seem impressive, but they fall
  into a fairly small number of generic types:

  1) Display methods:
  These methods (usually referred to by the name of the tag, such as nickname() or photo())
  are used to output a proper vCard formatted tag line (or all tag lines of that type, when
  called without parameters) in their most basic form.  For a number of these methods, specific
  subfields within a tag can be accessed by specifying the subtag requested, though this
  varies from tag type to tag type.  (This will hopefully be more standardized in later versions
  of this module)
  Also in this class are the grouped display methods, such as identification_group(), that
  return all tags from a specific related group (as grouped in RFC 2426) of tags, and the
  all() method which returns the full vCard.

  2) Parsing methods:
  These are methods that take information from existing tag lines and insert them into a vCard
  object.  It is rare that these need to be called directly; rather, call the parse() method,
  passing it an array of vCard lines.  At its simplest, this would be parse() called on a one
  entry array to parse a single line.  (parse() performs the neccessary preprocessing for the
  parse_*() methods and then calls them appropriately).  Note that if the lines are folded, you
  should call the importcard() method rather than the parse() method, as it will perform the 
  neccessary unfolding required before parsing.  
  NOTE: A suggestion has been made that parse() be changed to accept scalars as well as arrays
  as parameters.  The scalar (a full vCard or group of vCard lines) would be split by newline 
  (\n) into an array internally to the function and processed.  This has not been implemented
  yet, but expect it soon)

  3) Setting methods:
  These allow the direct setting of values for the various vCard tags.  Due to the variation in
  storage structures for the various types of tag information, these methods have the widest 
  variation in teir useage.  They share certain characteristics though:
  - They are all named in the format *_set(), where * is the name of the tag.
  - Most can take "NEW" as a parameter for entering a new tag of that type.  A few
    that do not allow multiple instances of that tag type do not.
  - Most allow manipulation of specific sub-elements within a tag.  Those that don't
    either have no sub-elements, or are being worked on further to allow this to be done.

  (UNDER CONSTRUCTION - Don't believe everything you read yet, kids...)

=head1 METHODS

  (UNDER CONSTRUCTION - Don't believe everything you read yet, kids...)
  new -  Creates a new instance
  some_other_function - ([param_name],value) -  detailed description of the use each function

=head1 PARAMETERS

  (UNDER CONSTRUCTION - Don't believe everything you read yet, kids...)
        # well known parameters for this object, normally passed into the contruction as a hash,
        # or gotten and set using the getValue() and setValue() calls.
  text -
  image -

=head1 AUTHOR

John F. Zmrotchek
HBE     zed@hbe.ca
July 23, 1999

=head1 REVISION HISTORY

$Log: vCard.pm,v $
Revision 1.4  1999/10/10 19:52:05  fhurtubi
Removed Data::Dumper call and nickname was buggy (had [01] instead of [0])

Revision 1.3  1999/09/05 00:03:30  gozer
FIxed a few things for the installer.
Added a global $VERSION in vCard.pm

Revision 1.2  1999/09/02 21:29:08  scott
added Office

Revision 1.1  1999/09/02 21:25:52  scott
fixed a cvs problem ... had a really old version of this file.

Revision 1.23  1999/08/27 20:00:19  fhurtubi
Changed the way URL stores its data

Revision 1.22  1999/08/27 19:20:48  fhurtubi
Fixed a = that really supposed to be a < in set_URL

Revision 1.21  1999/08/18 23:25:14  fhurtubi
Small changes

Revision 1.20  1999/08/17 22:09:59  fhurtubi
Added new parse methods to build formatted name (fn) and label

Revision 1.19  1999/08/16 17:32:16  fhurtubi
Fixed some bugs in set and get methods

Revision 1.16  1999/08/13 20:01:09  fhurtubi
Fixes bunch of get methods

Revision 1.15  1999/08/13 19:31:53  jzmrotchek
More bug fixes.  Will the madness never end?

Revision 1.14  1999/08/13 19:26:32  jzmrotchek
Bug fixes (scalar VS array contexts in EMAIL and PHONE).

Revision 1.13  1999/08/13 19:09:52  fhurtubi
Mofidied email_set and phone_set do handle types/values separately

Revision 1.12  1999/08/13 16:22:14  scott
Changed a bunch of
  my @bla;

to

 my @bla = [];

otherwise they don't get stored and we're in trouble bringin it back
out from the database

Revision 1.11  1999/08/12 19:23:40  jzmrotchek
Primarily another bugfix release.
One functionality change: The TEL (telephone) tag can also have a grouping tag attached now.

Revision 1.7  1999/08/02 21:26:42  jzmrotchek
Added in 'by field' returns for ADR, TEL, EMAIL, LOGO and SOUND tags.
Added some POD to explain above.
Did some minor cleanup work to make the code more legible.

Revision 1.6  1999/07/30 19:26:05  jzmrotchek

Minor documentation 'oops'.  parse() method is for unfolded vCard lines.  If the
vCard is properly folded (as most will be), call the import() method instead.

Revision 1.5  1999/07/30 15:51:14  jzmrotchek

Minor revision:  Took out debugging code that was printing out stuff it shouldn't
have been printing out when the module was invoked.  Oops.

Revision 1.4  1999/07/30 15:43:45  jzmrotchek

Lots of changes.  The first and foremost amongst them is that the parsing routines
are now in place.  Read the perldocs, the comments in the program, or just ask me
how it works. :)
I've also tightened up some of the tag return codes and default data structure values.
Previously, calling some display methods for theoretically empty tag groups still
returned tags, though the tags were empty of any values.  This has not only been fixed,
but if warnings are enabled, it will spit out a warning to STDERR that no values have
been set for that tag/tag group.
For more information, see the comments at the beginning of the module.

Revision 1.3  1999/07/23 21:11:12  jzmrotchek
Okay, I've stated writing the POD for the module.  Right now it's mostly a list of method invocations, but it
should be enough to get you started using the module.  Let me know what you think.
Next steps: writing parse methods and sub-object query methods (which may extend the current formatted return methods).

Revision 1.2  1999/07/23 18:37:22  jzmrotchek
Did a bunch of stuff; the first version of the module (sans POD docs or parsing methods, but setting and output methods in place) is pretty much good to go.  There are some issues, see the comments section at the beginning of the script for details.

Revision 1.1  1999/07/21 20:59:40  jzmrotchek
Added vCard Perl module to Father's collection of stuff.  Enjoy, folks!
(Comments, criticisms and bug reports to me at jzmrotchek@hbe.ca)


=head1 SEE ALSO

perl(1), RFC2426

=cut


