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

package SW::Application;

#------------------------------------------------------------
# SW::Application
# Main framework class for a SmartWorker App
#------------------------------------------------------------
# $Id: Application.pm,v 1.82 1999/11/15 18:17:32 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION %SW_FN_TABLE @ISA);

use Apache;
use Apache::Constants qw(:common);
use DBI;
use CGI '-autoload';

use SW::Panel;
use SW::Session;
use SW::User;
use SW::Util;
use SW::Component;
use SW::Constants;
use SW::Data::Document;
use SW::Language;
use SW::Handler; # for the redirect routine


@ISA = qw(SW::Component);

$VERSION = '0.01';

# constants

sub APP_ID () {"APPLICATION"}
sub DATA_TYPES () { " ( 'GENERIC' ) " }


#------------------------------------------------------------
# new
#
# Creates a new instance of a SmartWorker application
#------------------------------------------------------------

sub new
{
	my $swClassName = shift;
	my $nextArg = shift;
	my $parent;
	my $swAppName;
	my $args;

	if (ref $nextArg eq 'HASH')
	{
		# arguments arrive in a hash

		while (my ($name, $value) = each (%$nextArg))
		{
			if ($name eq "-parent")
			{
				$parent = $value;
			}
			elsif ($name eq "-args")
			{
				$args = $value;
			}
			elsif ($name eq "-name")
			{
				$swAppName = $value;
			}
		}
	}
	else
	{
		$swAppName = $nextArg;
		$parent = shift;
		$args = shift;  # This should be changed so we can get more arguments
	}

	my $self = {
					className	=> $swClassName,
					name			=> $swAppName,
					childId		=> 0,
					lines			=> [ "" ],
					cookies		=> [],
					appendages	=> {},
					components	=> {},
					args			=> $args,
					params		=> {
						   			visible => 1,
						  			},
					};

	# Bless this reference
	
	bless $self, $swClassName;

	$self->{master} = SW->master;
	if (ref($parent) eq "SW::Master")
	{
		#$self->{master} = $parent;
		if ($self->{name})
		{
			$self->{package} = 'SW::Master::'.$self->{name};
		} else
		{
			$self->{package} = 'SW::Master::'.ref($self);
		}
	} else
	{
		$self->{parent} = $parent;
		#$self->{master} = $parent->{master};
		if ($self->{name})
		{
			$self->{package} = $parent->{package}.'::'.($parent->{childId})++.'::'.$self->{name};
		} else 
		{
			$self->{package} = $parent->{package}.'::'.($parent->{childId})++.'::'.ref($self);
		}
	}

	# Create main panel

	$self->{panel} = SW::Panel->new($self);
	if (!$self->{parent})
	{
		$self->{panel}->{masterPanel} = 1;
	}


	if ($self->getDataValue('lang'))
	{
		$self->addAppendage("lang", $self->getLanguage());
	}

	return $self;
}


#------------------------------------------------------------
# getPanel
#
# Returns a reference to the main panel.
#------------------------------------------------------------

sub getPanel
{
	return $_[0]->{panel};
}


#-------------------------------------------------------------
# trickleState
#
# initiates a call down to all children to execute code
# pertaining to its argument, "state".
#-------------------------------------------------------------

sub trickleState
{
	my $self = shift;
	my $state = shift;
	my $noTrickle = undef;
	$self->{state} = $state;

	SW::debug($self,"[TrickleState - app ".(ref $self)."] going to $state",5);

	if ($state eq 'InitApplication')
	{
		if (! $self->{master}->{appRegistry}->checkRegistered($self->APP_ID))
		{
			$self->swInitApplication(@_);
		}
	}
	elsif ($state eq 'InitInstance')
	{
		if (! (SW->session->getPrivateValueOnBehalfOf(ref $self,"_loaded")))
			{
			print STDERR "CALLING INITINSTANCE\n";
			SW->session->setPrivateValueOnBehalfOf(ref $self,"_loaded","1");
			$self->swInitInstance(@_);
			}	
	}
	elsif ($state eq 'InitTransaction')
	{
		$self->swInitTransaction(@_);
	}
	elsif ($state eq 'BuildUI')
	{
		$self->swBuildUI(@_);
	}
	elsif ($state eq 'SaveState')
	{
		$self->saveState(@_);
	}
	elsif ($state eq 'CleanUp')
	{      		# call children first
		$self->getPanel()->trickleState($state);
		$self->cleanup();
		$noTrickle = 'true';
	}

	$self->getPanel()->trickleState($state) unless $noTrickle;
}


