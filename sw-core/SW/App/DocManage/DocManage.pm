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

package DocManage;

use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE @EXPORT @EXPORT_OK);

use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Data::Document;

use SDF;

@ISA = qw(SW::Application Exporter AutoLoader);
@EXPORT = qw(

);

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);

	$self->buildTable;
	return $self;
}

sub swBuildUI
#SW TransOrder 15
{
	my $self = shift;

	
	my $editPanel = new SW::Panel::FormPanel($self, { -name=> "NamePanel", } );
	my $previewPanel = new SW::Panel::HTMLPanel($self, {
																	-ref=> "PreviewPanel",
																	-frame=> "true",
																	-bgColor => "white",
																	} );

	my $title = new SW::GUIElement::Text($self, {	-text=>"SmartWorker Document Manager",
#							-textColor=>"",
						  } );
	my $textArea = new SW::GUIElement::TextArea($self,{	-width=>'50',
								-height=>'30',
								-ref=>"DocData",
					 	  });

	my $previewButton = new SW::GUIElement::Button($self, {
								-text=>"Update Preview",
								-target=>"Preview",
							  });
	my $helpButton = new SW::GUIElement::Button($self, { -text => "Brief Help", 
							  -target => "QuickRef",
								} );
   my $help2Button = new SW::GUIElement::Button($self, { -text => "Long Help",
                       -target => "Docs",
                        } );

	$editPanel->addElement(0,0, $title);
	$editPanel->addElement(0,1, $textArea);
	$editPanel->addElement(0,2, $previewButton);
	$editPanel->addElement(1,2, $helpButton);
	$editPanel->addElement(2,2, $help2Button);

	my $mainPanel = $self->getPanel();

	$mainPanel->addElement(0, 0, $editPanel);
	$mainPanel->addElement(1, 0, $previewPanel);

	$mainPanel->updateState();

} #  end of draw sub

sub setDefaults
#SW TransOrder 16
{
	my $self = shift;

	my $textArea = $self->getComponent("DocData");
	if (! $textArea->getValue('text'))
	{
		my $data = "# This is some test SDF stuck in here as a default ....\n#\n#\n\n";
		my $sdf = SDF::get_test_sdf;
		foreach (@$sdf)
		{
			$data .= $_;
		}
		$textArea->setValue('text', $data);
	}
}	

#------------------------------------------------------------
#  callback functions
#------------------------------------------------------------

sub ResponsePreview
#SW Callback Preview 18
{
	my $self = shift;

   my $previewPanel = $self->getComponent("PreviewPanel");
	my $ta = $self->getComponent("DocData");
	print STDERR "got it back: $ta";
	my @data;
	unshift  @data, $ta->getValue('text');

   $previewPanel->setValue("raw", SDF::convert(\@data));


	return;
#	return "persist";
}

sub swResponseToggle
#SW Callback QuickRef 18
{
	my $self = shift;

   my $previewPanel = $self->getComponent("PreviewPanel");
	$previewPanel->setValue('url', "http://www.mincom.com/mtr/sdf/quickref/qr_sdf.html");
	
	return;
}

sub swResponseShow
#SW Callback Docs 18
{
	my $self = shift;

   my $previewPanel = $self->getComponent("PreviewPanel");
	$previewPanel->setValue('url', "http://www.mincom.com/mtr/sdf/catalog.html");

	return;
}

#SW end

1;

__END__

=head1 NAME

SW::App::DocManage::DocManage - DocManage

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 PARAMETERS

=head1 AUTHOR

=head1 REVISION HISTORY

$Log: DocManage.pm,v $
Revision 1.3  1999/11/15 18:17:32  gozer
Added Liscence on pm files

Revision 1.2  1999/09/07 16:23:20  gozer
Fixed pod syntax errors


=head1 SEE ALSO

perl(1).

=cut

