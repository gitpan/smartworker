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

package SW::Util::Colors;

#-------------------------------------------------------------------------------------------------
# SW::Util::Colors
# HTML Colors that can be used to draw UIs 
#-------------------------------------------------------------------------------------------------
# $Id: Colors.pm,v 1.3 1999/11/15 18:17:33 gozer Exp $ #
#-------------------------------------------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

@ISA = qw();
$VERSION = '0.01';

my $colors = {};

$colors->{WHITE} = "ffffff";
$colors->{BLUE} = "0000ff";
$colors->{GREEN} = "00ff00";
$colors->{RED} = "ff0000";
$colors->{BLACK} = "000000";

#------------------------------------------------------------
# import (INTERNAL)
# Allows the caller to use the colors in its own namespace
# as $colors->{WHITE} let say
#
# call: NULL
#
# in:   - NULL
#
# out:  - NULL
#------------------------------------------------------------
sub import
{
	no strict;  # strict refs will complain about what this is doing
 
	my $caller = caller();
	*{$caller.'::colors'} = \$colors;

	use strict;
}

1;

__END__

=head1 NAME

	SW::Util::Colors - SmartWorker HTML colors hash

=head1 SYNOPSIS

	use SW::Util::Colors;

=head1 DESCRIPTION

	Instead of using the hexadecimal values of colors, simply refer them by their
	name as $colors->{COLORNAME}

=head1 FUNCTIONS

	None

=head1 METHODS

	None

=head1 AUTHOR

	Frederic Hurtubise
	fhurtubise@hbesoftware.com
	1999

=head1 REVISION HISTORY

	$Log: Colors.pm,v $
	Revision 1.3  1999/11/15 18:17:33  gozer
	Added Liscence on pm files
	
	Revision 1.2  1999/11/11 20:36:30  fhurtubi
	Added documentation
	

=head1 SEE ALSO
        
        perl(1).
        
=cut
