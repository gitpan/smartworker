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

package SW::User::Group;

#------------------------------------------------------------
# SW::User
# Generic User::Group Class for SmartWorker users
#------------------------------------------------------------
# $Id: Group.pm,v 1.5 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION);

use SW;
use SW::Util;
use SW::Application;
use SW::User::Admin;
use SW::User::Manager;
use Data::Dumper;
use Apache;
use SW::DB;



$VERSION = '0.01';

#------------------------------------------------------------
# new
# Creates a new group object.  The object is instantiated
# from the user database, or, if the user is not found, 
# it returns "guest" in the user name
#------------------------------------------------------------

sub new
{
	my $className = shift;
	
	my $self = bless {}, $className;
	
   $self->load(SW->user);
	 
	return $self;
}

sub byname {
	return $_[0]->{groups_byname};
	}
	
sub byid {
	return $_[0]->{groups_byid};
	}

sub in_byname {
	my $self = shift;
	my $name = shift;
	return $self->{groups_byname}{$name};
}

sub in_byid {
	my $self = shift;
	my $name = shift;
	return $self->{groups_byid}{$name};
}

sub load {
	my $self= shift;
	my $user = shift;
	
	my $uid = $user->getUid;
   return unless $uid;
	
	my $query = qq/SELECT groupname, g.groupid
                  FROM groups g, groupmembership gm
                  WHERE g.groupid=gm.groupid and userid=$uid
                  /;
  
   my $sth = getDbh()->prepare($query);
	$sth->execute() || print STDERR "SQL Error :", $sth->errstr;
   
	delete $self->{groups_byname} if exists $self->{groups_byname};
	delete $self->{groups_byid} if exists $self->{groups_byid};
	
	while(my $res = $sth->fetchrow_arrayref)
		{
		$self->{groups_byname}{$res->[0]} = $res->[1];
		$self->{groups_byid}{$res->[1]} = $res->[0];
		}
	$self->{groups_byname}{'GUEST'}=$SW::Constants::GROUP_GUEST;
	$self->{groups_byid}{$SW::Constants::GROUP_GUEST} = "GUEST";
	
	if ($user->authenticate->valid)
		{
		$self->{groups_byname}{'ALL'}=$SW::Constants::GROUP_ALL;
		$self->{groups_byid}{$SW::Constants::GROUP_ALL} = "ALL";
		}
		
	
	return;
	
}


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::User - SmartWorker User Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 FUNCTIONS
	
=head1 AUTHOR

Kyle Dawkins, kyle@hbe.ca

=head1 REVISION HISTORY

  $Log: Group.pm,v $
  Revision 1.5  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.4  1999/09/26 19:30:01  gozer
  Modularized some more
  Added Challenge-Response thing

  Revision 1.3  1999/09/20 18:26:31  gozer
  More modularization of the User object, added Pref in there

  Revision 1.2  1999/09/20 14:31:24  krapht
  Changed the way to get user (SW->user)

  Revision 1.1  1999/09/17 21:37:37  gozer
  Forgot to add those

 

=head1 SEE ALSO

perl(1).

=cut
