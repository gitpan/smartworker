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
								  "ch"=>"接受合併新聞",
                          "fr"=>"Est-se que vous appliquez pour la cr&eacute;dit quebecoise?"
                        },
                "sin"=>{ "en"=>"SIN",
								  "ch"=>"接受合併新聞",
                          "fr"=>"NAS"
                        },
                "name"=>{ "en"=>"Legal last name",
								  "ch"=>"接受合併新聞",
                          "fr"=>"Nom l&eacute;gal"
                        },
                "fnam"=>{ "en"=>"First name",
								  "ch"=>"編輯文件",
                          "fr"=>"Pr&eacute;nom"
                        },
                "firs"=>{ "en"=>"If this is your first income tax return, check this box",
								  "ch"=>"數據庫",
                          "fr"=>"Si c'est votre premi&egrave;re d&eacute;claration d'imp&ocirc;t, cochez ici"
                        },
                "sex" =>{ "en"=>"Sex",
                          "fr"=>"Sexe",
								  "ch"=>"接受合併新聞",
                        },
                "male"=>{ "en"=>"Male",
                          "fr"=>"Masculin",
								  "ch"=>"編輯文件",
                         },
                "yes" =>{ "en"=>"Yes",
                          "fr"=>"Oui",
								  "ch"=>"接受合併新聞",
                        },
                "no"  =>{ "en"=>"No",
                          "fr"=>"Non",
								  "ch"=>"編輯文件",
                        },
                "fema"=>{ "en"=>"Female",  
								  "ch"=>"接受合併新聞",
                          "fr"=>"F&eacute;minin"  
                        },
                "lang"=>{ "en"=>"Language of correspondance",
                          "fr"=>"Langue de correspondance",
								  "ch"=>"數據庫",
                        },
                "fren"=>{ "en"=>"French",
								  "ch"=>"編輯文件",
                          "fr"=>"Fran&ccedil;ais"
                        },
                "engl"=>{ "en"=>"English",
                          "fr"=>"Anglais",
								  "ch"=>"數據庫",
                        },
                "date"=>{ "en"=>"Date of birth",
                          "fr"=>"Date de naissance",
								  "ch"=>"接受合併新聞",
                        },
                "year"=>{ "en"=>"Year",
								  "ch"=>"編輯文件",
                          "fr"=>"Ann&eacute;e"
                        },
                "mont"=>{ "en"=>"Month",
                          "fr"=>"Mois",
								  "ch"=>"數據庫",
                        },
                "day" =>{ "en"=>"Day",
                          "fr"=>"Jour",
								  "ch"=>"數據庫",
                        },
                "numb"=>{ "en"=>"Number",
								  "ch"=>"接受合併新聞",
                          "fr"=>"Num&eacute;ro"
                        },
                "strt"=>{ "en"=>"Avenue, street, boulevard, P.O. box",
								  "ch"=>"接受合併新聞",
                          "fr"=>"Avenue, rue, boulevard, bo&icirc;te postale"
                        },
                "appt"=>{ "en"=>"Appartment",
                          "fr"=>"Appartement",
								  "ch"=>"編輯文件",
                        },
                "city"=>{ "en"=>"City, municipality",
								  "ch"=>"數據庫",
                          "fr"=>"Ville, municipalit&eacute;"
                        },
                "prov"=>{ "en"=>"Province",
                          "fr"=>"Province",
								  "ch"=>"編輯文件",
                        },
                "code"=>{ "en"=>"Postal code",
                          "fr"=>"Code postal",
								  "ch"=>"接受合併新聞",
                        },
		"situ"=>{ "en"=>"Check the box corresponding to your situation on December 31, 1998",
								  "ch"=>"接受合併新聞",
			  "fr"=>"Cochez la bo&icirc;te correspondant &agrave; votre situation au 31 d&eacute;cembre 1998"
			},
		"sing"=>{ "en"=>"single",
								  "ch"=>"編輯文件",
			  "fr"=>"c&eacute;libataire"
			},
		"marr"=>{ "en"=>"married",
			  "ch"=>"數據庫",
			  "fr"=>"mari&eacute;"
			},
		"sepa"=>{ "en"=>"separated",
			  "fr"=>"separe",
								  "ch"=>"編輯文件",
			},
		"divo"=>{ "en"=>"divorced",
								  "ch"=>"接受合併新聞",
			  "fr"=>"divorc&eacute;"
			},
		"wido"=>{ "en"=>"widowed",
			  "fr"=>"veuf (ve)",
								  "ch"=>"編輯文件",
			},
		"reli"=>{ "en"=>"in a religious order",   # no, it doesn't have anything to do with relish!
			  "fr"=>"dans un ordre religieux",
								  "ch"=>"接受合併新聞",
			},
		"defa"=>{ "en"=>"de facto spouse",
			  "fr"=>"epoux (se) de facto",
								  "ch"=>"編輯文件",
			  "fr"=>"&eacute;poux (se) de facto"
			},
		"stat"=>{ "en"=>"If your situation has changed since 1997, indicate the date of the change",
								  "ch"=>"編輯文件",
			  "fr"=>"Si votre situation a chang&eacute; depuis 1997, indiquez la date du changement"
			},
                "empi"=>{ "en"=>"Employment income",
                          "fr"=>"Revenu d'emploi",
								  "ch"=>"編輯文件",
                        },
                "empe"=>{ "en"=>"Employment expenses and deductions",
								  "ch"=>"接受合併新聞",
                          "fr"=>"D&eacute;penses et d&eacute;ductions d'emploi"
                        },
                "othe"=>{ "en"=>"Other employment income",
                          "fr"=>"Autres revenus d'emploi",
								  "ch"=>"數據庫",
                        },
                "othi"=>{ "en"=>"Other income",
                          "fr"=>"Autres revenus",
								  "ch"=>"接受合併新聞",
                        },
                "neti"=>{ "en"=>"Net income",
                          "fr"=>"Revenu net",
								  "ch"=>"數據庫",
                        },
                "toti"=>{ "en"=>"Total income",
                          "fr"=>"Revenus totaux",
								  "ch"=>"編輯文件",
                        },
                "totd"=>{ "en"=>"Total deductions",
								  "ch"=>"數據庫",
                          "fr"=>"D&eacute;ductions totales"
                        },
                "tott"=>{ "en"=>"Total taxable income",
                          "fr"=>"Revenu total taxable",
								  "ch"=>"接受合併新聞",
                        },
                "phhm"=>{ "en"=>"Home phone number",
								  "ch"=>"編輯文件",
                          "fr"=>"Num&eacute;ro de t&eacute;l&eacute;phone &agrave; la maison"
                        },
                "phwk"=>{ "en"=>"Work phone number",
								  "ch"=>"接受合併新聞",
                          "fr"=>"Num&eacute;ro de t&eacute;l&eacute;phone au bureau"
                        },
                "subm"=>{ "en"=>"Submit the form",
                          "fr"=>"Soumettre le formulaire",
								  "ch"=>"編輯文件",
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



