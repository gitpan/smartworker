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

# Mail.pm
# A small mail program
package SW::App::Mail;

use SW::Util::Prep;

use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE @EXPORT @EXPORT_OK);

use SW::Application;
use SW::Panel;
use SW::Panel::FormPanel;
use SW::Panel::HTMLPanel;
use SW::GUIElement;
use SW::GUIElement::Text;
use SW::GUIElement::Image;
use SW::GUIElement::TextBox;
use SW::GUIElement::TextArea;
use SW::GUIElement::Button;
#use SW::GUIElement::MineSweeper;


# Load the string table from Text.pm

use SW::App::Mail::Text;

@ISA = qw(SW::Application);

sub new
{
	my $classname=shift;
	my $self=$classname->SUPER::new(@_);
	bless($self,$classname);

	$self->{stringTable} = SW::App::Mail::Text->new("en");

	$self->buildTable();

	return $self;
}

sub swInitApplication
{
	my $self=shift;

}

sub swBuildUI
#SW TransOrder 15
{
	my $self=shift;
	my $mainPanel = $self->getPanel();

	my $textPanel = new SW::Panel::HTMLPanel($self,);
	my $formPanel = new SW::Panel::FormPanel($self,{ -name=>'mailer'});

	my $topImage = new SW::GUIElement::Image($self,{ -url=>"http://www.microtec.net/~krapht/sw/top.jpg"});  
	$textPanel->addElement(0,0,$topImage);

	my $addr_text = new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("mail",$self->getLanguage())});
	my $address   = new SW::GUIElement::TextBox($self,{ -name=>'email', -width=>'50', -ref=>'email'});
	my $subj_text = new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("subj",$self->getLanguage())});   
	my $subject   = new SW::GUIElement::TextBox($self,{ -name=>'sub', -width=>'60', -ref=>'subject'});

	my $msg_text = new SW::GUIElement::Text($self,{ -text=>$self->{stringTable}->getString("mesg",$self->getLanguage())});
	my $message = new SW::GUIElement::TextArea($self,{ -name=>'msg', -height=>'20',
                                                     -width=>'100', -ref=>'msg'});
	my $sendButton = new SW::GUIElement::Button($self,{ -text=>'Send!', -signal=>"Send"});      
	my $clearButton = new SW::GUIElement::Button($self,{ -text=>'Clear!', -type=>'reset'});

	$formPanel->addElement(0,0,$addr_text);
	$formPanel->addElement(1,0,$address);
	$formPanel->addElement(0,1,$subj_text);
	$formPanel->addElement(1,1,$subject);
	$formPanel->addElement(0,2,$msg_text);
	$formPanel->addElement(0,3,$message); 
	$formPanel->addElement(0,4,$sendButton);
	$formPanel->addElement(1,4,$clearButton);

	$mainPanel->addElement(0,0,$textPanel);
	$mainPanel->addElement(0,1,$formPanel);

}

sub swResponseSend
#SW Callback Send 10
{
	my $self=shift;
# my $subject= $self->getComponent("sub")->getValue("subject");

	my @addresses = split(';',$self->getComponent("email")->getValue());
	my $subject = $self->getComponent("subject")->getValue();
	my $message = $self->getComponent("msg")->getValue();

	foreach my $address (@addresses) {
		open(MAIL,"|/usr/lib/sendmail $address");                                                                  

		print MAIL "Subject: $subject\n";
		print MAIL $message;                                  

		print MAIL "---------------------------------------------\nThis message was sent with HBE Mail, the easy way to send e-mail on the Web\n";
		print MAIL "For more information, point your favorite browser to www.smartworker.com\n";

		close(MAIL);
	}
}


#==========================
# We need to return true
#==========================
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

$Log: Mail.pm,v $
Revision 1.3  1999/11/15 18:17:28  gozer
Added Liscence on pm files

Revision 1.2  1999/09/07 16:23:17  gozer
Fixed pod syntax errors


=head1 SEE ALSO

perl(1).

=cut


