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

package SW::Data::File;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::Data::File
#   smartworker flat file data type 
#------------------------------------------------------------
# $Id: File.pm,v 1.40 1999/11/15 22:33:50 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA $storage);
use SW::Data;
use SW::DB;
use SW::Data::File::Server;
use DBI;

use CGI qw(:standard);

@ISA = qw(SW::Data);

$VERSION = '0.50';

sub TABLE_NAME     () {'files'}
sub PRIMARY_KEY    () {'fileid'}
sub DATA_TYPE      () {'FILEURI'}

# This value is a flag to remember if we expanded the maximum file size
# properly (as specified in the config file)
$SW::Data::File::sizeExpanded = 0;


#sub MIMETYPE_FILEPATH() {}
$storage =	$SW::Config::FILE_STORAGE_MODULE	|| 'SW::Data::File::Basic';
foreach my $mod ($storage)
{
	eval "use $mod";
	die "SW::User Couldn't locate $mod at startup $@\n" if $@;
}


#------------------------------------------------------------
#  new  - assumes an uploaded file
#------------------------------------------------------------
sub new
{
	my ($classname,$app,$filename,$datatype,$appid) = @_;
	if (!$datatype) { $datatype = DATA_TYPE; }

	if(!$filename) { 
		print STDERR "Error!  No filename specified!\n";
		return undef; 
	}

	if($SW::Config::MAX_FILE_SIZE && !$SW::Data::File::sizeExpanded)
	{
		_expand_filesize();
	}

	my $user_id = SW->user->getUserId();
	my $contents;
	my $size = 0;

	my $buffer;

	my $bytes;
	my $mime_type;

	if($bytes = read ($filename, $buffer, 8092))
		{
		$contents .= $buffer;
		$size += $bytes;

		use File::MMagic;
		my $mm = new File::MMagic($SW::Config::MIME_MAGIC);
		$mime_type = $mm->checktype_contents($buffer);
		}
	
	while($bytes = read ($filename, $buffer, 1024))
	{
		$contents .= $buffer;
		$size += $bytes;
	}

	if(!$contents) { return; }

	# Don't accept files larger than the maximum file size

	if($SW::Config::MAX_FILE_SIZE && ($size > $SW::Config::MAX_FILE_SIZE)) { return; }

	my $du = SW->user->getDiskUsage();

	# Prevent users from uploading more than their quota
	if(($du+$size) > SW->user->getQuota()) { return; }

	$filename =~ s/.*\\(.*)/$1/;  # Strips out Windoze client filepaths.
	$filename =~ s/ /_/g;         # Strips out ugly space in filenames.

	#Defangs other nasty characters
	$filename =~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;

	print STDERR "##########  Demunged filename: $filename  ###########\n";

	my $exist_query  = <<"EOQ";
select a.id from datamap a,datainfo b, dataaccess c where a.id=b.id=c.id
and creator=\'$user_id\' and name=\'$filename\'
EOQ
; 

	my $check_sth = (getDbh())->prepare($exist_query) ||
			warn "Error! Couldn't prepare query: $exist_query";

	$check_sth->execute || warn "Error! Couldn't execute query: $exist_query";

	my $id;

	my $self;

	if ($check_sth->rows == 0)
	{
		$self = $classname->SUPER::new($app,'',$datatype);
	}
	else
	{
		$id = $check_sth->fetchrow_array;
		$self = $classname->SUPER::new($app,$id,$datatype);
	}

	my $file_mimetype;

	my $file_extension = $filename;
	$file_extension =~ s/.*\.(.*)$/$1/;
	$file_extension = lc($file_extension);
	
	$self->setStorage('filed', "N");

	$self->setName($filename);

	#this can only be checked after the file has been written
	print STDERR "Assigning $mime_type to this file";
	$self->setMimeType($mime_type);

	if ($contents)
		{
		_write_file($user_id,$self->getObjectId(),$contents);
		}
		
	

	SW->user->setDiskUsage($du+$size);

	return $self;
}


