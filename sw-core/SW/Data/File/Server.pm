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

package SW::Data::File::Server;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::Data::File::Server
#   stores/retrieves and provide access to files stored on an
#   HTTP FileServer
#------------------------------------------------------------
# $Id: Server.pm,v 1.11 1999/11/15 21:37:44 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);
use SW::Data;
use SW::Util;
use SW::DB;
use Apache::Constants;
use LWP::UserAgent;
use SW::Cookie;
use DBI;
use Data::Dumper;

@ISA = qw(SW::Data);

$VERSION = '0.01';

print STDERR "Using FileServer $SW::Config::FILESERVER\n" if $SW::Config::FILESERVER;

sub storeFile {
		my ($class,$user,$file,$contents) = @_;
		my $token = SW::Util::randomString(); 

		if(SW::DB::getDbh()->do("insert into mysql_auth (uid,token) values( '$user', PASSWORD('$token'))"))
			{		
			unless(_fileTransfer('PUT',$file, $user, $token , $contents))
				{
				print STDERR "SW::Data::File - Error sending file to $SW::Config::FILESERVER\n";
				SW::DB::getDbh()->do("delete from mysql_auth where uid='$user'");
				return 0;
				}
			SW::DB::getDbh()->do("delete from mysql_auth where uid='$user'");
			return 1;
			}
		else
			{
			print STDERR "SW::Data::File::Server - Cannot do authen query for FileServer $SW::Config::FILESERVER\n";
			return 0;
			}
}

sub getUri {
	my ($class,$fileid) = @_;
	my $filename 	= SW::Data::getInfoFromID($fileid)->{name};
	my $owner 		= SW::Data::getInfoFromID($fileid)->{owner};
	my $url = "$SW::Config::FILESERVER_HANDLER_LOC/$filename?fileid=$fileid&owner=$owner";
	return $url;
}


#---------------------------------------------------
# getFileType
#
# this returns the file-type
#
#---------------------------------------------------
sub getFileType {
	my ($class,$user,$file) = @_;
	my $token = SW::Util::randomString();
	my $content;
	my $content_type = 'application/octet-stream';

	if(SW::DB::getDbh()->do("insert into mysql_auth (uid,token) values ($user,PASSWORD('$token'))"))
			{		
			unless(($content,$content_type) = _fileTransfer('HEAD',$file, $user, $token))
				{
				print STDERR "SW::Data::File - Error getting file to $SW::Config::FILESERVER\n";
				}
			}
		else
			{
			print STDERR "SW::Data::File::Server - Cannot do authen query for FileServer $SW::Config::FILESERVER\n";
			}
	SW::DB::getDbh()->do("delete from mysql_auth where uid='$user'");
	
	
	print STDERR "IT is clear the file $file is $content_type\n";
				
	return $content_type;
}
#---------------------------------------------------
# getFile
#
# this handler retrieves the file and sends it back to the client
#
#---------------------------------------------------
sub getFile {
	my ($class,$user,$file) = @_;
	my ($content,$content_type);
	my $token = SW::Util::randomString();

	my $query = "SELECT groupid FROM dataaccess where id=$file and groupid is not null";
	my $sth = SW::DB::getDbh()->prepare($query);
	$sth->execute();
	my $groupid = $sth->fetchrow;

	print STDERR "SW::getFile  $user,$file,$groupid\n";

		if(SW::DB::getDbh()->do("insert into mysql_auth (uid,token) values ($user,PASSWORD('$token'))"))
			{		
			unless(($content,$content_type) = _fileTransfer('GET',$file, $user, $token))
				{
				print STDERR "SW::Data::File - Error getting file to $SW::Config::FILESERVER\n";
				SW::DB::getDbh()->do("delete from mysql_auth where uid='$user'");
				return NOT_FOUND;
				}
			SW::DB::getDbh()->do("delete from mysql_auth where uid='$user'");
			}
		else
			{
			print STDERR "SW::Data::File::Server - Cannot do authen query for FileServer $SW::Config::FILESERVER\n";
			return NOT_FOUND;
			}
	return wantarray ? ($content,$content_type) : $content;
}
#---------------------------------------------------
# _fileTransfer
#
# INTERNAL USE ONLY
#
# Sends/Retrieves/Delete a file stored on an HTTPFileServer
#---------------------------------------------------

sub _fileTransfer {
	my ($action,$filename, $user, $pwd, $content) = @_;
	my $url = "http://$SW::Config::FILESERVER/$user/$filename";
	
	my $ua = new LWP::UserAgent;
	$ua->agent("OpenDeskFileAgent/0.1 " . $ua->agent);
	$ua->credentials($SW::Config::FILESERVER, $SW::Config::FILESERVER_REALM, $user, $pwd);
	
	my $req = new HTTP::Request uc $action => $url;
	$req->content($content) if $action eq 'PUT';

	# Pass request to the user agent and get a response back
	my $res = $ua->request($req);

	# Check the outcome of the response

	if ($res->is_success) 
		{
		return wantarray ? ($res->content,$res->header('content-type')) : $res->content;
		} 
	else 
		{
		return undef;
		}
}
1;    

__END__

=head1 NAME

SW::Data::File::Server -  stores/retrieves and provide access to files stored on an HTTP FileServer

=head1 SYNOPSIS


=head1 DESCRIPTION

=head1 METHODS

=head1 PARAMETERS

=head1 AUTHOR

Philippe M. Chiasson
HBE	gozer@hbe.ca
Oct 21/99

=head1 REVISION HISTORY

  $Log: Server.pm,v $
  Revision 1.11  1999/11/15 21:37:44  gozer
  - some debugging stuff left

  Revision 1.10  1999/11/15 21:35:43  gozer
  removed the ref self stuff in getURI

  Revision 1.9  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.8  1999/11/15 00:03:43  gozer
  File::MMagic added for mime/type detection

  Revision 1.7  1999/11/08 22:01:53  gozer
  Changed a bit of SQL to allow for future table modification for garbage collection of one-time-auth-tokens

  Revision 1.6  1999/11/04 20:48:24  gozer
  TOward complete working file sharing
  Added mime-type finding thru mime-magic

  Revision 1.5  1999/10/26 15:49:56  gozer
  SOme little typos..

  Revision 1.4  1999/10/24 01:49:06  gozer
  Forgot one instance of $sessionid, damnit

  Revision 1.3  1999/10/24 01:45:10  gozer
  Changed to use MYSQL PASSWORD() fctn

  Revision 1.2  1999/10/23 22:01:25  gozer
  Fixed file download with File::Server, now you can click on any file, it will either show it or prompt to save it (with the right filename)

  Revision 1.1  1999/10/21 21:56:46  gozer
  Added 2 modules for file save/get


=head1 SEE ALSO

perl(1), SW::Data::File(3) SW::GUIElement::FileUpload(3)

=cut

