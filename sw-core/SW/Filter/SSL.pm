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

package SSLFilterHTML;

use HTML::Filter;
use Data::Dumper;
use Apache;

use  vars qw(@ISA $VERSION);
$VERSION='0.01';

@ISA=qw(HTML::Filter);

my $r=Apache->request;
my $base = $r->uri;
($base) = ( $base =~ /(.*\/)[^\/]*$/ );

my $server  = $SW::Config::SSL_PLAIN_HOST || 'father.hbe.ca';
my $port 	= $SW::Config::SSL_PLAIN_HOST_PORT || 8008;
my $scheme  = $SW::Config::SSL_PLAIN_HOST_SCHEME || 'http';

 
sub start {
	my ($self, $tagname, $attr, $attrseq, $origtext) = @_;
	
	if(exists $attr->{src})
		{
		my $uri = URI->new($attr->{src});
		
		$uri->path($base . $uri->path()) unless ($uri->path() =~ /^\//);
		$uri->scheme($scheme);
		$uri->host($server);
		$uri->port($port);	
			
		$attr->{src} = $uri;
				
		print "<" , uc($tagname) , (join '', (map { " " . uc($_) . '="' . $attr->{$_}. '"' } @$attrseq)) , '>';
		}
	else
		{
		print $origtext;	
		}
}



package SW::Filter::SSL;

use strict;
use Data::Dumper;
use vars qw($VERSION);

$VERSION = '0.03';

sub handler{
	my $r = shift;
	die ("Can't Filter Input") unless Apache->can('filter_input');
	my $fh = $r->filter_input();
	
	print "<!-- SSLFILTER BEGIN -->\n";
	
	local $/ = undef;
	my $p = SSLFilterHTML->new;
	$p->parse(<$fh>);	
	$p->eof;
	
	print "\n<!-- SSLFILTER END -->";
	return
	};
	