#------------------------------------------------------------
# importFile  - push a file in from an existing file handle   (Mail Attachments)
#------------------------------------------------------------

sub importFile
{	use Data::Dumper;
	my ($classname,$app, $args) = @_;

	if (ref($args) ne "HASH")
	{
		print STDERR "Error importFile should be called with the args: app, hashref_to_arguments\n";
		return undef;
	}

	my $filename = $args->{filename};
	my $datatype = $args->{datatype};
	my $appid = $args->{appid};
	my $io_handle = $args->{io_handle};
	my $mime_type = $args->{mime_type};

	if (!$datatype) { $datatype = DATA_TYPE; }

	if(!$filename) { 
		print STDERR "Error!  No filename specified!\n";
		return undef; 
	}

	if($SW::Config::MAX_FILE_SIZE && !$SW::Data::File::sizeExpanded)
	{
		_expand_filesize();
	}

	my $user_id = SW->user->getUserId();
	my $contents;
	my $size = 0;

	my $buffer;

	my $bytes;
	my $mimeType;

	if($bytes = $io_handle->read ($buffer, 8092))
		{
		$contents .= $buffer;
		$size += $bytes;

		use File::MMagic;
		my $mm = new File::MMagic($SW::Config::MIME_MAGIC);
		$mimeType = $mm->checktype_contents($buffer);
		}
	
	while($bytes = $io_handle->read ($buffer, 1024))
	{
		$contents .= $buffer;
		$size += $bytes;
	}
	 $io_handle->close                  || die "close I/O handle: $!";

	if(!$contents) { 
		print STDERR "Error! no content received\n";		
		return; 
	}

	print STDERR "Comparing mime-types ($mime_type)($mimeType [magic])";

	# Don't accept files larger than the maximum file size

	if($SW::Config::MAX_FILE_SIZE && ($size > $SW::Config::MAX_FILE_SIZE)) { return; }

	my $du = SW->user->getDiskUsage();

	# Prevent users from uploading more than their quota
	if(($du+$size) > SW->user->getQuota()) { return; }

	#Defangs other nasty characters
	$filename =~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;

	print STDERR "##########  Demunged filename: $filename  ###########\n";

	my $exist_query  = <<"EOQ";
select a.id from datamap a,datainfo b, dataaccess c where a.id=b.id=c.id
and creator=\'$user_id\' and name=\'$filename\'
EOQ
; 

	my $check_sth = (getDbh())->prepare($exist_query) ||
			warn "Error! Couldn't prepare query: $exist_query";

	$check_sth->execute || warn "Error! Couldn't execute query: $exist_query";

	my $id;

	my $self;

	if ($check_sth->rows == 0)
	{
		$self = $classname->SUPER::new($app,'',$datatype);
	}
	else
	{
		$id = $check_sth->fetchrow_array;
		$self = $classname->SUPER::new($app,$id,$datatype);
	}



	my $file_mimetype;

	my $file_extension = $filename;
	$file_extension =~ s/.*\.(.*)$/$1/;
	$file_extension = lc($file_extension);
	
	$self->setStorage('filed', "N");

	$self->setName($filename);

	if ($contents)
		{
		_write_file($user_id,$self->getObjectId(),$contents);
		}
		
	#this can only be checked after the file has been written
	$self->setMimeType($mime_type);

	SW->user->setDiskUsage($du+$size);

	return $self;
}


#-----------------------------------------------------
# setMimeType - method
#
# Sets the value of the MIME type in the database to
# the argument string, or to the value returned by
# the getFileType method, if the argument is empty.
#
# Returns the object;
#-----------------------------------------------------

