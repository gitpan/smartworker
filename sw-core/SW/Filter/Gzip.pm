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

package SW::Filter::Gzip;

use strict;
use Data::Dumper;
use Compress::Zlib 1.0;
use vars qw($VERSION);

$VERSION = '0.01';

sub handler{
	my $r = shift;
	die ("Can't Filter Input") unless Apache->can('filter_input');
	my $info;
	my($can_gzip);
	
	my @vary = $r->header_out('Vary');

	if(@vary)
		{
		my %vary;
		map {$vary{$_}++ if $_} (@vary, qw(Accept-Encoding User-Agent));
		$r->header_out('Vary',join ',', keys %vary);
		}
	else
		{
		$r->header_out('Vary','Accept-Encoding,User-Agent');
		}
	
	my($accept_encoding) = $r->header_in("Accept-Encoding");
	
	$can_gzip = 1 if index($accept_encoding,"gzip")>=0;
	
	my $user_agent = $r->header_in("User-Agent");
	
	$info = "$user_agent";
	
	
	unless ($can_gzip) 
			{
			
			if ($user_agent =~ m{
                         ^Mozilla/
                         \d+
                         \.
                         \d+
                         [\s\[\]\w\-]+
                         (
                          \(X11 |
                          Macint.+PPC,\sNav
                         )
                        }x
       ) {
      	$can_gzip = 1;
    		}
		
		}
   	
	$r->header_out('Content-Encoding' => 'gzip') if ($can_gzip);

	my $fh = $r->filter_input();

	return unless $fh;

	local $/ = undef;
	my $content = <$fh>;
	

	if ($can_gzip) {
		my $content_size = length($content);
		my $content = Compress::Zlib::memGzip("<!-- GzipFilter for $info BEGIN -->\n" . $content. "<!-- GzipFilter END -->\n");
		my $compressed_size = length($content);
		my $ratio = int(100*$compressed_size/$content_size) if $content_size;
		print STDERR "GzipCompression $content_size/$compressed_size ($ratio\%)\n";
		print $content;
   	}
	else
		{
		print $content;
		}

return
};


