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

package SW::AppRegistry;

#------------------------------------------------------------
# SW::AppRegistry
# Registry keeping track of Apps, their data types, and assoc. objects
#------------------------------------------------------------
# $Id: AppRegistry.pm,v 1.12 1999/11/15 18:17:32 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::Application;
use SW::Data;
use SW::Util;

@ISA = qw();

#-------------------------------------------
#  new
#-------------------------------------------

sub new
{
	my $classname = shift;
	my $app = shift;
	my $dbh = SW::DB->getDbh();

	my $self = { 
			_app => $app,
	};

	bless ($self, $classname);
	return $self;
}

#-------------------------------------------
#  dataTypes
#-------------------------------------------

sub dataTypes
{
	my $self = shift;
	my $app = shift;
	my $appName = shift;

	my $data;
	my $datatypes;

	if ($appName)
	{	
		my $query = "select datatypes from apps where appid=\'$appName\'";
		my $sth = SW::DB->getDbh()->prepare($query);
		$sth->execute;
		my $row = $sth->fetchrow_hashref;

	   $datatypes = eval( $row->{datatypes} );
	
	}
	else
	{
		my $query = "select datatype from datatypes";
		my $sth = SW::DB->getDbh()->prepare($query);
		$sth->execute;

		while (my $row = $sth->fetchrow_arrayref)
		{
			push @$datatypes, $row->{datatype};
		}
	}

	return $datatypes;

}


#-------------------------------------------
#  visibleDataTypes
#-------------------------------------------

sub visibleDataTypes
{
	my $self = shift;
	my $app = shift;

	my $data;
	my $datatypes;

	my $query = "select datatype from datatypes where hidden = \'false\'";
	my $sth = SW::DB->getDbh()->prepare($query);
	$sth->execute;

	while (my $row = $sth->fetchrow_arrayref)
	{
		push @$datatypes, $row->{datatype};
	}

	return $datatypes;
}


#-------------------------------------------
#  hiddenDataTypes
#-------------------------------------------

sub hiddenDataTypes
{
	my $self = shift;
	my $app = shift;

	my $data;
	my $datatypes;

	my $query = "select datatype from datatypes where hidden = \'true\'";
	my $sth = SW::DB->getDbh()->prepare($query);
	$sth->execute;

	while (my $row = $sth->fetchrow_arrayref)
	{
		push @$datatypes, $row->{datatype};
	}

	return $datatypes;
}



#-------------------------------------------
#  checkRegistered
#-------------------------------------------

sub checkRegistered
{
	my $self = shift;
	my $appName = shift;

	SW::debug($self,"checkRegistered on $appName",5);

	if (! $self->{appids}->{$appName})
	{
		my $query = SW::Util::buildQuery('select', 'apps', 
					'name', SW::DB->getDbh()->quote($appName));
		my $sth = SW::DB->getDbh()->prepare($query);

		return 0 unless $sth->execute;
		return 0 unless my $row = $sth->fetch();

		$sth->finish;

		$self->{appids}->{$appName} = $$row[0];
	}

	return  $self->{appids}->{$appName};
}

#-------------------------------------------
# register
#-------------------------------------------

sub register
{
	my $self = shift;

	SW::debug($self,"Deprecated - Applications should no longer call register ....",3);

	return 1;
}

#------------------------------------------------------------
# Loop through all registered apps and return a list of
# all registered document types
# THIS IS NOT CALLED AS A METHOD
#------------------------------------------------------------

sub registeredTypes
{
	my $app = shift;

	my $query = "select datatypes from apps";

	my $dbh = $app->getDbh();

	my $sth = $dbh->prepare($query);

	my @results = (1);

	if ($sth->execute)
	{
		while (my $ref = $sth->fetch)
		{
			my $array = eval $$ref[0];

			push (@results, @$array);
		}
	}

	$sth->finish;
	$dbh->disconnect;

	return @results;
}



1;

__END__

=head1 NAME

SW::AppRegistry - Interface Class to the apps DB table where we keep track of apps
		   and the anonymous documents and data types belonging to them

=head1 SYNOPSIS

(in SW::Master)

	use SW::AppRegistry;

	$self->{appRegistry} = new SW::AppRegistry($self);

(in SW::Application)

        if ($state eq 'InitApplication')
        {
                if (! $self->{master}->{appRegistry}->checkRegistered(ref $self))
                {
                        $self->swInitApplication(@_);
                }
        }

(in some Application)
	sub swInitApplication
	{
		...
       		my $appRegistry = $self->{master}->{appRegistry};

        	$appRegistry->register(ref $self, $data->getFullPath(), "", 
						"SW Documentation Tree Viewer");;
		...
	}

	sub swInitInstance
	{
	    my $self = shift;

	    my @objList = $self->{master}->{appRegistry}->dataObjects($self, ref $self);
	    SW->session->{dataDocumentPath} = shift @objList;

	    return 1;
	}

=head DESCRIPTION

AppRegistry is used to keep track of applications in the system.  Eventually this will
be how administrators "reload" or "restart" apps, as well as registering them, 
removing, updating, and associating data types and anonymous objects with them.

When an application is started, we check the appRegistry to see if the app has
ever been run before.  If not we run swInitApplication on the app.  The app will store
user independant state and setup information in a data object and register it with
the registry.


=head1 METHODS

  new - arguments: SW::Master

  register - arguments: App Name, @( data objects ), @( data type ), comment
		Registers the app

  checkRegistered - arguments: AppName
 			If the app is registered, returns its app is from the db,
			otherwise returns false

  dataTypes -  when passed an APPID, returns the data types associated with that
					app, otherwise returns a list of all the objects on the system.

  visibleDataTypes - return a list of not hidden data types

  hiddenDataTypes - returns a list of hidden data types


=head1 AUTHOR

Scott Wilson, scott@hbe.ca
Apr. 7/1999

=head1 SEE ALSO

perl(1).

=head1 REVISION HISTORY

  $Log: AppRegistry.pm,v $
  Revision 1.12  1999/11/15 18:17:32  gozer
  Added Liscence on pm files

  Revision 1.11  1999/09/20 19:58:54  fhurtubi
  Changed reference of $self->{session} to SW->session

  Revision 1.10  1999/09/13 22:28:23  gozer
  Fixed something wrong with master DESTRUCTION that caused memory leaks until the server ended
  Added the SW->master method that returns the current $master

  Revision 1.9  1999/09/07 03:33:06  scott
  added some methods in app registry for getting data types

  Revision 1.8  1999/09/01 01:35:03  krapht
  Removed the autoloader shit

  Revision 1.7  1999/08/30 20:23:11  krapht
  Removed the Exporter stuff

  Revision 1.6  1999/07/25 02:39:04  scott
  Minor changes to the type registering routines because some database fields
  have been renamed.

  Revision 1.5  1999/06/17 21:46:26  krapht
  Code cleanup

  Revision 1.4  1999/04/21 01:31:47  kiwi
  You can now use getRegisteredApp, and pass it a document type. It returns a
  list of the Class Name of the app that the document belongs to, and the
  "comment" from the database.

  Revision 1.3  1999/04/20 20:08:52  kiwi
  Added "registeredTypes" function

  Revision 1.2  1999/04/14 19:45:48  scott
  Debugging code

  Revision 1.1  1999/04/13 16:27:54  scott
  New Class - register apps and their objects, data types



=cut
