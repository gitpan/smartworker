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

#!/usr/bin/perl -I/usr/local/apache/dev/v1 -I/usr/local/apache/dev/zed/smartworker/SW
use SW::Util::Prep;


# TicTacToe.pm
# This is a sample app for playing tic tac toe against yourself.

package SW::App::TicTacToe;

use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE @EXPORT @EXPORT_OK);

use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;
use SW::GUIElement::Button;
use SW::GUIElement::RadioButtonSet;
use SW::Data::Document;
use SW::User::Pref;

use Data::Dumper;
@ISA = qw(SW::Application);
use SW::App::PrefMan('swBuildPrefUI','saveAppPrefs','getAppPref');

sub DATA_TYPE () { "TICTACTOE" }
sub APP_ID() { "TICTACTOE" }



my @preferences =  (['bgcolor','TEXT','red'],
		    ['textcolor','TEXT','yellow'], );
$SW::Config::AppDefaults::TicTacToe = \@preferences;

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	$self->{defaults} = $SW::Config::AppDefaults::TicTacToe;
	$self->{appid}    = APP_ID();
	$self->buildTable;

	return $self;
}

sub swInitInstance {
	my $self = shift;
	SW::debug($self,"swInitInstance",5);
	SW->session->setPrivateValue('grid' , "[['','',''],['','',''],['','','']]");
}

sub dispatcher {
#SW TransOrder 15
    my $self = shift;

    my $appstate = SW->session->getPrivateValue('appstate');
    print STDERR "appstate is $appstate\n";
    
    if ($appstate eq '') {
	print STDERR "Base state.\n";
	$self->swBuildUI;
    } elsif ($appstate eq 'swBuildPrefUI') {
	print STDERR "Pref state\n";
	$self->swBuildPrefUI;
    } elsif ($appstate eq 'SavePrefMenu') {
	print STDERR "Save state.\n";
	$self->saveAppPrefs;
	$self->swBuildUI;
    }
    print STDERR "Dispatch (pre): " . SW->session->getPrivateValue('prefattrs') . "\n";
    SW->session->delPrivateValue('appstate'); # make sure this isn't a leftover from a callback
    print STDERR "Dispatch (post): " . SW->session->getPrivateValue('prefattrs') . "\n";
}

