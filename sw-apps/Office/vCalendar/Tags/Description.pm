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

package Office::vCalendar::Tags::Description;
#use Data::Dumper;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#------------------------------------------------------------
# Office::vCalendar::Tags::Description
#  Creates/manipulates vCalendar (RFC2445) Description tag
#  objects.
#------------------------------------------------------------
#  CVS ID tag...
# $Id: Description.pm,v 1.2 1999/09/09 16:25:10 jzmrotchek Exp $
#------------------------------------------------------------


sub new {
    my $classname = shift;
    my $values = shift;
    bless ($values, $classname);
    return $values;
}

sub show_tag {
    my $tag = shift;
    my $out_tag;
    $out_tag .= "DESCRIPTION";

    $out_tag .= ":";
    $out_tag .= $tag->{'value'};
    $out_tag .= "\n";


    return $out_tag;
}

sub show_value {
    my $tag = shift;
    my $property = shift;

    
    return $tag->{$property}
}

1;

__END__



=head1 NAME

Office::vCalendar::Tags::Description 

=head1 SYNOPSIS

    my $event_description = new Office::vCalendar::Tags::Description;

=head1 DESCRIPTION


=head1 METHODS

  new -  Creates a new instance


=head1 PARAMETERS

	# well known parameters for this object, normally passed into the contruction as a hash, 
	# or gotten and set using the getValue() and setValue() calls.

=head1 AUTHOR

John F. Zmrotchek
HBE	zed@hbe.ca
August 9th, 1999

=head1 REVISION HISTORY

  $Log: Description.pm,v $
  Revision 1.2  1999/09/09 16:25:10  jzmrotchek
  Added basic docs, skeletal support.

   

=head1 SEE ALSO

perl(1), Office::vCalendar(3), Office::vCalendar::Tags(3), RFC2445

=cut
