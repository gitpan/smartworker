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

package SW::Renderer::XMLRenderer;

#------------------------------------------------------------
#  SW::Renderer::XMLRenderer
#  Base class for all renderers, this class should never be
#  intstantiated on its own!
#------------------------------------------------------------
# $Id: XMLRenderer.pm,v 1.3 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($BORDER_DEBUG $VERSION @ISA @EXPORT @EXPORT_OK);

use SW::Config;
use SW::GUIElement;
use SW::Language;

use Data::Dumper;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw( $BORDER_DEBUG
);

$VERSION = '0.01';


sub new
{
	my ($classname, $app, $browser, @args) = @_;
	my $self = {    theApp => $app,
			Browser => $browser,
			prefs => $app->{user}->getSystemPreferences(),	
			 };

	my %sizes = ( "Small" => 1,
						"Medium" => 2,
						"Large" => 3,
					);
		      
	bless ($self, $classname);

	#------------------------------------------------------------
	# Get the User's Preferences for rendering purposes
	#------------------------------------------------------------

	$self->{font} = $self->{theApp}->{user}->preference('Font');
	$self->{fontsize} = $sizes{$self->{theApp}->{user}->preference('Font Size')};
	$self->{bgcolor} = $self->{theApp}->{user}->preference('Background Colour');
	$self->{fgcolor} = $self->{theApp}->{user}->preference('Foreground Colour');
	if (! $self->{fgcolor}) { $self->{fgcolor} = "FFFFFF"; }

	return $self;
}

#-------------------------------------------------------------
#  renderData
#------------------------------------------------------------

#sub renderData
# {
# 	my $self = shift;
# 	my $element = shift;
# 
# 	my $data = $element->render($self);
# 
# #	$self->{theApp}->debug("Rendering element: $element, got back $data");
# 
# 	return $data;
# }


#------------------------------------------------------------
# TFValueSting
#------------------------------------------------------------

sub TFValueString
{
	my $obj = shift;
	my $param = shift;

	my $val = $obj->getValue("$param");

	($val =~ /(true|yes|1)/i) ? 
		return qq/ $param="true"/ :
		return qq/ $param="false"/;
}	

#------------------------------------------------------------
# ValueString
#------------------------------------------------------------

sub ValueString
{
   my $obj = shift;
   my $param = shift;

   my $val = $obj->getValue("$param");

   if ($val =~ /(""|undef)/ )
	{
      return qq//;
	}
      return qq/ $param="false"/;
}  

#------------------------------------------------------------
# renderApplication
#------------------------------------------------------------

sub renderApplication
{
   my $self = shift;
   my $app = shift;
	my $data;
	
	my $name = $app->getValue("name");

	if ($app->getPanel()->getValue('master'))
	{
      $data .= (CGI::header( -type=>'text/html' ));

   #------------------------------------------------------------
   # HACK
   #------------------------------------------------------------

      $data .= $SW::Config::CHAR_SET{SW::Language::getCode($app->{master}->{user}->preference("Language"))};

		$data .= "<html><body bgcolor=ffffff text=000000>\n";

	}
   $data .= "<font size=1, face=verdana><swApp name=$name>\n";
   my $xmldata = $app->{panel}->render();

	if (1)	#	to turn off html prettied xml
	{
		$xmldata =~ s/\n//;
		$xmldata =~ s/>/&gt\;\n/g;
		$xmldata =~ s/</&lt;/g;
		$xmldata =~ s/&lt;(\w*) /&lt\;&blue;$1&endcolor; /g;
		$xmldata =~ s/&lt;\/(\w+)\W*&gt;/&lt;\/&dblue;$1&endcolor;&gt;/g;
		$xmldata =~ s/ (\w+)=/ &red;$1&endcolor;=/g;
		$xmldata =~ s/&blue;/<font color=blue>/g;
		$xmldata =~ s/&dblue;/<font color=darkblue>/g;
		$xmldata =~ s/&red;/<font color=red>/g;
		$xmldata =~ s/&endcolor;/<\/font>/g;
		$data .= "<pre>$xmldata</pre></font>";
	}
	else
	{
		$data .= $xmldata;
	}
	$data .= "</swApp>\n";
	return $data;
}


#-------------------------------------------------------------
#  renderPanel
#------------------------------------------------------------

