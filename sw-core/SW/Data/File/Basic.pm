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

package SW::Data::File::Basic;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::Data::File::Server
#   stores/retrieves and provide access to files stored on an
#   HTTP FileServer
#------------------------------------------------------------
# $Id: Basic.pm,v 1.4 1999/11/15 18:17:33 gozer Exp $
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

@ISA = qw(SW::Data);

$VERSION = '0.01';

sub storeFile {
		my ($class,$user,$id,$contents) = @_;
		my $filepath = $SW::Config::FILE_SAVE_PATH  . "/" . $user . "/" . $id;

    	print STDERR "###################################################################\n";
    	print STDERR "in call to _write_file : filepath is $filepath\n";

    	# Then save the file.
    	if (open (OUTFILE,">$filepath")) 
			{
			print OUTFILE $contents;
			close (OUTFILE);
			return 1;
    		} 
		else {
			print STDERR "SW::Data::File - Error writing to $id : $!\n";
			return 0;
    		}
		}


sub getUri {
	my $class = shift;
	my $fileid = shift;
	return ($SW::Config::FILE_URI. SW::Data::getCreatorFromId($fileid) . "/" . $fileid);
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

  $Log: Basic.pm,v $
  Revision 1.4  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.3  1999/10/25 08:28:54  fhurtubi
  Added the getCreatorFromId call to retrieve a file

  Revision 1.2  1999/10/22 18:53:54  fhurtubi
  in StoreFile, it was missing the class as the 1st param

  Revision 1.1  1999/10/21 21:56:46  gozer
  Added 2 modules for file save/get


=head1 SEE ALSO

perl(1), SW::Data::File(3) SW::GUIElement::FileUpload(3)

=cut

