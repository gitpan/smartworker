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

#!/usr/local/bin/perl -I /usr/local/apache/dev/marc/smartworker
use SW::Util::Prep;
package ToDo;

#---------------------------------------------------------------
# ToDo (from MacgicalDesk)
# need two windows one for entering a new todo and another
# for viewing stored todos
#
#---------------------------------------------------------------
# $Id: ToDo.pm,v 1.2 1999/09/07 16:23:21 gozer Exp $
#---------------------------------------------------------------

use strict;
use vars qw($VERSION $SW_FN_TABLE @ISA @EXPORT @EXPORT_OK);
use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;
use SW::Data::Document;
use SW::Util;

@ISA = qw(SW::Application Exporter AutoLoader);
@EXPORT = qw(

);

#
# initialise the app
#

sub new 
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	bless ($self, $classname);

	$self->buildTable();	
	print STDERR "local..: ".SW::Util::flatten($self->{_FN_TABLE})."\n";
	return $self;
}

sub swBuildUI
#SW TransOrder 15
# build up the various panels (two main ones actually)
{
    my $self = shift;
    my $todoInitViewPanel = new SW::Panel::HTMLPanel($self, {
	-name=>'InitViewTodoPanel',
	-bgColor=>'blue'});
	 print STDERR "pkg... ".$todoInitViewPanel->{package}."\n";
    my $todoTopPanel = new SW::Panel::FormPanel($self, {
	-name=>'TopPanel',
	-bgColor=>'336699'});
    my $todoLeftPanel = new SW::Panel::HTMLPanel($self, {
	-name=>'LeftPanel',
	-grid_x=>1,
	-bgColor=>'4a7373'});

    my $newtodobutton = new SW::GUIElement::Button($self, {
	-text=>'New To Do',
	-target=>'NewToDo',
	});
    my $viewtodobutton = new SW::GUIElement::Button($self, {
	-text=>'My To Do',
	-target=>'ViewToDo',
	});
    $todoTopPanel->addElement(0,0,$viewtodobutton);
    $todoTopPanel->addElement(1,0,$newtodobutton);

    $todoLeftPanel->addElement(0,0,new SW::GUIElement::Image($self, " http://www2.magicaldesk.com/main/magicaldesk.gif"));

    my $mainPanel = $self->getPanel();
    $mainPanel->addElement(0,0,$todoLeftPanel);
    $mainPanel->addElement(1,0,$todoTopPanel);
#    $mainPanel->addElement(1,1,$todoInitViewPanel);
}

sub swResponseViewToDo
#SW callback ViewToDo  18
{

    my $self = shift;
    $self->debug("in ViewTodo");
    my $litishgrey = 'BFBFBF';
    my $liteyellow = 'FFFFC6';
    my $darkyellow = 'cccc99';
    my $todoViewPanel = new SW::Panel::HTMLPanel($self, {
	-name=>'ViewTodoPanel',
	-bgColor=>'white'});

#
# Obviously if this was real the following elements would be generated from 
# the user's data
#
    $todoViewPanel->addElement(0,0, new SW::GUIElement::Text($self, {
	-text=>'Raul Lipschitz\'s To Do List', 
	-textColor=>'black'
	}));
    $todoViewPanel->addElement(0,1, new SW::GUIElement::Text($self, {
	-text=>'Due Date',
	-bgColor=>$litishgrey,
	-textColor=>'black'
	}));
    $todoViewPanel->addElement(1,1, new SW::GUIElement::Text($self, {
	-text=>'Topic', 
	-bgColor=>$litishgrey,
	-textColor=>'black'
	}));
    $todoViewPanel->addElement(0,2, new SW::GUIElement::Text($self, {
	-text=>'5/14/99 15:00', 
	-bgColor=>$liteyellow,
	-textColor=>'black'
	}));
    $todoViewPanel->addElement(1,2, new SW::GUIElement::Link($self, {
	-image=>'http://www1.magicaldesk.com/main/todo.gif',
	-bgColor=>$liteyellow
	}));
    $todoViewPanel->addElement(2,2, new SW::GUIElement::Link($self, {
	-text=>'Something to do', 
	-bgColor=>$liteyellow,
	-textColor=>'black'
	}));
    my $sometext = <<EOM;
check out the K3Wl random text D()()DZ<br>
with line breaks and stuff<br>
and how about some other html...<b>bold</b><br>
<i>italic</i><br>
whatever
EOM
    $todoViewPanel->addElement(0,3, new SW::GUIElement::Text($self, { 
	-text=>$sometext,
	-bgColor=>$darkyellow,
	-textColor=>'black'
	}));
    $todoViewPanel->addElement(0,4, new SW::GUIElement::Text($self, { 
	-text=>'6/20/99 16:25', 
	-bgColor=>$liteyellow,
	-textColor=>'black'
	}));
    $todoViewPanel->addElement(1,4, new SW::GUIElement::Link($self, {
	-image=>'http://www1.magicaldesk.com/main/todo.gif',
	-bgColor=>$liteyellow
	}));
    $todoViewPanel->addElement(2,4, new SW::GUIElement::Link($self, {  
	-text=>'Yet another Todo', 
	-bgColor=>$liteyellow,
	-textColor=>'black'
	}));
    my $somemoretext = <<EOM;
blah blabh blahbl
asadsads
asdfa
sdfadsf
asdfasdfadsfasdf
asdfasdfasdf
asdfadsf
EOM
    $todoViewPanel->addElement(0,5, new SW::GUIElement::Text($self, {
	-text=>$somemoretext,
	-bgColor=>$darkyellow,
	-textColor=>'black'
	}));
    
    my $mainPanel = $self->getPanel();
#    $mainPanel->addElement(0,0,$todoLeftPanel,1);
#    $mainPanel->addElement(1,0,$todoTopPanel);
    $mainPanel->addElement(1,1,$todoViewPanel);
}

