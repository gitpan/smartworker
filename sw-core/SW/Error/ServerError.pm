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

package SW::Error::ServerError;

#------------------------------------------------------------
# SW::Error::ServerError
# HTTP Error Handler for crash recovery and Debugging output
#------------------------------------------------------------
# $Id: ServerError.pm,v 1.17 1999/11/22 22:29:09 gozer Exp $
#------------------------------------------------------------

use strict;
use Apache::Constants qw(:common);
use Data::Dumper;
use SW::Cookie;

use SW::Exporter;
use vars qw(@SW_EXPORT @ISA);

@ISA = qw(SW::Exporter);
@SW_EXPORT = qw(setSWDieHandler);

sub setSWDieHandler {
	SW->request->custom_response(SERVER_ERROR,"/ServerError");
#	SW->request->custom_response(NOT_FOUND,   "/NotFound");
	$SIG{__DIE__} = \&SW::Error::ServerError::die_handler;
	unless (tied(*STDERR))
		{
		*OLD_STDERR = *STDERR;
		tie *STDERR, __PACKAGE__;
		}
	SW->request->register_cleanup(sub { tied(*STDERR)->cleanup(); });
	return 1;
	}

sub die_handler {
	my $err_msg = shift;
	my @caller = caller;
	#remember the error for later
	SW->request->subprocess_env('SWERROR' => $err_msg);
	SW->request->subprocess_env(appName => $caller[0]);
	
	#Some black magic to figure out if we are within an eval block like eval "use $module"; and forget about it if so
	my $inEval = ($caller[1] =~ /^\(eval/) || $@ ne '';
	
	if ($inEval)
		{
		return $err_msg;
		}

	print STDERR "[$caller[0](line:$caller[2])DIED] $err_msg";

	print STDERR "Brigning the Apache children down for consistency sake\n";

	Apache->exit(DONE);
	}

#package SW::Error::ServerError::TieSTDERR;
sub TIEHANDLE {
    my $class = shift;
    my $self = (@_ ? shift : {});
    return bless $self, $class;
}
sub PRINT {
	my $self = shift;
	my ($caller, $file, $line) = caller;

	my $display = $SW::Config::Log;
	$display=1 if %SW::Config::LogEnable && $SW::Config::LogEnable{$caller} ;
	$display=0 if %SW::Config::LogDisable && $SW::Config::LogDisable{$caller} ; 

	my $lead = "[$caller(line:$line)]";
	my $log_msg = join '', @_;
	$log_msg .= "\n" unless $log_msg =~ /\n$/;
	
	push @ {$self->{messages}}, [$log_msg =~ /^\[/ ? $log_msg : "$lead $log_msg", $display];
}

sub PRINTF 		{warn "PRINTF not implemented\n";}
sub READLINE	{warn "READLINE not implemented\n";}
sub READ		{warn "READ not implemented\n";}
sub GETC 		{warn "GETC not implemented\n";}

sub cleanup {
	my $self = shift;
	untie(*STDERR);
	
	foreach (@ {$self->{messages}})
		{
		print STDERR $_->[0] if $_->[1];
		}
	delete $self->{messages};
	return;
	}


1;

__END__


=head1 NAME

SW::Error::ServerError - SmartWorker ServerError handler for HTTP

=head1 SYNOPSIS

in smartworker.conf : 

 <Location /ServerError>
         SetHandler perl-script
         PerlHandler SW::Error::ServerError
 </Location>

=head1 DESCRIPTION

Tbis handler will catch servererrors exception and generate debugging output
documenting the problem.

=head1 METHODS

handler - required by mod_perl for handlers

=head1 FUNCTIONS

none

=head1 AUTHOR

Philippe M. Chiasson, <gozer@hbe.ca>

=head1 REVISION HISTORY

  $Log: ServerError.pm,v $
  Revision 1.17  1999/11/22 22:29:09  gozer
  Added a child exit call after failure to make sure state is consistent (a bit extreme, but with _that_ much RAM)

  Revision 1.16  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.15  1999/11/15 07:40:22  gozer
  Some more code movement

  Revision 1.13  1999/11/15 00:03:57  gozer
  Removed some OD specific stuff out of SW

  Revision 1.12  1999/11/14 02:28:58  gozer
  Added e-mail notification of app failures..
  Default address is $SW::Config::BUGS
  But if your app compiles and declares an
  sub AUTHOR {'myemailaddress@there.com'};

  it will be sent to you instead, including more information than you might want...

  Revision 1.11  1999/11/12 22:18:25  gozer
  No more frameset

  Revision 1.10  1999/11/11 20:24:29  gozer
  Now sends mail to the guilty party

  Revision 1.9  1999/11/11 20:05:36  gozer
  Added mail errors to someone functionnality

  Revision 1.8  1999/11/11 07:13:39  gozer
  Removed the handling of 404 since we don't

  Revision 1.7  1999/10/23 04:38:16  gozer
  Errors are handled still a bit better

  Revision 1.6  1999/10/23 02:28:17  gozer
  Fixed and now filteres html codes in text elements. IF you want your text element
  to include pure HTML code, use the -raw=> true thing.
  Secondly, by default now, all spaces are remplaced by nbsp's.  Do disable that ->break =>  "true"

  Revision 1.5  1999/10/22 22:24:46  gozer
  Log filtering and better error handling

  Revision 1.4  1999/10/21 22:18:34  gozer
  Added new error messages, very nice looking :-)

  Revision 1.3  1999/10/19 15:31:42  gozer
  Added loaded modules dump

  Revision 1.2  1999/10/16 06:33:47  gozer
  Added some more error trapping

  Revision 1.1  1999/10/12 17:19:04  gozer
  Moved error-handling from Master to Handler
  Added a ServerError handler for debugging purposes


=head1 SEE ALSO

perl(1).

=cut