#-------------------------------------------------------------
# syncState
#
# This is used to catch an app up to the current state 
# of affairs if it has been added dynamically later in the 
# flow.
# aka catchup
#-------------------------------------------------------------

sub syncState
{
	my $self = shift;
	my $target = shift;
	my $currentState = $self->{state};

	my @stateList = qw(InitApplication InitInstance InitTransaction
                      BuildUI Render SaveState Cleanup);

	return unless $currentState;

	SW::debug($self,"Catchup on ".ref($target)." current state is $currentState",5);

	foreach my $state (@stateList)
	{
		if ($currentState eq $state)
		{
			last;
		} else
		{
			$target->trickleState($state);
		}
	}

}

#------------------------------------------------------------
# confirmRenderStyle
#------------------------------------------------------------

sub confirmRenderStyle
{
	my $self = shift;
	my $style = shift;

	SW->data->{renderStyle} ?
		return SW->data->{renderStyle} :
		return $style;
}

#------------------------------------------------------------
# DESTROY
# It would be ideal to use the DESTROY method to clean up
# and return all the HTML to the browser.  However,
# it turns out that it's not that possible.  Why?  Because
# the $self->{panel} reference prevents the DESTROY method
# of the app being called because $self->{panel} has a 
# reference back to the app... circular reference so 
# mod_perl doesn't bother to free either object.  So
# DESTROY can't be called unless $self->{panel} is undefined,
# in which case the DESTROY method will be called but can't
# render anything because $self->{panel} is undef...
#------------------------------------------------------------

sub DESTROY
{
	my $self = shift;

	SW::debug($self,"App DESTROY\n",5);
}

#------------------------------------------------------------
# saveState
#------------------------------------------------------------
sub saveState
{
	my $self = shift;
	my $d;
	while ($d = shift @{$self->{documents}})
	{
		SW::debug($self,"document close",5) if $d->close();
		$d = undef;
	}
}
#------------------------------------------------------------
# cleanup
#
# Cleans up! %?)
#------------------------------------------------------------

sub cleanup
{
	my $self = shift;

	SW::debug($self,"cleanup started..",5);

	my $redirect = $self->{_redirect};

	if ($redirect) { 
		
		$redirect .= "?".$self->getURLAppendages; 

		SW::debug ($self, "REDIRECTING to $redirect", 3);
		
		#added by gozer so redirecting is easy now and http_Headers are sent only once
		SW::Handler::redirect($redirect,0);	
	}

	# destroy links to components
	foreach my $c (keys %{$self->{components}})
	{
		$self->deleteComponent($c);
	}

	# remove FN_TABLE

	my $cname = ref($self);	

	$self->{_FN_TABLE} = undef;

	# remove the circular references
	foreach my $k (keys %$self)
	{
		delete($self->{$k});
	}
}

#------------------------------------------------------------
# abort
#
# Aborts a request any time before "exit" is called
#------------------------------------------------------------

