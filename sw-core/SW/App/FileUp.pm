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

#!/usr/bin/perl -I/usr/local/apache/dev/v1
use SW::Util::Prep;

# This is a sample app for playing tic tac toe against yourself.
# Actually, no it's not.  It's an upload module test that arose from a gutted tictactoe program.

# 	$Id: FileUp.pm,v 1.7 1999/11/15 18:17:28 gozer Exp $	


package SW::App::FileUp;

use strict;
#use vars qw($VERSION @ISA $SW_FN_TABLE @EXPORT @EXPORT_OK);
use vars qw($VERSION @ISA $SW_FN_TABLE);


use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;
use SW::GUIElement::Button;
use SW::GUIElement::RadioButtonSet;
use SW::GUIElement::FileUpload; 
use SW::GUIElement::Button;
use SW::GUIElement::Text;
use SW::Data::Document;
use SW::Data::File;
use Data::Dumper;
@ISA  = qw(SW::Application);

my $uberfilename;

sub new
{
        my $classname = shift;
        my $self = $classname->SUPER::new(@_);
	
        $self->buildTable;
        return $self;
}

sub swInitInstance {
	my $self = shift;
	SW::debug($self,"swInitInstance",5);
	$self->{session}->{grid} = [['']];
}


sub swBuildUI
#SW TransOrder 15
{
    my $self = shift;

    SW::debug($self,"swBuildUI",5);
    my $mainPanel = $self->getPanel();
    
    $mainPanel->setValue("background","NULL");
    $mainPanel->setValue("bgColor","Red");
    
    my $form = new SW::Panel::FormPanel($self,{-name=>'form',-signal=>'Upload'});

    my $upload = new SW::GUIElement::FileUpload($self,{
	name => "File",
    });
#    my $upload = new SW::GUIElement::FileUpload;

    $form->addElement(0,0,$upload);

    my $button = new SW::GUIElement::Button($self,{
	signal => "Upload", 
	text => "Upload it!", 
	type => "Submit",
    });
   
    $form->addElement(0,1, $button);

    my $uid = $self->{user}->{uid};
    my $uidtext = new SW::GUIElement::Text($self,"UID: " . $uid);
    $form->addElement(0,2,$uidtext);

    my $ubertext = new SW::GUIElement::Text($self,$uberfilename);
    $form->addElement(0,3,$ubertext);


    $mainPanel->addElement(0,0,$form);
    

}

sub swResponseUpload {
#SW Callback Upload 10
    my $self = shift;
    my $file_parameter_name = 'File';
    my $file = new SW::Data::File($self,$file_parameter_name);

#    print STDERR "File URI: " . $file->uri;

    1;
}


#SW end

1;

__END__

=head1 NAME

SW::App::FileUp - File Upload ?

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 PARAMETERS

=head1 AUTHOR

=head1 REVISION HISTORY

$Log: FileUp.pm,v $
Revision 1.7  1999/11/15 18:17:28  gozer
Added Liscence on pm files

Revision 1.6  1999/09/20 14:30:08  krapht
Changes in most of the files to use the new way of referring to session,
user, etc. (SW->user, SW->session).

Revision 1.5  1999/09/07 16:23:17  gozer
Fixed pod syntax errors


=head1 SEE ALSO

perl(1).

=cut