sub setMimeType
{
	my ($self,$type, $userid) = @_;
	my $id = $self->getObjectId();
	my $dbh = getDbh();

	$userid	||= SW->user->getUserId();
	
	$type	||= ($storage->can('getFileType')) ? $storage->getFileType($userid,$id) : 'application/octet-stream';

	$type = $dbh->quote($type);

	$id = SW::Data::getRealID($id);

	my $cmd = "UPDATE files SET mimetype=$type WHERE id=$id";

	$dbh->do($cmd) ||
			SW::debug($self,"setMimeType: error doing query $cmd",1);

	return $self;
}


#-----------------------------------------------------
# getMimeType - method
#
# Needs some work!
#-----------------------------------------------------

sub getMimeType
{
	my ($self) = @_;

	my $type = "foo/bar";

	return $type;
}


#-----------------------------------------------------
# delete - method
#
# Work in progress that will take care of subtracting
# the size of the file from the current disk usage of
# the user.
#-----------------------------------------------------

#sub delete
#{
#	my ($self) = @_;
#
#	my $du = SW->user->getDiskUsage();
#	my $fs = stat();
#
#	SW->user->setDiskUsage(($du-$fs));
#}


#-----------------------------------------------------
# get_uri
#
# Does a select in the files tables in the DB to get
# the uri value associated with the id passed
#
# Returns the uri associated with a particular file
# that was previously uploaded.
#-----------------------------------------------------

sub get_uri
{    
	my ($self,$fileid) = @_;
	print STDERR "Called ($self,$fileid)";

	return $storage->getUri($fileid) if(! ref($self));
	return $storage->getUri($self->{id});
}
#-----------------------------------------------------
# getFileType
#
# returns the mime-type of a file
#-----------------------------------------------------

sub getFileType
{    
	my ($self,$fileid) = @_;
	return $storage->can('getFileType') ? $storage->getFileType($fileid) : 'application/octet-stream';
}

#---------------------------------------------------
# _write_file
#
# INTERNAL USE ONLY
#
# Writes file to the disk.
#---------------------------------------------------

sub _write_file
{
	my ($user,$id,$contents) = @_;
	print STDERR "User is $user, id is $id\n";

	$storage->storeFile($user,$id,$contents);
}

#---------------------------------------------------
# _get_file
#
# INTERNAL USE ONLY
#
# Writes file to the disk.
#---------------------------------------------------

sub canGetFile
{
	return $storage->can('getFile');
}
	

sub _get_file
{
	my ($user,$id,$contents) = @_;
	return $storage->getFile($user,$id); 	
}



#---------------------------------------------------
# _expand_filesize - function
#
# Checks the format of SW::Config::MAX_FILE_SIZE to
# make sure any K (for kilobytes) and M (megabytes)
# symbols have been replaced by the right value!
#---------------------------------------------------

sub _expand_filesize
{
	if($SW::Config::MAX_FILE_SIZE =~/^[0-9]+K$/i)
	{
		$SW::Config::MAX_FILE_SIZE =~ s/K//i;

		$SW::Config::MAX_FILE_SIZE *= 1024;
	}
	elsif($SW::Config::MAX_FILE_SIZE =~ /^[0-9]+M$/i)
	{
		$SW::Config::MAX_FILE_SIZE =~ s/M//i;
		$SW::Config::MAX_FILE_SIZE *= (1024 * 1024);
	}

	$SW::Data::File::sizeExpanded = 1;
}







1;    

__END__

=head1 NAME

SW::Data::File - Stores data to file and reference to file in database.

=head1 SYNOPSIS

    $file = new SW::Data::File($self,$filename_parameter)
               where
    $self                = The calling app object.
    $filename_parameter = The name of the widget that the filename is entered into.

=head1 DESCRIPTION

WARNING:  One of the critical weaknesses of this component is that it's only as
good as the Apache mime.types table that it reads from.  A developmental example;
the default mime.types file that the development server used didn't have a mime
type defined for .exe files, and so saved the default 'text/html' encoding.   

=head1 METHODS