sub swResponseNewToDo
#SW callback NewToDo 18 
{

    my $self = shift;
    $self->debug("in NewTodo");

# colours...
    my $litishgrey = 'BFBFBF';
    my $liteyellow = 'FFFFC6';
    my $darkyellow = 'cccc99';

# dates and stuff...
    my (@years, @months, @daysofmonth, @years, @hoursofday, @minutes);
    my ($currentmonth, $currentdayofmonth, $currentyear);
    @months = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
    for my $d (0..30) {
	$daysofmonth[$d] = $d + 1;
    }
    for my $h (0..23) {
	$hoursofday[$h] = $h;
    }
    for my $m (0..11) {
	$minutes[$m] = $m * 5;
    }
    $currentmonth = $months[(localtime)[4]];
    $currentdayofmonth = $daysofmonth[(localtime)[3]-1];
    $currentyear = 1900 + (localtime)[5];
    my ($minyear,$maxyear);
    $minyear = $currentyear - 1;
    $maxyear = $currentyear + 5;
    my $i = 0;
    for my $y ($minyear..$maxyear) {
	$years[$i] = $y;
	$i++;
    }

# now set up the subpanels
    my $todoNewPanel = new SW::Panel::FormPanel($self, {
	-name=>'NewTodoPanel',
	-bgColor=>'white',
	-textColor=>'black'
	});
# Due Date Selection
    my $todoDateSelectPanel = new SW::Panel::FormPanel($self, {
	-name=>'DateSelectPanel',
	-bgColor=>'white',
	-textColor=>'black'
	});
    $todoDateSelectPanel->addElement(0,0,new SW::GUIElement::Text($self, {
	-text=>'Raul Lipschitz\'s New To Do Item',
	-bgColor=>$litishgrey,
	-textColor=>'black',
	}));
    $todoDateSelectPanel->addElement(0,1, new SW::GUIElement::Text($self, {
	-text=>'Due Date:',
	-textColor=>'black'
	}));
    $todoDateSelectPanel->addElement(1,1, new SW::GUIElement::SelectBox($self, {
	-ref=>'month_select',
	-options=>\@months,
	-selected=>$currentmonth
	}));
    $todoDateSelectPanel->addElement(2,1, new SW::GUIElement::SelectBox($self, {
	-ref=>'dayofmonth_select',
	-options=>\@daysofmonth,
	-selected=>$currentdayofmonth
	}));
    $todoDateSelectPanel->addElement(3,1, new SW::GUIElement::SelectBox($self, {
	-ref=>'year_select',
	-options=>\@years,
	-selected=>$currentyear
	}));
    $todoDateSelectPanel->addElement(4,1, new SW::GUIElement::Text($self, {
	-text=>'Time:',
	-textColor=>'black'
	}));
    $todoDateSelectPanel->addElement(5,1, new SW::GUIElement::SelectBox($self, {
	-ref=>'hour_select',
	-options=>\@hoursofday
	}));
    $todoDateSelectPanel->addElement(6,1, new SW::GUIElement::SelectBox($self, {
	-ref=>'minute_select',
	-options=>\@minutes
	}));
    $todoNewPanel->addElement(0,1, $todoDateSelectPanel);

# Content of the ToDo panel
    my $todoContentPanel = new SW::Panel::FormPanel($self, {
	-name=>'ContentPanel',
	-bgColor=>'white',
	-textColor=>'black'
	});
    $todoContentPanel->addElement(0,0, new SW::GUIElement::Text($self, {
	-text=>'Topic:',
	-textColor=>'black'
	}));
    $todoContentPanel->addElement(1,0, new SW::GUIElement::TextBox($self, {
	-ref=>'todo_topic',
	-width=>70
	}));
    $todoContentPanel->addElement(0,1, new SW::GUIElement::TextArea($self, {
	-width=>'65',
	-height=>'15',
	-ref=>'todo_content'
	}));
    $todoNewPanel->addElement(0,2, $todoContentPanel);
    
# Reminder options panel(s)
# I'm using lots of panels to play around with the rendering.
    my $todoReminderPanel = new SW::Panel::FormPanel($self, {
	-name=>'ReminderPanel',
	-bgColor=>'white',
	-textColor=>'black'
	});
    $todoReminderPanel->addElement(0,4, new SW::GUIElement::Text($self, {
	-text=>'Email Reminder',
	-bgColor=>$litishgrey,
	-textColor=>'black'
	}));
    $todoReminderPanel->addElement(0,5, new SW::GUIElement::Text($self, {
	-text=>'Recipients:',
    	-textColor=>'black'
}));
    $todoReminderPanel->addElement(1,5, new SW::GUIElement::TextBox($self, {
	-ref=>'recipients',
	-width=>70
	}));
    my $todoReminderCheckBoxPanel = new SW::Panel::FormPanel($self, {
	-name=>'ReminderCheckBoxPanel',
	-bgColor=>'white',
	-textColor=>'black'
	});
    $todoReminderCheckBoxPanel->addElement(0,0, new SW::GUIElement::Text($self, {
	-text=>'Reminder will be sent immediately',
	-textColor=>'black'
	}));
    $todoReminderCheckBoxPanel->addElement(1,0, new SW::GUIElement::CheckBox($self, {
	-ref=>'remind_immediate',
	-value=>'yes',
	-checked=>0
	}));  
    $todoReminderPanel->addElement(0,6, $todoReminderCheckBoxPanel);
    $todoReminderPanel->addElement(0,7, new SW::GUIElement::Text($self,  {
	-text=>'Reminder will be sent',
	-textColor=>'black'
    }));  
    $todoReminderPanel->addElement(1,7, new SW::GUIElement::TextBox($self, {
	-ref=>'remind_days',
	-width=>3
	}));
    $todoReminderPanel->addElement(2,7, new SW::GUIElement::Text($self, {
	-text=>'days before event completion',
	-textColor=>'black'
	}));
    $todoNewPanel->addElement(0,3, $todoReminderPanel);
# somewhat hackish...
    $todoNewPanel->addElement(0,4, new SW::GUIElement::Text($self, {
	-text=>qq/<hr noshade size='1'>/,
	}));
    $todoNewPanel->addElement(0,5, new SW::GUIElement::Button($self,{
	-text=>'Back',
	-target=>'ViewTodo'
	}));
    $todoNewPanel->addElement(1,5, new SW::GUIElement::Button($self,{
	-text=>'Save',
	-target=>'ViewTodo'
	}));
    my $mainPanel = $self->getPanel();
    $mainPanel->addElement(1,1,$todoNewPanel);
}

#-------------#
# return true #
#-------------#

#SW end

1;
# docs start here
__END__

=head1 NAME

ToDo - A Simple Demo App attempting to clone the Todo app of MagicalDesk

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Marc St-Laurent, marcst@hbe.ca

=head1 SEE ALSO

perl(1).

=head1 REVISION HISTORY

  $Log: ToDo.pm,v $
  Revision 1.2  1999/09/07 16:23:21  gozer
  Fixed pod syntax errors

  Revision 1.1  1999/09/02 20:11:13  gozer
  New namespace convention

  Revision 1.4  1999/06/15 20:50:49  marcst
  Fleshed out the callbacks for the NewToDo and ViewToDo buttons

  Revision 1.3  1999/06/10 18:44:49  scott
  Fixed up to use new callbacks

  Revision 1.2  1999/05/20 13:53:44  scott
  Updated ToDo to work with the new transaction model

  Revision 1.1  1999/05/15 00:00:58  marcst
  Simple Demo clone of ToDo list of MagicalDesk


=cut


