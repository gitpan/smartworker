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

package SW::Exporter;

#------------------------------------------------------------
# SW::Exporter
#
# A small stripped-down version of Exporter used for
# SmartWorker.  It removes much of the overhead of loading
# the full Exporter module, and provides a speed gain.
#
# Parts of this module were shamelessly stolen from Exporter.
#
# WARNING : Adding lines to this module will severely impair
#           your chances of survival.  Keep it clean and small
#
#------------------------------------------------------------
# $Id: Exporter.pm,v 1.7 1999/11/22 17:24:21 krapht Exp $
#------------------------------------------------------------

$VERSION = '0.1';

#------------------------------------------------------------
# import - method (static?)
#
# When a module inherits SW::Exporter, it uses this import
# method as its default.  It takes care of exporting the
# names of variables, subs, etc. in other packages using the
# module by using typeglobs.
#------------------------------------------------------------

sub import
{
	my $pkg = shift;
	my $caller = caller();

	*exports = *{"${pkg}::SW_EXPORT"};

	my @tmp = @exports;

	foreach my $exp (@tmp)
	{
		if($exp =~ s/^\$//)
		{
			*{"${caller}::$exp"} = \${"${pkg}::$exp"};
		}
		elsif($exp =~ s/^\@//)
		{
			*{"${caller}::$exp"} = \@{"${pkg}::$exp"};
		}
		elsif($exp =~ s/^%//)
		{
			*{"${caller}::$exp"} = \%{"${pkg}::$exp"};
		}
		elsif($exp =~ s/^&//)
		{
			*{"${caller}::$exp"} = \&{"${pkg}::$exp"};
		}
		else
		{
			# We suppose it's a prototyped sub (with no & in front)
			*{"${caller}::$exp"} = \&{"${pkg}::$exp"};
		}

		# Sorry, glob exporting not supported yet.  I suppose it won't be of much
		# use in SW.
	}

}


1;

__END__

=head1 NAME

SW::Exporter - one line description of a 15 line module 

=head1 SYNOPSIS

	use SW::Exporter;
	use vars qw(@SW_EXPORT);

	@SW_EXPORT = qw(function_names variable_names);
	@ISA = qw(SW::Exporter);

=head1 DESCRIPTION

SW::Exporter is a stripped-down version of the original Exporter.  The only
reason for this module is a speed gain in loading the module.  Exporter has
around 230 lines of code to load, most of which is not needed for SmartWorker.

The goal here is to keep the features in this module as small as possible.
Please no fancy stuff.  Use the real Exporter for that.


=head1 METHODS

	import - used to export namespace into other packages

=head1 PARAMETERS

	none

=head1 AUTHOR

Jean-Francois Brousseau <krapht@hbe.ca>
HBE Software
September 12/99

=head1 REVISION HISTORY

  $Log: Exporter.pm,v $
  Revision 1.7  1999/11/22 17:24:21  krapht
  Added the License on top that I had removed

  Revision 1.6  1999/11/22 17:18:13  krapht
  Added some documentation

  Revision 1.4  1999/09/20 14:30:00  krapht
  Changes in most of the files to use the new way of referring to session,
  user, etc. (SW->user, SW->session).

  Revision 1.3  1999/09/12 14:38:40  krapht
  Removed the debugging statements.

  Revision 1.2  1999/09/12 06:48:49  krapht
  Fully working version.  It is now ready for use :)

  Revision 1.1  1999/09/12 04:40:25  krapht
  A stripped-down Exporter to reduce the overhead of loading a large module!


=head1 SEE ALSO

perl(1).

=cut