sub abort
{
	my $self = shift;
	my $abortString = shift;

	my $r = $self->{r};

	#$r->status(OK);
	#$r->status(SERVER_ERROR);
	$r->content_type('text/html');
	$r->send_http_header();
	
	$r->print($abortString."<br>");
	$r->print(__PACKAGE__."<br>");
	$r->print("Package: ".$self->{package}."<br>");
	$r->print("<pre>".$self." / ".ref($self)."</pre>");


	if ($self->{parent})
	{
		$r->print("Aborting from child");
	}
	else
	{
		$r->print("Aborting from main app");
	}

	$self->cleanup;
	$r->rflush();
	Apache->exit();
}

#------------------------------------------------------------
# getComponent
#
# Returns a reference to the named component.
#------------------------------------------------------------

sub getComponent
{
	my $self = shift;
	my $componentName = shift;

	return $self->{components}->{$componentName};
}

#------------------------------------------------------------
# addComponent
#
# Adds a reference to a GUI component.
#------------------------------------------------------------

sub addComponent
{
	my $self = shift;
	my $newComponent = shift;
	my $componentName = shift;

	SW::debug($self,"[APP] Adding $componentName (".ref($newComponent).") to ".ref($self),5);

	$self->{components}->{$componentName} = $newComponent;
	return;

}

#------------------------------------------------------------
# render
#
# Makes a call to render the application.
#------------------------------------------------------------

sub render
{
	my $self = shift;

	SW::debug($self,"Rendering application ".$self->{name},5);

	my $data = $self->{panel}->renderer()->renderApplication($self);
	return  $data;
}

sub renderer
{
	my $self = shift;
	return $self->{panel}->{renderer};
}

#------------------------------------------------------------
# getSize
#------------------------------------------------------------

sub getSize
{
	my $self = shift;

	return (1, 1);
}

sub getElementSize
{
	my $self = shift;

	return (1, 1);
}


#------------------------------------------------------------
# deleteComponent
#------------------------------------------------------------

sub deleteComponent
{
	my $self = shift;
	my $componentName = shift;

	delete $self->{components}->{$componentName};
}

#------------------------------------------------------------
# findDataKey
#
# This function looks in $self->{data} for keys that would
# contain the argument (keyLookup) and returns a hash ref
# containing the keys that were found.
#------------------------------------------------------------
#THIS HAS NOTING TO DO HERE AND SHOULD BE MOVED
sub findDataKey
{
	my $self = shift;
	my $keyLookup = shift;
	my $foundKeys;		

	foreach my $key (keys %{SW->data})
	{
		if ($key =~ /$keyLookup/) { $foundKeys->{$key} = $self->getDataValue($key); }
	}

	return ($foundKeys);
}

#------------------------------------------------------------
# Stubs for Applications that don't feel the need to implement these
#------------------------------------------------------------

sub swInitApplication
{
	return 1;
}

sub swDrawingSetup
{
	return 1;
}

sub swInitTransaction
{
	return 1;
}

sub swInitInstance
{
	return 1;
}

sub swValidateUser
{
	return 1;
}


#------------------------------------------------------------
# getArgs
#
# Returns a reference to an array containing the arguments
# passed to the application by its caller, or undef if no
# arguments have been passed.
#------------------------------------------------------------

sub getArgs
{
	my $self = shift;

	if($self->{args})
	{
		return $self->{args};
	}

	return;
}


#------------------------------------------------------------
# getLanguage
#
# This should just call $user->getLang or something
# then return the Language object
#------------------------------------------------------------

sub getLanguage
{
	my $self=shift;

# all session things were commented out, plus I added param to test something
	my $pref  = SW->user->preference("Language");
 	my $sess  = SW->session->{lang};
	my $spec  = $self->getDataValue("lang");

## TEMPORARY HACK by FRED;
if (ref($spec) eq "ARRAY") 
{ 
	$spec = $spec->[1];
}

#	my $param = $self->getComponent("lang")->getValue();
	my $param = $self->getValue("lang");

	return $param if $param;
	return $spec  if $spec;
 	return $sess  if $sess;
	return SW::Language::getCode($pref, $self);
}


#------------------------------------------------------------------
# setPref
#------------------------------------------------------------------

