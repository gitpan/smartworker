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

# TaxForm.pm
# J-F (krapht@hbe.ca)
#

package SW::App::TaxForm;

use SW::Util::Prep;

use strict;
use vars qw(@ISA $SW_FN_TABLE @EXPORT @EXPORT_OK);

use SW::Application;
use SW::Panel;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;
use SW::GUIElement;
use SW::GUIElement::Text;
use SW::GUIElement::TextBox;
use SW::GUIElement::RadioButton;
use SW::GUIElement::RadioButtonSet;
use SW::GUIElement::Button;
use SW::GUIElement::CheckBox;
use SW::Data::Document;
use SW::App::TaxForm::Text;

@ISA=qw(SW::Application Exporter Autoloader);

sub new
{
  my $classname=shift;
  my $self=$classname->SUPER::new(@_);
  bless($self,$classname);

  $self->{stringTable} = TaxForm::Text->new("en");

  $self->buildTable();

  return $self;
}

# We're done with that one!!

sub swValidateUser
{
	my $self = shift;

	return 0 if $self->{user}->{user} eq "guest";

	return 1;
}

sub swInitApplication
{
  my $self=shift;

  my $appRegistry=$self->{master}->{appRegistry};
  my $data=SW::Data::Document->new($self);

  $self->{appDocument} = $data;
  $appRegistry->register(ref($self), [ $data->getFullPath()],[],"Yo man you gotta be!");

  return 1;
}

# This one too is A ok!!

sub swInitInstance
{
  my $self=shift;

  if(!$self->{document}) {
    $self->{document} = new SW::Data::Document($self,"",$self->{user});
    $self->{session}->{userDocumentPath} = $self->{document}->getFullPath();

#   my @objList= $self->{master}->{appRegistry}->dataObjects($self,ref($self));
#   $self->{session}->{dataDocumentPath}=shift(@objList);
  }
}

sub swInitTransaction
{
  my $self=shift;

  if(!$self->{document}) {
    $self->{document} = new SW::Data::Document($self,$self->{session}->{userDocumentPath},$self->{user},$self);
    $self->debug("Created a new userDocument : ".$self->{session}->{userDocumentPath});
  }
  else
  {
  		foreach my $f (keys %{$self->{document}->{storage}})
		{
			$self->debug("Setting values up for $f");

			if ($f =~ /^TaxForm/)
			{
				$self->{master}->setDataValue($f, $self->{document}->{storage}->{$f});
			}
		}

		$self->debug("Submitted arguments now: ".SW::Util::flatten($self->getMaster()->{data}));
	}

  return 1;
}

