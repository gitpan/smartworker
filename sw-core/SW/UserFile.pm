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

package SW::UserFile;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::UserFile
#  Handler for access to user-uploaded files not under the
#  web root.  (See also SW::Data::File)
#------------------------------------------------------------
#  CVS ID tag...
# 	$Id: UserFile.pm,v 1.5 1999/11/15 18:17:33 gozer Exp $	
#------------------------------------------------------------

use strict;
use Apache::Constants qw(:common);
use Apache::File ();
use SW::DB;

#-----------------------------------------------------------------
# Get the mime types so that proper file type headers can be sent.
#-----------------------------------------------------------------

my $filepath = $SW::Config::FILE_SAVE_PATH;  # The directory when user uploaded files live
my $urlpath  = $SW::Config::USERFILE_PATH;         # The URL of the Userfile handler.

sub handler {
    my $r =  shift;
    my $uid = '1';              # URL gets parsed to determine is UID is provided below.
    my $filename = $filepath;

    if (session_valid()) {
    # Case 1: Session is valid.
	#-----------------------------------------------------------------
	# Parse URI to determine UID (if provided) and filename requested.
	#-----------------------------------------------------------------
	my $uri        = $r->uri;
	my $extra_info = $uri;
	$extra_info =~ s/$urlpath//;
	my @extra_info = split(/\//,$extra_info);
	if (@extra_info == 1) {
	# Case 1: Only file name provided. UID defaults to session UID.
	    # $uid     = ???;
	    $filename .= $uid . "/";
	    $filename .= $extra_info[0];
	} else {
	# Case 2: UID & file name provided.
	    $uid       = $extra_info[0]; 
	    $filename .= $uid . "/" . $extra_info[1];
	}

	if ($uid) {
	# Case 1: UID is part of URL, use it.
	    if (-f $filename) {
	    # Case 1: File exists.
		if (authorized()) {
		# Case 1: Viewing of file is permitted.
                    # Eventually it'll be return_file($file)???
		    return_file($r,$filename,get_mimetype($filename)); 
		} else {
                # Case 2: Viewing of file is not permitted.
		    return FORBIDDEN;
		}
	    } else {
	    # Case 2: File does not exist.
		return NOT_FOUND;
	    }
	# Case 2: UID not part of URL, set to user default.
	} else {
	    # Case 1: File exists.
	    if (-f $filename) {
		if (authorized()) {
		# Case 1: Viewing of file is permitted.
		    return_file($r,$filename); # Eventually it'll be return_file($file)
		} else {
                # Case 2: Viewing of file is not permitted.
		    return FORBIDDEN;
		}
	    # Case 2: File does not exist.
	    } else {
		return NOT_FOUND;
	    }
	}
    } else {
	return FORBIDDEN; # AUTH_REQUIRED maybe?
    }
}

sub session_valid {

    1;
}

sub authorized {

    1;
}

sub get_mimetype {
    my $fid      = shift;
    my $mimetype;

    $fid =~ s/.*\/(.*)$/\1/;
    
    my $dbh       = getDbh();
    my $mimequery = "select mimetype from files ";
    $mimequery .= "where fileid = '" . $fid . "'";

    my $sth = $dbh->prepare($mimequery) || print STDERR "SW::UserFile -> Could not prepare query.\n";
    if ($sth->execute) {
	($mimetype) = $sth->fetchrow_array;
    } else {
	$mimetype = -1;
    }

    return $mimetype;
}

sub return_file {
    my $r         = shift;
    my $file      = shift;
    my $mime_type = shift;
    my $fh = Apache::File->new($file) || die "Ack!  Can't open file $file!";
    $r->content_type($mime_type);
    $r->send_http_header;
    $r->send_fd($fh);
    $fh->close;
    return OK;
}

1;
__END__

=head1 NAME

SW::UserFile - Allows access to files uploaded by SW users using the SW::Data::File methods.

=head1 SYNOPSIS

Requires the following Apache configuration directives:

<location /userfile>
	SetHandler perl-script
	PerlHandler SW::Userfile
</location>

=head1 DESCRIPTION

Allows for files uploaded by SW users through SW::GUIElement::FileUpload items to a SW::Data::File
handled and thereby stored to a SW file system parallel to the webroot to be accessed as common URLs,
given appropriate permissions and so forth.

Known issue: Valid session and permission handling stubs are in place, but don't currently DO anything.
A large part of this is because the security model isn't currently 100% solid.  According to Scott, he'll
be looking into this.

Known issue:  Default UID is currently set to '1'.  This should probably be changed to reflect a
"default" directory where "default" SW files are kept.  Currently this doesn't exist; set to taste.

=head1 METHODS


=head1 PARAMETERS

$filepath : The directory when user uploaded files live
$urlpath  : The URI of the UserFile handler.

=head1 AUTHOR

John F. Zmrotchek
HBE	zed@hbe.ca
Sep 6/99

=head1 REVISION HISTORY

  $Log: UserFile.pm,v $
  Revision 1.5  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.4  1999/09/20 14:30:00  krapht
  Changes in most of the files to use the new way of referring to session,
  user, etc. (SW->user, SW->session).

  Revision 1.3  1999/09/11 07:07:23  scott
  Made substantial changes to the database schema and data storage models.
  Now there's three global tables called datamap, dataaccess, and
  datainfo.  These hide the many other more data specific tables
  where the infomation is actually stored.

  Revision 1.2  1999/09/06 23:50:53  jzmrotchek
  Hokay... This is a working version, which nicely handles the reworked upload format of DB fileid instead of user-supplied filename as URI.  This will allow more power to the file management systems, but less convenience to the end user/developer IMHO, but that's a design tradeoff we're willing to live with for now.  This may get addressed further in the SW::Data::File or other modules functionality, but this handler isn't likely to change much from its present state.  (Bugfixes excluded)


=head1 SEE ALSO

perl(1), SW::GUIElement::FileUpload(3), SW::Data::File(3)

=cut