sub renderPanel
{
     my ($self, $panel) = @_;
	  my $data = "";
	  my $background;


	  $self->{theApp}->debug("XML Render Panel");
	  $data .= "<panel ";

	  if (! $panel->{background} )
	  {
			$background = $SW::Config::MEDIA_PATH."/images/desktop.jpeg";
	  } else
	  {
			$background =  $SW::Config::MEDIA_PATH.$panel->{background}
	  }

	  my $foreground = $self->{theApp}->{user}->preference("Foreground Colour");

	  $data .= "background=\"$background\" fgcolor=\"$foreground\" ";

	  $panel->getValue("bgColor") ?
			my $col = $panel->getValue("bgColor") :
			my $col = $self->{prefs}->{"Background Color"};
 	  $data .= qq/bgcolor="$col" /;

	  $data = $self->_renderPanelCore($panel, $data);
     $data .= "</panel>\n";

	return $data;

}

#-------------------------------------------------------------
#  renderHTMLPanel
#------------------------------------------------------------

sub renderHTMLPanel
{
	my $self = shift;
	my $panel = shift;

	my $data = "";

   	if (! $panel->{params}->{url})
	{	
		$data = "<panel ";	
		$data = $self->_renderPanelCore($panel, $data);
		$data .= "</panel>\n";
	} else
	{
		 $self->{theApp}->debug("panel url is ".$panel->{params}->{url});

		my $ua = new LWP::UserAgent;
		$ua->agent("SmartWorker/0.1 " . $ua->agent);


		my $uri = $panel->{params}->{url};
		my $doc = get $uri;
		$data = $doc;
		#(my $data = $doc) =~ s/.+<\/head>//i;
		#$data =~ s/<\/body>.*$//i;
		#$self->{theApp}->debug($data);
			
	}
	
	return $data;
}

#-------------------------------------------------------------
#  renderFormPanel
#------------------------------------------------------------

sub renderFormPanel
{
	my $self = shift;
	my $panel = shift;


	my $uri_target = $self->{theApp}->getRequest()->uri();

   my $data = qq/<panel form=true >\n/;

	my %appendages = %{$self->{theApp}->getAppendages()};

	while (my ($k, $v) = each(%appendages))
	{  
		$data .= qq/<appendage $k="$v">\n/; 
	}

	$data = $self->_renderPanelCore($panel, @_, $data);	
        
	$data .= "</table></form>\n";
	return $data;
}

#-------------------------------------------------------------
#  _renderPanelCore
#------------------------------------------------------------

sub _renderPanelCore
{
   my $self = shift;
   my $panel = shift;
   my $data = shift;
   my $elements = $panel->{elements};
   my ($cols, $rows) = $panel->getSize();
	my $border= $panel->{border};
	my $spacing = $panel->getValue("spacing");
	my $panelBgColor = $panel->getValue("bgColor") || $self->{prefs}->{"Background Color"};


  		$data .= TFValueString($panel, "master");
      $data .= TFValueString($panel, "grow_x");
      $data .= TFValueString($panel, "grow_y");
      $data .= TFValueString($panel, "BorderDebug");
		$data .= " >";

	for (my $y=0; $y<$rows; $y++)
	{
		$data .= "<tr >\n";
		for (my $x=0; $x<$cols; $x++)
		{
			if (! $elements->[$x][$y])
			{
				next;
			} 
			if (! $panel->{elements}[$x][$y])
         {
            $data .= "<td ></td >";
         } else

         {
              if (! $panel->{elements}[$x][$y]->visible)
              {
                     $data .= "<td ></td >";
              } else
              {
					my $elColspan = $elements->[$x][$y];
					my $elRowspan = $elements->[$x][$y];
					my $elAlign = $panel->{elements}[$x][$y]->getValue('align');
					my $elBgColor = $panel->{elements}[$x][$y]->getValue('bgColor');
					if ($elBgColor eq "") { $elBgColor = $panelBgColor; }
					my $elbg = $panel->{elements}[$x][$y]->getValue('background');

   				$self->{theApp}->debug("panel x $cols y $rows");

               my $elVAlign = $panel->{elements}[$x][$y]->getValue('valign');
               my $elWidth = $panel->{elements}[$x][$y]->getValue('width');
					$self->{theApp}->debug("width $elWidth");
               my $elHeight = $panel->{elements}[$x][$y]->getValue('height');
					my $font = $self->{font};
				   my $fontsize = $self->{fontsize};

					$data .= qq/<TD /;
					if ($elColspan) { $data .= "colspan=$elColspan "; }
					if ($elRowspan) { $data .= " rowspan=$elRowspan "; }
               if ($elWidth) { $data .= qq/width=$elWidth /; }
					if ($elHeight) { $data .= "height=$elHeight "; }
					if ($elAlign) { $data .= "align=$elAlign "; }
					if ($elVAlign) { $data .= "valign=$elVAlign "; }
#HACK!!!
	#				if ($elbg)
	#				{
	#					$data .= qq/ background="$elbg">/;
	#				}
	#				else
	#				{
						$data .= qq/ bgcolor="$elBgColor">/;
	#				}
            $data .= $panel->{elements}[$x][$y]->render($self);
				$data .= "</td>\n ";
				}
			}

		}
		$data .= "</tr>\n";
	}

	if ($panel->getValue('BorderDebug'))
	{
		$data .= "</table></td></tr>\n";
	}
	return $data;
}