sub swBuildUI
#SW TransOrder 15
{
  my $self = shift;
  my $mainPanel = $self->getPanel();

  # Current translation language
  my $tr = $self->getLanguage();

  my $text = new SW::Panel::HTMLPanel($self);

  # This panel contains the user information fields (name, address, etc.)
  my $user_info = new SW::Panel::FormPanel($self);

  # This panel contains the tax specific information
  my $taxform = new SW::Panel::FormPanel($self);

  my $topImage = new SW::GUIElement::Image($self,{ -url=> $SW::Config::MEDIA_PATH."/images/topimage.gif"});

  #---------------------------------------------------------------------------------------------#
  # These are signs used throughout the form.  They are declared here for better readability    #
  #---------------------------------------------------------------------------------------------#

  my $separator    = new SW::GUIElement::Text($self, { -text=>'/'});                                        
  my $left_parant  = new SW::GUIElement::Text($self,{ -text=>'('});
  my $right_parant = new SW::GUIElement::Text($self,{ -text=>')'});

  #----------------------------------------------------------------------------#
  # These are all the fields of input from the user                            #
  #----------------------------------------------------------------------------#

  my $legalname = new SW::GUIElement::TextBox($self,{ -ref =>'legalname', -width=>'30'});
  my $firstname = new SW::GUIElement::TextBox($self,{ -ref =>'firstname', -width=>'30'});
  my $firsttime = new SW::GUIElement::CheckBox($self,{ -ref =>'first', -checked=>'0', -text=>''});

  my $sex = new SW::GUIElement::RadioButtonSet($self,{ -ref=>'sex', -buttons=>[('male',$self->{stringTable}->getString("male",$tr)),
                                                                               ('female',$self->{stringTable}->getString("fema",$tr))],
                                                       -orientation=>'horizontal'});

  my $language = new SW::GUIElement::RadioButtonSet($self,{ -ref=>'language', -buttons=>[('fr',$self->{stringTable}->getString("fren",$tr)),
                                                                                         ('en',$self->{stringTable}->getString("engl",$tr))],
                                                            -orientation=>'horizontal'});

  my $birth_day   = new SW::GUIElement::TextBox($self,{ -ref =>'b_day', -width=>'2'});
  my $birth_month = new SW::GUIElement::TextBox($self,{ -ref =>'b_mnth', -width=>'2'});

  my $birth_year = new SW::GUIElement::TextBox($self,{ -ref =>'b_year', -width=>'4'});

  #--------------------------------------------------------------------#
  # The user's complete address.  Here is the meaning of each field    #
  # $addr_nb   --> the address number                                  #
  # $addr_str  --> the name of the street                              #
  # $addr_appt --> the appartment number (if any)                      #
  # $addr_city --> the name of the city                                #
  # $addr_prov --> the name of the province                            #
  # $addr_code --> the postal code                                     #
  #--------------------------------------------------------------------# 

  my $addr_nb   = new SW::GUIElement::TextBox($self,{ -ref =>'addr_nb', -width=>'8'}); 
  my $addr_str  = new SW::GUIElement::TextBox($self,{ -ref =>'addr_str', -width=>'29'});
  my $addr_appt = new SW::GUIElement::TextBox($self,{ -ref =>'addr_appt', - width=>'5'});
  my $addr_city = new SW::GUIElement::TextBox($self,{ -ref =>'addr_city', -width=>'30'});
  my $addr_prov = new SW::GUIElement::TextBox($self,{ -ref =>'addr_prov', -width=>'3'});
  my $addr_code = new SW::GUIElement::TextBox($self,{ -ref =>'addr_code', -width=>'6'});

  my $sin = new SW::GUIElement::TextBox($self,{ -ref =>'sin', -width=>'9'});

  my $status = new SW::GUIElement::RadioButtonSet($self, { -ref=>'status',
                                                     -buttons=>[('single',$self->{stringTable}->getString("sing",$tr)),
								('married',$self->{stringTable}->getString("marr",$tr)),
								('separated',$self->{stringTable}->getString("sepa",$tr)),
								('divorced',$self->{stringTable}->getString("divo",$tr)),
								('widowed',$self->{stringTable}->getString("wido",$tr)),
								('religious',$self->{stringTable}->getString("reli",$tr)),
								('defacto',$self->{stringTable}->getString("defa",$tr))],
                                                            -orientation=>'vertical'});


  my $stat_chg_m = new SW::GUIElement::TextBox($self,{ -ref =>'stat_chg_m', -width=>'2'});
  my $stat_chg_d = new SW::GUIElement::TextBox($self,{ -ref =>'stat_chg_d', -width=>'2'});

  my $no_spouse     = new SW::GUIElement::CheckBox($self,{ -ref =>'no_spouse', -checked=>'0'});
  my $spouse_sin    = new SW::GUIElement::TextBox($self,{ -ref =>'spouse_sin', -width=>'9'});
  my $spouse_income = new SW::GUIElement::TextBox($self,{ -ref =>'spouse_income', -width=>'8'});


  #-------------------------------------------------------------#
  # Here start the declarations for tax information inputs      #
  #-------------------------------------------------------------#

  my $qst_credit = new SW::GUIElement::RadioButtonSet($self, { -ref=>'qst_credit', -buttons=>[('yes',$self->{stringTable}->getString("yes",$tr)),
                                                                                              ('no',$self->{stringTable}->getString("no",$tr))],
                                                               -orientation=>'horizontal'});


  my $emp_income     = new SW::GUIElement::TextBox($self,{ -ref =>'emp_income', -width=>'8'});    
  my $emp_expenses   = new SW::GUIElement::TextBox($self,{ -ref =>'emp_expenses', -width=>'8'});
  my $other_emp_inc  = new SW::GUIElement::TextBox($self,{ -ref =>'other_emp_inc', -width=>'8'});
  my $other_income   = new SW::GUIElement::TextBox($self,{ -ref =>'other_income', -width=>'8'});
  my $net_income     = new SW::GUIElement::TextBox($self,{ -ref =>'net_income', -width=>'8'});
  my $total_income   = new SW::GUIElement::TextBox($self,{ -ref =>'total_income', -width=>'8'});
  my $total_deduct   = new SW::GUIElement::TextBox($self,{ -ref =>'total_deduc', -width=>'8'});
  my $total_taxable  = new SW::GUIElement::TextBox($self,{ -ref =>'total_taxable', -width=>'8'});


  my $area_code_home = new SW::GUIElement::TextBox($self,{ -ref =>'areacode_h', -width=>'3'});
  my $phone_home     = new SW::GUIElement::TextBox($self,{ -ref =>'phone_h', -width=>'8'});

  my $area_code_work = new SW::GUIElement::TextBox($self,{ -ref =>'areacode_w', -width=>'3'});
  my $phone_work     = new SW::GUIElement::TextBox($self,{ -ref =>'phone_w', -width=>'8'});

  my $submit = new SW::GUIElement::Button($self,{ -text=>$self->{stringTable}->getString("subm",$tr), -target=>'TaxForm::Submit'});      

  #-------------------------------------------------#
  # Start adding objects created to the panels      #
  #-------------------------------------------------#

  $text->addElement(0,0,$topImage);

  $taxform->addElement(0,0,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("name",$tr)}));
  $taxform->addElement(1,0,$legalname);
  $taxform->addElement(0,1,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("fnam",$tr)}));
  $taxform->addElement(1,1,$firstname);
  $taxform->addElement(0,2,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("firs",$tr)}));
  $taxform->addElement(1,2,$firsttime);
  $taxform->addElement(2,2,$sex);
  $taxform->addElement(3,2,$language);
  $taxform->addElement(4,2,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("date",$tr)})); 
  $taxform->addElement(5,2,$birth_year);
  $taxform->addElement(6,2,$separator);
  $taxform->addElement(7,2,$birth_month);
  $taxform->addElement(8,2,$separator);
  $taxform->addElement(9,2,$birth_day);
  $taxform->addElement(0,3,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("numb",$tr)}));
  $taxform->addElement(1,3,$addr_nb);
  $taxform->addElement(2,3,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("strt",$tr)}));
  $taxform->addElement(3,3,$addr_str);
  $taxform->addElement(4,3,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("appt",$tr)}));
  $taxform->addElement(5,3,$addr_appt);
  $taxform->addElement(0,4,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("city",$tr)}));
  $taxform->addElement(1,4,$addr_city);
  $taxform->addElement(2,4,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("prov",$tr)}));
  $taxform->addElement(3,4,$addr_prov);
  $taxform->addElement(4,4,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("code",$tr)}));
  $taxform->addElement(5,4,$addr_code);

  $taxform->addElement(0,6,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("sin",$tr)}));
  $taxform->addElement(1,6,$sin);
  $taxform->addElement(2,6,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("situ",$tr)}));
  $taxform->addElement(3,6,$status);

  $taxform->addElement(4,6,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("stat",$tr)}));

  my $dateForm = new SW::Panel::HTMLPanel($self);
  $dateForm->addElement(0,0,$stat_chg_m);  
  $dateForm->addElement(1,0,$separator);
  $dateForm->addElement(2,0,$stat_chg_d);  

  $taxform->addElement(5, 6, $dateForm);

  $taxform->addElement(0,10, new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("qstc",$tr)}));
  $taxform->addElement(1,10,$qst_credit);

  # The tax income part starts here!!!

  $taxform->addElement(0,11,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("empi",$tr)}));
  $taxform->addElement(1,11,$emp_income);
  $taxform->addElement(2,11,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("empe",$tr)}));
  $taxform->addElement(3,11,$emp_expenses);
  $taxform->addElement(4,11,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("othe",$tr)}));
  $taxform->addElement(5,11,$other_emp_inc);
  $taxform->addElement(0,12,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("othi",$tr)}));
  $taxform->addElement(1,12,$other_income);
  $taxform->addElement(2,12,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("neti",$tr)}));
  $taxform->addElement(3,12,$net_income);
  $taxform->addElement(4,12,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("toti",$tr)}));
  $taxform->addElement(5,12,$total_income);
  $taxform->addElement(0,13,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("totd",$tr)}));
  $taxform->addElement(1,13,$total_deduct);
  $taxform->addElement(0,14,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("tott",$tr)}));
  $taxform->addElement(1,14,$total_taxable);
  $taxform->addElement(0,15,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("phhm",$tr)}));
  $taxform->addElement(0,16,$area_code_home);
  $taxform->addElement(1,16,$phone_home);
  $taxform->addElement(2,15,new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("phwk",$tr)}));
  $taxform->addElement(2,16,$area_code_work);
  $taxform->addElement(3,16,$phone_work);
  $taxform->addElement(0,17,$submit);

  $self->debug("All elements added, connecting to main panel");

  $mainPanel->addElement(0,0,$text);
  $mainPanel->addElement(0,1,$taxform);
}

