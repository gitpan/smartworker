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

package SW::User::AuthenChallenge;

#------------------------------------------------------------
# SW::User::AuthenChallenge
# 	Subclass of SW::User::Authen
#
#	This modules adds challenge-response authentication to the
#	basic SW::User::Authen module.
#
#	NOTE: For this module to work, you will need to run an authentication
#	daemon (swauthd).  look at the source of swauthd for more information
#
#------------------------------------------------------------
# $Id: AuthenChallenge.pm,v 1.11 1999/11/17 19:48:19 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use IO::Socket;
use SW::User;
use SW::User::Authen;

use MIME::Base64;
use Digest::MD5 qw(md5_base64);

@ISA = qw(SW::User::Authen);

$VERSION = '0.02';

print STDERR "Using authen server $SW::Config::AUTHEN_SERVER:$SW::Config::AUTHEN_PORT\n";

#sub responsible for the determination of the validity of a given user that has no token yet.
sub validate {
	my $self = shift;
	my $username = SW->data->{'login'};
	if($username)
		{
		my $hash = SW->data->{'md5hash'};
		my $challenge = SW->session->getGlobalValue('challenge');
		#we don't need it anymore
		SW->session->delGlobalValue('challenge');
		$self->{_unknown} = 0; # we know your name :-)
	
		#print STDERR "CHALLENGE FOR $username, $challenge, $hash\n";
	
		my $socket = $self->getAuthd() or return;
		
		print $socket "AUTHMD5HEX\r\n";
		print $socket "$challenge\r\n$username\r\n";
		my $answer = <$socket>;
		chop $answer;
		chop $answer;
		close $socket;
		
		unless ($answer =~ /^ERR/)
			{
			my ($uid, $response) = split /:/, $answer;
			if ($response eq $hash)	
				{
				$self->{username} = $username;
				$self->{userid} = $uid;
				$self->{_valid} = 1;
				return;
				}
			}
		$self->{_failed} = 1;
		}
return;
}

sub setName {
	my ($self, $username) = @_;
	
	return 0 unless defined $username;

	return 0 if SW::User::userNameExists($username);

	my $socket = $self->getAuthd();	
	if( not defined $socket)
		{
		print STDERR "Call to getAuthd() failed\n";
		return;
		}
	
	my $userid = $self->{userid};
	
	print $socket "EDITUSERNAME\r\n$userid\r\n$username\r\n";

	my $response = <$socket>;
	close ($socket);
		
	if ($response =~ /^ERR/)
		{
		print STDERR "Auth server rejected new username\n";
		return 0;
		}

	$self->{username}=$username;
	SW->session->setPrivateValueOnBehalfOf("SW::User::Authen", "token", $self->{username} . ":" . $self->{userid});

return $userid;
}

sub set {
	my $self=shift;
	
	my $userid;
	my $response;
	
	if($self->guestuser) # are we already known ? no
		{	
		my $socket = $self->getAuthd() or return;
		my ($username, $password) = @_;
		print $socket "SETUSER\r\n";
		print $socket "$username\r\n$password\r\n";
		
		my $response = <$socket>;
		close($socket);
		
		if ($response =~ /^ERR/)
			{
			print STDERR "New user creation failed from swauthd\n";
			return 0;
			}
		
		($userid) = split /:/, $response;
		
		print STDERR "New user has id $userid\n";

		#re-sync the authentication object right away, so we can proceed to something else right away.
		$self->{username} = $username;
		$self->{userid} = $userid;
		$self->{_valid} = 1;
		$self->{_unknown} = 0;
	
		SW->session->setPrivateValueOnBehalfOf("SW::User::Authen", "token", $self->{username} . ":" . $self->{userid});
		}
	else # we are a logged-in user that wants to change his/her password/username
		{
		my $socket = $self->getAuthd();
		
		my $old_password = shift;
		my $new_password = shift;
		my $username = $self->{username};
		$userid = $self->{userid};
		
		#print STDERR "=================EDITUSERPWD\r\n$username\r\n$old_password\r\n$new_password\r\n";
		print $socket "EDITUSERPWD\r\n";
		print $socket "$userid\r\n$old_password\r\n$new_password\r\n";
		
		$response = <$socket>;
		close ($socket);
		
		return 0 if ($response =~ /^ERR/);
		
		#$userid = split /:/, $response;
		}
return $userid;
}

sub getAuthd {
	my $self = shift;
	#print STDERR "GOT INITIALLY [$hash] [$challenge]\n";
		my $socket = IO::Socket::INET->new( PeerAddr	=> $SW::Config::AUTHEN_SERVER, # $authen_server,
														PeerPort => $SW::Config::AUTHEN_PORT, #$authen_port,
														Proto 	=> "tcp",
														Type		=> SOCK_STREAM);
		unless ($socket)
			{
			print STDERR "odauthd server $SW::Config::AUTHEN_SERVER:$SW::Config::AUTHEN_PORT connect failure!\n";
			$self->{_valid}=0;
			$self->{_failed}=1;
			return;
			}
		
		<$socket>; #loose the server hello
		return $socket;
}
