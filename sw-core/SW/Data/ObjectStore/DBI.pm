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

package SW::Data::ObjectStore::DBI;

#------------------------------------------------------------
# SW::Data::ObjectStore::DBI
# Handles session tracking across transactions entirely
# transparently to the programmer by using database storage
#
# Based on SW::Session::DBI
#------------------------------------------------------------
# $Id: DBI.pm,v 1.3 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);
use SW;
use SW::DB;
use SW::Data::ObjectStore;
use Apache::Session::NullLocker;
use SW::Data::DBIStore;

@ISA = qw(SW::Data::ObjectStore);

#
#  because we use the $args = {}  style of parameter passing, no changes are required 
#	 to the SW::Data::Storage module.  These are the arguments that should be passed to new:
#
#	#  args:  { table => "db_table_name", 'fieldnames' => (), 'protected' => (), 'writeonce' => (),
#           pkey => "primary_key",  dbh => 'database handle' }
#

$VERSION = '0.01';

# Preloaded methods go here.

sub get_object_store {
    my $self = shift;

    return new SW::Data::DBIStore($self);
}

sub get_lock_manager {
    my $self = shift;

    return new Apache::Session::NullLocker $self;
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
  Revision 1.3  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.2  1999/09/20 14:30:48  krapht
  Changes to use the new method of getting session, user, etc.

  Revision 1.1  1999/07/25 02:25:02  scott
  New addition - simple inheritance on SW::Data::ObjectStore,
  installs the object_store module and the locking module


=head1 SEE ALSO

SW::Application, SW::Data, SW::Session, SW::Session::DBI perl(1).

=cut