# sub fillTargetPanel
# {
#   my $self=shift;
#   my $panel=shift;
#   my $data=$self->{userDocument};
#   my $app;
# 
#   if($data->{storage}->displayedApp}) 
#   {
#     $app=new TaxForm();
# 
#   }
# }


sub swResponseSubmit
#SW Callback 8 Submit
{
  my $self = shift;

  my $result = $self->getComponent("emp_income")->getValue();
  $result -= $self->getComponent("emp_expenses")->getValue();
  $result += $self->getComponent("other_emp_inc")->getValue();
  $result += $self->getComponent("other_income")->getValue();

  $self->getComponent("total_taxable")->setValue($result);

  foreach my $f (keys %{$self->getMaster()->{data}})
  {
		$self->debug("Checking $f...");
  		my $nspc;
		my $nkey;
		
		($nspc, $nkey) = split(/\:\:/, $f, 2);

		if ($nspc =~ "TaxForm" && $nkey ne "total_taxable")
		{
			$self->{document}->{storage}->{$f} = $self->getDataValue($f);
			$self->debug("Adding $f to storage");
		}
	}

	$self->{document}->{dirty} = 1;
	$self->{document}->save();
}

#SW end

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

$Log: TaxForm.pm,v $
Revision 1.2  1999/09/07 16:23:17  gozer
Fixed pod syntax errors


=head1 SEE ALSO

perl(1).

=cut


