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

package SW::Constants::Colours;

#------------------------------------------------------------
# SmartWorker - HBE Software, Montreal, Canada
# for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::Constants::Colours
#
# Provides colour constants for applications (UI).
#------------------------------------------------------------
# $Id: Colours.pm,v 1.6 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------


use strict;
use vars qw(@ISA $VERSION @SW_EXPORT);

use SW::Exporter;

use SW;
use SW::Constants;

@ISA = qw(SW::Constants SW::Exporter);

@SW_EXPORT = qw(getHexValue getAvailableColours registerColour);

# hex_col
#
# Hash associating colours with their hex value.  This hash
# contains the basic HTML-defined colours, but can be extended
# with the function registerColour to contain more colours.
#
# This hash should only contain the basic colours defined by
# HTML (see www.w3.org for details).

my %hex_col = (
				'white'		=> "#FFFFFF",
				'black'		=> "#000000",
				'red'			=> "#FF0000",
				'green'		=> "#008000",
				'lime'		=> "#00FF00",
				'olive'		=> "#808000",
				'blue'		=> "#0000FF",
				'navy'		=> "#000080",
				'aqua'		=> "#00FFFF",
				'yellow'		=> "#FFFF00",
				'fuschia'	=> "#FF00FF",
				'purple'		=> "#800080",
				'teal'		=> "#008080",
				'silver'		=> "#C0C0C0",
				'maroon'		=> "#800000",
				'gray'		=> "#808080",
);


#------------------------------------------------------------
# getHexValue - function
#
# getHexValue gets a string corresponding to a colour name
# as argument and looks up that string in the colour hash.
#
# Returns the hexadecimal value of the colour, or undef if
# the colour name wasn't found.
#------------------------------------------------------------

sub getHexValue
{

	if(exists($hex_col{$_[0]}))
	{
		return $hex_col{$_[0]};
	}
	else
	{
		return undef;
	}
}


#------------------------------------------------------------
# getAvailableColours - function
#
# getAvailableColours returns an array consisting of the
# names of all the available colours in the hash.
#------------------------------------------------------------

sub getAvailableColours
{
	my @col_names;

	foreach(keys %hex_col)
	{
		push(@col_names,$_);
	}

	return @col_names;
}


#------------------------------------------------------------
# registerColour - function
#
# This function provides a way to add new colours to the
# colour hash, therefore letting other applications use it!
#
# Returns the name registered, or undef if there is
# already a value associated with the key (colour name).
#------------------------------------------------------------

sub registerColour
{
	my $col = shift;
	$col =~ s/\W//; # Make sure the name is clean (kinda)

	if(!exists($hex_col{$col}))
	{
		$hex_col{$col} = $_[1];
		return $col;
	}
	else
	{
		return undef;
	}
}


1;

__END__

=head1 SYNOPSIS

=head1 DESCRIPTION




=head1 REVISION HISTORY

$Log: Colours.pm,v $
Revision 1.6  1999/11/15 18:17:33  gozer
Added Liscence on pm files

Revision 1.5  1999/10/07 03:00:13  krapht
Fixed some problem with modifying read-only value ($_[0]) in registerColour

Revision 1.4  1999/10/04 21:05:55  krapht
Forgot SW::Exporter in @ISA...oops!

Revision 1.3  1999/10/01 20:35:16  krapht
Fixed a stupid error (was missing = qw after SW_EXPORT)



=head1 AUTHOR

Jean-Francois Brousseau (krapht@hbe.ca)
HBE software
October 1, 1999
