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

package SW::App::Calculator;

#------------------------------------------------------------
# SW::App::Calculator
#  Demo Calculator
#------------------------------------------------------------
# $Id: Calculator.pm,v 1.3 1999/11/15 18:17:27 gozer Exp $
#------------------------------------------------------------


use strict;
use vars qw($VERSION @ISA);

use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;
use SW::Data;
use SW::Data::Document;
use SW::Util;

# Load the stringtables

# use View::Text;

@ISA = qw(SW::Application);

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	bless ($self, $classname);

# 	my $cb = sub { $self->swTranslate(@_) };
# 	$self->registerCallback("swTranslate", $cb);

# 	$self->{stringTable} = View::Text->new("en");

	return $self;
}

sub swValidateUser
{
	my $self = shift;

	return 0 if ($self->{user}->{user} eq "guest");

	return 1;
}

sub swBuildUI
{
	my $self = shift;
	my $abort = shift;

	my $mainPanel = $self->getPanel();

	# set up the main screen

	
	my $htmlPanel = new SW::Panel::HTMLPanel($self,
										{ -background => ".",
										});

	$htmlPanel->addElement(0, 0, new SW::GUIElement::Text($self, <<EOT
<SCRIPT LANGUAGE="JavaScript">
<!--
// The basics of the calculator were designed in part with the help of the javascript calculator
// written by Aidan Dysart
// http://www.monkey.org/~adysart/java/calc.html

var power=false;
var buf=0;
var mode=0;

function set_mode(which)
{
  mode=which;
  alert("Mode has been changed to" + mode);
}

function change_equation(string)
{
  if(power==false) document.calculator.screen.value+=string;
  else {
    document.calculator.screen.value=string;
    power_it(1);
    power=false;
  }
}

function calculate()
{
  var equation = document.calculator.screen.value;
  document.calculator.screen.value=eval(equation);
  
}

function clearlcd()
{
  document.calculator.screen.value='';
}

function reverse()
{
  var temp = document.calculator.screen.value;
  document.calculator.screen.value= -temp;
}

function square_it()
{
  document.calculator.screen.value=Math.pow(document.calculator.screen.value,2);
}

function power_it(how)
{
  if(how==0)
    {
    buf=document.calculator.screen.value;
    power=true;
  }

  else document.calculator.screen.value=Math.pow(buf,document.calculator.screen.value);
}

function sin()
{
  document.calculator.screen.value=Math.sin(document.calculator.screen.value);
  alert("The value of sin 45 is "+Math.sin(45));
}

function cos()
{
  document.calculator.screen.value=Math.cos(document.calculator.screen.value);
}

function tan()
{
  document.calculator.screen.value=Math.tan(document.calculator.screen.value);
}

function log()
{
  alert("There is no such thing as a log!");
}

-->
</SCRIPT>

<FORM NAME="calculator">
<TABLE BORDER=1>
<TR><TD COLSPAN=5><INPUT TYPE="text" NAME="screen"></TD></TR>
<TR>
<TD COLSPAN=4>
<FONT SIZE=-1>
<INPUT TYPE="radio" NAME="angle" VALUE="Deg" CHECKED onClick="set_mode(0)">Deg
<INPUT TYPE="radio" NAME="angle" VALUE="Rad" onClick="set_mode(1)">Rad
<INPUT TYPE="radio" NAME="angle" VALUE="Grad" onClick="set_mode(2)">Grad
</FONT>
<TD align=center><INPUT TYPE="button" VALUE="AC" onClick="clearlcd()"></TD></TR>
<TR><TD COLSPAN=1 align=center></TD>
<TD align=center><INPUT TYPE="button" VALUE="x^y" onClick="power_it(0)"></TD>
<TD align=center><INPUT TYPE="button" VALUE="x^2" onClick="square_it()"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" / " onClick="change_equation('/')"></TD></TR>
<TR><TD align=center><INPUT TYPE="button" VALUE="sin" onClick="sin()"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" 7 " onClick="change_equation('7')"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" 8 " onClick="change_equation('8')"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" 9 " onClick="change_equation('9')"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" * " onClick="change_equation('*')"></TR>
<TR align=center><TR><TD align=center><INPUT TYPE="button" VALUE="cos" onClick="cos()"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" 4 " onClick="change_equation('4')"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" 5 " onClick="change_equation('5')"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" 6 " onClick="change_equation('6')"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" - " onClick="change_equation('-')"></TD></TR>
<TR><TR><TD align=center><INPUT TYPE="button" VALUE="tan" onClick="tan()"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" 1 " onClick="change_equation('1')"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" 2 " onClick="change_equation('2')"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" 3 " onClick="change_equation('3')"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" + " onClick="change_equation('+')"></TD></TR>
<TR><TD align=center><INPUT TYPE="button" VALUE="log" onClick="log()"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" 0 " onClick="change_equation('0')"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" . " onClick="change_equation('.')"></TD>
<TD align=center><INPUT TYPE="button" VALUE="+/-" onClick="reverse()"></TD>
<TD align=center><INPUT TYPE="button" VALUE=" = " onClick="calculate()"></TD></TR>
</TABLE>
</CENTER>
</FORM>
EOT
));

	$mainPanel->addElement(0, 0, $htmlPanel);
	
} #  end of draw sub

#------------------------------------------------------------
# return true
#------------------------------------------------------------
1;

__END__

=head1 NAME

SW::Application - Main framework class for SmartWorker applications

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Kyle Dawkins, kyle@hbe.ca

=head1 SEE ALSO

perl(1).

=head1 REVISION HISTORY

  $Log: Calculator.pm,v $
  Revision 1.3  1999/11/15 18:17:27  gozer
  Added Liscence on pm files

  Revision 1.2  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors

  Revision 1.1  1999/09/02 20:11:05  gozer
  New namespace convention

  Revision 1.1  1999/04/21 02:48:48  kiwi
  New Javascript applet

  Revision 1.3  1999/04/20 05:04:55  kiwi
  Made these work with the new themes a bit.

  Revision 1.2  1999/04/17 21:30:11  kiwi
  Fixed up Browse to use document names, fixed View to correctly display
  document info.

  Revision 1.1  1999/04/16 18:09:14  kiwi
  Basic app components

  Revision 1.2  1999/04/13 21:57:31  kiwi
  Changed it to use stringtables.

  Revision 1.1  1999/04/13 16:40:05  scott
  Test applications altered to work in the new Master / Application model



=cut


