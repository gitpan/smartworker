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

package SW::User::Pref;


#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::Preferences
#  Module to manipulate both user and application preferences
#------------------------------------------------------------
#  CVS ID tag...
# $Id: Pref.pm,v 1.4 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

$VERSION = '0.01';


#------------------------------------------------------------
#  new
#------------------------------------------------------------

sub new
{
   my $classname = shift;
   my $self;
   
	if (ref($_[0]) eq "HASH") {
       $self = shift;
   } else {
       $self = { 'global' => {},
		 'user'   => {},
		 'apps'    => {},
	     };
   }

   bless ($self, $classname);
	
   return $self;
}

#------------------------------------------------------------
#  getGlobalPref($prefkey)
#
#     Gets the value of the preference whose key is $prefkey
#------------------------------------------------------------

sub getGlobalPref
{
	my $self     = shift;
	my $prefkey  = shift; 

	my $prefvalue = $self->{global}->{$prefkey};

	return $prefvalue;
}

#------------------------------------------------------------
#  getUserPref($prefkey)
#
#     Gets the value of the preference whose key is $prefkey
#------------------------------------------------------------

sub getUserPref
{
	my $self     = shift;
	my $prefkey  = shift; 

	my $prefvalue = $self->{user}->{$prefkey};

	return $prefvalue;
}


#------------------------------------------------------------
#  getAppPref($prefkey)
#
#     Gets the value of the preference whose key is $prefkey
#------------------------------------------------------------

sub getAppPref
{
	my $self     = shift;
	my $appid    = shift;
	my $prefkey  = shift; 

	my $prefvalue = $self->{apps}->{$appid}->{$prefkey};

	return $prefvalue;
}

#------------------------------------------------------------
#  setGlobalPref($prefkey,$prefvalue)
#
#     Sets the value of the preference whose key is $prefkey
#     to $prefvalue.
#------------------------------------------------------------

sub setGlobalPref
{
	my $self      = shift;
	my $prefkey   = shift; 
	my $prefvalue = shift; 

	SW->user->{_dirty} = 1;
	$self->{global}->{$prefkey} = $prefvalue;

	return $prefvalue;
}

#------------------------------------------------------------
#  setUserPref($prefkey,$prefvalue)
#
#     Sets the value of the preference whose key is $prefkey
#     to $prefvalue
#------------------------------------------------------------

sub setUserPref
{
	my $self      = shift;
	my $prefkey   = shift; 
	my $prefvalue = shift; 

	SW->user->{_dirty} = 1;
	$self->{user}->{$prefkey} = $prefvalue;
	return $prefvalue;
}

#------------------------------------------------------------
#  setAppPref($appid,$prefkey,$prefvalue)
#
#     Gets the value of the preference whose key is $prefkey
#------------------------------------------------------------

sub setAppPref
{
	my $self      = shift;
	my $appid     = shift;
	my $prefkey   = shift; 
	my $prefvalue = shift; 

	SW->user->{_dirty} = 1;
	$self->{apps}->{$appid}->{$prefkey} = $prefvalue;

	return $prefvalue;
}


1;

__END__

=head1 NAME

SW::Preferences - A module to set/retrieve preferences in SW objects (apps & users)

=head1 SYNOPSIS

    Never called directly.  Rather, in Master, User and App items, call setPref and getPref
    which act as wrappers for calling the appropriate function appropriately.

=head1 DESCRIPTION

    Simple module to create a preferences hash within an object, then set/get preferences from it.

=head1 METHODS

    new(%prefs) :  Sets up a hash of preference values.   Will initialize a new hash if nothing passed.
    Expects a hash in the following format:  hash{ 'global' => {}, 'user' => {}, 'apps' => {}}

    getUserPref($prefkey)
    setUserPref($prefkey,$prefvalue)

    getGlobalPref($prefkey)
    setGlobalPref($prefkey,$prefvalue)

    getAppPref($appid,$prefkey)
    setAppPref($appid,$prefkey,$prefvalue)

=head1 PARAMETERS

    %prefs     : a hash of preference values
    $prefkey   : a key value for the preference hash table
    $prefvalue : a preference value
    $appid     : the AppID value of the app for which the pref will be changed

=head1 AUTHOR

John F. Zmrotchek
HBE	zed@hbe.ca
September 9, 1999 (And nothing crashed here!)

=head1 REVISION HISTORY

  $Log: Pref.pm,v $
  Revision 1.4  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.3  1999/09/22 07:44:11  fhurtubi
  Added _dirty = 1 to the self object so that user prefs are stored

  Revision 1.2  1999/09/20 18:33:33  fhurtubi
  Changed package name :)

  Revision 1.1  1999/09/20 18:26:31  gozer
  More modularization of the User object, added Pref in there

  Revision 1.7  1999/09/20 02:03:45  jzmrotchek
  Yes Fred, it does break something.   I changed it back;  my tests show it working.
  (There are other weirdnesses, but that's another story that has nothing to do with
  this particular module)

  As usual, comments, breakage reports, etc... >> me

  Revision 1.6  1999/09/19 07:01:14  fhurtubi
  This is what used to be there
         $self->{apps}->{$appid}->{$prefkey} = $prefvalue;
  This is what is there now
         $self->{$appid}->{$prefkey} = $prefvalue;

  Since it's working on my server, i wonder if this was corrected by John or
  Scott in my version since I don't recall touching that!

  Revision 1.5  1999/09/12 01:31:21  scott
  Fixed a problem where we were blessing nothingness :-)

  Revision 1.4  1999/09/11 22:40:43  jzmrotchek
  Bug fix.

  Revision 1.3  1999/09/11 21:59:06  jzmrotchek
  Added some perldoc.

  Revision 1.2  1999/09/11 21:41:25  jzmrotchek
  New version, new philosophy;  this module isn't called directly.  Rather, it's a collection of methods for dealing with various preference classes.   getPref or setPref called from the context of either a User, Master or Application object will get/set the preferences for that object through transparent calls to the Preferences methods.   The User object will actully do the work of saving/loading the preferences.

  Revision 1.1  1999/09/10 00:39:54  jzmrotchek
  First version of SW::Preferences.  A pretty simple module, really, more to set a constant interface across all preference useage, but simple and functional.  Note that it only attaches preferences to an existing object, such as a user or an app.  It doesn't yet support a 'global' preference set.  Perhaps SW::Master could instantiate a new Preferences object for itself?  Or do we need a SW::Global object?


=head1 SEE ALSO

perl(1).

=cut









