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

# Yahoo_Day.pm
# Copy of the Yahoo calendar

# $Id: Day.pm,v 1.3 1999/11/15 18:17:32 gozer Exp $

package Day;   

use SW::Util::Prep;

use strict;
use vars qw(@ISA $SW_FN_TABLE);

use SW::Application;
use SW::Panel;
use SW::Panel::FormPanel;
use SW::GUIElement;
use SW::GUIElement::Text;
use SW::GUIElement::Button;
use SW::Util::Cal;

@ISA=qw(SW::Application);


sub new
{
  my $classname=shift;
  my $self=$classname->SUPER::new(@_);
  bless($self,$classname);

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
  my $mainPanel=$self->getPanel();

  my $white='#ffffff';
  my $black='#000000';
  my $yellow='#eeeebb';
  my $blue='#90a8b8';
  my $pale_gray='#eeeeee';
  my $dark_gray='#cccccc';

  my $month=new SW::Panel::HTMLPanel($self,{ -bgColor=>$white, -border=>'1'});
  my $days=new SW::Panel::FormPanel($self,{ -bgColor=>$white});
  my $todo=new SW::Panel::HTMLPanel($self,{ -bgColor=>$white, -border=>'1'});

  #-----------------------------
  # Create the month section
  #-----------------------------

  my @mlen=qw(31 28 31 30 31 30 31 31 30 31 30 31);
  my @wdays=qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
  my @periods=qw(Day Week Month Year);
  my @date=gmtime(time());

  # my $topMonth = new SW::Panel::HTMLPanel($self,{ -bgColor=>$white, -border=>'1'});

  my $i=0;
  foreach my $period (@periods) {
    $month->addElement($i,0,new SW::GUIElement::Link($self,{ -text=>$period, -bgColor=>($period eq 'Day'?$blue:$white)}));
    $i++;
  }
  # $month->addElement(0,0,$topMonth);

  my $dude=new SW::Panel::HTMLPanel($self,{ -bgColor=>$dark_gray, -align=>'center'});

  $dude->addElement(0,0,new SW::GUIElement::Link($self,{ -image=>'http://us.yimg.com/i/cal/left4.gif', -bgColor=>$dark_gray}));
  $dude->addElement(1,0,new SW::GUIElement::Text($self,{ -text=>monthToString($date[4]).' 1999', -bgColor=>$dark_gray, -textColor=>$black, -attrib=>'bold'}));
  $dude->addElement(2,0,new SW::GUIElement::Link($self,{ -image=>'http://us.yimg.com/i/cal/right4.gif', -bgColor=>$dark_gray}));

  $month->addElement(0,1,$dude);

  my $weeksPanel = new SW::Panel::HTMLPanel($self,{ -bgColor=>$white, -grow_x=>'true', -align=>'center'});

  $i=0;
  foreach my $day (@wdays) {
    $weeksPanel->addElement($i,0,new SW::GUIElement::Text($self,{ -text=>substr($day,0,2), -bgColor=>$pale_gray, -textColor=>$black}));
    $i++;
  }

  #-----------------------------------------------
  # Fill the calendar with the appropriate dates
  #-----------------------------------------------

  # length of each month
  $date[5]+=1900;

  my $first_day=find_first_day(@date[3..6]);

  my $length=$mlen[$date[4]];
  my $row=1;

  for($i=0;$i<$length;$i++) {
    if(($i+1)==$date[3]) {
      $weeksPanel->addElement(($first_day%7),$row,new SW::GUIElement::Text($self,{ -text=>($i+1), -textColor=>$black, -attrib=>'bold'}));
    } else { 
      $weeksPanel->addElement(($first_day%7),$row,new SW::GUIElement::Link($self,{ -text=>($i+1)}));
    }

    if(((++$first_day)%7)==0) { $row++; }
  }

  $month->addElement(0,2,$weeksPanel);

  #-------------------------------
  # Today is part
  #-------------------------------

  my $bottom=new SW::Panel::HTMLPanel($self,{ -bgColor=>$yellow, -align=>'center'});

  $bottom->addElement(0,0,new SW::GUIElement::Text($self,{ -text=>"Today is ", -textColor=>$black}));
  $bottom->addElement(1,0,new SW::GUIElement::Link($self,{ -text=>monthToString($date[4])." $date[3], 1999", -attrib=>'bold'}));

  $month->addElement(0,3,$bottom);

  #-----------------------------------------------
  # Create the To Do section
  #-----------------------------------------------

  my $upperTodo = new SW::Panel::FormPanel($self,{ -bgColor=>$blue});

  $upperTodo->addElement(0,0,new SW::GUIElement::Text($self,{ -text=>'To Do', -textColor=>$black, -attrib=>'bold'}));
  $upperTodo->addElement(1,0,new SW::GUIElement::Button($self,{ -text=>'Add'}));

  $todo->addElement(0,0,$upperTodo);
  $todo->addElement(0,1,new SW::GUIElement::Text($self,{ -text=>"No tasks listed", -bgColor=>$pale_gray, -textColor=>$black, -attrib=>'ital'}));

  #-----------------------------------------------
  # Create the day section
  #-----------------------------------------------

  my $today=wdayToString($date[6]).' '.monthToString($date[4]).' '.$date[3].', '.$date[5];

  my $topDays = new SW::Panel::FormPanel($self,{ -bgColor=>$blue});

  $topDays->addElement(0,0,new SW::GUIElement::Link($self,{ -image=>'http://us.yimg.com/i/cal/left4.gif', -bgColor=>$blue}));
  $topDays->addElement(1,0,new SW::GUIElement::Text($self,{ -text=>$today, -bgColor=>$blue, -textColor=>$black, -fontSize=>'4', -attrib=>'bold'}));  
  $topDays->addElement(2,0,new SW::GUIElement::Link($self,{ -image=>'http://us.yimg.com/i/cal/right4.gif', -bgColor=>$blue}));
  $topDays->addElement(3,0,new SW::GUIElement::Button($self,{ -text=>'Add event', bgColor=>$blue}));

  $days->addElement(0,0,$topDays);

  my @hours=qw(8am 9am 10am 11am 12pm 1pm 2pm 3pm 4pm 5pm 6pm);

  $i=1;
  foreach my $hour (@hours) {
    $days->addElement(0,$i,new SW::GUIElement::Link($self,{ -text=>$hour, -bgColor=>($i%2==0)?$pale_gray:$dark_gray}));
    $i++;
  }

  $mainPanel->addElement(0,0,$month);
  $mainPanel->addElement(0,1,$todo);
  $mainPanel->addElement(1,0,$days);   
}


#-------------------------------------------------------------
# This function finds the first weekday of the month
#-------------------------------------------------------------

sub find_first_day
{
  my ($curday,$curmon,$curyear,$weekday)=@_;
  $curday-=(7*int($curday/7));
  my $result;
  ($weekday+1-$curday)>0?($result=($weekday+1-$curday)):($result=$weekday+(8-$curday));
  
  return $result;
}

#SW End

#==============
# Return true
#==============

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

$Log: Day.pm,v $
Revision 1.3  1999/11/15 18:17:32  gozer
Added Liscence on pm files

Revision 1.2  1999/09/07 16:23:34  gozer
Fixed pod syntax errors


=head1 SEE ALSO

perl(1).

=cut


