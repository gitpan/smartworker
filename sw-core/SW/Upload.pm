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

#!/usr/local/bin/perl

package SW::Upload;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::Upload
#  Allows for file uploads using the format established 
#  originally in Netscape 2.0 and shown an example of below.
#  Example:
#  <form action='/upload' enctype='multipart/form-data'>
#     <input type='file' name='UPLOADFILE'>
#     <input type='submit'>
#  </form>
#------------------------------------------------------------
#  CVS ID tag...
# $Id: Upload.pm,v 1.4 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

$VERSION = '0.01';

use strict;
use Apache::Constants qw(:common);

my $fileroot = "/usr/local/apache/dev/jf/uploads/";  # Root of file storage tree.

sub handler {
    my $r = shift;
    if (session_valid()) {
    # Case 1: Session is valid.
	if ($r->header_in('Content-length') > 0) {
	# Case 1: Actual attempt to give something to handler.
	    get_content($r);
	    $r->send_http_header('text/plain');
	    $r->print(<<EOF)
File uploaded.
Fancier page yet to come.  
EOF
    ;
	    return OK;
	} else {
        # Bad case: Handler called directly.
	    $r->send_http_header('text/plain');
	    $r->print(<<EOF)
No file data submitted.
Please use file submission element.
EOF
    ;
	    return OK;
	}
    } else {
    # Case 2: Invalid session.
	return FORBIDDEN; # AUTH_REQUIRED maybe?
    }
}

sub session_valid {

    1;
}


sub get_content {
    #-------------------------------
    # Get the uploaded file content.
    #-------------------------------
    my $r  = shift;
    my $cl = shift;
    my $content;
    $r->read($content,$cl);

    #-------------------------
    # Strip out the file name.
    #-------------------------
    my $fn = $content;
    $fn =~ s/.*filename=\"(.*)/\1/s;
    $fn =~ s/\".*//s;

    #------------------------------------------------------------
    # Now demunge the nasty form-encodings from the REAL content.
    #------------------------------------------------------------
    $content =~ s/------.*\n//g;
    $content =~ s/Content.*\n//g;
    $content =~ s/.*\n//;

    my $fp = $fileroot . $fn;
    store_file($fp,$content);

    1;
}


sub store_file {
#-----------------------------------------------------------------------
# Stores the uploaded content (Cleaned up of all the nasty form encoding) 
# and stores it to file.
#-----------------------------------------------------------------------
    my $fp = shift;  # File name (fully qualified path)
    my $fc = shift;  # File content to be stored.
    print STDERR $fp . "\n";
    open(SAVE,">$fp");
    print SAVE $fc;
    close SAVE;
    1;
}

1;
__END__

=head1 NAME

SW::Upload 

=head1 SYNOPSIS

Not called as anything else but a handler for SW uploads.

=head1 DESCRIPTION

SW::Upload is used to upload files to a Smartworker server.

=head1 METHODS

n/a

=head1 PARAMETERS

n/a

=head1 AUTHOR

John F. Zmrotchek
HBE     zed@hbe.ca
Aug 31/1999

=head1 REVISION HISTORY

    $Log: Upload.pm,v $
    Revision 1.4  1999/11/15 18:17:33  gozer
    Added Liscence on pm files

    Revision 1.3  1999/09/20 14:30:00  krapht
    Changes in most of the files to use the new way of referring to session,
    user, etc. (SW->user, SW->session).

    Revision 1.2  1999/09/07 15:51:17  gozer
    Pod syntax error fixed

    Revision 1.1  1999/09/02 23:46:59  jzmrotchek
    Module for uploading files.  Basic version, few controls at this point.  Read the module comments and perldocs for now.  More to come.


=head1 SEE ALSO

perl(1)

=cut















