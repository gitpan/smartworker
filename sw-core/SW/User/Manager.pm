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

package SW::User::Manager;

#------------------------------------------------------------
# SW::User::Manager
# Represents the Manager class.
#------------------------------------------------------------
# $Id: Manager.pm,v 1.5 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::User;


@ISA = qw(SW::User);

$VERSION = '0.01';


1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::User::Manager - SmartWorker class for a group manager

=head1 SYNOPSIS

  use SW::User::Manager;

=head1 DESCRIPTION

This class represents a group manager. It is derived from the
User class and is instantiated by creating an instance of a User class
and blessing it to be a manager.

=head1 AUTHOR

Kyle Dawkins, kyle@hbe.ca

=head1 SEE ALSO

perl(1).

=cut
