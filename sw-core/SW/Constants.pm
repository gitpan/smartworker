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

package SW::Constants;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::Constants
#  Description of my module
#------------------------------------------------------------
# $Id: Constants.pm,v 1.11 1999/11/15 18:17:32 gozer Exp $
#------------------------------------------------------------


use strict;
use vars qw(@ISA @SW_EXPORT);

use SW::Exporter;

use SW::Constants::Colours;


@ISA = qw(SW::Exporter);

# Stuff to export

@SW_EXPORT = qw(
%PERMS READABLE WRITABLE WRITEABLE STICKY HIDDEN SYSTEM
GROUP_ALL ALL GROUP_GUEST GUEST
BOLD ITAL UL STRIKE CENTER
NOVALUE DEFAULT
);

sub READABLE()	{ 0x01 };
sub WRITABLE()	{ 0x02 };
sub WRITEABLE()	{ 0x02 };
sub STICKY()	{ 0x04 };
sub HIDDEN()	{ 0x08 };
sub SYSTEM()	{ 0x10 };

%SW::Constants::PERMS = (
							0x01 => 'READABLE',
							0x02 => 'WRITEABLE',
							0x04 => 'STICKY',
							0x08 => 'HIDDEN',
							0x10 => 'SYSTEM',
						);

sub GROUP_ALL() { 2 };     # all registered users
sub ALL() { 2 };     # all registered users
sub GROUP_GUEST() { 1 };  # absolutely everyone
sub GUEST() { 1 };  # absolutely everyone



#-------------------------------------------------------
# BOLD, ITAL, UL
#
# Used as a mask for text attributes
#-------------------------------------------------------
 
sub BOLD() { 0x01 }
sub ITAL() { 0x02 }
sub UL() { 0x04 }
sub STRIKE() { 0x08 }
sub CENTER() { 0x10 }

#-------------------------------------------------------
# NOVALUE - corresponds to an HTML tag which is just there (no ="")
# DEFAULT - corresponds to a HTML tag which is not there
#-------------------------------------------------------

# relies on the HTML codes not containing this
# not so klugy, could've been worse
sub NOVALUE () { "\001\001\001" }
sub DEFAULT () { "\002\002\002" }


1;
__END__

