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

#--------------------------------------------------------------------
# SW::PrefMan::Text
#--------------------------------------------------------------------
# $Id: 
#--------------------------------------------------------------------

package SW::App::PrefMan::Text;

use strict;
use vars qw(@ISA);

use SW::Language;

@ISA = qw(SW::Language Exporter);

sub new
{
    my $classname=shift;
    my $self=$classname->SUPER::new(@_);
    bless($self,$classname);
    
    $self->{VARIANT_LIST} = [ "en", "fr", "zh", "es"];
    $self->{STRING_TABLE} = {
	"PreferencesEditor" => 
	{
	    "en"        =>      "Preferences Editor",
	},
	"SavePrefs"         =>
	{
	    "en"        =>      "Save Application Preferences",
	},
	"Preference"         =>
	{
	    "en"        =>      "Preference",
	},
	"Value"         =>
	{
	    "en"        =>      "Value",
	},	
	"SaveUserPrefs"         =>
	{
	    "en"        =>      "Save User Preferences",
	},	
	"Value"         =>
	{
	    "en"        =>      "Value",
	},	
	"Default"         =>
	{
	    "en"        =>      "Default",
	},	
	"Name"         =>
	{
	    "en"        =>      "Name",
	},	
	"Phone Number"         =>
	{
	    "en"        =>      "Phone Number",
	},	
	"Address"         =>
	{
	    "en"        =>      "Address",
	},	
	"City"         =>
	{
	    "en"        =>      "City",
	},	
	"State or Province"         =>
	{
	    "en"        =>      "State or Province",
	},	
	"Country"         =>
	{
	    "en"        =>      "Country",
	},	
	"Zip Code"         =>
	{
	    "en"        =>      "Zip Code",
	},	
	"Lang"         =>
	{
	    "en"        =>      "Language",
	},	
	"Logout"         =>
	{
	    "en"        =>      "Logout",
	},	
	"Change Password"         =>
	{
	    "en"        =>      "Change Password",
	},	
	"New Password"         =>
	{
	    "en"        =>      "New Password",
	},	
	"Old Password"         =>
	{
	    "en"        =>      "Old Password",
	},	
	"Confirm New Password"         =>
	{
	    "en"        =>      "Confirm New Password",
	},	
	"User Preferences"         =>
	{
	    "en"        =>      "User Preferences",
	},	
	"Application Preferences"         =>
	{
	    "en"        =>      "Application Preferences",
	},	
	"ChangePassword"          => 
	{
	    "en"        =>      "Change Password",
	}
    };
    
    
    return $self;
} 

1;



