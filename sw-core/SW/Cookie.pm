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

package SW::Cookie;

#------------------------------------------------------------
# SW::Cookie
# Cookie handling class
#
#There is some BENCHMARKING NEEDED HERE!  TripleDES encoding the cookies on every
#request might be bad.. Maybe some lighter encryption of some sort ??
#THe connection will already be thru SSL, so the only thing we want to prevent is
#an user to look at his cookie.txt file and modify some stuff...(this is only if we use expires
#settings, because if not, the cookie will only live for the time of the session, and
#never get stored to disk
#------------------------------------------------------------
# $Id: Cookie.pm,v 1.13 1999/11/15 18:17:32 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION);
use CGI::Cookie;
use Data::Dumper;
use Crypt::TripleDES;
use MIME::Base64;


sub new {
	my $class = shift;
	my $cookiename = shift;
	my $self = bless {}, $class;
	
	$self->{cookiename} = $cookiename;
	$self->{_cookie} = fetch CGI::Cookie;
	$self->{_dirty} = 0;

	if((exists $self->{_cookie}{$cookiename}) && (my $cyphertext = $self->{_cookie}{$cookiename}->value))
		{
		return $self if $cyphertext eq 'null';  #thus proving cookie=null isn't the right way to delete cookies in JS
		if(defined $SW::Config::COOKIE_KEY)
			{
			my $des = new Crypt::TripleDES;
			$cyphertext = $des->decrypt3(decode_base64($cyphertext),$SW::Config::COOKIE_KEY);
			}
			
		$self->{cookie} = eval $cyphertext;
		
		if($@)
			{
			#make sure this is sane
			$self->{cookie} = undef;
			print STDERR "INVALID COOKIE RECIEVED!!!WE MIGHT BE UNDER ATTACK, BUT MOST LIKELY NOT, SO DO NOT RUN FOR YOUR LIVES YET!!!\n";
			}
		}
return $self;
}
	
sub send {
	my $self = shift;
	#print STDERR "Attemptig to send Cookie" . $self->{_dirty};
	return unless exists $self->{cookie};
	return if $self->{_dirty} == 0;
	
	my $cyphertext = SW::Util::flatten($self->{cookie});
	if(defined $SW::Config::COOKIE_KEY)
			{
			my $des = new Crypt::TripleDES;
			$cyphertext = encode_base64($des->encrypt3($cyphertext,$SW::Config::COOKIE_KEY));
			}
			
	my @expires = ();
	@expires = ('-expires',$SW::Config::COOKIE_DURATION) if $SW::Config::COOKIE_DURATION;
	
	my @secure = ();
	@secure = ('-secure',$SW::Config::COOKIE_SECURE) if $SW::Config::COOKIE_SECURE;
	
	my @path = ('-path', $SW::Config::COOKIE_PATH ? $SW::Config::COOKIE_PATH : '/');
	
	my @cookies;
	
	my @hosts;
	unshift @hosts, @SW::Config::COOKIE_HOST if defined @SW::Config::COOKIE_HOST;
	push @hosts, $SW::Config::COOKIE_HOST if defined $SW::Config::COOKIE_HOST;
	
	#print STDERR "Cookie::send [$cyphertext]called for(", @hosts, ")\n";
	
	foreach my $host (@hosts,0)
		{
		
		my @domain = ('-domain',$host) if $host;
		my $cookie = new CGI::Cookie( 
			-name		=> $self->{cookiename},
			-value  	=> $cyphertext,
			@domain,
			@path,
			@expires,
			@secure,
			);
		#print STDERR "Cookie for ($host) $cookie\n";	
		SW->request->cgi_header_out('Set-Cookie',$cookie);
		}
return;
}

