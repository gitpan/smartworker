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

package SW::Handler;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for internal use only!!
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::Handler;
#  This is a mod_perl handler to replace SW::Registry and also
#  to provide a SW::Handler/ subtree for other funky handlers
#  mapping URI/URL's to specific Apps.
#
#------------------------------------------------------------
#  CVS ID tag...
# $Id: Handler.pm,v 1.49 1999/11/16 20:18:58 scott Exp $
#------------------------------------------------------------

use strict;
use SW::Login;
use SW::Cookie;
use Data::Dumper;
use SW::User::Authz;
use SW::User::Authen;
use SW::Error::ServerError;
use SW;
use File::Basename;
use CGI;
use Data::Dumper;
use Apache::Constants qw(DECLINED NOT_FOUND SERVER_ERROR OK);

use vars qw($VERSION %CACHE $AUTHENF $AUTHZF $LOGIN $handleFileDownload $loginHandler $errorHandler);

$errorHandler = $loginHandler = $SW::Config::LOGIN_HANDLER || 'SW::Login';

foreach my $mod ($loginHandler)
{
	eval "use $mod";
	die __PACKAGE__ . " Couldn't locate $mod at startup $@\n" if $@;
}

$VERSION = '0.03';

sub handler {
	&setSWDieHandler();

	my $r = shift;
	
	my ($AUTHENF ,$AUTHZF ,$LOGIN, $uri, $query) = (0,0,0,$r->uri,new CGI);
	
	undef $handleFileDownload ;
	
	my ($sub, $className, $directory, $basename, $sessionid, @namespace);

   print STDERR "\n==================BEGIN HTTP REQUEST ($$) ==================\n";
	print STDERR "URI: ".$r->uri()."?".$r->args()."\n";
   $r->register_cleanup( sub { print STDERR "\n===================END HTTP REQUEST ($$) ===================\n"; });

	if (defined $SW::Config::COOKIE_NAME)
		{
		SW->setCookie(new SW::Cookie($SW::Config::COOKIE_NAME));
		$r->register_cleanup( sub { SW->destroyCookie });
		}

	SW->setData(&parseData());
	$r->register_cleanup( sub { SW->destroyData; });		
	
	if(defined $SW::Config::COOKIE_NAME)
		{
		$sessionid = SW->cookie->getValue('sessionid');
		}
	else
		{
		$sessionid = SW->data->{'SESSION_ID'};
		}	
	
	#create the session
	SW->setSession(new SW::Session($sessionid));
	$r->register_cleanup( sub { SW->destroySession; });
	
	if(defined $SW::Config::COOKIE_NAME)
		{
		SW->cookie->setValue('sessionid',SW->session->getSessionID) if not defined SW->cookie->getValue('sessionid');
		}

# check for special uris here!

	if (! ($className = isSpecialUri($r)))
	{
		# is there something sitting on the stack now?
		if (SW->session->stackPeek())
		{
			$className = SW->session->stackPeek()->[0];
		}
		else
		{
			$className = getClassName($r, $basename, \@namespace);
      	return $className if ($className == DECLINED || $className == NOT_FOUND );
			die if $className == SERVER_ERROR;
		}
	}
	
	
   	print STDERR "Handler ClassName =  $className\n";
 
	#register the current user to SW
	SW->setUser(new SW::User());
	$r->register_cleanup( sub { SW->destroyUser; });
	
	#file-request ?? if so, serve it right away
	if($handleFileDownload)
		{
		my %args = $r->args;
		
		my $fileid = $args{'fileid'};
		my $owner = $args{'owner'} || SW->user->getUid();
		
		my ($content,$content_type) = SW::Data::File::_get_file($owner,$fileid);
		
		return NOT_FOUND if (not defined $content || $content == NOT_FOUND);

		$r->send_http_header($content_type || 'application/octet-stream');
		print $content;
		
		return OK;
		}
	
	#bad username/password...
	if(SW->user->authenticate->failed)
		{ $AUTHENF = 1;}
	 
	 if (! SW->user->authorize($className)->granted )
      { 
         if(SW->user->authorize->could_try_login)
				{
				$LOGIN=1;			
				}
			else
				{
         	$AUTHZF=1;
				}
      }  
		 
		#Transaction checking stuff  .. read on...there is a lost child on line 176
		transactionStuff() unless ($AUTHENF or $AUTHZF);
		  
		#filter stuff, should be moved but will be ok for now
		$r->content_type('text/html');
		
		#disable caching
		my $headers = $r->headers_out;
		$headers->{'Pragma'} = $headers->{'Cache-control'} = 'no-cache';
		
		SW->cookie->send() if (defined $SW::Config::COOKIE_NAME);  	

		if ($r->header_only)
			{
			#HEAD requests, should be checked by Apache::Filter though...
			$r->send_http_header();
			return OK;
			}



		if (Apache->can('filter_input'))
			{
			$r->filter_input();
			}	
		else
			{
			$r->send_http_header();
			}		
	
		if ($LOGIN)
			{
			no strict 'refs'; #From string to function name#
         	my $result = &{$loginHandler ."::handler"}($r);
         	use strict 'refs';
			return $result;
			}	
		elsif ($AUTHENF)
			{
			no strict 'refs'; #From string to function name#
         	my $result = &{$errorHandler ."::authenFailure"}($r);
         	use strict 'refs';
			return $result;
			}
		elsif ($AUTHZF)
			{
			no strict 'refs'; #From string to function name#
         	my $result = &{$errorHandler ."::authzFailure"}($r);
         	use strict 'refs';
			return $result;
			}
		
		if (! exists $CACHE{$className})
      	{
      
      		$CACHE{$className} = eval <<"EOS";
				
				package $className;
				sub {
				my \$master = SW->master;
				my \$app = $className->new("SmartWorker", SW->master);
				\$master->setChild(\$app);
				\$master->go();
				\$app = undef;
				}
EOS
;
			}
			
     if($@) {
			#something went wrong, most likely in SW::*
			warn "SW::Handler calling SW::Master failed : $@";
			$CACHE{$className}="ERROR"; # so we remember it fails for later
			die;
			}
			
		SW->setMaster(new SW::Master($className)); 
		$r->register_cleanup( sub {SW->destroyMaster;});  
	
		#shouldn't be here, but it's an improvement.
		SW->master->addAppendage("TRANSACTION_ID", SW->data->{'TRANSACTION_ID'});
		
		unless(defined $SW::Config::COOKIE_NAME)
			{
			SW->master->addAppendage("SESSION_ID",SW->session->getSessionID);
			}
			
		&{$CACHE{$className}};		
return;
}	



