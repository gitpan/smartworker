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

#--------------------------------------------------
#
#  SW::Data::DBIStore
#
#--------------------------------------------------
#  Eventually we'll build some protection of fields in here, so users can't
#		set system ones etc...
#
# note that this modules just blindly makes calls to the DB
#  it is the responsability of SW::Data::ObjectStore and SW::Data with
#		its descendants to pass in the 
#	fields it wants to have operated on.

#-------------------------------------------------------------------------
#	$Id: DBIStore.pm,v 1.33 1999/11/15 18:17:33 gozer Exp $
#----------------------------------------------------------------------

package SW::Data::DBIStore;

use strict;

use DBI;
use SW;
use SW::DB;
use SW::Util qw(intersection a_not_in_b);
use SW::Constants;
use vars qw(@INFO_FIELDS);

@INFO_FIELDS = qw(creator name type appid);
sub PKEY () {'id'};
sub DATAKEY () {'dataid'};


#------------------------------------------------------------
# new
#------------------------------------------------------------

sub new
{
	my $class = shift;
	my $object = shift;
	my $id = $object->{id};
	my $dbh = $object->{args}->{dbh};
	my $table = $object->{args}->{table};
	my $access = $object->{args}->{access_table};
	my $map = $object->{args}->{map_table};
	my $info = $object->{args}->{info_table};
	my $user = $object->{args}->{user};
	my $type = $object->{args}->{datatype};
	my $creator = $object->{args}->{creator};

	my $self = { 
				'id' => $id,
				'dbh' => $dbh,
				'data_table' => $table,
				'map_table' => $map,
				'access_table' => $access,
				'info_table' => $info,
				'pkey' => PKEY,
				'datakey' => DATAKEY,
				'user' => $user,
				'datatype' => $type,
				'creator' => $creator,
				 evalFields => $object->{args}->{evalFields},
	};

	SW::debug($self,"new dbistore with id $id",5);

   return bless($self, $class);
}


#------------------------------------------------------------
# insert - method
#
#
#------------------------------------------------------------

