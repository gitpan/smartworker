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

package SW::Session::DBI;

#------------------------------------------------------------
# SW::Session::DBI
# Handles session tracking across transactions entirely
# transparently to the programmer by using database storage
#------------------------------------------------------------
# $Id: DBI.pm,v 1.9 1999/11/16 17:07:07 scott Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);
use Apache::Session;
use Apache::Session::NullLocker;
use SW::Session::DBIStore;

@ISA = qw(Apache::Session);

$VERSION = '0.01';

# extra stuff to add a read-only characteristic to the session

sub READONLY	()	{16};

sub is_readonly	{ $_[0]->{status} & READONLY }
sub make_readonly	{ 
	 $_[0]->{status} |= READONLY;
	 print STDERR "This copy of Session is now READ-ONLY!\n";
}
sub make_unreadonly   { $_[0]->{status} &= ($_[0]->{status} ^ READONLY) }

sub TIEHASH {
    my $class = shift;

	 my $self = $class->SUPER::TIEHASH(@_);

	 $self->make_readonly() if $self->{args}->{readonly};

	return $self;
}

sub save {
	my $self = shift;
	
	if ($self->is_readonly())
	{
		$self->make_unmodified();
		return;
	}
	
	return $self->SUPER::save(@_);
}

# Preloaded methods go here.
sub get_object_store {
	 return new SW::Session::DBIStore $_[0];
}

sub get_lock_manager {
    return new Apache::Session::NullLocker $_[0];
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

  $Log: DBI.pm,v $
  Revision 1.9  1999/11/16 17:07:07  scott
  added code so that you can make a session read-only

  Revision 1.8  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.7  1999/09/24 22:04:27  gozer
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