sub swBuildUI
{
	my $self = shift;

	#print STDERR "\nUser:\n" . Dumper(SW->user->pref->get);
	#print STDERR "\nswBuildUI:\n" . Dumper($self);

	my $mainPanel = $self->getPanel();

	$mainPanel->setValue("background","NULL");
	
	$mainPanel->setValue("bgColor",SW->user->pref->getAppPref(APP_ID(),'bgcolor'));

	print STDERR "Bgcolor is: " . SW->user->pref->getAppPref(APP_ID(),'bgcolor') . "\n";

	my $gridPanel      = new SW::Panel::HTMLPanel($self,{-name=>'gridPanel',
							     -bgColor=>'black',
							     -bgColor=>SW->user->pref->getAppPref(APP_ID(),'bgcolor'),
							     -align=>'center',
							     -valign=>'center',
							     -cellpadding=>'5',
							 });

	my $titlePanel     = new SW::Panel::HTMLPanel($self,{-name=>'titlePanel',
								-bgColor=>'White',
								-align=>'Center'});

	my $titlePanelText = new SW::GUIElement::Text($self, { -text => '<font face=Sans-Serif><b>TicTacToe</b></font>',
							       -textColor=>'Black',
							       -fontSize=>'+3',
							   });
	$titlePanel->addElement(0,0,$titlePanelText);


	my $SpacerPanel = new SW::Panel::FormPanel($self,{-name=>'HSpacerPanel',
							  -bgColor=>'White',
							  });
	

	my $topLeftPanel   = new SW::Panel::FormPanel($self,{-name=>'0-0-topLeftPanel',
							     -bgColor=>'Black',
							     -text=>'white',
							     -align=>'center',
							     -valign=>'center',
							     -padding=>'10',
							     -spacing=>'10',
							     });
	my $topMiddlePanel = new SW::Panel::FormPanel($self,{-name=>'1-0-topLeftPanel',
							     -bgColor=>'Black',
							     -text=>'white',
							     -align=>'center',
							     -valign=>'center',
							     -padding=>'10',
							     -spacing=>'10',
							 });
	my $topRightPanel  = new SW::Panel::FormPanel($self,{-name=>'2-0-topLeftPanel',
							     -bgColor=>'Black',
							     -text=>'white',
							     -align=>'center',
							     -valign=>'center',
							     -padding=>'10',
							     -spacing=>'10',
});

	my $middleLeftPanel   = new SW::Panel::FormPanel($self,{-name=>'0-1-middleLeftPanel',
								-bgColor=>'Black',
								-text=>'white',
								-align=>'center',
								-valign=>'center',
								-padding=>'10',
								-spacing=>'10',
});
	my $middleMiddlePanel = new SW::Panel::FormPanel($self,{-name=>'1-1-middleLeftPanel',
								-bgColor=>'Black',
								-text=>'white',		
								-align=>'center',
								-valign=>'center',
								-padding=>'10',
								-spacing=>'10',
});
	my $middleRightPanel  = new SW::Panel::FormPanel($self,{-name=>'2-1-middleLeftPanel',
								-bgColor=>'Black',
								-text=>'white',
								-align=>'center',
								-valign=>'center',
								-padding=>'10',
								-spacing=>'10',
});

	my $bottomLeftPanel   = new SW::Panel::FormPanel($self,{-name=>'0-2-bottomLeftPanel',
								-bgColor=>'Black',
								-text=>'white',
								-align=>'center',
								-valign=>'center',
								-padding=>'10',
								-spacing=>'10',
});
	my $bottomMiddlePanel = new SW::Panel::FormPanel($self,{-name=>'1-2-bottomLeftPanel',
								-bgColor=>'Black',
								-text=>'white',
								-align=>'center',
								-valign=>'center',
								-padding=>'10',
								-spacing=>'10',
});
	my $bottomRightPanel  = new SW::Panel::FormPanel($self,{-name=>'2-2-bottomLeftPanel',
								-bgColor=>'Black',
								-text=>'white',
								-align=>'center',
								-valign=>'center',
								-padding=>'10',
								-spacing=>'10',
});

	my $xButton = new SW::GUIElement::Button($self, { -text => 'X',
							  -signal => 'XClick' });
	my $yButton = new SW::GUIElement::Button($self,{ -text => 'Y',
							 -signal => 'YClick' });


	my $xChosen = new SW::GUIElement::Text($self, { -text      => '<font size=+3><b>&nbsp;<br>&nbsp;&nbsp;X&nbsp;&nbsp;</b><br>&nbsp;</font>',
							-textColor => SW->user->pref->getAppPref(APP_ID(),'textcolor'),
							-align     => 'center',
							-valign    => 'center',
						    });
	my $yChosen = new SW::GUIElement::Text($self, { -text      => '<font size=+3><b>&nbsp;<br>&nbsp;&nbsp;Y&nbsp;&nbsp;</b><br>&nbsp;</font>',
							-textColor => SW->user->pref->getAppPref(APP_ID(),'textcolor'),
							-align     => 'center',
							-valign    => 'center',
						    });

	my $grid = eval SW->session->getPrivateValue("grid");
	
	if ($grid->[0][0] eq "") {	
		$topLeftPanel->addElement(0,0,$xButton);
		$topLeftPanel->addElement(1,0,$yButton);
	} elsif ($grid->[0][0] eq "Y") {
		$topLeftPanel->addElement(0,0,$yChosen);
	} elsif ($grid->[0][0] eq "X") {
		$topLeftPanel->addElement(0,0,$xChosen);
	}

	if ($grid->[1][0] eq "") {	
		$topMiddlePanel->addElement(0,0,$xButton);
		$topMiddlePanel->addElement(1,0,$yButton);
	} elsif ($grid->[1][0] eq "Y") {
		$topMiddlePanel->addElement(0,0,$yChosen);
	} elsif ($grid->[1][0] eq "X") {
		$topMiddlePanel->addElement(0,0,$xChosen);
	}


	if ($grid->[2][0] eq "") {	
		$topRightPanel->addElement(0,0,$xButton);
		$topRightPanel->addElement(1,0,$yButton);
	} elsif ($grid->[2][0] eq "Y") {
		$topRightPanel->addElement(0,0,$yChosen);
	} elsif ($grid->[2][0] eq "X") {
		$topRightPanel->addElement(0,0,$xChosen);
	}
	

	if ($grid->[0][1] eq "") {	
		$middleLeftPanel->addElement(0,0,$xButton);
		$middleLeftPanel->addElement(1,0,$yButton);
	} elsif ($grid->[0][1] eq "Y") {
		$middleLeftPanel->addElement(0,0,$yChosen);
	} elsif ($grid->[0][1] eq "X") {
		$middleLeftPanel->addElement(0,0,$xChosen);
	}


	if ($grid->[1][1] eq "") {	
		$middleMiddlePanel->addElement(0,0,$xButton);
		$middleMiddlePanel->addElement(1,0,$yButton);
	} elsif ($grid->[1][1] eq "Y") {
		$middleMiddlePanel->addElement(0,0,$yChosen);
	} elsif ($grid->[1][1] eq "X") {
		$middleMiddlePanel->addElement(0,0,$xChosen);
	}

	if ($grid->[2][1] eq "") {	
		$middleRightPanel->addElement(0,0,$xButton);
		$middleRightPanel->addElement(1,0,$yButton);
	} elsif ($grid->[2][1] eq "Y") {
		$middleRightPanel->addElement(0,0,$yChosen);
	} elsif ($grid->[2][1] eq "X") {
		$middleRightPanel->addElement(0,0,$xChosen);
	}

	if ($grid->[0][2] eq "") {	
		$bottomLeftPanel->addElement(0,0,$xButton);
		$bottomLeftPanel->addElement(1,0,$yButton);
	} elsif ($grid->[0][2] eq "Y") {
		$bottomLeftPanel->addElement(0,0,$yChosen);
	} elsif ($grid->[0][2] eq "X") {
		$bottomLeftPanel->addElement(0,0,$xChosen);
	}

	if ($grid->[1][2] eq "") {	
		$bottomMiddlePanel->addElement(0,0,$xButton);
		$bottomMiddlePanel->addElement(1,0,$yButton);
	} elsif ($grid->[1][2] eq "Y") {
		$bottomMiddlePanel->addElement(0,0,$yChosen);
	} elsif ($grid->[1][2] eq "X") {
		$bottomMiddlePanel->addElement(0,0,$xChosen);
	}

	if ($grid->[2][2] eq "") {	
		$bottomRightPanel->addElement(0,0,$xButton);
		$bottomRightPanel->addElement(1,0,$yButton);
	} elsif ($grid->[2][2] eq "Y") {
		$bottomRightPanel->addElement(0,0,$yChosen);
	} elsif ($grid->[2][2] eq "X") {
		$bottomRightPanel->addElement(0,0,$xChosen);
	}


	$gridPanel->addElement(0,0,$topLeftPanel);
	$gridPanel->addElement(2,0,$topMiddlePanel);
	$gridPanel->addElement(4,0,$topRightPanel);

	$gridPanel->addElement(0,2,$middleLeftPanel);
	$gridPanel->addElement(2,2,$middleMiddlePanel);
	$gridPanel->addElement(4,2,$middleRightPanel);

	$gridPanel->addElement(0,4,$bottomLeftPanel);
	$gridPanel->addElement(2,4,$bottomMiddlePanel);
	$gridPanel->addElement(4,4,$bottomRightPanel);
	

	$gridPanel->addElement(0,1,$SpacerPanel);
	$gridPanel->addElement(0,3,$SpacerPanel);

	$gridPanel->addElement(1,0,$SpacerPanel);
	$gridPanel->addElement(1,2,$SpacerPanel);
	$gridPanel->addElement(1,4,$SpacerPanel);


	$gridPanel->addElement(2,1,$SpacerPanel);
	$gridPanel->addElement(2,3,$SpacerPanel);

	$gridPanel->addElement(3,0,$SpacerPanel);
	$gridPanel->addElement(3,2,$SpacerPanel);
	$gridPanel->addElement(3,4,$SpacerPanel);

	$gridPanel->addElement(4,1,$SpacerPanel);
	$gridPanel->addElement(4,3,$SpacerPanel);



	$mainPanel->addElement(0,0,$titlePanel);
	$mainPanel->addElement(0,1,$gridPanel);

	my $prefPanel  = new SW::Panel::FormPanel($self,{-name=>'Preferences',
							 -bgColor=>'White',
							 });
	my $prefButton = new SW::GUIElement::Button($self,{signal => "PrefMenu",
							   text => "Preferences", 
							   type => "submit",
	});

	$prefPanel->addElement(0,0,$prefButton);

	$mainPanel->addElement(0,2,$prefPanel);
}
 