sub insert
{
	my ($self,$object) = @_;
	my $data = $object->{data};
	my $dbh = $self->{dbh};

	# insert into the data table

	my $query = "insert into  ".$self->{data_table}.qq/ (id) values (NULL)/;

	SW::debug($self,"insert query $query",5);
	
	 my $sth = $dbh->prepare($query) ||
			SW::debug($self,"insert, Error preparing query - $query\n\t".$dbh->errstr,3);

	$sth->execute ||
			SW::debug($self,"insert, Error executing query - $query\n\t".$dbh->errstr,3); 

	$self->{'dataid'} =  $sth->{'mysql_insertid'};

	# insert into the map table      id | class | dataid

	$query = "insert into ".$self->{map_table}.qq/ 
		(id, dataclass, dataid) values (NULL,\'/.$self->{datatype}.qq/\', $self->{dataid} )/;

	SW::debug($self,"insert query $query",5);

	$sth = $dbh->prepare($query) ||
			SW::debug($self,"insert, Error preparing query - $query\n\t".$dbh->errstr,3);

	 $sth->execute ||
			SW::debug($self,"insert, Error executing query - $query\n\t".$dbh->errstr,3); 

	$self->{id} = $sth->{'mysql_insertid'};
	$data->{id} = $self->{id};

	# insert into the info table   id | type | name | creator | appid

	$query = "insert into  ".$self->{info_table}.qq/ (id, creator) values ($self->{id}, $self->{creator} )/;

	SW::debug($self,"insert query $query",5);

	 $sth = $dbh->prepare($query) ||
			SW::debug($self,"insert, Error preparing query - $query\n\t".$dbh->errstr,3);

	 $sth->execute ||
			SW::debug($self,"insert, Error executing query - $query\n\t".$dbh->errstr,3); 

	# set up owner access record
	$self->addOwnerAccess();
}


#------------------------------------------------------------
# addOwnerAccess - method
#------------------------------------------------------------

sub addOwnerAccess
{
	my $self = shift;
	my $value = READABLE + WRITABLE;

	#	id | groupid | perm | owner | userid |
	my $query = "insert into ".$self->{access_table}."(id, userid, groupid, perm, owner)	values(";
	$query .= "$self->{id}, ".SW->user->getUserId.", NULL,$value, ".SW->user->getUserId;
	$query .= " )";

	my $sth = $self->{dbh}->prepare($query) ||
			SW::debug($self,"Error preparing query: $query",1);

	if ($sth->execute())
	{   
		SW::debug($self, "set owner access",5);
	}
	else
	{
		SW::debug($self,"error executing query $query - ".$self->{dbh}->errstr,1);
	}
}


#------------------------------------------------------------
# update - method
#------------------------------------------------------------

sub update
{
	my ($self,$object) = @_;
	my $data = $object->{data};
	my $id = $self->{PKEY()};
	my $dataid = $self->{DATAKEY()};
	my $dbh = $self->{dbh};
	
	# don't insert the timestamp so it gets updated automagically
	my @stop_list = qw( lastmodified id dataid);

	# first we'll ingore fields in the stop list
	my @keylist = keys %$data;
	my @templist;
	my $found = 0;

	foreach my $k (@keylist)
	{
		foreach my $l (@stop_list)
		{
			$found = 1 if $k eq $l;
		}
		unshift @templist, $k unless $found;
		$found = 0;
	}

	@keylist = @templist;

	return unless @keylist > 0;

	my @info_keylist = @{intersection(\@keylist, \@INFO_FIELDS)};
	my @data_keylist = @{a_not_in_b(\@keylist, \@INFO_FIELDS)};

	SW::debug($self,"data key list - ".SW::Util::flatten(\@data_keylist),5);

	# now we'll update the info table
	my $infoquery = "update $self->{info_table} set ";

	for (my $k=0; $k<@info_keylist; $k++)
	{
		$infoquery .= qq/ $info_keylist[$k]=/;

		if ($self->evalfield($info_keylist[$k])) 
		{ 
			$infoquery .= $dbh->quote(SW::Util::flatten($data->{$info_keylist[$k]}));
		}
		else
		{
	 		$infoquery .= $dbh->quote($data->{$info_keylist[$k]});
		}
		$infoquery .= ", " unless $k == $#info_keylist;
	}
	$infoquery .= " where ".PKEY()." = $id";

	my $dataquery = "update $self->{data_table} set ";

	for (my $k=0; $k<@data_keylist; $k++)
	{
		$dataquery .= qq/ $data_keylist[$k]=/;

		if ($self->evalfield($data_keylist[$k])) 
		{ 
			$dataquery .= $dbh->quote(SW::Util::flatten($data->{$data_keylist[$k]}));
		}
		else
		{
	 		$dataquery .= $dbh->quote($data->{$data_keylist[$k]});
		}

		$dataquery .= ", " unless $k == $#data_keylist;
	 }

	 $dataquery .= " where ".PKEY()." = $dataid";

	SW::debug($self,"update infoquery - $infoquery",5);
	SW::debug($self,"update dataquery - $dataquery",5);
	
	if (@info_keylist > 0)
	{
		my $info_sth = $dbh->prepare($infoquery) || 
				SW::debug($self,"update, Error preparing query - $infoquery\n\t".$dbh->errstr,1);
		$info_sth->execute ||
				SW::debug($self,"update, Error executing query - $infoquery\n\t".$dbh->errstr,1); 
	}

	if (@data_keylist > 0)
	{	
		my $data_sth = $dbh->prepare($dataquery) || 
				SW::debug($self,"update, Error preparing query - $dataquery\n\t".$dbh->errstr,3);
		$data_sth->execute ||
				SW::debug($self,"update, Error executing query - $dataquery\n\t".$dbh->errstr,3); 
	}

	SW::debug($self,"returning from update $id",5);
}


#------------------------------------------------------------
# materialize - method
#------------------------------------------------------------

sub materialize
{
   my ($self,$object) = @_;
	my $data = $object->{data};
	my $id = $self->{id};
	my $dbh = $self->{dbh};

	SW::debug($self,"Calling map resolver in materialize",5);

	my $info = $self->resolveMapping($id);

	if(!$info)
	{
		# If we can't get this information, there's certainly
		# a problem, so return undef

		print STDERR "####### Hmmmmmm, error in resolveMapping, couldn't get info\n";

		return undef;
	}

	$self->{'dataid'} = $info->{dataid};

	my $query = "select * from $self->{data_table} a, $self->{info_table} b where b.".PKEY()." = $id and a.".PKEY()." = ".$info->{dataid};
	my $sth = $dbh->prepare($query) || 
			SW::debug($self,"materialize, Error preparing query $query".$dbh->errstr,3);
	
	$sth->execute ||
			SW::debug($self,"materialize, Error executing query $query".$dbh->errstr,3);

	my $row = $sth->fetchrow_hashref;
	foreach my $k (keys %$row)
	{
		if ($self->evalfield($k))
		{
			 SW::debug($self,"about to eval $k -> ".$row->{$k},5);
			 $data->{$k} = eval ($row->{$k});
			# eval "+{this=>'that'}";
			 $data->{$k} = eval "+$row->{$k}";
			# This works, ask Randal Schwartz <merlyn@stonehenge.com> if you want to know why
		}
		else
		{
	 		 $data->{$k} = $row->{$k};
		}
	}
	$data->{id} = $id;
}


#------------------------------------------------------------
# resolveMapping - method
#
# The map resolver extracts information from the map table
# in the database.  For more information on how data is
# stored, see the SW-Backend-HOWTO.
#
# Returns a hash reference to the information, or undef if
# no information was found.
#------------------------------------------------------------


sub resolveMapping
{
	my ($self,$id) = @_;

	my $q = "select * from $self->{map_table} where ".PKEY()." = $id";

	SW::debug($self,"Resolver query $q",5);

	my $sth = $self->{dbh}->prepare($q) ||
			SW::debug($self, "error preparing query $q",1);

	$sth->execute() ||
			SW::debug($self, "error executing query $q",1);

	my $row = $sth->fetchrow_hashref;

	($row) ? (return $row) : (return undef);
}


#------------------------------------------------------------
# remove - method
#------------------------------------------------------------

sub remove
{
	my ($self,$data) = @_;
	my $dbh = $self->{dbh};

	# deleting from data table

	my $query = "delete from $self->{data_table} where ".PKEY()." = $self->{dataid}";
	my $sth = $dbh->prepare($query) || 
			SW::debug($self,"remove, Error preparing query - $query\n\t".$dbh->errstr,3);

	$sth->execute ||
			SW::debug($self,"remove, Error executing query - $query\n\t".$dbh->errstr,3);

	#deleting from access,map,info tables	

	my $q1 = "delete from $self->{access_table} where ".PKEY()." = $self->{id}";
	my $q2 = "delete from $self->{map_table} where ".PKEY()." = $self->{id}";
	my $q3 = "delete from $self->{info_table} where ".PKEY()." = $self->{id}";
		
	 $dbh->do($q1) ||
			SW::debug($self,"remove, Error executing query - $query\n\t".$dbh->errstr,3);
	 $dbh->do($q2) ||
			SW::debug($self,"remove, Error executing query - $query\n\t".$dbh->errstr,3);
	 $dbh->do($q3) ||
			SW::debug($self,"remove, Error executing query - $query\n\t".$dbh->errstr,3);
}


#------------------------------------------------------------
# DESTROY - method
#------------------------------------------------------------

sub DESTROY
{
	my $self = shift;

	if (ref $self->{dbh})
	{
		delete($self->{dbh});
	}
}


#------------------------------------------------------------
# evalfield
#
#	checks the input value to see if it corresponds
#	to one of the values in the list of fields that
#	must be eval'ed 
#
#
#	returns 1 if an eval field, undef otherwise
#
#	a faster way to implement this would be to make the 
#	protected fields keys in a hash and check defined on them.
#------------------------------------------------------------

sub evalfield
{
	my ($self, $key) = @_;
	
	foreach my $field (@{$self->{evalFields}})
	{
		return 1 unless $field ne $key;
	}
	return undef;
}


1;

__END__

=head1 NAME

SW::Data::DBIStore - Abstraction of all data storage - all the SQL and direct
							database access is in here

=head1 SYNOPSIS

	instantiated inside SW::Data::ObjectStore::DBI (descendant of  SW::Data::ObjectStore) 
	to provid object_store services to the data object

=head1 DESCRIPTION

	based heavily on Apache::Session, this series of SW::Data modules simply 
	generalize the concept of transparently (using TIE) presenting doucments
	to the user and handling storage and retrieval.

	A great deal more protection, error checking, and field control must still
	be built in here.

=head1 METHODS

	new -
	insert -
	update -
	delete -
	materialize -
	DESTROY -


=head1 PARAMETERS

	 evalFields - a list of the fields that should be flattened on their 
	 		way out to the database and eval'ed on the way back in.
	 dbh - database handle
	 pkey - the name of the primary key field in the table
	 table - the name of the sql table

=head1 AUTHOR

  Scott Wilson
  HBE   scott@hbe.ca
  Jul 22/99

=head1 REVISION HISTORY

	$Log: DBIStore.pm,v $
	Revision 1.33  1999/11/15 18:17:33  gozer
	Added Liscence on pm files
	
	Revision 1.32  1999/11/05 21:58:59  scott
	changed insertid for mysql_insertid to stop warnings
	
	Revision 1.31  1999/10/25 10:28:55  gozer
	quotes
	
	Revision 1.30  1999/09/29 21:25:43  krapht
	Added error handling (so it stops crashing the server), new functions, blablabla
	
	Revision 1.29  1999/09/27 22:07:47  krapht
	Fixed a bug in addOwnerAccess with READABLE and WRITABLE
	
	Revision 1.28  1999/09/27 21:07:02  krapht
	Removed FULL_ACCESS and put READABLE+WRITABLE instead
	
	Revision 1.27  1999/09/27 15:15:17  fhurtubi
	Added a Randal Schwartz trick for materializing a Dump
	
	Revision 1.26  1999/09/26 20:42:42  krapht
	Added a line to check the validity of a key from resolveMapping, so it doesn't
	crash the server if no value was found.  Plus some more debugging messages.
	
	Revision 1.25  1999/09/24 00:06:44  scott
	fixing some config stuff with file upload
	
	Revision 1.24  1999/09/20 19:59:52  fhurtubi
	Changed reference of $self->{user} to SW->user
	
	Revision 1.23  1999/09/20 14:30:45  krapht
	Changes to use the new method of getting session, user, etc.
	
	Revision 1.22  1999/09/17 22:18:28  scott
	fixed a problem with mysql_insertid
	
	Revision 1.21  1999/09/17 21:18:16  gozer
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
	
	Revision 1.20  1999/09/15 21:32:54  fhurtubi
	Fixed query in DBIStore, Changed LOTS of things in File.pm (and this is
	not over yet). Removed a buggy line in Folder
	
	Revision 1.19  1999/09/15 01:52:34  scott
	fixed delete
	
	Revision 1.18  1999/09/13 15:01:01  scott
	lots of changes, sorry this is bad documentation :-(
	
	Revision 1.17  1999/09/13 02:03:41  fhurtubi
	Fixed something that gozer broke :(
	userid wasnt store in the creator database field
	
	Revision 1.16  1999/09/11 08:44:36  gozer
	Made a whole bunch of little kwirps.
	Fixed Handler to deal correctly with SW_App_Namespace without defaulting to SW::App when the var is set
	Fixed the bug that made Login.pm create an empty hidden argument on every login attempt
	Added a whole bunch of modules preloading in sw-perl-startup, good speed improvment
	Fixed a few warning here and there.  Only one missing the sweep.  Application.pm and AUTOLOAD warning ?!?
	Changed the SW::Util::flatten and circular_flatten to succesfully use Data::Dumper ;-} (-180 lines of code)
	Gone to bed very late
	
	Revision 1.15  1999/09/11 07:07:40  scott
	Made substantial changes to the database schema and data storage models.
	Now there's three global tables called datamap, dataaccess, and
	datainfo.  These hide the many other more data specific tables
	where the infomation is actually stored.
	
	Revision 1.14  1999/09/01 01:26:48  krapht
	Hahahahha, removed this %#*(!&()*$& autoloader shit!
	
	Revision 1.13  1999/08/30 20:23:15  krapht
	Removed the Exporter stuff
	
	Revision 1.12  1999/08/27 21:08:09  fhurtubi
	Removed debug lines that are intended for me only, I shouldn't have commited the previous
	version...
	
	Revision 1.11  1999/08/27 21:06:58  fhurtubi
	This file is being moved to /apps/ContactManager
	
	Revision 1.10  1999/08/14 00:21:26  scott
	ContactList - move, delete, edit all work!!!!
	
	DBIStore - bug fixes
	
	Revision 1.9  1999/08/13 16:02:51  scott
	Bug fixes with ContactList
	
	Revision 1.8  1999/08/13 14:32:52  scott
	Bug fixes on database access, and getting ContactManager working
	
	Revision 1.7  1999/08/12 19:44:02  scott
	Fixed a dumb bug in protected() that was stopping data from being written in the db
	
	Revision 1.6  1999/08/11 15:27:04  scott
	Small bug fixes on the code I wrote last night
	
	Revision 1.5  1999/08/11 05:55:53  scott
	Added an initialization parameter to $args called evalFields.  This
	is a list (much lik @protected in SW::Data::ObjectStore) that
	simply detailsd a list of fields that should be flattened (Data::Dumpered)
	on the weay into the database and eval'ed again on the way back out.
	
	Revision 1.4  1999/08/10 16:38:57  scott
	fixed it to flatten data in to the db and eval it out
	
	Revision 1.3  1999/08/09 22:12:46  scott
	oops!  ghosts!
	
	Revision 1.2  1999/08/09 21:49:47  scott
	Fixed remove() so that it also removes records in the object access tables
	for the applicable data object
	
	Revision 1.1  1999/07/25 02:20:02  scott
	Newly added module - this is the SQL low level db access module associated with
	SW::Data, SW::Data::ObjectStore
	
	This is based on Apache::Session::DBIStore
	

=head1 SEE ALSO

SW::Data, SW::Data::ObjectStore, SW::Data::ObjectStore::DBI,
Apache::Session, perl(1).

=cut

