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

package SW::DB;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::DB
#    Module that will do Low Level database communcation,
#	   create and hold onto DBIx::Recordset Database defs etc...
#------------------------------------------------------------
# $Id: DB.pm,v 1.17 1999/11/15 18:17:32 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA %DB_HANDLES @SW_EXPORT %DB_FUNC);

use SW::Exporter

@ISA = qw(SW::Exporter);

$VERSION = '0.01';

@SW_EXPORT = qw(&getDbh);


#------------------------------------------------------------
# getDbh   - moved in here from Master July 20/99 RSW
#
# The getDbh function returns a handle to an opened database.
# The database name may be specified as an argument,
# otherwise the function will revert to the current default
# value in SW::Config.
#
# Returns a database handle, undef if the handle is not valid
#------------------------------------------------------------

sub getDbh
{
	my ($self,$dbString) = @_;

	#this builds function stubs to return database handles while removing the password entry in the config file for security reasons
	#this should be done at startup-time though.  But where is the init sub ?? scott ??
	unless (exists $DB_FUNC{$dbString || "DEFAULT"})
		{
		my $dbInfo;
		my $dbPassword;
		my $dbUser;
		my $db;
		my $database;
		my $dbPort;
		my $dbh;
		my $dbFullPath;
		my $dbType;

		if ($dbString)
			{
			$dbInfo = $SW::Config::DB_LIST{$dbString};
 			}
 		else
 			{
			$dbInfo = $SW::Config::DEFAULT_DB;
 			}

		$database = $dbInfo->{'database'};
#		$dbFullPath = "database=".$database.";host=".$dbInfo->{'host'}.";port=".$dbInfo->{'port'};

		# changed this around so that that we call it exactly as Apache::Session does
		#  so that we only ever get one connection per process

      $dbFullPath = "dbname=".$database.";host=".$dbInfo->{'host'};
		$dbUser = $dbInfo->{'username'};
		$dbPassword = $dbInfo->{'password'};
		$dbType = $dbInfo->{'dbType'};

		$DB_FUNC{$dbString || "DEFAULT"} = sub { 
			return DBI->connect("dbi:$dbType:$dbFullPath", $dbUser, $dbPassword); 
			};
		#done with the confidential stuff, so we can make it dissapear forever !
		if ($dbString)
			{
			delete $SW::Config::DB_LIST{$dbString}{'password'};
			delete $SW::Config::DB_LIST{$dbString}{'username'};
 			}
 		else
 			{
			delete $SW::Config::DEFAULT_DB->{'password'};
			delete $SW::Config::DEFAULT_DB->{'username'};
 			}
		}
	
	
	
	
	return &{$DB_FUNC{$dbString || "DEFAULT"}};
}


#------------------------------------------------------------
# importData
#
# Takes a hashref row return from DBI, and
# adds each field into the hash specified
# optionally takes a list of fields to process.
#
# returns the number of fields imported
#------------------------------------------------------------

sub importData
{
	my ($self,$row,$target,@fields) = @_;
	my $count = 0;

	@fields = keys %$row unless @fields;
	
	foreach my $f (@fields)
	{
		if ($row->{$f} =~ /{/)
		{
			$target->{$f} = eval $row->{$f};
		}
		else
		{
			$target->{$f} = $row->{$f};
		}
		$count++;
	}

	return;
}

#------------------------------------------------------------
# getDataSourceString
#------------------------------------------------------------

sub getDataSourceString
{
	my $db = shift;

	my $db_name = $db || $SW::Config::DEFAULT_DB_NAME;

	my $db_ref = $SW::Config::DB_LIST{$db_name};	

	my $type = $db_ref->{'dbType'};
	my $database = $db_ref->{'database'};
	my $host = $db_ref->{'host'};
	my $port = $db_ref->{'port'};

	my $src = "DBI:$type:database=$database:host=$host:port=$port";
	
	return $src;
}

1;

__END__

=head1 NAME

SW::DB - SW module to handle Database handle creation, passing etc...

=head1 SYNOPSIS

   

=head1 DESCRIPTION


=head1 METHODS

  getDbh - get database handle - takes an optional parameter of a database name 
				or a fully qualified object path.

  getDataSourceString - optionally takes a database indentifier (see Conifg.pm) and
				returns a well formatted data source string.  This is mostly intended for
				outside DBI related modules that need this.  EG Apache::Session

=head1 PARAMETERS


=head1 AUTHOR

Scott Wilson
HBE	scott@hbe.ca
Jul 20/1999

=head1 REVISION HISTORY

  $Log: DB.pm,v $
  Revision 1.17  1999/11/15 18:17:32  gozer
  Added Liscence on pm files

  Revision 1.16  1999/10/27 16:00:06  scott
  fixed the DB connect string so it's the same as Apache::Session
  so we get one connection per process

  Revision 1.15  1999/09/24 22:04:25  gozer
  Modified DB access to hide username/password

  Revision 1.14  1999/09/22 19:23:24  gozer
  Fixed a stupid logig bug that was allowing you only to modify one application per session :-/

  Revision 1.13  1999/09/19 20:34:42  gozer
  Documented SW.pm and I changed a few more $self->{master} stuff to SW->master

  Revision 1.12  1999/09/19 16:06:11  krapht
  Used SW::Exporter in there, so we don't have to say SW::DB::getDbh now.
  Also removed shifts, which produce more opcodes! :)

  Revision 1.11  1999/09/15 01:51:38  scott
  debuging a problem iwith load order, memoryizing tables at load time

  Revision 1.10  1999/09/04 19:08:05  scott
  Fixed a hash syntax problem in getDataSourceString and Session

  Revision 1.9  1999/09/03 20:23:03  scott
  evel -> eval!

  Revision 1.8  1999/09/03 20:22:16  scott
  Fixing Session so that it doesn't have hardcoded database names

  Revision 1.7  1999/09/01 01:26:46  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.6  1999/08/29 15:40:19  scott
  changed datasource format to use host= port= database= style

  Revision 1.5  1999/08/17 05:22:50  scott
  Changed the comments

  Revision 1.4  1999/08/13 14:33:24  scott
  Removed some annoying debugging from DB and bug fixes and tweaking in Data

  Revision 1.3  1999/08/11 21:09:40  scott
  debugging

  Revision 1.2  1999/07/25 02:46:23  scott
  documentation fixes

  Revision 1.1  1999/07/25 02:45:14  scott
  This file abstracts out of master and application the handling of
  database handles :-)  $self->{master}->getDbh($dbName)  becomes SW::DB->getDbh($dbName);

  Motivation mostly just to alleviate some clutter.


=head1 SEE ALSO

perl(1), %SW::Config::DB_LIST

=cut
