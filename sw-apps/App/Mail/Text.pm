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

# Text.pm

#--------------------------------------------------------------------
#
#--------------------------------------------------------------------
#
#--------------------------------------------------------------------

package Mail::Text;   

use strict;
use vars qw(@ISA);

use SW::Language;

@ISA = qw(SW::Language Exporter Autoloader);

sub new
{
  my $classname=shift;
  my $self=$classname->SUPER::new(@_);
  bless($self,$classname);

  $self->{STRING_TABLE} = {
		"mail"=>{ "en"=>"E-mail address (es) : ",
			  "fr"=>"Adresse(s) de courier &eacute;lectronique : "
			},
		"subj"=>{ "en"=>"Subject : ",
			  "fr"=>"Sujet : "
			},
		"mesg"=>{ "en"=>"Message body : ",
			  "fr"=>"Message : "
			},
		"inst"=>{ "en"=>"To mail the message to multiple addresses, separate the addresses by a semi-colon in the first field",
			  "fr"=>"Pour envoyer le message &agrave; plusieurs adresses, s&eacute;parez les adresses par un point-virgule"
			}

  };

  return $self;
} 

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
Revision 1.2  1999/09/07 16:23:23  gozer
Fixed pod syntax errors


=head1 SEE ALSO

perl(1).

=cut