sub LogoutJS {
	my $doWeCloseBefore = shift;
	my $dontRefresh = shift;

	my $logout_code="function logout() {\n";
	
	my @hosts;
	push @hosts, @SW::Config::COOKIE_HOST if defined @SW::Config::COOKIE_HOST;
	push @hosts, $SW::Config::COOKIE_HOST if defined $SW::Config::COOKIE_HOST;
	
	my $path = ";path=" . ($SW::Config::COOKIE_PATH ? $SW::Config::COOKIE_PATH : '/');
	
	my $secure = $SW::Config::COOKIE_SECURE ? ";secure=$SW::Config::COOKIE_SECURE" : ''; 
	
	foreach my $host (@hosts,0)
		{
		my $domain = $host ? ";domain=$host" : '';
		$logout_code.= "document.cookie='$SW::Config::COOKIE_NAME=$path$domain$secure;expires=Thu, 01-Jan-70 00:00:01 GMT';\n";
		}
	
	if ($doWeCloseBefore) {
		
		my $closeCode = qq#
			window.onerror = giveAChanceToIE;

			// the following function is because IE crashes when you call window.name
			// on a closed window!! so stupid
			function giveAChanceToIE ()
			{
				var newWindow = window.open('/', 'OpenDeskLoginPage');
				top.window.close();
				return true;
			}

			var father = top.window.opener;
			var isFatherClosed = ((father.name != "rightlogin") || (father.closed)) ? true : false;
			if (isFatherClosed) {
				var newWindow = window.open('/', 'OpenDeskLoginPage');
			} else {
				father.location.reload();
			}
			top.window.close();
		#;
		return "$logout_code\n$closeCode\n}";	
		} else {
		my $code = $logout_code;
		$code .= "\ntop.window.location='/';" unless $dontRefresh;
		return "$code}";
		}
	}

sub getBrowserCookieJS {
return <<"EOF";
<SCRIPT LANGUAGE="Javascript">
var testCookieName = 'testCookie' + Math.random();
document.cookie=testCookieName+'=test';
var hasCookie=true;

if(-1==document.cookie.indexOf(testCookieName+'='))
	{
	hasCookie=false;
	}
else
	{
	//clear the cookie to be nice
	document.cookie=testCookieName+'=;expires=Thu, 01-Jan-70 00:00:01 GMT';
	}

function cookieAvaliable()
	{
	if(hasCookie) return false;
	return (document.write('<FONT COLOR="#FF4400" SIZE="+1"><BLINK>You do not have Cookies enabled</BLINK></FONT><BR><BR>'));
	}
</SCRIPT>
EOF
}

sub getBrowserCookieAvaliableJS {
return <<"EOF";
<SCRIPT>cookieAvaliable()</SCRIPT>
EOF
}

sub setValue {
	my ($self, $key, $value) = @_;
	#print STDERR "Set ($key, $value) called and previous key was " . $self->{cookie}{$key}." \n";
	$self->{_dirty} = 1;
	#print STDERR "COOKIE STATUS is " , $self->{_dirty};
	return $self->{cookie}{$key} = $value;
	}
	
sub getValue {
	my ($self, $key) = @_;
	return $self->{cookie}{$key};
	}

sub delValue {
	my ($self, $key) = @_;
	$self->{_dirty} = 1 if exists $self->{cookie}{$key};
	return delete $self->{cookie}{$key};
	}
	
1;    # All perl module must return true at the completion of loading
__END__

=head1 NAME

SW::Cookie - Deals with all cookie issues

=head1 SYNOPSIS

none so far, check out SW::Handler  
   
=head1 DESCRIPTION


=head1 METHODS

new - Read the request and prepare a cookie object

setValue - Sets a key to a value

getValue - Gets the value of a key

delValue - Delete the entry associated with a key

send - Send the cookie to the browser

=head1 PARAMETERS


=head1 AUTHOR

Philippe M. Chiasson
HBE	gozer@hbe.ca
Sept 2/1999

=head1 REVISION HISTORY

  $Log: Cookie.pm,v $
  Revision 1.13  1999/11/15 18:17:32  gozer
  Added Liscence on pm files

  Revision 1.12  1999/11/15 14:06:29  gozer
  Fixed a very annoying warning

  Revision 1.11  1999/11/15 01:11:25  gozer
  MOved some function that belong here, here

  Revision 1.10  1999/11/14 02:22:14  gozer
  Fixed most of the problems with cookies

  Revision 1.8  1999/11/12 22:15:08  gozer
  OUpss. fixed recursive logout

  Revision 1.7  1999/11/11 20:37:51  fhurtubi
  Added the close window on logout part

  Revision 1.6  1999/11/11 07:13:24  gozer
  Cookie sends the cookie only if necessary
  Handler returns a 404 when handling the get of a file that isn't on the file server
  User - added the change of username call SW->user->authen->setName("NewName");

  Revision 1.5  1999/11/02 19:13:56  gozer
  Cleaned up code that was written in 5 minutes during the 1st launch attempt of OD

  Revision 1.4  1999/10/27 03:47:49  gozer
  Added code for an IP based cookie too

  Revision 1.3  1999/10/25 02:20:14  gozer
  Removed loggin

  Revision 1.2  1999/10/23 04:38:15  gozer
  Errors are handled still a bit better

  Revision 1.1  1999/09/30 11:38:52  gozer
  Added the support for cookies

   
=head1 SEE ALSO

perl(1).

=cut

