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

package SW::Data::ObjectStore;

#------------------------------------------------------------
#  SW::Data::ObjectStore
#------------------------------------------------------------
#
#    for now this is almsot the same as Apache::Session 
#		but with the locker and storage modules
#		linked in from here rather than from another,
#		so this modules get's tied directly
#
#------------------------------------------------------------
#  $Id: ObjectStore.pm,v 1.9 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------
use strict;
use vars qw($VERSION);
use SW;

$VERSION = '0.1';

#State constants
#
#These constants are used in a bitmask to store the
#object's status.  New indicates that the object 
#has not yet been inserted into the object store.
#Modified indicates that a member value has been
#changed.  Deleted is set when delete() is called.
#Synced indicates that an object has been materialized
#from the datastore.

sub NEW      () {1};
sub MODIFIED () {2};
sub DELETED  () {4};
sub SYNCED   () {8};

#State methods
#
#These methods tweak the state constants.

sub is_new          { $_[0]->{status} & NEW }
sub is_modified     { $_[0]->{status} & MODIFIED }
sub is_deleted      { $_[0]->{status} & DELETED }
sub is_synced       { $_[0]->{status} & SYNCED }

sub make_new        { $_[0]->{status} |= NEW }
sub make_modified   { $_[0]->{status} |= MODIFIED }
sub make_deleted    { $_[0]->{status} |= DELETED }
sub make_synced     { $_[0]->{status} |= SYNCED }

sub make_old        { $_[0]->{status} &= ($_[0]->{status} ^ NEW) }
sub make_unmodified { $_[0]->{status} &= ($_[0]->{status} ^ MODIFIED) }
sub make_undeleted  { $_[0]->{status} &= ($_[0]->{status} ^ DELETED) }
sub make_unsynced   { $_[0]->{status} &= ($_[0]->{status} ^ SYNCED) }

#Tie methods
#
#Here we are hiding our complex data persistence framework behind
#a simple hash.  See the perltie manpage.
#
#  args:  { table => "db_table_name", 'fieldnames' => (), 'protected' => (), 'writeonce' => (),
#				pkey => "primary_key",  dbh => 'database handle' }
#
#  add some code later to retrieve the field list from the table .... for now we'll pass it in

sub TIEHASH {
    my $class = shift;
    
    my $object_id = shift;
    my $args       = shift || {};



    #Make sure that the arguments to tie make sense
        
    $class->validate_id($object_id);
    
    if(ref $args ne "HASH") {
        SW::debug($class,"Additional arguments should be in the form of a hash reference",3);
    }

    #Set-up the data structure and make it an object
    #of our class
    
    my $self = {
        args         => $args,
	 	  pkey			=> $args->{pkey},
        data         => { },
		  id				=> $object_id,
        protected    => $args->{protected},
        lock         => 0,
        lock_manager => undef,
        object_store => undef,
        status       => 0,
    };
    
    bless $self, $class;

    #If a session ID was passed in, this is an old hash.
    #If not, it is a fresh one.

    if (defined $object_id) {
        $self->make_old;
        $self->restore;
    }
    else {
        $self->make_new;
#        $self->{data}->{_object_id} = $class->generate_id();
        $self->save;
    }
    
    return $self;
}

sub FETCH {
    my $self = shift;
    my $key  = shift;
        
    return $self->{data}->{$key};
}

sub STORE {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

	SW::debug($self,"objectstore got STORE $key $value",5);
    
    if (! $self->protected($key))
    {
    
    	$self->{data}->{$key} = $value;
  
    	$self->make_modified;
    
    	return $self->{data}->{$key};
    }

    return undef;
}

sub DELETE {
    my $self = shift;
    my $key  = shift;
    
    $self->make_modified;
    
    delete $self->{data}->{$key};
}

sub CLEAR {
    my $self = shift;

    $self->make_modified;
    
    $self->{data} = { $self->{pkey} => $self->{data}->{$self->{pkey}} };
}

sub EXISTS {
    my $self = shift;
    my $key  = shift;
    
    return exists $self->{data}->{$key};
}