#------------------------------------------------------------
# renderClock
#------------------------------------------------------------

sub renderClock
{
	my $self = shift;

	my $data = "<B>".scalar(localtime)."</B>";

	return $data;

}
#-----------------------------------------------------
#  renderText
#_____________________________________________________


sub renderText
{
   my $self = shift;
	my $swText = shift;
	my $text = $swText->getValue('text');
	my $textColor = $swText->getValue('textColor');
	my $fontSize = $swText->getValue('fontSize');

	my $fontColor = $textColor || $self->{prefs}->{"Foreground Color"};
	my $fsize = $fontSize || $self->{prefs}->{"Font Size"};

	my $data .= " <font face=\"".$self->{font}."\" size=\"$fsize\" color=\"$textColor\">$text</font> ";	

	return $data;
}

#------------------------------------------------------------
# renderChat
#------------------------------------------------------------

sub renderChat
{
	my $self = shift;
	my $chat = shift;

	my $user = $chat->getValue('user');
	my $width = $chat->getValue('width');
	my $height = $chat->getValue('height');

	my $data = "<applet codebase=\"".$SW::Config::JAVA_CODE_BASE."\" code=\"chat\" width=$width height=$height>\n";
	$data .= "<param name=\"CHANNEL\" value=\"sw\">";
	$data .= "<param name=\"MONIKER\" value=\"$user\">";
	$data .= "</applet>\n";

	return $data;
}

#-----------------------------------------------------
#  renderTextBox
#_____________________________________________________

sub renderTextBox
{
        my $self = shift;
        my $swTextBox = shift;

        my ($chars, $rows) = $swTextBox->getSize();
        my $ref = $swTextBox->getValue('ref');
        my $text = $swTextBox->getValue('text');

        my $data .= qq/<input type=text name="$ref" size=$chars value="$text">/;

        return $data;

}

#-----------------------------------------------------
#  renderTextArea
#_____________________________________________________

sub renderTextArea
{
        my $self = shift;

        my ($swTextArea) = @_;
        my ($chars, $rows) = $swTextArea->getSize();
	my $ref = $swTextArea->getValue("ref");
	my $text = $swTextArea->getValue('text');
	
	my $data .= qq/<textarea NAME="$ref" ROWS=$rows COLS=$chars >$text<\/textarea>/;

        return $data;

}

#-----------------------------------------------------
#  renderButton
#_____________________________________________________


sub renderButton
{
   my $self = shift;
	my $swButton = shift;
	my $data;

	my $text = $swButton->getValue('text');
   my $target = $swButton->getValue('target');
   my $textColor = $swButton->getValue('textColor');
	my $type = $swButton->getValue('type');


	# should this default to pre or post?  curretnly it's set to post

	if ($swButton->getValue('preBuild'))
	{
		$data = qq/ <input type=hidden name="cb" value="$target"> /;
	} else
	{
		$data = qq/ <input type=hidden name="postcb" value="$target"> /;
	}
	$data .= qq/<input type="$type" value="$text" >/;
	return $data;
}

#-----------------------------------------------------
#  renderLink
#_____________________________________________________

