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

package SW::Util::Prep;

#------------------------------------------------------------
# SW::Util::Prep
#    Source filter to build the callback table for apps
#------------------------------------------------------------
# $Id: Prep.pm,v 1.16 1999/11/19 17:48:39 scott Exp $
#------------------------------------------------------------

use strict;

use Filter::Util::Call;
use SW::Util;

#------------------------------------------------------------
# import
#------------------------------------------------------------
sub import
{
	my ($type, @args) = @_;
#	print STDERR "adding filter...\n";
	filter_add({});
}

#------------------------------------------------------------
# filter
#------------------------------------------------------------

sub filter 
{
	my $self = shift;
	my $status = filter_read();
	my $tabl = "tabl";

#	print STDERR "watchNext ".$self->{watchNext}."\n";

	if (($status > 0) && /^\s*#SW\s+end.*$/i)		# write it out - we're done!
	{
#		print STDERR "end $status $_\n";
		my $tabl = SW::Util::flatten($self->{data});
#		print STDERR $tabl;
		my $data = <<'EOA';
sub import
{

EOA

	$data .= 'my $str = '."qq#$tabl#\;";
	$data .= <<'EOB';

	$SW_FN_TABLE = eval $str;
}

sub buildTable 
{ 
   my $self = shift; 
	my $stupid_local_debug = 0;
	my $pkg_str = $self->{package};

	print STDERR "package $pkg_str\n";

   foreach my $typ (keys %$SW_FN_TABLE) 
   { 
      foreach my $id (keys %{$SW_FN_TABLE->{$typ}}) 
      { 
			foreach my $record (@{$SW_FN_TABLE->{$typ}->{$id}})
			{
				my $rec = Storable::dclone($record);
				unshift @{$self->{_FN_TABLE}->{$typ}->{$id}}, $rec;
				if ($rec->{sub})
				{
					my $fname = $rec->{sub};
         		if ($self->can($fname)) 
         		{ 
            		$self->{_FN_TABLE}->{$typ}->{$id}->[0]->{code} = 
               		sub { $self->$fname(@_); };
         		}
					else 
					{ 
						print STDERR "Error! ".ref($self)." can't $fname\n"; 
					}
				} 
			} 
      } 
   }
	if ($stupid_local_debug)
	{
   	print STDERR "global..: ".SW::Util::flatten($SW_FN_TABLE);
		print STDERR "\n\nlocal..: ".SW::Util::flatten($self->{_FN_TABLE})."\n\n";
	}
	$self->{master}->registerObject($self);
} 
 
 
EOB

#		print STDERR $data;
		$data =~ s/\n/ /g;
		$_ = $data;
		filter_del();
	}	
	elsif (($status > 0) && /^\s*sub\s+.*$/i)  # A sub name
	{
	      my @line = split;
			$self->{watchNext} = $line[1];
	}
	elsif ($self->{watchNext})
	{
		if (($status > 0) && /^\s*#SW\s+.*$/i)
		{
			my @scratch = split;
			my $subName = $self->{watchNext};

			print STDERR "sub $subName -> $_";

			my $cmd = $scratch[1];
			my $arg1 = $scratch[2];
			my $arg2 = $scratch[3];
			my $rec = { 'sub' => $subName };

			if ($cmd =~ /TransOrder/i)
			{	
				 $rec->{order} = $arg1;
				 $rec->{proto} = $arg2;
				 unshift @{$self->{data}->{transOrder}->{$rec->{order}}}, $rec;
			} 
			elsif ($cmd =~ /CallBack/i)
			{
				 $rec->{signal} = $arg1;
				 $rec->{order} = $arg2;
				 unshift @{$self->{data}->{callBack}->{$rec->{signal}}}, $rec;
			}
			elsif ($cmd =~ /Expose/i)
			{
				 $rec->{order} = $arg1;
				 $rec->{proto} = $arg2;
				 unshift @{$self->{data}->{exposure}->{$rec->{signal}}}, $rec;
                        }         
                        elsif ($cmd =~ /ExceptionHandler/i)
                        {
			    $rec->{exception_signal} = $arg1;
			    unshift @{$self->{data}->{exception}->{$rec->{exception_signal}}}, $rec;
                        }
			else
			{
				print STDERR "Bad Opcode in #SW line: $_\n";
				$status= -1;
			}
		}
		else
		{
#			print STDERR "out of watchNext: $status $_\n";
			delete $self->{watchNext};	
		}
	}
	
#	print STDERR "called output $status $_\n";
	return $status;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::Util::Prep - SmartWorker source filter

=head1 SYNOPSIS

#!/usr/bin/perl
use SW::Util::Prep;

# everything from here down is getting passed through the source filter

use vars qw(.... $SW_FN_TABLE ...);

use SW::Application....

sub new
{
	.....
	$self->buildTable;
	return $self;
}

.........
sub some_sub
#SW TransOrder 10
#SW Callback 8 MyCallBackSignal
{
}

#SW end

1;
__END__

=head1 DESCRIPTION

The Prep source filter reads through your application source code as its loaded
in and replaces some directives disguised as comments with code.  It is essentially
the same a a pre-processor.  The idea is that you can now register callbacks 
and define transaction order for your methods just using one or more comment
lines following the sub my_sub line.

There are four things you must add to your code (besides the directives that 
this filter processes)  those are:

- use SW::Util::Prep;          before any code
- use vars qw( ....  $SW_FN_TABLE ...);   a static variable for the Object
- $self->buildTable();						right before the return $self in new()
- #SW end								after all your code - this is where the filter
											writes its output.

=head1 METHODS

import - called automatically when the filter is imported, sets up the state
			hash and blesses the filter.  calls add_filter() to start running the
			filter

filter - called for each line of code that's read in


=head1 AUTHOR

Scott Wilson		May 18,1999
scott@hbe.ca

=head1 DIRECTIVES

#SW TransOrder [n]	
		Tells the system that the sub named above this line should be run EVERY
		transaction at increment n.

#SW Callback Signal [n] [Proto  (future)]
		Tells the system to register this callback under the signal Signal.  It
		should be run at time increment n.  When the system checks fore callbacks
		and finds this one, it temporarily adds this callback into the table with
		the transorder pointers.

#SW Expose [Proto]
		Doesn't do anything yet, but I think this is how we'll expose methods to
		other apps / objects in SW.

#SW end
		IMPORTANT  this must be inserted between the last line of code and the
		true return of the module.  This is how the source filter knows where
		to write the code it creates.

#SW ExceptionHandler
                Tells the system to register this method as an exception handler; that is,
                if the running of the app causes any of the Apache error types (returns a
                status other than OK) and triggers an error handler, the error handler will
                redirect to the app that threw the exception and will call this method.


=head1 STANDARD ORDER

	15 - swBuildUI

=head1 REVISION HISTORY

  $Log: Prep.pm,v $
  Revision 1.16  1999/11/19 17:48:39  scott
  fixed nasty bug in my regexps causing "ends" to  be erroneously caught

  Revision 1.15  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.14  1999/09/09 16:05:41  jzmrotchek
  *sighs*  Yet another quick bugfix.  Same line, too...

  Revision 1.13  1999/09/09 16:03:35  jzmrotchek
  ANother bugfix.

  Revision 1.12  1999/09/09 16:02:32  jzmrotchek
  Oopsie...  Fixed stupid bug.

  Revision 1.11  1999/09/08 21:19:06  jzmrotchek
  Added in code to register an ExceptionHandler method.  This allows an error handler to redirect back to an app, which can then attempt to clean up and still maintain state, after everything from a "404 Not Found" to a "500 Server Error" condition.

  Revision 1.10  1999/09/03 00:04:18  scott
  fixed the parsing to ignore leading spaces .. for people cutting and
  pasting from netscape :-)

  Revision 1.9  1999/07/18 20:35:21  scott
  turned off some debugging :-(

  Revision 1.8  1999/07/18 20:31:11  scott
  Fixed a big with the source filter .. be VERY careful editing
  this module!  because it's building up code to be squirted into
  other modules, it's very difficult to find bugs!

  Revision 1.7  1999/07/18 20:13:55  scott
  Changed build table so it uses Storable::dclone to make a deep
  copy of the entries as they're added to the instance table
  ( $self->{_FN_TABLE} )   I was incorectly making shallow copies
  before and they were clobbering the original table.

  Revision 1.6  1999/06/18 15:28:41  scott
  Touched up some debugging messages

  Revision 1.5  1999/06/10 18:49:11  scott
  bug fix with oder of arguments to
  #SW callback

  Revision 1.4  1999/06/02 17:11:34  scott
  table generation fixes

  Revision 1.3  1999/06/01 18:46:52  scott
  fixed up some of the tables for callback processing

  Revision 1.2  1999/05/20 16:47:57  scott
  Fixed a bug in the docs - should be
   #SW CallBack Action [n] [proto]

  Revision 1.1  1999/05/20 14:21:00  scott
  New addition - source filter for SW applications


=head1 SEE ALSO

SW::Filter::Call, perl(1).

=cut