sub setPref
{
	my $self      = shift;
	my $prefkey   = shift; 
	my $prefvalue = shift;

	SW->user->setDirty(1);  # Set user value saver on.

	return SW->user->{preferences}->setAppPref($self->AppID(),$prefkey,$prefvalue);
}


#------------------------------------------------------------------
# getPref
#------------------------------------------------------------------

sub getPref
{
	my $self    = shift;
	my $prefkey = shift;
    
	return SW->user->{preferences}->getAppPref($self->AppID(),$prefkey);
}


#------------------------------------------------------------------
# getDatatypes - method
#
# Queries the database for datatypes associated with the
# application, depending on the value of its APP_ID.
#
# Returns an array of the associated datatypes.
#------------------------------------------------------------------

sub getDatatypes
{
	my $self = shift;

	my $query = "SELECT datatypes FROM apps where appid=\"" . $self->APP_ID . "\"";

	my $sth = getDbh()->prepare($query);

	$sth->execute();

	my @types = split(/,/,$sth->fetchrow_array());

	return @types;
}


use Data::Dumper;
sub dump {
	my $self = shift;
	return Dumper $self;
}

#------------------------------------------------------------
#  this is here to replace all the $self->{master} calls
#	which are totally unneccessary and starting to cause
#	problems
#------------------------------------------------------------

sub AUTOLOAD {
	my $self = shift;
	my $callname = $SW::Application::AUTOLOAD;

	$callname =~ s/.*:://;    	 # remove any package qualifier 
	return unless $callname =~ /[^A-Z]/;	# toss out any all caps methods
												#  especially DESTROY

	if (! SW->master)
	{
		SW::debug($self, "Oops, no master!!! Error in AUTOLOAD",1);
	}

	return SW->master->$callname(@_) if SW->master->can($callname);
	print STDERR "There is no $callname() defined anywhere\n";
	return;
}


1;

__END__

=head1 NAME

SW::Application - Main framework class for SmartWorker applications

=head1 SYNOPSIS

  use SW::Application;

  my $app = new SW::Application("Hello World");


  # sample of session tracking

  my $session = $app->getSession();
  $session->{myValue} = "Hello!";
  $session->{greatBigArray} = [ 0, 1 , 2, "Bob", "Doug"];
  $session->{complexStuff} = {
                            sampleHash => { "name" => "Bob" },
                            sampleArray => [ "Bananas", "Apples" ],
                            sampleScalar => "Thingy",
                            };

=head1 DESCRIPTION

The application framework class provides a way of abstracting the transaction-based
protocol of the WWW from the developer of server-side applications.  These applications
are designed to run on the SmartWorker server only, so they can take advantage of the
simple API offered to the programmer.  This API is useful for rendering platform-independent
HTML, handling transparent and persistent connections to databases, and
writing multi-user client-server apps.

The Application class handles session persistence transparently by retaining session ID
values as part of posted URLs or cookies (if the browser can support these
features). Moreover, the application class is the message translation system for
every SmartWorker application.  It is respsonsible for executing user-written callback
methods to handle client-side interaction such as URL requests or POST operations.

=head1 SESSION TRACKING

