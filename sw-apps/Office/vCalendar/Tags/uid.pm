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

package Office::vCalendar::Tags::Uid;
use Data::Dumper;

#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#------------------------------------------------------------
# Office::vCalendar::Tags::Uid
#  Creates/manipulates vCalendar (RFC2445) UID tag
#  objects.
#------------------------------------------------------------
#  CVS ID tag...
# $Id: uid.pm,v 1.2 1999/09/09 20:32:24 jzmrotchek Exp $
#------------------------------------------------------------


sub new {
    my $classname = shift;
    my $values = shift;
    my $tag = $values;
    bless \$tag, $classname;
    return $tag;
}

sub show_tag {
    my $tag = shift;
    my $out_tag;
    $out_tag .= "UID";

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

Office::vCalendar::Tags::Uid

=head1 SYNOPSIS

    my $event_uid = new Office::vCalendar::Tags::Uid;

=head1 DESCRIPTION


=head1 METHODS

  new -  Creates a new instance


=head1 PARAMETERS

    Allowable key values for hash passed:
    - value
    

=head1 AUTHOR

John F. Zmrotchek
HBE	zed@hbe.ca
August 9th, 1999

=head1 REVISION HISTORY

  $Log: uid.pm,v $
  Revision 1.2  1999/09/09 20:32:24  jzmrotchek
  Basic functionality, basic docs.






=head1 SEE ALSO

perl(1), Office::vCalendar(3), Office::vCalendar::Tags(3), RFC2445

=cut

