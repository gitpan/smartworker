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

package Compose;
use SW::Util::Prep;
#---------------------------------------------------------------
# Compose
# part of an IMP clone for SmartWorker
#---------------------------------------------------------------
# $Id: Compose.pm,v 1.3 1999/11/15 18:17:32 gozer Exp $
#---------------------------------------------------------------

use strict;
use vars qw(@ISA $SW_FN_TABLE);

use SW::Application;
use SW::Renderer;
use SW::Panel;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;
use SW::GUIElement;
use SW::GUIElement::SelectBox;  # is this really necessary?
use SW::GUIElement::Link;
use SW::GUIElement::LinkExternal;
use SW::GUIElement::Button;
use SW::GUIElement::Text;
use SW::Data;
use SW::Data::Document;

@ISA = qw(SW::Application);
#
# initialise the app
#
sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	bless ($self, $classname);

	$self->buildTable();
	return $self;
}

sub swBuildUI
#SW TransOrder 15
{
    my $self = shift;

#-----------------------------------------------------------------------------#
# Colours and things#
#-----------------------------------------------------------------------------#

    my $darkblue='002266';
    my $black='000000';
    my $white='ffffff';
    my $yellow='ffffcc';
    my $offwhite='e0e0e0';
    my $softwhite='e9e9e9';
    my $grey='dcdcdc';
    my $impgfxdir = '/horde/imp/graphics/';

    my $blank = new SW::GUIElement::Text($self, {-text=>'&nbsp;'});

    my $mainPanel = $self->getPanel();
    my $topPanel = new SW::Panel::HTMLPanel($self,{-bgColor=>$darkblue});
    $topPanel->addElement(0,0,new SW::GUIElement::Text($self,{
	-text=>'<b>Compose a message</b> - <i>'.(scalar localtime()).'</i>',
	-textColor => $white}));
#
# Mail Headers Panel
#
    my $headersPanel = new SW::Panel::FormPanel($self,{-bgColor=>$yellow});
    $headersPanel->addElement(0,0,new SW::GUIElement::Text($self, {
	-text=>'From',
	-align=>'right',
	-bgColor=>$grey,
	-textColor=>'black'}));
    $headersPanel->addElement(1,0, new SW::GUIElement::TextBox($self, {
	-ref=>'from_addr',
	-width=>70}));
    $headersPanel->addElement(2,0, new SW::GUIElement::Link($self, {
	-bgColor=>$grey,
	-image=>$impgfxdir.'help1.gif'}));
    $headersPanel->addElement(0,1,new SW::GUIElement::Text($self, {
	-text=>'To',
	-align=>'right',
	-bgColor=>$grey,
	-textColor=>'black'}));
    $headersPanel->addElement(1,1, new SW::GUIElement::TextBox($self, {
	-ref=>'to_addr',
	-width=>70,
	-bgColor=>$yellow}));
    $headersPanel->addElement(2,1, new SW::GUIElement::Link($self, {
	-bgColor=>$grey,
	-image=>$impgfxdir.'help1.gif'}));
    $headersPanel->addElement(0,2,new SW::GUIElement::Text($self, {
	-text=>'Cc',
	-align=>'right',
	-bgColor=>$grey,
	-textColor=>'black'}));
    $headersPanel->addElement(1,2, new SW::GUIElement::TextBox($self, {
	-ref=>'cc_addr',
	-width=>70,
	-bgColor=>$yellow}));
    $headersPanel->addElement(2,2, new SW::GUIElement::Link($self, {
	-bgColor=>$grey,
	-image=>$impgfxdir.'help1.gif'}));
    $headersPanel->addElement(0,3,new SW::GUIElement::Text($self, {
	-text=>'Bcc',
	-align=>'right',
	-bgColor=>$grey,
	-textColor=>'black'}));
    $headersPanel->addElement(1,3, new SW::GUIElement::TextBox($self, {
	-ref=>'bcc_addr',
	-width=>70,
	-bgColor=>$yellow}));
    $headersPanel->addElement(2,3, new SW::GUIElement::Link($self, {
	-bgColor=>$grey,
	-image=>$impgfxdir.'help1.gif'}));
    $headersPanel->addElement(0,4,new SW::GUIElement::Text($self, {
	-text=>'Subject',
	-align=>'right',
	-bgColor=>$grey,
	-textColor=>'black'}));
    $headersPanel->addElement(1,4, new SW::GUIElement::TextBox($self, {
	-ref=>'subject',
	-width=>70,
	-bgColor=>$yellow}));
    $headersPanel->addElement(2,4, new SW::GUIElement::Link($self, {
	-bgColor=>$grey,
	-image=>$impgfxdir.'help1.gif'}));

    $headersPanel->addElement(0,5,new SW::GUIElement::Text($self, {
	-text=>'Attachment',
	-align=>'right',
	-bgColor=>$grey,
	-textColor=>'black'}));
    $headersPanel->addElement(1,5, new SW::GUIElement::TextBox($self, {
	-ref=>'attach',
	-width=>70,
	-bgColor=>$yellow}));
    $headersPanel->addElement(2,5, new SW::GUIElement::Link($self, {
	-bgColor=>$grey,
	-image=>$impgfxdir.'help1.gif'}));
    $headersPanel->addElement(0,6,new SW::GUIElement::Text($self, {
	-text=>'Options',
	-align=>'right',
	-bgColor=>$grey,
	-textColor=>'black'}));
    $headersPanel->addElement(1,6, new SW::GUIElement::Link($self, {
	-bgColor=>$yellow,
	-image=>$impgfxdir.'addressbook.gif'}));
    $headersPanel->addElement(2,6, new SW::GUIElement::Link($self, {
	-bgColor=>$grey,
	-image=>$impgfxdir.'help1.gif'}));
#
# Text panel
#
    my $textPanel = new SW::Panel::FormPanel($self, {
	-bgColor=>$grey}); 
    $textPanel->addElement(1,0, new SW::GUIElement::TextArea($self, {
	-ref=>'msg_body',
	-width=>'80',
	-height=>'20'}));
    $textPanel->addElement(0,1,new SW::GUIElement::Link($self, {
	-text=>'Spell Check in'}));
    $textPanel->addElement(1,1,new SW::GUIElement::SelectBox($self, {
	-name=>'Languages',
	-options=>['English','French'],
	-selected=>'English'}));
    $textPanel->addElement(2,1, new SW::GUIElement::Button($self, {
	-text=>'Cancel Message'}));
    $textPanel->addElement(3,1, new SW::GUIElement::Button($self, {
	-text=>'Send Message'}));
#
# Now add headers and message panels to main
#
    $mainPanel->addElement(0,0,$topPanel);
    $mainPanel->addElement(0,1,$headersPanel);
    $mainPanel->addElement(0,2,$textPanel);
}

#SW end


#-------------#
# return true #
#-------------#

1;
# docs start here
__END__

=head1 NAME

IMP::Compose - Compose a mail message

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Marc St-Laurent, marcst@hbe.ca

=head1 SEE ALSO

perl(1).

=head1 REVISION HISTORY

  $Log: Compose.pm,v $
  Revision 1.3  1999/11/15 18:17:32  gozer
  Added Liscence on pm files

  Revision 1.2  1999/09/07 16:23:22  gozer
  Fixed pod syntax errors

  Revision 1.1  1999/09/02 20:11:15  gozer
  New namespace convention

  Revision 1.2  1999/06/10 18:44:52  scott
  Fixed up to use new callbacks

  Revision 1.1  1999/05/15 00:01:18  marcst
  Simple Demo clone of IMP


=cut
