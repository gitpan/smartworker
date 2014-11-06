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

package TaxForm::Text;

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
                "qstc"=>{ "en"=>"Are you applying for the QST credit?",
								  "ch"=>"�����X�ַs�D",
                          "fr"=>"Est-se que vous appliquez pour la cr&eacute;dit quebecoise?"
                        },
                "sin"=>{ "en"=>"SIN",
								  "ch"=>"�����X�ַs�D",
                          "fr"=>"NAS"
                        },
                "name"=>{ "en"=>"Legal last name",
								  "ch"=>"�����X�ַs�D",
                          "fr"=>"Nom l&eacute;gal"
                        },
                "fnam"=>{ "en"=>"First name",
								  "ch"=>"�s����",
                          "fr"=>"Pr&eacute;nom"
                        },
                "firs"=>{ "en"=>"If this is your first income tax return, check this box",
								  "ch"=>"�ƾڮw",
                          "fr"=>"Si c'est votre premi&egrave;re d&eacute;claration d'imp&ocirc;t, cochez ici"
                        },
                "sex" =>{ "en"=>"Sex",
                          "fr"=>"Sexe",
								  "ch"=>"�����X�ַs�D",
                        },
                "male"=>{ "en"=>"Male",
                          "fr"=>"Masculin",
								  "ch"=>"�s����",
                         },
                "yes" =>{ "en"=>"Yes",
                          "fr"=>"Oui",
								  "ch"=>"�����X�ַs�D",
                        },
                "no"  =>{ "en"=>"No",
                          "fr"=>"Non",
								  "ch"=>"�s����",
                        },
                "fema"=>{ "en"=>"Female",  
								  "ch"=>"�����X�ַs�D",
                          "fr"=>"F&eacute;minin"  
                        },
                "lang"=>{ "en"=>"Language of correspondance",
                          "fr"=>"Langue de correspondance",
								  "ch"=>"�ƾڮw",
                        },
                "fren"=>{ "en"=>"French",
								  "ch"=>"�s����",
                          "fr"=>"Fran&ccedil;ais"
                        },
                "engl"=>{ "en"=>"English",
                          "fr"=>"Anglais",
								  "ch"=>"�ƾڮw",
                        },
                "date"=>{ "en"=>"Date of birth",
                          "fr"=>"Date de naissance",
								  "ch"=>"�����X�ַs�D",
                        },
                "year"=>{ "en"=>"Year",
								  "ch"=>"�s����",
                          "fr"=>"Ann&eacute;e"
                        },
                "mont"=>{ "en"=>"Month",
                          "fr"=>"Mois",
								  "ch"=>"�ƾڮw",
                        },
                "day" =>{ "en"=>"Day",
                          "fr"=>"Jour",
								  "ch"=>"�ƾڮw",
                        },
                "numb"=>{ "en"=>"Number",
								  "ch"=>"�����X�ַs�D",
                          "fr"=>"Num&eacute;ro"
                        },
                "strt"=>{ "en"=>"Avenue, street, boulevard, P.O. box",
								  "ch"=>"�����X�ַs�D",
                          "fr"=>"Avenue, rue, boulevard, bo&icirc;te postale"
                        },
                "appt"=>{ "en"=>"Appartment",
                          "fr"=>"Appartement",
								  "ch"=>"�s����",
                        },
                "city"=>{ "en"=>"City, municipality",
								  "ch"=>"�ƾڮw",
                          "fr"=>"Ville, municipalit&eacute;"
                        },
                "prov"=>{ "en"=>"Province",
                          "fr"=>"Province",
								  "ch"=>"�s����",
                        },
                "code"=>{ "en"=>"Postal code",
                          "fr"=>"Code postal",
								  "ch"=>"�����X�ַs�D",
                        },
		"situ"=>{ "en"=>"Check the box corresponding to your situation on December 31, 1998",
								  "ch"=>"�����X�ַs�D",
			  "fr"=>"Cochez la bo&icirc;te correspondant &agrave; votre situation au 31 d&eacute;cembre 1998"
			},
		"sing"=>{ "en"=>"single",
								  "ch"=>"�s����",
			  "fr"=>"c&eacute;libataire"
			},
		"marr"=>{ "en"=>"married",
			  "ch"=>"�ƾڮw",
			  "fr"=>"mari&eacute;"
			},
		"sepa"=>{ "en"=>"separated",
			  "fr"=>"separe",
								  "ch"=>"�s����",
			},
		"divo"=>{ "en"=>"divorced",
								  "ch"=>"�����X�ַs�D",
			  "fr"=>"divorc&eacute;"
			},
		"wido"=>{ "en"=>"widowed",
			  "fr"=>"veuf (ve)",
								  "ch"=>"�s����",
			},
		"reli"=>{ "en"=>"in a religious order",   # no, it doesn't have anything to do with relish!
			  "fr"=>"dans un ordre religieux",
								  "ch"=>"�����X�ַs�D",
			},
		"defa"=>{ "en"=>"de facto spouse",
			  "fr"=>"epoux (se) de facto",
								  "ch"=>"�s����",
			  "fr"=>"&eacute;poux (se) de facto"
			},
		"stat"=>{ "en"=>"If your situation has changed since 1997, indicate the date of the change",
								  "ch"=>"�s����",
			  "fr"=>"Si votre situation a chang&eacute; depuis 1997, indiquez la date du changement"
			},
                "empi"=>{ "en"=>"Employment income",
                          "fr"=>"Revenu d'emploi",
								  "ch"=>"�s����",
                        },
                "empe"=>{ "en"=>"Employment expenses and deductions",
								  "ch"=>"�����X�ַs�D",
                          "fr"=>"D&eacute;penses et d&eacute;ductions d'emploi"
                        },
                "othe"=>{ "en"=>"Other employment income",
                          "fr"=>"Autres revenus d'emploi",
								  "ch"=>"�ƾڮw",
                        },
                "othi"=>{ "en"=>"Other income",
                          "fr"=>"Autres revenus",
								  "ch"=>"�����X�ַs�D",
                        },
                "neti"=>{ "en"=>"Net income",
                          "fr"=>"Revenu net",
								  "ch"=>"�ƾڮw",
                        },
                "toti"=>{ "en"=>"Total income",
                          "fr"=>"Revenus totaux",
								  "ch"=>"�s����",
                        },
                "totd"=>{ "en"=>"Total deductions",
								  "ch"=>"�ƾڮw",
                          "fr"=>"D&eacute;ductions totales"
                        },
                "tott"=>{ "en"=>"Total taxable income",
                          "fr"=>"Revenu total taxable",
								  "ch"=>"�����X�ַs�D",
                        },
                "phhm"=>{ "en"=>"Home phone number",
								  "ch"=>"�s����",
                          "fr"=>"Num&eacute;ro de t&eacute;l&eacute;phone &agrave; la maison"
                        },
                "phwk"=>{ "en"=>"Work phone number",
								  "ch"=>"�����X�ַs�D",
                          "fr"=>"Num&eacute;ro de t&eacute;l&eacute;phone au bureau"
                        },
                "subm"=>{ "en"=>"Submit the form",
                          "fr"=>"Soumettre le formulaire",
								  "ch"=>"�s����",
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
Revision 1.3  1999/11/15 18:17:32  gozer
Added Liscence on pm files

Revision 1.2  1999/09/07 16:23:32  gozer
Fixed pod syntax errors


=head1 SEE ALSO

perl(1).

=cut



