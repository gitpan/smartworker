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

package SW;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW
#  A core module to include some highly available 
#	 status, logging and debugging stuff
#------------------------------------------------------------
#  CVS ID tag...
# $Id: SW.pm,v 1.17 1999/11/14 02:22:03 gozer Exp $
#------------------------------------------------------------

use strict;

use vars qw($VERSION %GLOBALS %global_ok $current_master $current_session $current_data $current_user $current_cookie);

use SW::Server::Debug;


%global_ok = ( 
				'cookie'	=> 'SW::Handler',
				'data'		=> 'SW::Handler',
				'session'	=> 'SW::Handler',
				'user'		=> 'SW::Handler',	
				'master'	=> 'SW::Handler',
			);

$VERSION = '0.9';

#------------------------------------------------------------
#  package variables
#------------------------------------------------------------

@SW::Log = ();
@SW::Debug = ();

sub dumpDebug
{
	if (@_ == 0)	# basically purge Debug
	{
		while (shift @SW::Debug)
		{ 
		}
		return 1;
	}

	my $types = shift;
	my $level = shift;

	while (my $st = shift @SW::Debug)
	{
		$st =~ /^(.+):-:(.+):-:(.+):-:(.+)$/;
		if ($1 <= $level)
		{
			foreach my $t (@$types)
			{
#				print STDERR "\$3 $3 ? $t\n";
				if ((lc($3) eq lc($t)) || ($t eq "ALL"))
				{
					print STDERR "$3 - $4\n";
				}
			}
		}
	}
	return 1;
}



#------------------------------------------------------------
#  debug - basicaly refers it over to Server::Debug
#				with a reference to the log array kept here
#------------------------------------------------------------
sub debug
{
	my ($callingClass,$msg,$priority) = @_;
   my $caller;

	if(!$priority)
	{
		$priority = 5;
	}

	if(!$msg)
	{
		$msg = $callingClass;
		$callingClass = "??";
	}

	$caller = ref($callingClass) || $callingClass;

	my $string = $priority.':-:'.time.':-:'.$caller.':-:'."$msg";
	push @SW::Debug, $string;

	SW::Server::Debug::postDebugMessage($caller, $msg, $priority);

	return 1;
}

#------------------------------------------------------------
# log
# Takes caller, message, and priority (optional)
#
# eventually pass this to Server::Log  ??
#
#------------------------------------------------------------

sub log  
{
   my $callingClass = shift;
   my $msg = shift;
   my $priority = shift;
   my $caller;

   if ($callingClass->can("getValue"))
   {
      $caller = $callingClass->getValue('name')."(".ref($callingClass).")";
   }
   else
   {
      $caller = ref($callingClass);
   }

   my $str = $priority.'::'.time.'::'.$caller.'::'."$msg";
   push @SW::Log, $str;

	return 1;
}	

#------------------------------------------------------------
# request
#
# returns the Apache request object of the current request.  	
#------------------------------------------------------------

sub request
{
	return Apache->request;
}


#------------------------------------------------------------
# pushControl - push another app onto the stack
#------------------------------------------------------------

sub pushControl
{
	my $self = shift;
	SW->session->stackPush(@_);
}

#------------------------------------------------------------
# passControl - push another app onto the stack
#------------------------------------------------------------

sub passControl
{
	my $self = shift;
	SW->session->stackPass(@_);
}

#------------------------------------------------------------
# returnControl - push another app onto the stack
#------------------------------------------------------------

sub returnControl
{
	my $self = shift;
	SW->session->stackPop(@_);
}


#------------------------------------------------------------
# error string handling
#------------------------------------------------------------

sub errstr
{
	return SW->master->{_errstr};
}

sub errcode 
{
	return SW->master->{_errcode};
}

sub set_errcode
{
	my ($code, $str) = @_;
	SW->master->{_errcode} = $code;
	eval ("{ \$str |= caller()->ERROR_STRINGS->{$code} }");
	$str |= "$code - Unknown error";
	SW->master->{_errstr} = $str;
	return $code;
} 