sub FIRSTKEY {
    my $self = shift;
    
    my $reset = keys %{$self->{data}};
    return each %{$self->{data}};
}

sub NEXTKEY {
    my $self = shift;
    
    return each %{$self->{data}};
}

sub DESTROY {
    my $self = shift;
 
	 SW::debug($self,"object DESTROY ",5);
	 print STDERR "object DESTROY \n";
 
    $self->save;
    $self->release_all_locks;
}





#Persistence methods
#


sub restore {
    my $self = shift;
    
    return if $self->is_synced;
    return if $self->is_new;
    
    $self->acquire_read_lock;

    if (!defined $self->{object_store}) {
        $self->{object_store} = $self->get_object_store;
    }
    
    $self->{object_store}->materialize($self);
    
    $self->make_unmodified;
    $self->make_synced;
}

sub save {
    my $self = shift;
    
    return unless ($self->is_modified || $self->is_new || $self->is_deleted);

    $self->acquire_write_lock;
    
    if (!defined $self->{object_store}) {
        $self->{object_store} = $self->get_object_store;
    }
    
    if ($self->is_deleted) {
        $self->{object_store}->remove($self);
        $self->make_synced;
        $self->make_unmodified;
        $self->make_undeleted;
        return;
    }
    if ($self->is_modified) {
        $self->{object_store}->update($self);
        $self->make_unmodified;
        $self->make_synced;
        return;
    }
    if ($self->is_new) {
        $self->{object_store}->insert($self);
        $self->make_old;
        $self->make_synced;
        $self->make_unmodified;
        return;
    }
}

sub delete {
    my $self = shift;
    
    return if $self->is_new;
    
    $self->make_deleted;
    $self->save;
}    


#------------------------------------------------------------
# setProtectedValue
#
#  this is the equivalent of STORE but for the protected values
#	we'll eventually want to add more checking in here for
#	whether or not we allow writing of these values
#------------------------------------------------------------

sub setProtectedValue
{
	my $self = shift;
	my $key = shift;
	my $value = shift;

	print STDERR "Got set protectedvalue for $key = $value\n";	

	$self->{data}->{$key} = $value;

	$self->make_modified;
 
	return $self->{data}->{$key};
}

#
#Locking methods
#

sub READ_LOCK  () {1};
sub WRITE_LOCK () {2};

sub has_read_lock    { $_[0]->{lock} & READ_LOCK }
sub has_write_lock   { $_[0]->{lock} & WRITE_LOCK }

sub set_read_lock    { $_[0]->{lock} |= READ_LOCK }
sub set_write_lock   { $_[0]->{lock} |= WRITE_LOCK }

sub unset_read_lock  { $_[0]->{lock} &= ($_[0]->{lock} ^ READ_LOCK) }
sub unset_write_lock { $_[0]->{lock} &= ($_[0]->{lock} ^ WRITE_LOCK) }

sub acquire_read_lock  {
    my $self = shift;

    return if $self->has_read_lock;

    if (!defined $self->{lock_manager}) {
        $self->{lock_manager} = $self->get_lock_manager;
    }

    $self->{lock_manager}->acquire_read_lock($self);

    $self->set_read_lock;
}

sub acquire_write_lock {
    my $self = shift;

    return if $self->has_write_lock;

    if (!defined $self->{lock_manager}) {
        $self->{lock_manager} = $self->get_lock_manager;
    }

    $self->{lock_manager}->acquire_write_lock($self);

    $self->set_write_lock;
}

sub release_read_lock {
    my $self = shift;

    return unless $self->has_read_lock;

    if (!defined $self->{lock_manager}) {
        $self->{lock_manager} = $self->get_lock_manager;
    }

    $self->{lock_manager}->release_read_lock($self);

    $self->unset_read_lock;
}

sub release_write_lock {
    my $self = shift;

    return unless $self->has_write_lock;

    if (!defined $self->{lock_manager}) {
        $self->{lock_manager} = $self->get_lock_manager;
    }

    $self->{lock_manager}->release_write_lock($self);
    
    $self->unset_write_lock;
}