Session tracking is built-in to the application object.  When an application is woken
up, it checks the submitted request for a sessionId.  If present, the application
retrieves the session data from storage (provided it hasn't yet expired).  Otherwise, it
creates a new session object.

These objects can be written to just like a hash (see example above) and they will 
be stored and retrieved transparently between calls.

Session-specific data should be minimised as much as possible, and the goal of
SmartWorker is to remove the concept of "Session Tracking" as much as possible.
Nevertheless, the idea of a session object is appealing to many programmers, and will
solve a number of problems inherent in the stateless HTTP protocol.

=head1 STATE INFORMATION

The app also uses a hash called "appendages" to generate state information that is passed
through query strings or POST operations.  This hash can be added to at will and the
contents of it will be passed from one call to another.  Because session tracking
has been implemented, this is only necessary for passing authentication information back
and forth between browser and server, but can be used for anything else (like session ID if
session tracking is using files).

=head1 METHODS

new
arguments: (str) Application Name
	Creates and returns an instance of the application class.  It detects the
	caller's package name for use with future callback functions, and sets up
	the $app->{data} structure, which contains information submitted to the
	application either through a URL or through a POST request. It also creates
	a basic SW::Panel object that will serve as the basic visual framework for
	the application.

  go  - The go() method takes no arguments.  It is mandatory to call this method
        when any setup has been performed, because the go() method creates the basic
		  application structure, sets up the interface, etc.

  registerCallback - takes a unique (we hope) name and a method reference to the 
			callback in question.  You can get a method reference like this:
			   my $mref = = sub { $obj->method(@_) };  (see Perl Cookbook 11.8)

  callback - takes a name and runs the corresponding method as registered with
		registerCallback.

  getPanel - returns a reference to the main Panel in the application, which can then
        be used to generate display logic.

  getSession - returns a reference to the session object, which is either new
        or has been loaded by the app when it's woken up.

  confirmRenderStyle - as the Renderer.pm class is about to create a specialized renderer
							 it calls up to the app to confirm the style, this allows us to 
							 override the render type with URL arguments.  Takes the Style 
							as determined bny browser detection and receives it back again
							unless there's some change forced from above

  exit - This needs to be called prior to terminating the application, because it takes
        care of fundamental circular references that must be removed or the DESTROY
        function will never be called.

  sessionMethod - returns which method of session tracking the app is using.  This should
        only be used by other SW classes to decide how to rewrite links & forms.
  
  sessionId - returns the session id if the app if using file sessions tracking
               or undef if cookie session 

  addComponent - adds a component to the application's component array. Then, to
                 read values from that component in the future, you only need to
					  use getComponent to retrieve it and then getValue on the component. 

  getComponent - retrieves a reference to a named component

  deleteComponent - removes a component from the system list

  findDataKey - returns a reference to a hash of key/values matching the wanted key

  getUser - returns a reference to the current user object

  getDocuments - returns a list of documents that are currently open

  addDocument - adds a document object to the document list
  
  getDbh - This returns a handle to a currently open, working database.  The
           database will either be the default db, or a database that was requested
			  through the use of a fully qualified object path.  If the object path
			  "DUDE:objects:188" is given, for example, the getDbh() method returns
			  a handle to the database called "DUDE".

	addSessionValue - adds a key/value pair to the current session.  Note that the value
	        can actually be anything, such as an array, a hash, or a complex data structure.

	deleteSessionValue - when passed a key, this removes the key and value completely from
	        the session object.

getDatatypes


=head1 AUTHOR

Kyle Dawkins, kyle@hbe.ca

=head1 SEE ALSO

perl(1).

=head1 REVISION HISTORY

  $Log: Application.pm,v $
  Revision 1.82  1999/11/15 18:17:32  gozer
  Added Liscence on pm files

  Revision 1.81  1999/10/24 17:44:15  gozer
  Email-related fixes

  Revision 1.80  1999/10/18 17:59:50  krapht
  Added SW::Constants, so the apps wouldn't complain about BOLD, and stuff

  Revision 1.79  1999/10/08 23:00:17  gozer
  FIxed a little problem with redirects. now SW::Handler::redirect(url,time)
  redirects you to url in time seconds

  Revision 1.78  1999/10/04 21:04:29  gozer
  lots of small diffs...
  Fixed Handler to be more Apache::Filter nice ... (still the non-existent file problem)
  Now you can access SW::Config stuff anytime (even at start-up use)
  MOdularized some more the SW::User class
  Small minor code fixes all over the place

  Revision 1.77  1999/10/03 18:39:45  scott
  debuggin

  Revision 1.76  1999/09/30 11:38:52  gozer
  Added the support for cookies

  Revision 1.75  1999/09/21 01:05:08  krapht
  Fixed the InitApplication callback

  Revision 1.74  1999/09/21 00:23:33  gozer
  MOdified some more stuff to SW->user and SW->session

  Revision 1.73  1999/09/20 20:43:13  krapht
  It works!!  It works!!  We fixed the problem we had with session.
  _insertSignal had problems, it was setting appState as a global, but it
  really is a private value for each app.

  Revision 1.72  1999/09/20 19:57:47  fhurtubi
  Changed references of $self->{session} to SW->session

  Revision 1.71  1999/09/20 19:51:18  gozer
  Temp fix for the lost DataValues

  Revision 1.70  1999/09/20 14:30:00  krapht
  Changes in most of the files to use the new way of referring to session,
  user, etc. (SW->user, SW->session).

  Revision 1.69  1999/09/19 20:34:42  gozer
  Documented SW.pm and I changed a few more $self->{master} stuff to SW->master

  Revision 1.68  1999/09/17 21:18:16  gozer
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

  Revision 1.67  1999/09/14 01:25:33  gozer
  Little type correction, preparing for the moving of session and user out of master

  Revision 1.66  1999/09/12 13:26:50  krapht
  Changed some stuff (can't remember what, but it's late (actually, it's early!:))
  Added some docs too!

  Revision 1.65  1999/09/12 01:20:44  fhurtubi
  Added the redirection thing in sub cleanup

  Revision 1.64  1999/09/11 21:07:18  jzmrotchek
  Added setPref() and getPref() methods to allow setting & getting of app-specific preference values.  (i.e. app defaults)

  Revision 1.63  1999/09/11 08:44:36  gozer
  Made a whole bunch of little kwirps.
  Fixed Handler to deal correctly with SW_App_Namespace without defaulting to SW::App when the var is set
  Fixed the bug that made Login.pm create an empty hidden argument on every login attempt
  Added a whole bunch of modules preloading in sw-perl-startup, good speed improvment
  Fixed a few warning here and there.  Only one missing the sweep.  Application.pm and AUTOLOAD warning ?!?
  Changed the SW::Util::flatten and circular_flatten to succesfully use Data::Dumper ;-} (-180 lines of code)
  Gone to bed very late

  Revision 1.62  1999/09/03 01:05:36  scott
  Mods so we can remove the site specific configurations info
  (SW::Config) from the framework.

  Revision 1.61  1999/09/01 01:29:23  krapht
  Removed the )($*@&#%*@$#&%) autoloader shit

  Revision 1.60  1999/08/30 20:29:54  krapht
  Removed the Exporter stuff

  Revision 1.59  1999/08/28 03:17:07  scott
  Removed a whole pile of methods from SW::Application that were just going
  $self->{master}->whateverYouJustCalledOnMe(@_).  They now use the autoload
  mechanism.  This makes the code in Application more readble (not to mention
  shorter) and less error prone if these methods are changed in Master.

  Revision 1.58  1999/08/27 20:48:05  krapht
  Changed the addSessionValue to setSessionValue like in Master

  Revision 1.57  1999/08/14 00:20:35  scott
  messing around with debugging

  Revision 1.56  1999/08/13 14:33:51  fhurtubi
  Added getSessionValue method

  Revision 1.55  1999/07/25 02:42:27  scott
  Mostly changes to squash circular reference bugs that were causing
  sessions and applications to linger arouond until server restart
  (thus really messing up the session storage)

  Revision 1.54  1999/07/22 14:21:40  fhurtubi
  Added method findDataKey that gets a wanted key and returns all key/values who's key matches that wanted key

  Revision 1.53  1999/07/19 13:59:01  fhurtubi
  fixed up $self->{data} refs to always refer to {master}

  Revision 1.52  1999/07/19 13:29:19  scott
  Lots of clean-up work, debugged and improved the desctructor calling of all
  copmonents so none should be left lingering after the transaction completes.

  This in turn solved the session problem (destructor wasn't being called
  because it was persisting past the end of the transaction)

  Revision 1.51  1999/07/08 15:45:27  scott
  oops - should have done these separately ...

  Working on changes to the database code for users, groups, and objects

  as well as debugging and signals

  Revision 1.50  1999/06/17 21:46:26  krapht
  Code cleanup

  Revision 1.49  1999/06/10 18:45:24  scott
  Added confirmRenderStyle function to allow overiding the render style from
  a URL argument

  Revision 1.48  1999/05/20 13:51:14  scott
  Changes for the new transaction model

  Revision 1.47  1999/05/05 15:28:14  scott
  *** empty log message ***

  Revision 1.46  1999/05/05 15:26:11  scott
  fixed a bad print

  Revision 1.45  1999/05/04 15:53:15  scott
  -New Apache::Session based database session tracking
  -New debugging scheme

  Revision 1.44  1999/04/22 13:35:07  kiwi
  Added a "getMaster" hack

  Revision 1.43  1999/04/21 09:54:51  scott
  nothing

  Revision 1.42  1999/04/21 08:55:59  kiwi
  *** empty log message ***

  Revision 1.41  1999/04/21 06:04:10  kiwi
  Can now accept an argument "document=" as part of the GET/POST

  Revision 1.40  1999/04/21 05:55:31  scott
  added getURLAppendages to return all appendages as a URL formatted string

  Revision 1.39  1999/04/21 02:48:36  kiwi
  Fixed application to load in SW::Language

  Revision 1.38  1999/04/21 02:01:39  kiwi
  Fixed some more language issues

  Revision 1.37  1999/04/21 01:32:11  kiwi
  Some of the language code, including a "getLanguage" method, has been
  implemented.

  Revision 1.36  1999/04/20 23:27:54  kiwi
  Fixed error in the "new" method that loads a requested doc.  No user was
  being specified for the doc.

  Revision 1.35  1999/04/16 18:08:42  kiwi
  Changed constructor to use named argument hash

  Revision 1.34  1999/04/13 21:56:41  kiwi
  Fixed the callback to validateUser

  Revision 1.33  1999/04/13 16:30:58  scott
  Major changes,  split off Application and master so that run-once stuff
  like sessions, documents, and users are handled by Master.

  Also removed all old style callbacks, all callbacks now use the CODE reference
  method of registering and calling.  This includes developer apps.

  Implemented trickleState and syncState to achieve better control over the
  execution stages of embeddable apps

  Revision 1.32  1999/04/09 18:44:41  kiwi
  Removed reference to "guest" user.  Guests are not, by default,
  allowed to view anything unless restricted within individual apps.
  We will probably change this behaviour later.

  Revision 1.31  1999/03/30 23:16:58  kiwi
  Fixed an error in $self->getDbh() that was not processing full
  database paths correctly (so "FATHER" would work but "FATHER:object:1212"
  would not)

  Revision 1.30  1999/03/29 20:58:17  kiwi
  Updated documentation

  Revision 1.29  1999/03/29 20:48:51  scott
  some work on the callback mechanisms..

  Revision 1.28  1999/03/27 21:50:28  kiwi
  Added "documents" list to app object, to track open documents.
  Fixed save order: first all documents are saved, then the user object

  Revision 1.27  1999/03/19 22:41:30  kiwi
  Added code to save the user object when the transaction completes.

  Revision 1.26  1999/03/17 23:16:55  kiwi
  Changed $app->getDbh() to actually work with different databases.

  Revision 1.25  1999/03/16 00:22:53  kiwi
  Now includes "SW::Config"

  Revision 1.24  1999/03/10 23:20:10  kiwi
  Changed User Authentication slightly

  Revision 1.23  1999/03/09 22:43:31  kiwi
  *** empty log message ***

  Revision 1.22  1999/02/22 15:43:22  kiwi
  Temporarily added callback to "swValidateUser" in the executing application
  but will re-work this to work with scott's new callback system

  Revision 1.21  1999/02/22 00:52:58  scott
  1)  added a $object->visible() method to enable hiding objects
  2)  created TreeView
  3)  implemented an easier, more flexible callback system to facilitate
  	callbacks calling other callbacks and better control over which
  	level of objects get the callbacks.  Also allows argument passing
  	to the callback.

  Revision 1.20  1999/02/18 23:59:15  kiwi
  Added some documentation

  Revision 1.19  1999/02/18 21:00:53  kiwi
  Fixed up the MySQL line for localhost.  Hmmmmm.

  Revision 1.18  1999/02/18 10:42:50  scott
  New GUIElement components - LinkExternal, ListBox, SelectBox, TextBox, RadioButtonSet

  Revision 1.17  1999/02/17 22:49:43  kiwi
  Changed component list so that each sub-app owns its own

  Revision 1.16  1999/02/17 17:07:45  kiwi
  Huge update to Application.pm.
  Application data is now accessed through accessor methods that check for a parent
   (or host) application. If it exists, they pass the call up the hierarchy to the
   parent, which does the same.  This means that all session/appendage/argument data
   remains on the main application object.
  Have also implemented a few stub functions for rendering.

  Revision 1.15  1999/02/15 19:07:35  kiwi
  Added "component" hash on the application object, and "getComponent", "addComponent", and
  "deleteComponent" methods to handle it.

  Revision 1.14  1999/02/12 22:41:19  scott
  removed getArgs()
  added a call to $panel->updateState() in the go method to force all objects
    to adjust their state with the session object
  added ref(caller()) to the beggining of each debug string

  Revision 1.13  1999/02/12 22:31:31  kiwi
  Moved the flatten method to the SW::Util package

  Revision 1.12  1999/02/12 18:58:23  kiwi
  Added some debugging info to dump out the appendages hash.

  Revision 1.11  1999/02/12 17:15:03  kiwi
  FIxed stupid appendages typo.

  Revision 1.10  1999/02/12 17:07:38  kiwi
  Added "appendages" hash.
  Fixed POST problem by parsing command args with CGI::param instead of $r->content.

  Revision 1.9  1999/02/12 00:07:33  kiwi
  Added user checking, $app->cleanup() method, $app->error() method

  Revision 1.8  1999/02/11 22:44:43  kiwi
  *** empty log message ***

  Revision 1.7  1999/02/11 22:38:02  scott
  Modified CallBacks to support either a subclassed application or stand-alone app

  Added sessionId()  to return the session id if in file style session tracking
  and undef if in Cookie style sessions.

  Revision 1.6  1999/02/11 20:58:51  kiwi
  Added initial callback to "swInitApplication".
  Changed callbacks to be prefixed with "swResponse" instead of just "response".

  Revision 1.5  1999/02/11 18:04:24  kiwi
  Added the "addCookie" method to allow for developers to create
  cookies that are transparently passed back and forth between the browser and
  the app.

  Revision 1.4  1999/02/10 23:29:08  kiwi
  *** empty log message ***

  Revision 1.3  1999/02/10 23:17:26  kiwi
  Fixed up some documentation about session tracking.

  Revision 1.2  1999/02/10 23:10:08  kiwi
  Added "getSession" to retrieve a reference to the session hash.

  Revision 1.1.1.1  1999/02/10 19:49:10  kiwi
  SmartWorker

  Revision 1.4  1999/02/10 17:22:24  kiwi
  *** empty log message ***

  Revision 1.3  1999/02/09 22:53:12  kiwi
  Changed the way the application is destroyed, and corrected some docs.

  Revision 1.2  1999/02/09 18:07:07  kiwi
  Added Revision History to heading in perldoc section


=cut
