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

package SW::App::MyApp;

use strict;

use vars qw($VERSION @ISA $SW_FN_TABLE @EXPORT @EXPORT_OK);

use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;
use SW::GUIElement::RadioButtonSet;
use SW::Data::Document;
use SW;

@ISA = qw(SW::Application);


sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	SW::debug($self, "Test debug message!",1);
	$self->buildTable;
	return $self;
}

sub swBuildUI
#SW TransOrder 15
{
	my $self = shift;
	
	my $leftPanel = new SW::Panel::FormPanel($self, "NamePanel" );
	my $rightPanel = new SW::Panel::FormPanel($self);
	my $bottomPanel = new SW::Panel::FormPanel($self, {
								-name=>"SnowBoarding",
								-grid_x=>10,
								-bgColor => "blue",
							}  );


	my $text = new SW::GUIElement::Text($self, {	-text=>"Please enter you name ....",
							-textColor=>"Yellow",
						  } );
						  
	my $textArea = new SW::GUIElement::TextArea($self,{	-width=>'50',
								-height=>'1',
							-name=>"name",
					 	  });

	my $subButton = new SW::GUIElement::Button($self, {
								-text=>"Send it!",
								-signal=>"Hello",
							  });
	my $subButton2 = new SW::GUIElement::Button($self, { -text => "Go", 
							  -signal => "Show",
								} );
   my $subButton3 = new SW::GUIElement::Button($self, { -text => "Toggle",
                       -signal => "Toggle",
                        } );

	my $text2 = new SW::GUIElement::Text($self, {	-text=>"<H2>My links panel!</H2>",
																	-bgColor => "Blue",
																		 });
	my $textArea2 = new SW::GUIElement::TextArea($self,  {	-text=>"Here's the text we started with",
								-width=>'40',
								-height=>'4',
							-name=>"nothing",
						     });


	my $image = new SW::GUIElement::Image($self, "http://www.webshots.com/photos/imgs2/snowboard3/1640-small.jpg");
	my $image3 = new SW::GUIElement::Image($self, {  -url=>"http://www.webshots.com/html/hc/sfhnk016-small.jpg",
							-border=>'1',
							-visible=>'0',
							} );
	my $image2 = new SW::GUIElement::Image($self, {  -url=>"http://www.webshots.com/photos/imgs2/snowboard3/1648-small.jpg",  
							-border=>'1',
							} );
	$self->addComponent($image3,"visibleImage");
	my $image4 = new SW::GUIElement::Image($self, {  -url=>"http://www.webshots.com/html/hc/sab015-small.jpg",  
							-border=>'1',
							} );

	my $bannerimage = new SW::GUIElement::Image($self, {  -url=>"http://www.ridesnowboards.com/news/imgs/work.jpg",  
							-border=>'1',
							} );

	my $link_plain = new SW::GUIElement::LinkExternal($self, { -signal=>"http://www.abcnews.com",
							   -text=>"Plain Text Link"
							} );

        my $link_img = new SW::GUIElement::LinkExternal($self, { -signal=>"http://www.hbe.ca/",
                                                           -text=>"Image URL link",
							   -image=>"http://www.webshots.com/html/hc/gren013-small.jpg",
                                                        } );

        my $link_obj = new SW::GUIElement::Link($self, { -signal=>"/perl/AnotherApp.pm",
                                                           -text=>"Image Object Link",
							   -image=>$image4,
                                                        } );


	my $radioButtonSet = new SW::GUIElement::RadioButtonSet( $self,
											{  -name => "boards",
											   -buttons => [('burton', 'Burton'), ('ride', 'Ride'),
												            ('lamar', 'Lamar')],
												-orientation => 'vertical',
												-name => 'boardType',
											});
											
						
	my $check1 = new SW::GUIElement::CheckBox($self, {	-name=>"bindings",
								-value=>"bindings",
								-text=>"Binding Included?",
							} );
							

	$leftPanel->addElement(0,0, $text);
	$leftPanel->addElement(0,1, $textArea);
	$leftPanel->addElement(0,2, $subButton);
	$leftPanel->addElement(1,2, $subButton3);
   $leftPanel->addElement(0,3, $bannerimage);

	$rightPanel->addElement(0,0, $text2);
	$rightPanel->addElement(0,1, $link_plain);
   $rightPanel->addElement(0,2, $link_img);
   $rightPanel->addElement(0,3, $link_obj);

	$bottomPanel->addElement(0,0, $image);
	$bottomPanel->addElement(1,0, $image2);
	$bottomPanel->addElement(2,0, $image3);

	$bottomPanel->addElement(3,0, $radioButtonSet);

	$bottomPanel->addElement(1,1, $check1);

	$bottomPanel->addElement(1,2, $subButton2);

	my $mainPanel = $self->getPanel();

	$mainPanel->addElement(0, 0, $leftPanel);
	$mainPanel->addElement(1, 0, $rightPanel);
	$mainPanel->addElement(0, 1, $bottomPanel);


	$mainPanel->updateState();	
} #  end of draw sub