new($app,$filename_parameter) : Creates a new file object (or fetches info on a previously
                                created one), saves (or updates) database information about
                                the object, and writes the object to file if the request contains
                                a multipart/form-data encoded file.

get_uri($filename,[$uid])     : Gets the URI required to be passed to the file retrieval handler
                                in order to access the file.

=head1 PARAMETERS

$app                : The SW application object calling the method.
$filename_parameter : The parameter name of the file upload widget. (SW::GUIElement::FileUpload)
$filename           : The user-supplied name of the file.
$uid                : The SW user id of the file uploader.  Only neccessary if being called for a
                      file that is owned by another SW user.  

=head1 AUTHOR

John F. Zmrotchek
HBE	zed@hbe.ca
Aug 31/99

=head1 REVISION HISTORY

  $Log: File.pm,v $
  Revision 1.40  1999/11/15 22:33:50  gozer
  FIxed the method/fuction call of getUri

  Revision 1.39  1999/11/15 21:35:40  gozer
  removed the ref self stuff in getURI

  Revision 1.38  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.37  1999/11/15 16:19:09  gozer
  2 minor glitches fixed (language error on new login, SW::Data::File errro when calling getfileUri)

  Revision 1.36  1999/11/15 00:03:19  gozer
  Added File::MMagic to find out mime-types on the fly during download

  Revision 1.35  1999/11/14 02:24:03  gozer
  Renamed import to importFile, since it's a reserved keyword

  use module LIST; -->
  			BEGIN {
  			require module;
  			import module LIST;
  			}

  And it was generating a very annoying warning

  Revision 1.34  1999/11/12 20:32:32  scott
  added import to provide an IO handle and have the file
  sucked up in the file server

  Revision 1.33  1999/11/05 04:12:53  fhurtubi
  Changed filehandle reading to replace it with binary reading (cleaner)

  Revision 1.32  1999/11/04 21:34:11  krapht
  Fixed setMimeType

  Revision 1.31  1999/11/04 20:48:24  gozer
  TOward complete working file sharing
  Added mime-type finding thru mime-magic

  Revision 1.30  1999/11/04 20:11:07  krapht
  Fixed a bug with ID

  Revision 1.29  1999/11/04 20:08:41  krapht
  Changed with Gozer the system to register MIME types

  Revision 1.28  1999/11/04 19:11:19  krapht
  Added code to bypass the max file size settings if no value is present in the
  config file

  Revision 1.27  1999/11/04 18:43:06  krapht
  Added minor stuff (undef returned when problems encountered with the filename,
  etc.)

  Revision 1.26  1999/10/26 19:18:32  krapht
  Added quota checking with total disk space and file size

  Revision 1.25  1999/10/25 22:40:29  krapht
  Removed strict 'refs' while reading from the filename

  Revision 1.24  1999/10/24 01:45:09  gozer
  Changed to use MYSQL PASSWORD() fctn

  Revision 1.23  1999/10/21 21:56:08  gozer
  SOme abstraction of file serving (FileServer)

  Revision 1.22  1999/09/24 00:06:44  scott
  fixing some config stuff with file upload

  Revision 1.21  1999/09/23 19:43:43  fhurtubi
  Changed hard coded value of /web/ to $SW::Config::FILE_URI

  Revision 1.20  1999/09/22 07:45:28  fhurtubi
  Changed $app to $self because I was getting really confused :))
  Also, I removed all calls to $self->{user} and replaced them with SW->user

  Revision 1.19  1999/09/20 19:59:33  fhurtubi
  Changed reference of $self->{user} to SW->user

  Revision 1.18  1999/09/20 14:30:45  krapht
  Changes to use the new method of getting session, user, etc.

  Revision 1.17  1999/09/17 00:45:40  fhurtubi
  Changed the way File works. Remove query in get_uri

  Revision 1.16  1999/09/15 21:32:54  fhurtubi
  Fixed query in DBIStore, Changed LOTS of things in File.pm (and this is
  not over yet). Removed a buggy line in Folder

  Revision 1.15  1999/09/15 18:24:26  jzmrotchek
  Changed file open for write a little bit.   Now, if the open fails, it writes a message to STDERR and returns 0, or returns 1 if the file open/write are successful.

  Revision 1.14  1999/09/15 16:37:34  krapht
  It works perfectly.  A couple of points to note.  I removed the directory creation
  part from write_file, because the registrar should take care of creating the
  user folder when the user is created.  Also, edit the FULL_SAVE_PATH at the top
  of the file, so it points to your upload directory.

  Revision 1.13  1999/09/15 00:33:36  fhurtubi
  Fixed a \1 that should have been $1

  Revision 1.12  1999/09/14 21:56:55  jzmrotchek
  Bugfix dealing with the Config file mime types VS local mime types.

  Revision 1.11  1999/09/14 21:33:03  jzmrotchek
  Moved mime type stuff to Config.pm where it belongs!

  Revision 1.10  1999/09/14 20:57:28  krapht
  Changed some stuff so the name only gets written in the datainfo table.

  Revision 1.9  1999/09/14 19:20:51  jzmrotchek
  Fixed bug that wasn't storing file names properly.  Let me know if it isn't working right.

  Revision 1.8  1999/09/11 07:07:40  scott
  Made substantial changes to the database schema and data storage models.
  Now there's three global tables called datamap, dataaccess, and
  datainfo.  These hide the many other more data specific tables
  where the infomation is actually stored.

  Revision 1.7  1999/09/06 23:23:49  jzmrotchek
  Newer version; stores files not by filename but by fileid field.  Also stores with a default "filed" value of "N", so that file management apps can track newly uploaded data.  Only files that have a $self->{storage}->{filed} value set to "N" can be overwritten; in all other cases, it will create a new file reference.

  Revision 1.6  1999/09/06 16:47:40  jzmrotchek
  OKay, this is pretty much the functional module.  (It even has perldoc!)  A few caveats; you definitely want to change the constants near the beginning of the module to match your server environment, and you definitely want to makes sure the permissions on the directories and files you've specified in those constants are appropriate.
  Other issues: currently, the mime type checking gets done over and over in this module.  This means a lot of filehandle creation/destruction overhead.  We'll probably want to move this into the mod_perl startup script at some point, and make the mime type hash a mod_perl global.  THis would heavily cut back on this module's overhead, and considering the otherwise sleek nature of the module, would probably be a Good Thing.

  So...

  Use and enjoy.  Comments and criticisms will be dealt with as received on the basis of their merit. :)

  Revision 1.5  1999/09/05 03:53:52  jzmrotchek
  It works.  It still needs some tweaking around the edges (notably the bits where the MIME type gets determined and the get_uri() method), but otherwise it's looking pretty good.  Feel free to take it for a test drive.  Adjust the FILE_SAVE_PATH according to your needs.

  Revision 1.4  1999/09/05 03:19:38  jzmrotchek
  Almost working.   Expect a rapid followup to this.

  Revision 1.3  1999/09/03 21:44:28  jzmrotchek
  Okay, making progress.  Cut out a lot of deadwood code, and it works... kinda.  At the moment, it will put code in the user-specific directory, but only with the user specified filename rather than the SW id.  Speaking of which, the DB stuff hasn't been entered yet.  That's the next step.   Time to consult with the SW::Data wizard...

  Revision 1.2  1999/09/03 20:22:39  jzmrotchek
  Early proto version.  Won't be functional except for testing purposes for a while.

  Revision 1.1  1999/09/03 06:43:46  jzmrotchek
  Pre-working version of SW::Data::File.   Will hopefully be working version Real Soon Now.



=head1 SEE ALSO

perl(1), SW::GUIElement::FileUpload(3)

=cut


