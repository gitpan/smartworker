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

package Preferences::Text;

#------------------------------------------------------------
# Preferences::Text
#------------------------------------------------------------
# $Id: Text.pm,v 1.2 1999/09/07 16:23:30 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use SW::Language;

@ISA = qw(SW::Language Exporter AutoLoader);
@EXPORT = qw(

);

sub new
{
	my $className = shift;
	my $self = 	$className->SUPER::new(@_);
	bless ($self, $className);

	$self->{STRING_TABLE} = {
		"Full Name"=>{ "en"=>"Full name",
			  "fr"=>"Nom complet",
			  "ch"=>"�ϳo�s�D�X�{�b��L����",
			},
		"Email Address"=>{ "en"=>"E-mail address",
			  "fr"=>"Adresse electronique",
			  "ch"=>"�r���j�p",
			},
		"Font"=>{ "en"=>"Font",
			  "fr"=>"Fonte",
			  "ch"=>"�r��",
			},
		"Font Size"=>{ "en"=>"Font size",
			  "fr"=>"Grosseur de fonte",
			  "ch"=>"�ϳo�s�D�X�{�b��L����",
			},
		"Screen Size"=>{ "en"=>"Screen size",
			  "fr"=>"Grandeur de l'ecran",
			  "ch"=>"�r��",
			},
		"Language"=>{ "en"=>"Language",
			  "fr"=>"Langue",
			  "ch"=>"�ϳo�s�D�X�{�b��L����",
			},
		"Foreground Colour"=>{ "en"=>"Foreground Colour",
			  "fr"=>"Couleur de surface",
			},
		"Background Colour"=>{ "en"=>"Background Colour",
			  "fr"=>"Couleur de fond",
			  "ch"=>"�ϳo�s�D�X�{�b��L����",
			}
	};

	return $self;
};

#------------------------------------------------------------
# return true
#------------------------------------------------------------
1;

__END__

=head1 NAME

SW::App::FillIn - Fill In

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 PARAMETERS

=head1 AUTHOR

=head1 REVISION HISTORY

$Log: Text.pm,v $
Revision 1.2  1999/09/07 16:23:30  gozer
Fixed pod syntax errors


=head1 SEE ALSO

perl(1).

=cut