#handle everyt global access now
sub SW::AUTOLOAD {
	my $self = shift;
	my $method = $SW::AUTOLOAD;
	
	$method =~ s/.*:://;
	return unless $method =~ /[^A-Z]/;

	if($method =~ /^set(.*)$/)
		{
		my $key = lc $1;

		if((not exists $SW::global_ok{$key}) || ($SW::global_ok{$key} eq caller))
			{
			if (defined $GLOBALS{$key})
				{
				print STDERR "Can't create a $key object twice in the same process!!!\n";
				return undef;
				}
			else
				{
				return $GLOBALS{$key} = shift;
				}
			}
		else
			{
			print STDERR "SW->$method called by someone else than $global_ok{$key}, namely(". caller() . ")\n";
			return undef;
			}
		
		}
	elsif ($method =~ /^destroy(.*)$/)
		{
		my $key = lc $1;
		if((not exists $SW::global_ok{$key}) || ($SW::global_ok{$key} eq caller))
			{
			if (defined $GLOBALS{$key})
				{
				print STDERR "Destroying " . uc $key . "\n";
				return delete $GLOBALS{$key};
				}
			else
				{
				print STDERR "Can't delete an undef $key object!!!\n";
				return undef;
				}
			}
		else
			{
			print STDERR "SW->$method called by someone else than $global_ok{$key}, namely(". caller() . ")\n";
			return undef;
			}
		}
	else 
		{
		my $key = lc $method;
		if (exists $GLOBALS{$key})
			{
			return $GLOBALS{$key};
			}
		else
			{
			#print STDERR "SW->$method ?? What are you trying to get ? (" , (join " ", caller) , ")\n";
			return undef;
			}
		}
	
print STDERR "SW couldn't handle SW->$method correctly\n";
return undef;
}


1;

__END__

=head1 NAME

SW -  Request status logging interface, constant definitions... 

=head1 SYNOPSIS

use SW;

...

SW::debug($self, "This is what happened...", $level);
-or-
SW::debug("An identifying name", "msg", $level);


=head1 DESCRIPTION

	This module contains static methods to call debug and log functions,
	called as above in the synopsis.  
	
	Debugging levels will run from 1 to 5 with 1 being sparse and 5 being 
	verbose.  Therefore a message tagged priority 1 will appear in all levels
	(except 0 obviously) while a message tagged 5 will only appear in 
	level 5.


=head1 METHODS

  log - ($caller, message, [priority])
  debug - ($caller, message, [priority])

=head1 PARAMETERS

=head1 AUTHOR

Scott Wilson
HBE	scott@hbe.ca
June 17/99

=head1 REVISION HISTORY

  $Log: SW.pm,v $
  Revision 1.17  1999/11/14 02:22:03  gozer
  Removed an annoying warning

  Revision 1.16  1999/11/11 07:12:32  gozer
  Removed all the setThing destroyThing and replaced all global access with one AUTOLOAD routine,
  because I was tired of adding 3 function stub each time we needed a new constant

  Revision 1.15  1999/10/23 04:38:13  gozer
  Errors are handled still a bit better

  Revision 1.14  1999/10/18 05:41:11  scott
  adding file locking code

  Revision 1.13  1999/10/04 21:04:27  gozer
  lots of small diffs...
  Fixed Handler to be more Apache::Filter nice ... (still the non-existent file problem)
  Now you can access SW::Config stuff anytime (even at start-up use)
  MOdularized some more the SW::User class
  Small minor code fixes all over the place

  Revision 1.12  1999/10/02 23:38:25  krapht
  Fixed a line in setSession because it's now called from Handler

  Revision 1.11  1999/09/30 11:38:50  gozer
  Added the support for cookies

  Revision 1.10  1999/09/28 15:02:54  scott
  don't remember :-(

  Revision 1.9  1999/09/22 01:45:39  scott
  added setNEwUser for creating users

  Revision 1.8  1999/09/20 20:42:23  krapht
  It works!!  It works!!  We fixed the problem we had with session.

  Revision 1.7  1999/09/19 20:34:42  gozer
  Documented SW.pm and I changed a few more $self->{master} stuff to SW->master

  Revision 1.6  1999/09/17 21:43:04  gozer
  Removed some DEBUGing messages

  Revision 1.4  1999/09/14 01:29:20  gozer
  added SW->request for the current apache request record

  Revision 1.2  1999/09/03 02:04:44  scott
  set the version number

  Revision 1.1  1999/09/02 17:28:05  gozer
  moved it where it belongs

  Revision 1.5  1999/07/19 13:29:19  scott
  Lots of clean-up work, debugged and improved the desctructor calling of all
  copmonents so none should be left lingering after the transaction completes.

  This in turn solved the session problem (destructor wasn't being called
  because it was persisting past the end of the transaction)

  Revision 1.4  1999/07/08 15:51:34  krapht
  It seems DNS comments are getting on Scott's mind :), changed ; for #

  Revision 1.3  1999/07/08 15:49:05  scott
  commented out Server::Debug

  Revision 1.2  1999/07/08 15:45:27  scott
  oops - should have done these separately ...

  Working on changes to the database code for users, groups, and objects

  as well as debugging and signals

  Revision 1.1  1999/06/18 15:23:49  scott
  First addition of this file, some package global holders and functions
  for debugging


=head1 SEE ALSO

perl(1).

=cut