sub PrefMenu 
#SW Callback PrefMenu 10
{
    my $self = shift;
    print STDERR "Woo hoo!\n";
    print STDERR Dumper(SW->session);
    SW->session->setPrivateValue('appstate', 'swBuildPrefUI');
}

sub AppPrefSave 
#SW Callback AppPrefSave 10
{
    my $self = shift;
    print STDERR "Saverino (app)o...\n";
    print STDERR Dumper(SW->session);
    SW->session->setPrivateValue('appstate','SavePrefMenu');
}

sub UserPrefSave 
#SW Callback UserPrefSave 10
{
    my $self = shift;
    print STDERR "Saverino (user)...\n";
    print STDERR Dumper(SW->session);
    SW->session->setPrivateValue('appstate','SavePrefMenu');
}

sub swResponseXClick
#SW Callback XClick 10
{
	my $self = shift;
	my $grid = eval SW->session->getPrivateValue("grid");

	#-------------------------------------------------------------#
	# Here, we figure out what element of the array gets changed. #
	#-------------------------------------------------------------#
	my $formname = SW->master->getDataValue("_submitted");
	SW::debug($self,"X clicked  in form $formname",3);		# Debug Line: Shows form name passed in logs (L3)
	my $form_xpos = substr($formname,0,1);
	my $form_ypos = substr($formname,2,1);
	SW::debug($self,"Xpos: $form_xpos, Ypos: $form_ypos",3);	# Debug Line: Shows form X/Y coords passed in logs (L3)

	if ($grid->[$form_xpos][$form_ypos] ne "Y") {
		$grid
		->[$form_xpos][$form_ypos] = "X";
	} else {
		#--------------------------------------------------------------#
		# Here we'll eventually deal with generating an error message. #
		#--------------------------------------------------------------#
	}
	SW::debug($self,SW::Util::flatten(SW->session),5);

	SW->session->setPrivateValue("grid", $grid);
}

sub swResponseYClick
#SW Callback YClick 10
{
	my $self = shift;
	my $grid = eval SW->session->getPrivateValue("grid");

	#-------------------------------------------------------------#
	# Here, we figure out what element of the array gets changed. #
	#-------------------------------------------------------------#
	my $formname = SW->master->getDataValue("_submitted");
	SW::debug($self,"Y clicked  in form $formname",3);		# Debug Line: Shows form name passed in logs (L3)
	my $form_xpos = substr($formname,0,1);
	my $form_ypos = substr($formname,2,1);
	SW::debug($self,"Xpos: $form_xpos, Ypos: $form_ypos",3);	# Debug Line: Shows form X/Y coords passed in logs (L3)

	if ($grid->[$form_xpos][$form_ypos] ne "X") {
		$grid->[$form_xpos][$form_ypos] = "Y";
	} else {
		#--------------------------------------------------------------#
		# Here we'll eventually deal with generating an error message. #
		#--------------------------------------------------------------#
	}
	SW::debug($self,SW::Util::flatten(SW->session),5);
	SW->session->setPrivateValue("grid", $grid);
}

#SW end

1;









