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

package SW::Session::DBIStore;

#------------------------------------------------------------
# SW::Session::DBIStore
# 
# Redefines one small function of DBIStore so we can pass it a 
# database handle instead of a host, username, password, etc.
# for security reasons...
#------------------------------------------------------------
# $Id: DBIStore.pm,v 1.2 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);
use Apache::Session::DBIStore;

@ISA = qw(Apache::Session::DBIStore);

$VERSION = '0.01';

# Preloaded methods go here.

sub connection {
    shift->{dbh} ||= SW::DB::getDbh();
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::Session::DBI - SmartWorker Session handler using database

=head1 SYNOPSIS

  use SW::Session::DBI;

  $self->{_storage} = new SW::Session::DBI($cookie);

=head1 DESCRIPTION

This is loaded transparently by the SW::Session object

June 14/99 For now I'm implementing a get user info functions that will only the the values
be read out once.  Eventually I need to go into apache::session and prevent the swa from being read at all in the read / write method.

=head1 AUTHOR

	Scott Wilson	scott@hbe.ca
	May 4/1999

=head1 REVISION HISTORY

  $Log: DBIStore.pm,v $
  Revision 1.2  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.1  1999/09/24 22:04:27  gozer
  Modified DB access to hide username/password

  Revision 1.6  1999/09/17 21:18:17  gozer
  This is a major modification on the whole SW structure
  New methods in SW:
  SW->master	: returns the current Master o bject
  SW->session	: returns the current session object
  SW->user	: returns the current user
  SW->data	: returns the current URL/URI parsed data (getDataValue, setDataValue) but it's incomplete for now

  Now, no object needs to get a hold on any of those structures, they can access them thru the global methods instead.  Thus fixing a lot of problems with circular dependencies.

  Completed the User class with User::Authen for authentication User::Authz for authorization and User::Group for group membership.

  I modified quite many files to use the new SW-> methods instead of holding on them.  Still some cleaning up to do

  Tonight, I debug this change and tommorrow I'll document everything in details.

  SW::Session now has 2 accesses  set/get/delGlobalValues and set/get/delPrivateValues for private(per application class) and global.

  Revision 1.5  1999/09/13 22:59:16  scott
  added the make_reaonly so we can stop sessions from getting saved out

  Revision 1.4  1999/08/30 20:28:48  krapht
  Removed some useless comments about Exporter

  Revision 1.3  1999/07/08 15:45:44  scott
  Trying to add some security - doesn't work yet ...

  Revision 1.2  1999/06/18 15:28:28  scott
  Working on a way to only release user authentication info one over
  the course of a session

  Revision 1.1  1999/05/04 15:53:59  scott
  -New Apache::Session based database session tracking


=head1 SEE ALSO

SW::Application, SW::Session, perl(1).

=cut