sub renderLink
{
        my $self = shift;
	my $link = shift;

	my $target = $link->getValue('target');
	my $icon = $link->getValue('icon');

	if ($target =~ /^[A-Za-z0-9]+$/)
	{
		#------------------------------------------------------------
		# target is a callback
		#------------------------------------------------------------

		my $cb = $target;
		
		$target = $self->{theApp}->getRequest()->uri();
		$target .= "?";
		while (my ($k, $v) = each(%{$self->{theApp}->getAppendages()}))
		{  
			$target .= "$k=$v&"; 
		}
		$target .= "cb=$cb&";
		while (my ($k, $v) = each(%{$link->{params}->{args}}))
                {  $target .= "$k=$v&"; }
	}
	elsif ($target =~ /^\//)
	{	#  maybe move all this into swLink with a getArgs
		#  method and some more strict checking 
		
		$target .= "?";
		while (my ($k, $v) = each(%{$self->{theApp}->getAppendages()}))
		{  $target .= "$k=$v&"; }
		$target .= "m=".$link->{params}->{ref}."&";
		while (my ($k, $v) = each(%{$link->{params}->{args}}))
                {  $target .= "$k=$v&"; }
	} else {
		$self->{theApp}->debug("Error:  $target looks like an external link, use swLinkExternal");
		return;
	}
        my $text = $link->getValue('text');
        if (! $text)
        { $text = $link->getValue('target'); }

	my $data = qq/<a href="$target">/;
	if ($link->getValue('image'))
	{
		my $image = $link->getValue('image');
		if (ref($image))   # an image element
		{
			$data .= $image->render($self);
		} else	# just an image url
		{
			$data .= qq/<img src="$image" alt="$text" border=0 >/;
		}
	} else	#text link
	{
		if ($icon)
		{
			$data .= qq/<img border=0 valign=middle width=24 height=24 src="\/sw_lib\/images\/$icon"> /;
		}
		$data .= qq/<font size="/.$self->{fontsize}.qq/" face="/.$self->{font}.qq/" >$text<\/font>/;
	}
	$data .= "</a>";

        return $data;
}

#-----------------------------------------------------
#  renderLinkExternal
#_____________________________________________________

sub renderLinkExternal
{
        my $self = shift;
        my $link = shift;

        my $target = $link->getValue('target');

        if ($target =~ /^\/.+$/)
        {
                $self->{theApp}->debug("Error:  $target looks like an internal link, usr swLink");
                return;
        }

        my $data = qq/<a href="$target">/;

        my $text = $link->getValue('text');
        if (! $text)
        { 
		$text = $link->getValue('target'); 
	}
        if ($link->getValue('image'))
        {
                my $image = $link->getValue('image');
                if (ref($image))   # an image element
                {
                        $data .= $image->render($self);
                } else  # just an image url
                {
                        $data .= qq/<img src="$image" alt="$text" border=0 >/;
                }
        } else  #text link
        {
                $data .= $text;
        }
 
	$data .= "</a>";

        return $data;
}

#-----------------------------------------------------
#  renderImage
#_____________________________________________________

sub renderImage
{
	my $self=shift;

	my $swImage = shift;
	my $url = $swImage->getValue('url');
	my $width = $swImage->getValue('width');
        my $height = $swImage->getValue('height');
        my $border = $swImage->getValue('border');
        my $text = $swImage->getValue('text');
        my $align = $swImage->getValue('align');
	if (! $border)
	{
		$border = 0;
	} 

	my $data = qq/ <img src="$url" /;

	if ($width) 
	{ 
		$data .= qq/width="$width " /; 
	}
	if ($height) 
	{ 
		$data .= qq/height="$height" /; 
	}

	$data .= qq/ border="$border"/;

	if ($text)
	{
		$data .= qq/ alt="$text"/;
	}

	if ($align)
	{
		$data .= qq/ align="$align"/;
	}

	$data .= ">";

	return $data;
}

#-----------------------------------------------------
#  renderRadioButtonSet	
#_____________________________________________________

sub renderRadioButtonSet
{
        my $self = shift;
	my $buttonSet = shift;
	my $buttons = $buttonSet->getButtons();

        my $data = "";
        foreach my $b (@$buttons)
        {
                my $renderCall = "\$b->render(\$self)";
                $data .= eval $renderCall;
                if ($buttonSet->{params}->{orientation} eq "vertical")
                { $data .= "<br>\n"; }
                else { $data .= "  "; }
        }
        return $data;
}



#-----------------------------------------------------
#  renderRadioButton
#_____________________________________________________

sub renderRadioButton
{
        my $self=shift;

        my $swRadioButton = shift;
	my $ref = $swRadioButton->getValue("ref");
	my $value = $swRadioButton->getValue('value');
	my $text = $swRadioButton->getValue('text');
	my $checked = undef;
	
	if ($swRadioButton->{set}->{params}->{checked} eq $value) 
	{ $checked = 1; } 
	
	$self->{theApp}->debug("checked :".$swRadioButton->{set}->{checked}. " value: $value");

        my $data = qq/ <input type="radio" name="$ref" value="$value" /;
        if ($checked) { $data .= " checked "; };
        $data .= " >";
        $data .= qq/ $text /;
        return $data;
}

#-----------------------------------------------------
#  renderCheckBox
#_____________________________________________________

sub renderCheckBox
{
        my $self=shift;

        my ($swCheckBox) = @_;
        my $ref = $swCheckBox->getValue('ref');
        my $value = $swCheckBox->getValue('value');
        my $text = $swCheckBox->getValue('text');
	my $checked = $swCheckBox->getValue('checked');
	

        my $data = qq/ <input type=checkbox name="$ref" value="$value" /;
	if ($checked) { $data .= " checked "; };
	$data .= " >";
        $data .= qq/ $text /;

        return $data;
}

#-----------------------------------------------------
#  renderSelectBox
#_____________________________________________________

sub renderSelectBox
{
        my $self=shift;

        my ($swSelectBox) = @_;

	my $ref = $swSelectBox->getValue('ref');
	my $options = $swSelectBox->getValue('options');
	my $sel = $swSelectBox->getValue();

        my $data = qq/ <select name="$ref" > /;
	foreach my $o (@$options)
	{
		if ($o eq $sel)
		{
			$data .= qq/\t<option selected value="$o">$o\n/;
		} else {
			$data .= qq/\t<option value="$o">$o\n/;
		}
	}	
        $data .= "</select>\n";

        return $data;
}

#-----------------------------------------------------
#  renderListBox
#_____________________________________________________

sub renderListBox
{
        my $self=shift;

        my ($swListBox) = @_;

        my $ref = $swListBox->getValue('ref');
        my $options = $swListBox->getValue('options');
        my $sel = $swListBox->getValue('selected');

        my $data = qq/ <select multiple name="$ref" > /;
        foreach my $o (@$options)
        {
                if ($o eq $sel)
                {
                        $data .= qq/\t<option selected value="$o">$o\n/;
                } else {
                        $data .= qq/\t<option selected value="$o">$o\n/;
		}
	}
        $data .= "</select>\n";

        return $data;
}

#-----------------------------------------------------
#  renderSpacer
#_____________________________________________________

sub renderSpacer
{
        my $self = shift;
}


1;

__END__

=head1 NAME

SW::Renderer::XMLRenderer - Base class for SmartWorker Renderers

=head1 SYNOPSIS

  use SW::Renderer::XMLRenderer;
 
  (never called except internally) 

  $self->{renderer} = new SW::Renderer::XMLRenderer ($Application, $Browser);

=head1 DESCRIPTION

  Super class for all the Renderer classes, holds the actual implementation of HTML3Renderer becuase many of the other renderers will default back to those implementations.

  Specific browser information if passed in in case finer browser specific tweaks must be added to the renderer.

=head1 METHODS

  renderHTMLPanel($swPanel)

  renderFormPanel($swPanel)

  renderText($swText)

  renderTextBox($swTextBox)

  renderTextArea($swTextAream)
 
  renderButton($swButton)

  renderLink($swLink)

  renderLinkExternal($swLinkExternal)

  renderSelectBox($swSelectBox)

  renderListBox($swListBox)

  renderImage($swImage)

  renderRadioButton($swRadioButton)

  renderCheckBox($swCheckBox)

=head1 AUTHOR

Scott Wilson
HBE  	scott@hbe.ca
Feb 5/99

=head1 REVISION HISTORY

  $Log: XMLRenderer.pm,v $
  Revision 1.3  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.2  1999/09/01 01:26:56  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.1  1999/06/10 18:49:59  scott
  First time adding in XML renderer code

  Revision 1.30  1999/05/07 01:27:37  scott
  working on  some layout issues

  Revision 1.29  1999/05/05 18:14:07  scott
  fixed text color bug

  Revision 1.28  1999/05/05 18:05:42  scott
  Some clean-up, added font color support etc...

  Revision 1.26  1999/05/04 15:53:48  scott
  -New Apache::Session based database session tracking
  -New debugging scheme

  Revision 1.25  1999/04/22 13:35:39  kiwi
  Fixed some HTML3 table stuff, font size stuff

  Revision 1.24  1999/04/21 09:55:02  scott
  Fixed HTML3 backgrounds

  Revision 1.23  1999/04/21 08:56:21  kiwi
  Some language stuff, character encoding

  Revision 1.22  1999/04/21 05:57:04  scott
  Fixed _renderPanelCore() to remove the likes of

  		colspan=""  and width=""

  to help appease Bill and his windows CE machine

  Revision 1.21  1999/04/20 20:31:03  kiwi
  Changed default alignment to be read out of the 'align' parameter,
  chnaged some background things

  Revision 1.20  1999/04/20 05:03:16  kiwi
  Made XMLRenderer read out of the user's preferences for fonts and
  colours

  Revision 1.19  1999/04/18 22:26:08  scott
  Fixed renderButton to check for preBuild being defined rather than specifically 'true'

  Revision 1.18  1999/04/17 21:29:07  kiwi
  Added basic rendering of chat class

  Revision 1.17  1999/04/15 22:07:45  scott
  Fixed button callbacks

  Revision 1.16  1999/04/13 16:37:37  scott
  bug fixes in selectBox and checkBox

  Revision 1.15  1999/03/29 20:56:29  scott
  - rendering tweaks, split off _renderPanelCore to DHTMRenderer, consolidated the panel
  rendering to one spot rather than once for the root panel and again for the rest
  - implemented a two pass method from gridStyle layout, first creating a matrix, then
  identifying where open cells are, then growing them to fill based in based on growth rules
  ($GUIELement->{grow_x} and {grow_y} in the gui element or inherited from the panel it
  belongs to

  Revision 1.14  1999/02/22 00:52:58  scott
  1)  added a $object->visible() method to enable hiding objects
  2)  created TreeView
  3)  implemented an easier, more flexible callback system to facilitate
  	callbacks calling other callbacks and better control over which
  	level of objects get the callbacks.  Also allows argument passing
  	to the callback.

  Revision 1.13  1999/02/18 23:59:31  kiwi
  Changed the way tables are formatted so the source is easier to read

  Revision 1.12  1999/02/18 21:01:04  kiwi
  Fixed up the table columns problem, borders, etc.

  Revision 1.11  1999/02/18 19:20:39  scott
  Fixed State problems is RadioButtonSet, moved setNameSpace($ref) into
  it's own method in swGUIElement (out of the processSessionData method)

  Revision 1.10  1999/02/18 18:50:19  scott
  Removed offending width = 100% tags

  Revision 1.9  1999/02/18 10:42:54  scott
  New GUIElement components - LinkExternal, ListBox, SelectBox, TextBox, RadioButtonSet

  Revision 1.8  1999/02/17 17:09:38  kiwi
  Removed debugging HTML output that was getting in the way

  Revision 1.7  1999/02/17 17:08:46  kiwi
  Altered class to use hierarchical parent/child app relationships

  Revision 1.6  1999/02/12 22:44:58  scott
  added renderLink()

  Revision 1.5  1999/02/12 00:06:40  scott
  added support for sessions

  Revision 1.4  1999/02/11 18:59:17  scott
  added RadioButton and CheckBox, passed in hashes rather than parameter strings

  Revision 1.3  1999/02/10 23:08:47  scott
  Fixed getElementSize() bug is _renderPanelCore()

  Revision 1.2  1999/02/10 20:12:40  scott
  Added renderImage

  Revision 1.1.1.1  1999/02/10 19:49:10  kiwi
  SmartWorker

  Revision 1.3  1999/02/09 23:55:56  scott
  trivial - Changed some debug messages

  Revision 1.2  1999/02/09 19:51:37  scott
  Changed the behaviour of renderPanel so that it completes the <td> tags be query the
  child before calling render on it.


=head1 SEE ALSO

perl(1).

=cut
