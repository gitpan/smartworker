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

package SW::Login;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for internal use only!!
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::Handler;
#  This is a mod_perl handler to replace apps/login.pl with a more
#  complete and configurable version.
#
#------------------------------------------------------------
#  CVS ID tag...
# $Id: Login.pm,v 1.9 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION);
$VERSION='0.03';

use SW::Util;

use Apache;
use Apache::Constants;
use Data::Dumper;

*handler = \&loginHandler;
sub loginHandler {

	my $r = shift; 
	my %args = $r->args();

	my $uri = $r->uri;


	my $on_click=qq|this.form.submit();|;
	my $hidden_arguments;
	my $md5_lib;
	my $md5_form;
	if($SW::Config::AUTHEN_SERVER)
		{
		my $challenge = SW::Util::randomString;
		SW->session->setGlobalValue("challenge",$challenge);
		SW->session->delPrivateValueOnBehalfOf("SW::User::Authen","token");
		$md5_lib = <<"EOL";
		<SCRIPT TYPE="text/javascript" SRC="/sw_lib/MD5.js" LANGUAGE="Javascript"></SCRIPT>
		<SCRIPT TYPE="text/javascript" LANGUAGE="Javascript">var challenge="$challenge";</SCRIPT>
EOL
		$md5_form = <<"EOL";	
		<!-- Hack around JavaScript taint checking -->
		<FORM name="Auth" method=post action="$uri" target="_top">
		<INPUT type=hidden name="login" class="textarea">
		<INPUT type=hidden name="md5hash" class="textarea"> 
EOL

		unless(defined $SW::Config::COOKIE_NAME)
			{
			my $session_id = SW->session->getSessionID;
			$md5_form .= qq|<input type=hidden name="SESSION_ID" value="$session_id">|;
			}

		$on_click=qq|document.Auth.md5hash.value=MD5( challenge + MD5(this.form.password.value) ); document.Auth.login.value=this.form.login.value; document.Auth.submit();|;
		}

	while (my ($key, $value) = each %args)
	   {
    	  $hidden_arguments .= qq/<input type=hidden name="$key" value="$value">\n/ if $value;
	   }


	print <<"EOL";
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
	<HTML>
	<HEAD>
	<title>SmartWorker Login Page</title>
	$md5_lib

	</HEAD>
	<body bgcolor=#f0f0f0>
	$md5_form
	$hidden_arguments
	</FORM>

	<center>
	<table width=600 height=400 cellspacing=0 cellpadding=1 border=0>
	<tr><td width=600 height=400 align=center valign=center bgcolor=#00000f>
		<table width=598 height=398 cellspacing=1 cellpadding=2 border=0>
		<tr><td bgcolor=#9090b0 width=598 height=398 align=center valign=center>

			<table width=300 cellspacing=0 cellpadding=1 border=0>
			<tr><td width=300 align=center valign=center bgcolor=#000f0f>
				<table width=100% cellspacing=1 cellpadding=2 border=0>
				<tr><td bgcolor=#606090 width=100% align=center valign=center>

				<font face="Verdana,Arial" size=+2>
				<font color=#202040><i>Smart</i></font><font color=#000010>Worker Login</font></font><p>

				<table border=0 cellspacing=0 cellpadding=4><tr>

        	 <form name="Login" action=$uri method=POST>
					<td align=right><font face="Verdana,Arial" size=+1>Login:</td>
					<td align=left><input size=16 name=login></td></tr>
					<tr><td align=right><font face="Verdana,Arial" size=+1>Password:</td>
					<td align=left><input size=16 type=password name=password></td></tr>
					<tr><td>&nbsp;</td><td align=right>
					<input value=Login type=button onClick="$on_click">

		    	  $hidden_arguments

				   </form>

				</table>

				</td></tr>
				</table>
			</td></tr>
			</table>

		</td></tr>
		</table>
	</td></tr>
	</table>
	</center>
	</body>
EOL
return OK;  
}

sub errorHandler {
	my $r = shift;
	return DECLINED if $r->is_initial_req;
	
	#data dumper local options for niceness
	local $Data::Dumper::Useqq=1;
	local $Data::Dumper::Terse=1;
	
	$r->content_type('text/html');

	if (SW->cookie)
		{
		SW->cookie->send();
		}
	
	if ($r->can('filter_input'))
		{
		$r->filter_input();
		}
	else
		{
		$r->send_http_header();
		}

	return OK if $r->header_only;

	#get at the original request that triggered the error
	$r = $r->prev;

	my $className = $ENV{REDIRECT_appName};
	my $errorCode = $ENV{REDIRECT_STATUS};
	my $err_msg   = $ENV{REDIRECT_SWERROR};
	
	my $appid = $className->APP_ID() if defined $className && $className->can('APP_ID'); 

#things we want to dump;
my %dumps = 	(
					'compilation' => $err_msg ? "<PRE>$err_msg</PRE>" : undef,
					'session'	=> SW->session() ? "<PRE>" . (Dumper (SW->session)) . "</PRE>" : undef,
					'cookie'		=> defined $SW::Config::COOKIE_NAME ? "<PRE>" . (Dumper new SW::Cookie($SW::Config::COOKIE_NAME)) . "</PRE>" : undef,
					'user'		=> SW->user() ? "<PRE>" . (Dumper (SW->user)) . "</PRE>" : undef,
					'env'			=> '<TABLE BORDER="1" BGCOLOR="666666">' . (join "\n", map {"<TR><TD><B>$_</B></TD><TD>" . ($ENV{$_} || '<I>undef</I>') . " </TD></TR>"} sort keys %ENV) . "</TABLE>",
					'master' 	=> SW->master() ? "<PRE>" . (Dumper (SW->master)) . "</PRE>" : undef,	
					'includes'	=> "<PRE>" . (Dumper \%INC) . "</PRE>",
				);

	print qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
	<HTML>
	<HEAD>
	<TITLE>$ENV{REDIRECT_STATUS} Error</TITLE>
	</HEAD>
	<body BGCOLOR="#23238E" LINK="yellow" VLINK="#B0B0B0" TEXT="white"><h1><A NAME="top"> $className(|,  (defined $appid ? $appid : 'no APP_ID') ,qq|) returned a  $errorCode Error</A></h1>|;

	#list of items that might be dumped
	print "<UL>" , (join "\n", map { "<LI>" . ( defined $dumps{$_} ? '<A HREF="#' . $_ . '">' . ucfirst $_ . '</A>' : ucfirst $_  ) . '</LI>'  } sort keys %dumps) ,"</UL>";

	#print the dumps that are avaliable
	print "<HR>" , (join "<HR>\n", map { qq|\n<H2><A NAME="$_">| . ucfirst ($_) . qq| Dump</A></H2><A HREF="#top">top</A>\n$dumps{$_}| } sort grep { defined $dumps{$_} } keys %dumps);

	#footer
	print '</BODY></HTML>';
return OK;
}	


sub authenFailure {
print <<"EOF";

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
	<title>Error</title>
</head>
<body>
<H1>Authentication Failure</H1>
</body>
</html>
EOF
return OK;
}

sub authzFailure {
print <<"EOF";

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
	<title>Error</title>
</head>
<body>
<H1>Authorization Failure</H1>
</body>
</html>
EOF
return OK;
}