sub release_all_locks {
    my $self = shift;
    
    return unless ($self->has_read_lock || $self->has_write_lock);
    
    if (!defined $self->{lock_manager}) {
        $self->{lock_manager} = $self->get_lock_manager;
    }

    $self->{lock_manager}->release_all_locks($self);

    $self->unset_read_lock;
    $self->unset_write_lock;
}        



#
#Utility methods
#

#------------------------------------------------------------
# protected
#
#	checks the input value to see if it corresponds
#	to one of the values in the list of protected 
#	fields.
#
#	returns undef if unprotected, 1 otherwise
#
#	a faster way to implement this would be to make the 
#	protected fields keys in a hash and check defined on them.
#------------------------------------------------------------

sub protected
{
	my ($self, $key) = shift;
	
	foreach my $field (@{$self->{protected}})
	{
		return 1 unless $field ne $key;
	}
	return undef;
}


#------------------------------------------------------------
# getInsertId
#------------------------------------------------------------

sub getInsertId
{  
   my $self = shift;
   my $sth = shift;
   
   return $sth->{mysql_insertid};
}



sub generate_id {
    return substr(MD5->hexhash(time(). {}. rand(). $$. 'blah'), 0, 16);
}

sub validate_id {
#    if(defined $_[1] && $_[1] =~ /[^a-f0-9]/) {
#        die "Garbled session id";
#    }
}

1;

__END__

=head1 NAME

SW::Data::ObjectStore - implementation of the tied hash to keep track of
								object synchronization between the hash and the database

=head1 SYNOPSIS

	in SW::Data

	tie $self->{storage}, 'SW::Data::ObjectStore::DBI', { some args }

=head1 DESCRIPTION

   This code is almost entirely Apache::Session!!

=head1 METHODS

	TIEHASH -
	FETCH -
	STORE -
	DELETE -
	CLEAR -
	NEXT -
	KEYS -
	DESTROY -

	save -
	restore -

=head1 PARAMETERS	

	protected - an array of fieldnames corresponding to columns in the db table, but
			protected such that the only way to change these values is using
			the accessors.


=head1 AUTHOR

Jeffrey Baker

modifications by:

Scott Wilson
HBE   scott@hbe.ca
Jul 22/1999

=head1 REVISION HISTORY

  $Log: ObjectStore.pm,v $
  Revision 1.9  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.8  1999/09/11 07:07:40  scott
  Made substantial changes to the database schema and data storage models.
  Now there's three global tables called datamap, dataaccess, and
  datainfo.  These hide the many other more data specific tables
  where the infomation is actually stored.

  Revision 1.7  1999/09/07 15:51:18  gozer
  Pod syntax error fixed

  Revision 1.6  1999/09/01 01:26:48  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.5  1999/08/13 14:32:52  scott
  Bug fixes on database access, and getting ContactManager working

  Revision 1.4  1999/08/12 19:44:02  scott
  Fixed a dumb bug in protected() that was stopping data from being written in the db

  Revision 1.3  1999/08/11 15:27:04  scott
  Small bug fixes on the code I wrote last night

  Revision 1.2  1999/08/11 05:54:23  scott
  In conjunction with changes to SW::Data, added an initialization
  (TIEHASH) parameter that provides a list of protected fields.
  These fields still exist as keys in the tied hash, but can only
  by written using special accessor functions ( which I just realized
  I forgot to write - oops! I'll do that in the morning)  The standard
  set of protecdted fields will include creator, type, PRIMARY_KEY, appid,
  name etc...

  The new accessor methods work sometihng like:

  tied ($self->{storage}) -> setProtectedValue('key',$value);

  Revision 1.1  1999/07/25 02:31:43  scott
  New addition - this object is essentially Apache::Session generalized a bit
  more.  It is an abstract super class to SW::Data::ObjectStore::DBI, which
  gets tied to the {storage} hash in SW::Data.


=head1 SEE ALSO

Apache::Session, SW::Data, perl(1).

=cut