#------------------------------------------------------------
#  Test of a callback function
#------------------------------------------------------------

sub swResponseHello
#SW Callback Hello 18
{
	my $self = shift;

	my $name = $self->getComponent("name")->getValue();	

	my $board = $self->getComponent("boards")->getValue();

	$self->getComponent("name")->setValue(ucfirst($name));

	my $newPanel = new SW::Panel::HTMLPanel($self);
   	my $mainPanel = $self->getPanel();
   	$newPanel->addElement(0,0, new SW::GUIElement::Text($self, "Thanks $name, Hello World!","White","Red"));

	if ($board eq "lamar")
	{
		$newPanel->addElement(0,1, new SW::GUIElement::Text($self, "LAMAR! YEAH!", "White"));

		my $user = $self->getUser();
		my $home = $user->getFullHome();
		my $homeDocument = new SW::Data::Document($self, $home, $self->{user});

		$newPanel->addElement(0,2, new SW::GUIElement::Text($self, SW::Util::flatten($homeDocument->{storage}), "White"));
	}
	elsif ($board eq "ride")
	{
		$newPanel->addElement(0,1, new SW::GUIElement::Text($self, "Ride?", "White"));
		my $user = $self->getUser();
		my $newDocument = new SW::Data::Document($self, "", $user);

#		$newPanel->addElement(0,2, new SW::GUIElement::Text($self, SW::Util::flatten($user), "White"));
		$newPanel->addElement(1,0, new SW::GUIElement::Text($self, SW::Util::flatten($newDocument->{storage}), "White"));
		
	}
	$self->addComponent($newPanel, "TogglePanel");
	if ($self->{session}->{panelVisible} != 1)
	{
		$newPanel->visible(0);
	}
   $mainPanel->addElement(1,1, $newPanel);

	SW::debug($self,"FInished Hello callback, returning persist",4);

	return "persist";
}

sub swResponseToggle
#SW Callback Toggle 19
{
	my $self = shift;

	if ( $self->getComponent("TogglePanel"))
	{

		if ($self->{session}->{panelVisible} == 1)
		{
			$self->getComponent("TogglePanel")->visible(0);
			$self->{session}->{panelVisible} = 0;
		}
		else
		{
			$self->getComponent("TogglePanel")->visible(1);
		$self->{session}->{panelVisible} = 1;
		}
	}
	return 1;
}

sub swResponseShow
#SW Callback Toggle 19
{
	my $self = shift;

	my $img = $self->getComponent("visibleImage");

	if ($self->{session}->{imgShown} == 1) 
	{
		$img->visible(0);
		$self->{session}->{imgShown} = 0;
	} else
	{
		$img->visible(1);
		$self->{session}->{imgShown} = 1;
	}
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

$Log: MyApp.pm,v $
Revision 1.5  1999/09/28 16:29:37  gozer
Changed a bit more authentication to have password changing/checking thru swauthd

Revision 1.4  1999/09/11 07:07:33  scott
Made substantial changes to the database schema and data storage models.
Now there's three global tables called datamap, dataaccess, and
datainfo.  These hide the many other more data specific tables
where the infomation is actually stored.

Revision 1.3  1999/09/11 07:06:07  scott
Tweaking these apps so they work with the new datamap model
(actually they don't change at all unless they were being bad
and writing their own SQL).

Revision 1.2  1999/09/07 16:23:17  gozer
Fixed pod syntax errors


=head1 SEE ALSO

perl(1).

=cut


