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

package SW::User::Admin;

#------------------------------------------------------------
# SW::User::Admin
# Represents the Admin class.
#------------------------------------------------------------
# $Id: Admin.pm,v 1.4 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);
use SW::User::Manager;


@ISA = qw(SW::User::Manager);

$VERSION = '0.01';


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::User::Admin - SmartWorker class for an administrator

=head1 SYNOPSIS

  use SW::User::Admin;

=head1 DESCRIPTION

This class represents a system administrator. It is derived from the
User class and is instantiated by creating an instance of a User class
and blessing it to be an administrator.

=head1 AUTHOR

Kyle Dawkins, kyle@hbe.ca

=head1 SEE ALSO

perl(1).

=cut