sub redirect {
	my ($location,$time) = @_;
	$location ||= '/';
	$time ||= 0;
	print qq|<HTML><HEAD><META HTTP-EQUIV="REFRESH" CONTENT=$time;URL=$location></HEAD></HTML>|;
	}

sub find_mod {
	my $basename = shift;
	my $className;
	foreach my $prefix ( @_ )
		{
	  	#try all the configured prefix for a match, resorting to SW::App:: if all else fails.
	  	$className = $prefix . "::" . $basename;
	  
	  	if (!defined $CACHE{$className}) #this is something new
	  	{ 
	  	#do a few things we need to do only once in the callee namespace
		print STDERR "Checking $className\n";
		
		if ($className !~ /^(\w+)(::\w+)*$/)
			{
			#bye bye script kiddies !
			die "WARNING: Bogus package attempt with $className";
			}
		
		eval "use $className";
	      
      #this converts the module name in a relative pathname to check it against $@ to make sure
      #it's our module that was not found, not one that's used in our module.  sic.
      my $use_path_name = $className;
      $use_path_name =~ s/::/\//g;
		
		next if($@ =~ /^Can\'t locate\s+$use_path_name/);
			
		if($@){
			warn "SW::Handler : App [$basename] failed it's compile tests : $@";
			die;
			}
		
		}
		return $className;
	}
	return NOT_FOUND;
}


sub isSpecialUri
{
	my $r = shift;
	my $uri = $r->uri;

	my $className;
	
	#handle file serving
	if (defined $r->dir_config('download') && SW::Data::File::canGetFile())
		{
		$handleFileDownload = $r-args;
		return $handleFileDownload;
		}
	
	if ( $uri =~ /\/apps\/launch\/(.*)/ )
		{
		$className = $1;
		}
	elsif ( $uri =~ /\/stack\/push\/(.*)/ )
		{
		$className = $1;
		SW->session->stackPush($className, SW->data);
		}
	elsif ( $uri =~ /\/stack\/pass\/(.*)/ )
		{
		$className = $1;
		SW->session->stackPass($className, SW->data);	
		}
	elsif ( $uri =~ /\/stack\/return/ )
	{
		my $row = SW->session->stackPop();
		$className = $row->[0];
 		my $args = $row->[1];
 		for (my $x=0; $x<=$#$args; $x++)
 		{
 			SW->data->{$args->[0]} = $args->[1];	
 		}
	}
	elsif ( $uri =~ /\/stack/ )
		{
		$className = SW->session->stackPeek()->[0];	
		}
	else
		{
		return undef;
		}
	
	if ($className !~ /^(\w+)(::\w+)*$/)
			{
			#bye bye script kiddies !
			die "WARNING: Bogus package attempt with $className";
			}
	eval "use $className";
	return $className;

}


sub getClassName
{
	my $r = shift;
	my $basename = shift;
	my $namespace = shift;
	my @namespace = @$namespace;
	my $directory;
	my $uri = $r->uri;
	my $filename = $r->filename;

	my $filesmatch = (join '|', (split /\s+/, $r->dir_config("SW_App_Extension"))) || 'pm' ;

	print STDERR "filesmatch - $filesmatch\nfilename - $filename\n";

	#check if we are faced with a module file like we should
	return DECLINED if ($filename !~ /\.($filesmatch)$/);

	#in the end, everythings gets translated to a module
	$filename =~ s/\.($filesmatch)$/\.pm/;

	#we do not check if the filename exists, now we simply
	#translate the URI in the appropriate module name
	# i.e. http://www.host.com/Whatever.sw => SW::App::Whatever.pm
	# That means one could use a whole bunch of virtual URIs with access
	# control over the apps 


	my @append = split "\s+" , $r->dir_config("SW_App_Namespace");
	#proivde a default prefix to try.
	push @append, "SW::App";
	#this is supposed to be portable.
	$directory = dirname($filename);
	$basename = basename($filename, '.pm');

	if ($r->dir_config("SW_App_Namespace")) {
		@namespace = ( split /\s+/ , $r->dir_config("SW_App_Namespace") ) 
		}
	else {
		@namespace = ( "SW::App" );
		}

	return find_mod($basename, @namespace);
}	

sub transactionStuff {
#BACK BUTTON CHECKER MOVE HERE by gozer so it makes session master independent

	my $returnedTransId=SW->session->getGlobalValue("TRANSACTION_ID"); 
	
	my $currentTransId = SW->data->{"TRANSACTION_ID"};

	if ($returnedTransId eq "") { # 1st call probably
		print STDERR " [BACK] WELCOME NEW USER";
	} elsif ($returnedTransId ne $currentTransId) { 
		print STDERR " [BACK] OH OH!!! BACK BUTTON ERROR!!! ($returnedTransId -> $currentTransId)";
		#return;
	} else {
		print STDERR " [BACK] GOOD USER ($returnedTransId -> $currentTransId)";
	}

	#THIS SHOLD BE REMOVED

	SW->data->{"TRANSACTION_ID"} = SW::Util::randomString();
	
	SW->session->setGlobalValue('TRANSACTION_ID',SW->data->{"TRANSACTION_ID"});
	
	#END BACK BUTTON CHECKER
return;
}

#This should me moved somewhere else
sub parseData {
	my $data = {};
	my @params = CGI::param();

	foreach my $k (@params)
	{
		my @tmp_array = CGI::param($k);
			
		# either return array or scalar, now need to find a way to getValue easily!
		$data->{$k} = (@tmp_array > 1) ? [@tmp_array] : shift (@tmp_array);
	}
return $data;
}

1;    # All perl module must return true at the completion of loading
__END__

=head1 NAME

SW::Handler - Apache Handler for SmartWorker Apps

=head1 SYNOPSIS

   <FilesMatch "\.(pl|sw)">
   SetHandler perl-script
   PerlHandler SW::Handler;
   #PerlSetVar SW_App_Namespace "Name::Space1 Name::Spave2"
   Options +ExecCGI	
   </FilesMatch>
   
=head1 DESCRIPTION

This is a mod_perl handler dealing with actual invocation of an App.  If the URI it's acting
upon can be mapped to a module in the SW::App hierachy, it will launch that application.

There is no need to put the App .pm files and subclasses into a publicly avaliable htdoc space. 
It gives a way to configure more tightly what Applications can and can't be called (thru
Apache access restrictions).  And it removes all the helper .pm modules that you could click on 
and produce unpredictable and messy behaviour.

Currently it will map both .pm and .sw files.  And the namespace they are searched under is SW::App
by default, but you can add other namespaces to search in with the SW_App_Namespace PerlVar.  For example,
with SW_App_Namespave set to "Name::Space1 Name::Space2" the request http://host/apps/MyApp.pm will
result in the followings attempts Name::Space1::MyApp, Name::Space2::MyApp and in last resort, 
SW::App::MyApp.

It will report compilation failures thru a Server Error message, checks the logs for more information.

There is the idea to provide for more special mapping facilities thru DBI, DBM, etc and as soon
as they exist they will populate the SW::Handler::* namespace.

=head1 METHODS

  handler - default mod_perl routine.  It declines anything but .pm and .sw files (should be changed).

=head1 PARAMETERS

PerlSetEnv

=head1 AUTHOR

Philippe M. Chiasson
HBE	gozer@hbe.ca
Sept 2/1999

=head1 REVISION HISTORY

  $Log: Handler.pm,v $
  Revision 1.49  1999/11/16 20:18:58  scott
  fixed my debugging line

  Revision 1.48  1999/11/16 20:12:18  scott
  changed debugging message to $r->uri

  Revision 1.47  1999/11/15 22:20:39  scott
  added a URI line to the debugging

  Revision 1.46  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.45  1999/11/15 07:40:20  gozer
  Some more code movement

  Revision 1.44  1999/11/15 00:02:57  gozer
  MOved some OD specific stuff out of SW

  Revision 1.43  1999/11/14 02:22:14  gozer
  Fixed most of the problems with cookies

  Revision 1.42  1999/11/12 23:28:32  gozer
  Fixed a few errors related to the dir structure change of the HTML

  Revision 1.41  1999/11/12 22:15:09  gozer
  OUpss. fixed recursive logout

  Revision 1.40  1999/11/11 07:13:24  gozer
  Cookie sends the cookie only if necessary
  Handler returns a 404 when handling the get of a file that isn't on the file server
  User - added the change of username call SW->user->authen->setName("NewName");

  Revision 1.39  1999/11/04 20:48:24  gozer
  TOward complete working file sharing
  Added mime-type finding thru mime-magic

  Revision 1.38  1999/10/23 22:00:47  gozer
  cvs bug

  Revision 1.36  1999/10/23 04:38:15  gozer
  Errors are handled still a bit better

  Revision 1.35  1999/10/22 22:24:43  gozer
  Log filtering and better error handling

  Revision 1.34  1999/10/21 22:18:32  gozer
  Added new error messages, very nice looking :-)

  Revision 1.33  1999/10/21 21:56:07  gozer
  SOme abstraction of file serving (FileServer)

  Revision 1.32  1999/10/16 06:33:43  gozer
  Added some more error trapping

  Revision 1.31  1999/10/14 16:32:41  gozer
  Fixed 1-2 little typos

  Revision 1.30  1999/10/14 01:11:07  gozer
  Added the needed options to the popp-up code, but as it grew, I realized it was badly planned.
  It works right now, but I already have a rewrite in mind.  Nice and clean.  But for now, crude but functionnal :-)

  Revision 1.28  1999/10/08 23:00:17  gozer
  FIxed a little problem with redirects. now SW::Handler::redirect(url,time)
  redirects you to url in time seconds

  Revision 1.27  1999/10/07 02:31:59  krapht
  Modified the moment the http_headers were sent, so it will work even if no
  Handler chaining takes places and if Apache::Filter is not 'use'd
  	- gozer (impersonating krapht)

  Revision 1.26  1999/10/04 21:04:29  gozer
  lots of small diffs...
  Fixed Handler to be more Apache::Filter nice ... (still the non-existent file problem)
  Now you can access SW::Config stuff anytime (even at start-up use)
  MOdularized some more the SW::User class
  Small minor code fixes all over the place

  Revision 1.25  1999/09/30 11:38:52  gozer
  Added the support for cookies

  Revision 1.24  1999/09/28 15:03:16  scott
  Begginings of the stack implementation

  Revision 1.23  1999/09/21 16:09:03  gozer
  Added a Launching ability to SW::Handler, you can now call a specific package name with
  /apps/launch/SW::App::AppTest

  Revision 1.22  1999/09/19 20:34:42  gozer
  Documented SW.pm and I changed a few more $self->{master} stuff to SW->master

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

  Revision 1.18  1999/09/13 22:28:23  gozer
  Fixed something wrong with master DESTRUCTION that caused memory leaks until the server ended
  Added the SW->master method that returns the current $master

  Revision 1.17  1999/09/12 18:59:40  gozer
  EMERGENCY UPDATE BEFORE MY MACHINES CRASHES FOR REAL

  Moved user Authorization outside everything and inside it's own package SW::User::Authz
  The swValidateUser should be removed from the code now.
  Removed login info from smartworker.conf, not needed anymore
  added $SW::CONFIG::LOGIN_HANDLER = "SW::Login"
  added to the new SW::App::Admin::Applications so you can edit the access privlieges for your app in there

  Revision 1.16  1999/09/11 08:44:36  gozer
  Made a whole bunch of little kwirps.
  Fixed Handler to deal correctly with SW_App_Namespace without defaulting to SW::App when the var is set
  Fixed the bug that made Login.pm create an empty hidden argument on every login attempt
  Added a whole bunch of modules preloading in sw-perl-startup, good speed improvment
  Fixed a few warning here and there.  Only one missing the sweep.  Application.pm and AUTOLOAD warning ?!?
  Changed the SW::Util::flatten and circular_flatten to succesfully use Data::Dumper ;-} (-180 lines of code)
  Gone to bed very late

  Revision 1.15  1999/09/10 23:31:51  gozer
  I made another change in SW::Handler, now it takes a configurable argument as to
  the filenames it will translate into an Application package name :

  PerlSetVar SW_App_Extension "pm sw long-extension"

  Revision 1.14  1999/09/07 20:03:13  fhurtubi
  The foreach shouldnt be there. Right now, Scott added a last command at the end of it...

  Revision 1.13  1999/09/06 19:45:33  gozer
  Fixed the Not_Found error when a module failed it's compile tests because
  a module it use'd wasn't found . sic.

  Revision 1.12  1999/09/05 15:40:31  gozer
  *** empty log message ***

  Revision 1.11  1999/09/05 02:31:55  gozer
  Added PerlSetVar SW_App_Namespace to allow searching for modules in more than the
  default namespave of SW::App

  Revision 1.8  1999/09/04 18:39:16  gozer
  Fixed so that a module that isn't found returns NOT_FOUND but one that doesn't
  comiple right returns a SERVER_ERROR

  Revision 1.7  1999/09/02 20:40:11  gozer
  Return Not_found in case of error since Server_error triggers zero-byte send

  Revision 1.6  1999/09/02 20:35:36  gozer
  NOT_FOUND works better

  Revision 1.5  1999/09/02 20:34:42  gozer
  *** empty log message ***

  Revision 1.4  1999/09/02 20:33:12  gozer
  handling of use errors

  Revision 1.3  1999/09/02 20:31:34  gozer
  Fixed

  Revision 1.2  1999/09/02 19:54:15  gozer
  Now deals correctly with the new namespace

  Revision 1.1  1999/09/01 22:10:04  gozer
  Added initial version of SW::Registry replacement

  Revision 1.1  1999/06/11 19:24:00  scott
  new file
   
=head1 SEE ALSO

perl(1).

=cut
