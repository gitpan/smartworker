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

package Office::vCalendar::Component;

use Data::Dumper;
use Exporter;
use vars qw(@ISA);
@ISA = qw(Exporter);

@EXPORT_OK = qw( @zero_or_one_properties @zero_or_more_properties @either_or_properties );

#print "Loading component: ";

my @zero_or_one_properties;
my @zero_or_more_properties;
my @either_or_properties;



sub start_tag{
    my $self = shift;
    my $tag = "BEGIN:" . $self->{'type'} . "\n";
    return $tag;
}

sub end_tag{
    my $self = shift;
    my $tag = "END:" . $self->{'type'} . "\n";
    return $tag;
}

sub display{
    my $self = shift;
    my $tagtype = shift;
    my $output;
    $output .= start_tag($self); 
    foreach (@{$self->{'zero_or_one'}}) {
	$output .=  "Displaying: $_\n";
    }
    foreach (@{$self->{'either_or'}}) {
	$output .=  "Displaying: $_\n";
    }
    foreach (@{$self->{'zero_or_more'}}) {
	$output .=  "Displaying: $_\n";
    }
    $output .= end_tag($self);
    return $output;
}

1;











