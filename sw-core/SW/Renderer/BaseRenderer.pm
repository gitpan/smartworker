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

package SW::Renderer::BaseRenderer;

#------------------------------------------------------------
#  SW::Renderer::BaseRenderer
#  Base class for all renderers, this class should never be
#  instantiated on its own!
#------------------------------------------------------------
# $Id: BaseRenderer.pm,v 1.167 1999/11/23 18:53:26 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA $CSS $JS);

use SW::Renderer::HTML3Renderer;
use SW::Renderer::DHTMLRenderer;
use SW::Renderer::TextRenderer;
#use SW::Renderer::XMLRenderer;
#use SW::Renderer::PalmRenderer;
use SW::Renderer::WinCERenderer;
use SW::Util;
use SW::GUIElement;
use SW::Language;
use SW::Constants;
use Apache::URI();
use Apache::Util;

use Data::Dumper;
use LWP::UserAgent;
use LWP::Simple;
#please do not put it pack without a good reason
#use LWP::Debug qw (+);
require HTTP::Request;


@ISA = qw();

$VERSION = '0.01';


#-------------------------------------------------------
# constructor
#-------------------------------------------------------

sub new
{
	my ($classname, $app, $browser, @args) = @_;
	my $self = {
		theApp => $app,
		Browser => $browser,
		prefs => SW->user->getSystemPreferences(),	
	};

	my %sizes = (
		Small => 1,
    	        Medium => 2,
		Large => 3,
	);
		      
	bless ($self, $classname);

	#------------------------------------------------------------
	# Get the User's Preferences for rendering purposes
	#------------------------------------------------------------

	$self->{font} = SW->user->preference('Font');
	$self->{fontsize} = $sizes{SW->user->preference('Font Size')};
	$self->{bgcolor} = SW->user->preference('Background Colour');
	$self->{fgcolor} = SW->user->preference('Foreground Colour');

	####  This stuff should be in user prefs / system prefs / themes
	$self->{bgcolor} = "#000080" if not $self->{bgcolor};

	return $self;
}

#------------------------------------------------------------
# tag - function
#
# Generates a tag with the arguments received.
#
# Returns the string corresponding to the tag.
# NOVALUE creates an atomic parameter (like CHECKED)
# DEFAULT doesn't do anything (nothing inserted into tag)
# undef is just like DEFAULT (so DEFAULT might be useless)
# double-quotes are automatically escaped
#------------------------------------------------------------

sub tag
{
	my ($name,%params) = @_;
	return
	"<$name".
	join('',map {tag_1($_,$params{$_})} (keys %params)).
	">";
}

# don't use this directly ("private sub")
sub tag_1
{
	my ($k,$v) = @_;
	return qq/ $k/ if $v eq NOVALUE;
	return '' if $v eq DEFAULT or not defined $v;
	$v =~ s/"/&quot;/g;
	return qq/ $k="$v"/;
};



#------------------------------------------------------------
# tag_param - function
#
# Generates a <PARAM> tag
#------------------------------------------------------------

sub tag_param
{
	my ($name,$value) = @_;

	return tag('param',
		'name'=>$name,
		'value'=>$value);
}


#------------------------------------------------------------
# mangleText - method
#
# Generates the text depending on the attributes chosen, etc.
#------------------------------------------------------------

sub mangleText
{
	my ($self,$widget,$text) = @_;
	my $data = '';
	my $font = $widget->getValue('font');
	my $fontSize = $widget->getValue('fontSize');
	my $textColor = $widget->getValue('textColor');
	my $fontColor = $textColor || $self->{prefs}->{'Foreground Color'};
	my $panelFontColor = SW->user->preference('Foreground Color');
	$panelFontColor ||= "#000000";
	my $attrib = $widget->getValue('attrib');
	my $fsize = $fontSize || $self->{prefs}->{"Font Size"};

	
	#safe HTML'ization of stuff
	unless ($widget->getValue('raw'))
		{
		$text = Apache::Util::escape_html($text);
		$text =~ s/\ /&nbsp;/g unless $widget->getValue('break');
		}
	
	if ($fontColor eq $panelFontColor) {$fontColor=undef}

	if ($font or $fontColor or $fsize) {
		$data .= "<FONT";
		$data .= " FACE=\"$font\"" if $font;
		$data .= " COLOR=\"$fontColor\"" if $fontColor;
		$data .= " SIZE=$fsize" if $fsize;
		$data .= ">"
	}

	$data .= tag('b') if $attrib & BOLD();
	$data .= tag('i') if $attrib & ITAL();
	$data .= tag('u') if $attrib & UL();
	$data .= tag('s') if $attrib & STRIKE();
	$data .= tag('center') if $attrib & CENTER();
	$data .= $text;
	$data .= tag('/s') if $attrib & STRIKE();
	$data .= tag('/u') if $attrib & UL();
	$data .= tag('/i') if $attrib & ITAL();
	$data .= tag('/b') if $attrib & BOLD();
	$data .= tag('/center') if $attrib & CENTER();

	$data .= tag('/font') if $font or $fontColor or $fsize;

	return $data;
}

#-------------------------------------------------------------
#  renderData
#------------------------------------------------------------

sub renderData
{
	my ($self,$element) = @_;
	my $data = $element->render($self);
#	$self->{theApp}->debug("Rendering element: $element, got back $data");
	return $data;
}

#-------------------------------------------------------------
#  layoutPanel
#------------------------------------------------------------

sub layoutPanel
{
	my ($self,$panel) = @_;
	my @xLayout = undef;
	my @yLayout = undef;
	my @layout = undef;

	for (my $row = 0; $row < $panel->{rows}; $row++)
	{
		for (my $col=0; $col<$panel->{columns}; $col++)
		{
			if (! $panel->{elements}[$col][$row])
			{	# a cell that may be grown to
				$layout[$col][$row] = '.'; 

			} else 
			{	# a root cell
				$layout[$col][$row] = '+';   
			}
		}
	}

	for (my $row = 0; $row < $panel->{rows}; $row++) 
	{
		for (my $col=0; $col<$panel->{columns}; $col++)
		{
			if ($layout[$col][$row] eq '+')
			{       # a cell that may be grown to
				my $el = $panel->{elements}[$col][$row];
				if ($el->getValue("grow_x"))
				{
					my $walker = 1;
					if ($el->getValue("grow_x") eq "true")
					{
						while ($layout[$walker+$col][$row] eq '.')
						{
							$layout[$walker+$col][$row] = '>';
							$walker++;
						}
					}

					($walker > 1) ? $layout[$col][$row] = $walker : 1;
					$el->setValue("colspan", $walker);
					$xLayout[$col][$row] = $walker;
				} else
				{
					my $walker = 1;
					if ($panel->getValue("grow_x") eq "true")
					{
						while ($layout[$walker+$col][$row] eq '.')
						{
							$layout[$walker+$col][$row] = '>';
							$walker++;
						}
					}

					($walker > 1) ? $layout[$col][$row] = $walker.'>' : 1;
					$xLayout[$col][$row] = $walker;
				}
				if ($el->getValue("grow_y"))
				{
					my $walker = 1;
					if ($el->getValue("grow_y") eq "true")
					{
						while ($layout[$col][$walker+$row] eq '.')
						{
							$layout[$col][$walker+$row] = 'v';
							$walker++;
						}
					}
					($walker > 1) ? $layout[$col][$row] .= $walker.'v' : 1;
					$yLayout[$col][$row] = $walker;

				} else
				{
					my $walker = 1;
					if ($el->getValue("grow_y") eq "true")
					{
						while ($layout[$col][$walker+$row] eq '.')
						{
							$layout[$col][$walker+$row] = 'v';
							$walker++;
						}
					}

					($walker > 1) ? $layout[$col][$row] .= $walker.'v' : 1;
					$yLayout[$col][$row] = $walker;
				}
			} else  # (not a +)
			{
				if ($layout[$col][$row] eq '.') 
				{
					$yLayout[$col][$row] = 1; 
					$xLayout[$col][$row] = 1;
				}
			}
		}
	}
	return (\@yLayout, \@xLayout, \@layout);
}

#-------------------------------------------------------------
#  renderPanel  
#
#  !!!!!!!! Fix the divergence problems between here and DHTMLRenderer
#------------------------------------------------------------

sub renderPanel
{
	my ($self, $panel) = @_;
	my $data = "";
	my $background = $SW::Config::MEDIA_PATH .
		($panel->{background} || '/images/desktop.jpeg');

	$self->{theApp}->debug("Render Panel");

 	my $foreground = SW->user->preference("Foreground Colour");
	$foreground = $panel->getValue("textColor") || "#000000";

	if ($panel->getValue("master"))   # if this is the top level html
	{
		my $col =
			$panel->getValue("bgColor") ||
			$self->{prefs}->{"Background Color"} ||
			undef;

		my $link = $panel->getValue('link') || "#0000BB";
		my $vlink = $panel->getValue('vlink') || "#BB0000";
		my $alink = $panel->getValue('alink') || "#00BB00";

		# Check if the main panel has a title
		my $title = $panel->getValue('name');

		# Check if there is javascript lib to load
		my $jsLibs = $panel->getValue('jsLib');
		my $javaScriptCode;
		
		if ($jsLibs)
		{
			foreach my $lib (@{$jsLibs})
			{
				$javaScriptCode = qq{<script language="Javascript" src="}.$SW::Config::JS_LIB_URI.qq{$lib"></script>\n};
			}
		}

                my $cssLib = $panel->getValue('cssLib');
                my $cssCode;

                if ($cssLib) {
					foreach my $lib (@{$cssLib}) {
		       		if (!$CSS->{$lib}) {
						print STDERR "/lib/css/$lib";
						$CSS->{$lib} .= qq|<LINK HREF="$SW::Config::CSS_LIB_URI/$lib" REL="stylesheet" TYPE="text/css">|;
						}
					$cssCode .= $CSS->{$lib}."\n";
					}
				}

                my $preRenderCode = $panel->getValue("preRenderCode");
        
                my $margins;
                if ($panel->getValue("zeroMargin")) {
                        $margins = qq/leftmargin="0" bottommargin="0" rightmargin="0" topmargin="0" marginwidth = "0" marginheight = "0"/;
                }		
		
		my $onLoad = qq/onLoad="/.$panel->getValue("onLoad").qq/"/ if ($panel->getValue("onLoad"));
		my $onResize = qq/onResize="/.$panel->getValue("onResize").qq/"/ if ($panel->getValue("onResize"));
		my $onBlur = qq/onBlur="/.$panel->getValue("onBlur").qq/"/ if ($panel->getValue("onBlur")); 
		my $bodyParam = $panel->getValue("bodyParam");	


		$data = <<EOF;
<HTML><HEAD><TITLE>$title</TITLE>
<!-- SW::Renderer::BaseRenderer $VERSION -->
$javaScriptCode
$cssCode
$preRenderCode
</HEAD>
<BODY $margins BGCOLOR="$col" TEXT="$foreground" BACKGROUND="$background" LINK="$link" VLINK="$vlink" ALINK="$alink" $onLoad $onResize $onBlur $bodyParam>
EOF
	}

	$data = $self->_renderPanelCore($panel, $data);
	$data .= "</TABLE>\n</BODY>\n</HTML>";

	return $data;

}

#-------------------------------------------------------------
#  renderHTMLPanel
#------------------------------------------------------------

sub renderHTMLPanel
{
	my ($self,$panel) = @_;
	my $data = "";

	if (! $panel->{params}->{url})
	{	
		$data = $self->_renderPanelCore($panel, $data);
		$data .= "</table>\n";
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
	my ($self,$panel) = @_;

	# kluge
	shift;shift;

	my $uri_target = SW->request->uri();
	my $target = qq/ TARGET="/.$panel->getValue("target").qq/" / if $panel->getValue("target");
	my $onSubmit = qq/ onSubmit="/.$panel->getValue("onSubmit").qq/" / if $panel->getValue("onSubmit");

	my $data = qq/<form method=post name="/.$panel->getValue('name').qq/" action="$uri_target" enctype="multipart\/form-data" $target $onSubmit>\n/;

	my %appendages = %{$self->{theApp}->getAppendages()};

	while (my ($k, $v) = each(%appendages))
	{  
		$data .= qq/<input type="hidden" name="$k" value="$v">\n/ if $v; 
	}

	$data .= qq/<input type="hidden" name="_submitted" value="/.$panel->getValue("name").qq/">\n/;
	$data = $self->_renderPanelCore($panel, @_, $data);	

	# I changed the order of the form and table tags because it seems it was adding
	# a useless line in tables when the order was reversed!

	$data .= "</FORM></TABLE>\n";

	return $data;
}

#-------------------------------------------------------------
#  _renderPanelCore
#------------------------------------------------------------

sub _renderPanelCore
{
	my ($self,$panel,$data) = @_;
	my $elements = $panel->{elements};
	my ($cols, $rows) = $panel->getSize();
	my $border= $panel->{border};
	my $spacing = $panel->getValue('spacing') || '0';
	my $padding = $panel->getValue('padding') || '0';

   my $panelBgColor = $panel->getValue("bgColor") || $self->{prefs}->{"Background Color"};

   my ($yLayout, $xLayout, $debugLayout) = $self->layoutPanel($panel);

   my $tableBorder = $panel->getValue("border") || '0';

   $data .= qq/<table valign=top/;

   $data .= $tableBorder? " border=$tableBorder" : " border=0";

	$data .= " CELLPADDING=$padding CELLSPACING=$spacing";


	if ($panel->getValue("master") eq "true")
 	{
#  		$data .= " width=100% height=100%";
 	}
	else
 	{
		$data .= " width=100%" if $panel->getValue("grow_x") eq "true";
		$data .= " height=100%"	if $panel->getValue("grow_y") eq "true";
 	}	
 
 	if ($panel->getValue('BorderDebug'))
 	{ 
 		$data .= "><tr valign=top><td bgcolor=".$self->{bgcolor}.">";
 		$data .= "<table cellspacing=1 cellpadding=1 border=0>\n";
 	}
 	else
 	{
		$data .= ">\n";
 	}
	

	#$data .= "</tr>";
#   $self->{theApp}->debug("panel x $cols y $rows");

	for (my $y=0; $y<$rows; $y++)
	{
		$data .= "<tr>\n";
		for (my $x=0; $x<$cols; $x++)
		{
			if (! $yLayout->[$x][$y])
			{
				next;
			} 

			if (! $panel->{elements}[$x][$y])
			{
				$data .= "<td></td>";
			} else
			{
				if (! $panel->{elements}[$x][$y]->visible)
				{
					$data .= "<td></td>";

				} else
				{
					my $elColspan = $xLayout->[$x][$y];
					my $elRowspan = $yLayout->[$x][$y];
					my $elAlign = $panel->{elements}[$x][$y]->getValue('align');
					my $elBgColor = $panel->{elements}[$x][$y]->getValue('bgColor');
					if ($elBgColor eq "") { $elBgColor = $panelBgColor; }
					my $elbg = $panel->{elements}[$x][$y]->getValue('background');
					my $elStyle = $panel->{elements}[$x][$y]->getValue('style');
					my $elClass = $panel->{elements}[$x][$y]->getValue('class');
					my $defaultCSSClass = $panel->getValue('defaultCSSClass');					

#   				$self->{theApp}->debug("panel x $cols y $rows");

               my $elVAlign = $panel->{elements}[$x][$y]->getValue('valign');
               my $elWidth = $panel->{elements}[$x][$y]->getValue('width');
#					$self->{theApp}->debug("width $elWidth");
					my $elHeight = $panel->{elements}[$x][$y]->getValue('height');
					my $font = $self->{font};
				   my $fontsize = $self->{fontsize};

					$data .= qq/<TD/;

					if ($elColspan>1) { $data .= " colspan=$elColspan"; }
					if ($elRowspan>1) { $data .= " rowspan=$elRowspan"; }
					if ($elWidth) { $data .= qq/ width=$elWidth/; }
					if ($elHeight) { $data .= " height=$elHeight"; }
					if ($elAlign) { $data .= " align=$elAlign"; }
					if ($elVAlign) { $data .= " valign=$elVAlign"; }
					if ($elStyle) { $data .= " style=$elStyle"; }
					if ($elClass) { $data .= " class=$elClass"; }
					elsif ($defaultCSSClass) { $data .= "class=$defaultCSSClass"; }
#HACK!!!
	#				if ($elbg)
	#				{
	#					$data .= qq/ background="$elbg">/;
	#				}
	#				else
	#				{
						if ($panelBgColor ne "$elBgColor")
						{
							$data .= qq/ bgcolor="$elBgColor">/;
						}
						else
						{
							$data .= qq/>/;
						}
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
# renderApplication
#------------------------------------------------------------

sub renderApplication
{
	my ($self,$app) = @_;
	my $data = "";

	if ($app->getPanel()->getValue('master'))
		{
		my @lang = @{Apache::Language->new->lang()};

		my $bestPick;

		foreach my $wantedLang (@lang) 
			{ 
			if(grep {$wantedLang eq $_} keys %SW::Config::Languages)
				{
				$bestPick = $wantedLang;
				last;
				}
			}	

		$data .= <<"EOF";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
$SW::Config::CHAR_SET{$bestPick}
EOF

		}
	$data .= $app->{panel}->render();
	return $data;
}


#------------------------------------------------------------
# renderClock
#------------------------------------------------------------

sub renderClock
{
	my ($self,$widget) = @_;
	return tag('b').scalar(localtime).tag('/b');
}

#-----------------------------------------------------
#  renderText
#-----------------------------------------------------

# style, class not honored here
sub renderText {
	my ($self,$widget) = @_;

	return $self->mangleText(
		$widget,
		$widget->getValue('text'));
}

#------------------------------------------------------------
# renderApplet
#------------------------------------------------------------

sub renderApplet {
	my ($self,$w) = @_;
	my $a = $w->getValue('args');
	return tag('applet',
		codebase=> $w->getValue('codebase'),
		code	=> $w->getValue('code'),
		width	=> $w->getValue('width'),
		height	=> $w->getValue('height'))
	.join('', map { tag_param($_=>$a->{$_}) } keys %$a)
	.tag('/applet');}

#-----------------------------------------------------
#  renderm
#-----------------------------------------------------

sub renderTextBox
{
	my ($self,$widget) = @_;
	my ($chars, $rows) = $widget->getSize();
	my $name = $widget->getValue('name');
	my $text = $widget->getValue('text');
	my $maxlength = $widget->getValue('maxlength');
	my $attrib = $widget->getValue('attrib');

	$text =~ s/"/&quot;/g; # hack to avoid the " delimiters of HTML
	$chars = length($text)+1 if not $chars;
	my $data .= qq/<INPUT TYPE="text" NAME="$name" SIZE=$chars/;
	$data .= " MAXLENGTH=$maxlength" if $maxlength;
	$data .= " VALUE=\"$text\">";
	
	
	$data = "<CENTER>$data</CENTER>" if $attrib & CENTER();
	return $data;

}

#-----------------------------------------------------
#  renderTextArea
#-----------------------------------------------------

sub renderTextArea
{
	my ($self,$w) = @_;

	return tag('textarea',
		name=>$w->getValue('name'),
		rows=>$w->getValue('iheight') || $w->getValue('height'),
		cols=>$w->getValue('iwidth')  || $w->getValue('width'),
		wrap => $w->getValue('wrap') || 'virtual',
	)
	.$w->getValue('text')
	.tag('/textarea');
}

#-----------------------------------------------------
#  renderButton
#-----------------------------------------------------


sub renderButton
{
	my ($self,$widget) = @_;
	my $data;

	my $text = $widget->getValue('text');
	my $signal = $widget->getValue('signal');
	my $type = $widget->getValue('type');
	my $class = $widget->getValue('iclass');
	my @onClick;
	
	push @onClick, $widget->getValue('onClick')  if $widget->getValue('onClick');
	

	$text =~ s/"/&quot;/g; # to avoid the " delimiters of HTML

	$data .= qq/<INPUT NAME="action\:\:$signal" TYPE="$type" VALUE="$text"/;
	
	
	my @popupOnCLick = $self->getPopupOnClick($widget);
	
	push @onClick, @popupOnCLick if  @popupOnCLick;
	
	$data .= ' onClick="' . (join ';', @onClick) . ';"' if @onClick;
	 
#END-ADDED BY gozer POPUP


	$data .= qq/ class="$class"/ if $class;

	$data .= '>';
	return $data;
} 

#-----------------------------------------------------
#  renderLink
#-----------------------------------------------------

sub renderLink {
  my ($self,$widget) = @_;
  my $signal = 'action::'.$widget->getValue('signal');
  my $argString;
  if (my $arg = $widget->getValue('args')) {
	$argString = join '&', map { "$_=" . $arg->{$_} } (keys %$arg);
  }
  my $appendages= SW->master()->getURLAppendages();
  my $icon	= $widget->getValue('icon');
  my $uri	= $widget->getValue('URI');
  my $text	= $widget->getValue('text') || $uri;
  my $class	= $widget->getValue('iclass') || $widget->getValue('class');
  my $javascript = $widget->getValue('javascript');
 

 my $href = ($javascript) ? "Javascript:$javascript" : 
        $uri .
        SW::Util::buildArgString($appendages,"$signal=signal",$argString);
 	
	my @popupOnClick = $self->getPopupOnClick($widget) unless $widget->getValue('noPopup');

	my $data;
	if (@popupOnClick) {
		$data = "<A HREF='javascript:" . (join ';', @popupOnClick) . "'" if @popupOnClick;
	} else { 
		$data = qq/<A HREF="$href"/;
	}
  
    if($SW::Config::FRAME_TARGET) {
	$data .= " target=$SW::Config::FRAME_TARGET ";
  } else {
	if ($widget->getValue('target') ne '') {
		$data .= " target=" . $widget->getValue('target') . " ";
	}
  }

  # Yet another hack; this one applies class to link as well as
  # table cell.
  $data .= " class='$class' " if $class;

	my @onClick;
	push @onClick, $widget->getValue('onClick')  if $widget->getValue('onClick');
	$data .= ' onClick="' . (join ';', @onClick) . ';"' if @onClick;


  $data .= ">";

  if ($widget->getValue('image')) {
	my $image = $widget->getValue('image');
	# an image element
	if (ref($image)) {
		$data .= $image->render($self);
	}
	# just an image url
	else {
		$data .= tag('img',src=>$image,alt=>$text,border=>0);
	}
  }
  # text link
  else {
	if ($icon) {
		$data .= tag('img',
			border=>0,valign=>'middle',
			width=>24,height=>24,
			src=>"/sw_lib/images/$icon");
	}
	$data .= $self->mangleText($widget,$text);
  }

  $data .= "</A>";
  return $data;
}

#-----------------------------------------------------
#  renderLinkExternal
#-----------------------------------------------------

sub renderLinkExternal {
	my ($self,$link) = @_;
	my $target  = $link->getValue('target');
	my $frame   = $link->getValue('frame');
	my $onClick = $link->getValue('onClick');

	if ($target =~ /^\/.+$/ && ($link->getValue('noCheck') ne "true")) # i had to add the no true arg cuz sometimes,
									   # we really wanted to have something that looks internal 
									   # (like uploaded files)
	{
		$self->{theApp}->debug("Error:  $target looks like an internal link, usr swLink");
		return;
	}

	my $data = tag('a',
		href=>$target,
		target=>$frame,
		onClick=>$onClick,
	);

	my $text = $link->getValue('text') || $link->getValue('target');

	if ($link->getValue('image'))
	{
		my $image = $link->getValue('image');

		# image element
		if (ref($image)) {
			$data .= $image->render($self);
		}
		# just an image url
		else {
			$data .= tag('img',src=>$image,alt=>$text,border=>0);
		}
	}
	else  #text link
	{
		$data .= $self->mangleText($link,$text);
	}
 	$data .= "</A>";
	return $data;
}

#-----------------------------------------------------
#  renderImage
#-----------------------------------------------------

sub renderImage
{
	my ($self,$w) = @_;
	return tag('img',
		src => $w->getValue('url'),
		border => $w->getValue('border') || '0',
		width => $w->getValue('iwidth') || $w->getValue('width'),
		height => $w->getValue('iheight') || $w->getValue('height'),
		alt => $w->getValue('text') || "",
		align => $w->getValue('align'),
		valign => $w->getValue('valign'),
		text => $w->getValue('text'),
#		class => $w->getValue('iclass') || $w->getValue('class'),
	)
	.($w->getValue('addbr') ? "<br>" : "");
}

#-----------------------------------------------------
#  renderSpacer
#-----------------------------------------------------

sub renderSpacer
{
	my ($self,$w) = @_;
	return tag('img',
		src=>'/images/spacer.gif',
		border=>0,
		width=>     $w->getValue('iwidth') || $w->getValue('width'),
		height=>    $w->getValue('height'),
	);
}

#-----------------------------------------------------
#  renderRadioButtonSet	
#-----------------------------------------------------

sub renderRadioButtonSet
{
	my ($self,$w) = @_;
	my $buttons = $w->getButtons();
	my $separator = '';
	$separator = "<br>" if $w->{params}->{orientation} eq 'vertical';

	return join $separator,
		map {eval {$_->render($self)}} (@$buttons);
}



#-----------------------------------------------------
#  renderRadioButton
#-----------------------------------------------------

sub renderRadioButton { 
	my ($self,$w) = @_;
	my $checked = $w->getValue('set')->getValue('checked');
	my $value = $w->getValue('value');

	return tag('input',
		type=>'radio',
		name=>$w->getValue('name'),
		value=>$value,
		checked=>($checked eq $value)?NOVALUE:undef,
		class => $w->getValue('class'),
	)
	.$w->getValue('text');
}

#-----------------------------------------------------
#  renderCheckBox
#-----------------------------------------------------

sub renderCheckBox { 
	my ($self,$w) = @_;
  return tag('input',
	type => 'checkbox',
	name => $w->getValue('name'),
	value => $w->getValue('value'),
	checked => $w->getValue('checked')?NOVALUE:undef,
  )
  .$w->getValue('text');
}

#-----------------------------------------------------
#  renderSelectBox
#-----------------------------------------------------

sub renderSelectBox { 
	my ($self,$swSelectBox) = @_;

	my $name = $swSelectBox->getValue('name');
	my $options = $swSelectBox->getValue('options') || []; # in case it's not passed
	my $values = $swSelectBox->getValue('values') || [];
	my $optval = $swSelectBox->getValue('optval');
	my $sel = $swSelectBox->getValue('selected');
	my $action = $swSelectBox->getValue('action');
	my $size = $swSelectBox->getValue('size');
	my $multiple = $swSelectBox->getValue('multiple');
	my $truncate = $swSelectBox->getValue('truncate');
	my $switchOrder = $swSelectBox->getValue('switchOrder');

	my $data = "<SELECT";

	$data .= " NAME=\"$name\"" if $name;
	$data .= " onChange='document.$action.submit()'" if $action;
	$data .= " MULTIPLE" if $multiple == 1;

	# size of select box = user defined size unless: 
	# a) more options than size, which means we take number of options instead
	# b) size is not a digit or size not present, which means size = 1
	$data .= " SIZE=".(($size =~ /^\d+$/) ? (($size > @$options) ? @$options : $size) : 1). ">\n";

	if ($optval) { # this goes first
		foreach my $key (sort {$optval->{$a} cmp $optval->{$b}} keys (%{$optval}))
		{
			my $selected = $key eq $sel ? "SELECTED" : "";
			$key =~ s/"/&quot;/g; # to avoid the " delimiters of HTML
			if ($switchOrder) {
				$data .= "<OPTION $selected VALUE=\"$optval->{$key}\">$key\n";
			} else {
				$data .= "<OPTION $selected VALUE=\"$key\">$optval->{$key}\n";
			}
		}
	} else {
		for (my $x = 0; $x < @$options; $x++) {
			# if no value for this element, use the name instead
			my $elementValue = defined($$values[$x]) ? $$values[$x] : $$options[$x];

			my $selected;
			if (ref($sel) eq 'ARRAY')
			{
				$selected = inArray($elementValue, $sel) ? "SELECTED" : "";
			} else {	
				$selected = "$elementValue" eq "$sel" ? "SELECTED" : "";
			}
			$elementValue =~ s/"/&quot;/g; # to avoid the " delimiters of HTML
			$data .= "<OPTION $selected VALUE=\"$elementValue\">";
			if ($truncate && (length($$options[$x]) > $truncate)) {
			    $data .= substr($$options[$x],0,$truncate) . "...";
			} else {
			    $data .= $$options[$x];
			}
			$data .= "\n";
		}

		# in case there is more values than options, let's add the options to the select statement
		if (@$values > @$options) {
			for (my $x = (@$values - (@$values - @$options)); $x < @$values; $x++) {
				my $selected = $$values[$x] eq $sel ? "SELECTED" : "";
				$$values[$x] =~ s/"/&quot;/g; # to avoid the " delimiters of HTML
				$data .= "<OPTION $selected VALUE=\"$$values[$x]\">$$values[$x]\n";
			}
		}
	}

	$data .= "</SELECT>\n";

	return $data;
}

#-----------------------------------------------------
#  renderListBox
#-----------------------------------------------------
         
sub renderListBox
{
	my ($self,$w) = @_;
	my $sel = $w->getValue('selected');

	return tag('select',
		multiple => NOVALUE,
		name => $w->getValue('name'),
	)
	.map {
		tag('option',
			selected => ($_ eq $sel) ? NOVALUE : undef,
			value => $_)
		.$_
	} (@{$self->getValue('options')})
	.tag('/select');
}   

#---------------------------------------------------------------
# renderFileUpload
#
# Renderer for file upload widgets
# (Renamed from renderFileBrowse by Zed on 31/08/1999)
#---------------------------------------------------------------

sub renderFileUpload
{
	my ($self,$w) = @_;
	return tag('input',
		type=>'file',
		name=>$w->getValue('name'),
		size=>$w->getValue('size') || 30,
		maxlength=>$w->getValue('maxlen'),
	);
}


#-------------------------------------------------------
# renderPasswordField
#
# Renders a password-type input field in a form
#-------------------------------------------------------

sub renderPasswordField
{
	my ($self,$info) = @_;
	return tag('input',
		type=>'password',
		name=>$info->getValue('name'),
		size=>$info->getValue('size'),
	);
}


#-------------------------------------------------------
# renderImageButton
#
# Renders an image-type input field which can be used
# as the submit button in a form
#-------------------------------------------------------

sub renderImageButton
{
	my ($self,$w) = @_;
	return tag('input',
		type	=> 'image',
		name	=> "action::".$w->getValue('signal'),
		src	=> $w->getValue('image'),
		align	=> $w->getValue('align'),
		border	=> $w->getValue('border') || 0,
		height	=> $w->getValue('height'),
		width	=> $w->getValue('width'),
	);
}

#-------------------------------------------------------
# renderImageRollover
#
# Renders an image that changes whenever the mouse
# cursor goes over or out of the image boundaries
#-------------------------------------------------------

sub renderImageRollover
{
	my $self = shift;
	my ($info) = @_;

	my $url = $info->getValue('url') || '#';
	my $imageOn = $info->getValue('imageOn');
	my $imageOff = $info->getValue('imageOff');
	my $name = $info->getValue('name');
	my $border = $info->getValue('border') || 0;

	my $data .= qq/<A HREF="$url"/;
	$data .= " onMouseOver=\"$name.src='$imageOn';return true\"";
	$data .= " onMouseOut=\"$name.src='$imageOff';return true\"";
	$data .= ">\n<IMG SRC=\"$imageOff\" NAME=\"$name\"";
	$data .= " BORDER=$border";
	$data .= "></A>\n";
	return $data;
}

#-------------------------------------------------------
# renderHorizontalRule
#-------------------------------------------------------

sub renderHorizontalRule
{
	my ($self,$w) = @_;

	return tag('hr',
		width => $w->getValue('width'),
		size => $w->getValue('size'),
		align => $w->getValue('align'),
		noshade => $w->getValue('noshade') ? NOVALUE : undef,
	);
}

#-------------------------------------------------------
# getPopupCode
# this is to return the correct JAVSCRIPT stuff for popups, 
# should eventually detect browser/os and pick the right thing
#-------------------------------------------------------
sub getPopupCode {
	return qq|<SCRIPT LANGUAGE="Javascript" SRC="/sw_lib/js_lib/popup/base.js"></SCRIPT>|;
}

#-------------------------------------------------------
# getPopupOnClick
#returns the list (no ;) of onClick javascript code for 
#the current widget
#-------------------------------------------------------
sub getPopupOnClick {
	my ($self,$widget) = @_;
	my @onClick = ();
	my $popupArg = $widget->getValue('popup');
	
	#ADDED BY gozer POPUP
	if((ref $widget eq 'SW::GUIElement::Button') || (ref $widget eq 'SW::GUIElement::Link')) {
		my $popupString;
	
 		if (defined $popupArg) {
			$popupString = join '&',( 'popup=1' , map { "popup_$_=" . $popupArg->{$_} } (keys %$popupArg));
   		}

		#very bad design choices, will have to rework it all tomorrow :-( but it seems to work.

#print STDERR "#==================================================================#\n";
#print STDERR "popup-> ".SW->master->getDataValue('popup')."\n";
#print STDERR "comeFromDrowpDown-> ".SW->master->getDataValue("comeFromDropDown")."\n";
#print STDERR "forceClose -> ".$popupArg->{forceClose}."\n";
#print STDERR "#==================================================================#\n";

		# we are in a popuped window !
		if (!$popupArg->{otherPopup} && (
			SW->master->getDataValue('popup') || SW->master->getDataValue("comeFromDropDown") || $popupArg->{forceClose}
		)) {
			#we need to differentiate false of undef (since undef => true (default))
			my $submit	= $popupArg->{'submit'};
			my $close 	= $popupArg->{'close'};
			my $target  = $popupArg->{'target'};

			$submit		= 1 if not defined $submit;
			$close		= 1 if not defined $close;

			if ($submit)
			{
				my $targ = qq/,\'$target\'/ if $target;
				my $closeValue = ($close) ? "true" : "false";
				push @onClick, qq/submitPopup(this.form,$closeValue$targ)/;
			} elsif ($close) { 
				push @onClick, ('window.close()','return true'); 
			}

			if (!$submit && !$close) 
			{
				push @onClick, "return false";
			}
		} elsif ($popupArg->{'target'} eq "self") {
# do nothing, this is for links pointing to self in a popup
		} elsif ($popupString) {
			#we want to create a popup
			my $signal = 'action::'.$widget->getValue('signal');

			my $argString;
	   		if (my $arg = $widget->getValue('args')) {
				$argString = join '&', map { "$_=" . $arg->{$_} } (keys %$arg);
			}

			my $appendages = SW->master()->getURLAppendages();

			my $popupString;
			my $popupArg;
	 		if ($popupArg = $widget->getValue('popup')) {
				$popupString = join '&',( 'popup=1' , map { "popup_$_=" . $popupArg->{$_} } (keys %$popupArg));
			}

			my $args;
			if (ref $widget eq "SW::GUIElement::Button") {
				$args = SW::Util::buildArgString($appendages,"$signal=signal",$argString,$popupString);
			} elsif (ref $widget eq 'SW::GUIElement::Link') {
				my $signal = $widget->getValue("signal");
				$signal =~ s/:(.*)$//;
				$args = SW::Util::buildArgString($appendages,($signal) ? "appState=$signal" : undef,$argString,$popupString);
			}
			my $popupWidth  = $popupArg->{'width'} if ($popupArg);
			my $popupHeight = $popupArg->{'height'} if ($popupArg);

			my $other = ',"'.$popupArg->{'otherPopup'}.'"' if ($popupArg->{'otherPopup'});
			if (ref $widget eq 'SW::GUIElement::Button') {
				push @onClick, qq/openPopup(this.form.action + '$args',$popupWidth,$popupHeight,false$other);return false;/;
			} elsif (ref $widget eq 'SW::GUIElement::Link') {
				my $uri_object = ($widget->getValue("URI")) ? undef : SW->request->parsed_uri();
				my $uri = ($widget->getValue("URI")) ? $widget->getValue("URI") : $uri_object->path();
				push @onClick, qq/openPopup("$uri$args",$popupWidth,$popupHeight,true$other)/;
			}
		}
	}

	return @onClick;
}

1;

__END__

=head1 NAME

SW::Renderer::BaseRenderer - Base class for SmartWorker Renderers

=head1 SYNOPSIS

  use SW::Renderer::BaseRenderer;
 
  (never called except internally) 

  $self->{renderer} = new SW::Renderer::BaseRenderer ($Application, $Browser);

=head1 DESCRIPTION

  Super class for all the Renderer classes, holds the actual implementation of HTML3Renderer because many of the other renderers will default back to those implementations.

  Specific browser information if passed in in case finer browser specific tweaks must be added to the renderer.

=head1 METHODS

  renderHTMLPanel($swPanel)

  renderFormPanel($swPanel)

  renderText($swText)

  ($swTextBox)

  renderTextArea($swTextAream)
 
  renderButton($swButton)

  ($swLink)

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

  $Log: BaseRenderer.pm,v $
  Revision 1.167  1999/11/23 18:53:26  gozer
  Added code to send correct document-type encoding to make the browser correctly switch encoding on the fly

  Revision 1.166  1999/11/22 22:41:14  gozer
  Modified the renderes so the CSS stuff is now a hard link of the form:
  <LINK HREF="/lib/css/opendesk.css" REL="stylesheet" TYPE="text/css">

  Revision 1.165  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.164  1999/11/12 21:02:35  fhurtubi
  Added switchOrder as an argument of selectBox. This is to get the key-value
  pairs of the optval variable in any order

  Revision 1.163  1999/11/01 22:54:06  fhurtubi
  Added the onSubmit argument to the FORM panel rendering..
  Tweaked the popup code

  Revision 1.162  1999/10/26 18:13:29  jzmrotchek
  Truncate minifix.

  Revision 1.161  1999/10/26 17:14:59  jzmrotchek
  Added "truncate" parameter to SelectBox option.
  Takes an integer value, and will cause options with names longer than the
  specified length to appear in the selectbox truncated to the length specified
  and followed by a "..."

  Revision 1.160  1999/10/25 17:36:28  gozer
  Hurry before the thundering hearth

  Revision 1.159  1999/10/25 08:26:49  fhurtubi
  Added onBlur et bodyParams (for other tags) for both Base and DHTML Renderers..
  Also, JS code is not included anymore but read from a src file

  Revision 1.158  1999/10/24 03:10:35  fhurtubi
  LinkExternal is now using mangleText

  Revision 1.157  1999/10/24 01:26:59  gozer
  Little comment

  Revision 1.156  1999/10/24 01:14:21  gozer
  REmoved annoying warning message

  Revision 1.155  1999/10/23 22:02:02  gozer
  Added support for onResize for the <BODY> tag

  Revision 1.154  1999/10/23 20:16:57  matju
  panelHeight, ...

  Revision 1.153  1999/10/23 17:23:37  fhurtubi
  Added the noCheck argument for LinkExternal. Sometimes, we really want a link within
  the SW tree..(like for downloading an uploaded file)

  Revision 1.152  1999/10/23 02:28:19  gozer
  Fixed and now filteres html codes in text elements. IF you want your text element
  to include pure HTML code, use the -raw=> true thing.
  Secondly, by default now, all spaces are remplaced by nbsp's.  Do disable that ->break =>  "true"

  Revision 1.151  1999/10/22 20:43:50  fhurtubi
  Added the onLoad argument for panels

  Revision 1.150  1999/10/22 18:00:03  fhurtubi
  Added the noPopup argument for link (if you're in a popup and want to stay within it)

  Revision 1.149  1999/10/20 06:42:29  fhurtubi
  Added the margins (right/bottom) for the zeroMargin argument

  Revision 1.148  1999/10/19 20:08:07  fhurtubi
  Fixed the popups again...i had a return false missing, added the possibility to pass
  javascript code instead of a url in the link element (<a href=javascript:foo();bar()>)
  Added the preRenderCode and the zeroMargin arguments which were only in the DHTMLRenderer

  Revision 1.147  1999/10/18 22:31:03  fhurtubi
  Hope I wont break anybody's link elements!
  I modified it to work with the popups.

  Revision 1.146  1999/10/18 10:24:35  matju
  fixed the backwards </font> tag

  Revision 1.145  1999/10/17 16:25:02  gozer
  Fixed a little runaway }

  Revision 1.144  1999/10/17 09:47:01  fhurtubi
  getPopupOnClick had a major facelift!

  Revision 1.143  1999/10/15 06:59:56  fhurtubi
  Fixed popups things

  Revision 1.142  1999/10/14 19:02:45  matju
  typos++

  Revision 1.141  1999/10/14 18:25:17  gozer
  Added some bit more of modularized popup code for Fred

  Revision 1.138  1999/10/14 01:11:09  gozer
  Added the needed options to the popp-up code, but as it grew, I realized it was badly planned.
  It works right now, but I already have a rewrite in mind.  Nice and clean.  But for now, crude but functionnal :-)

  Revision 1.137  1999/10/13 19:12:31  fhurtubi
  Added iclass for Buttons and fixed a bug with onClick

  Revision 1.136  1999/10/13 16:01:49  fhurtubi
  Added the onClick argument to the popup rendering

  Revision 1.135  1999/10/12 18:57:50  fhurtubi
  Typos...

  Revision 1.134  1999/10/12 18:28:06  fhurtubi
  Added the onClick argument for Button Elements,
  Added the target parameter for Form Panel Elements

  Revision 1.133  1999/10/12 15:10:01  matju
  deleting the Chat widget
  adding the Applet widget
  general facelifting that may introduce fresh, new, innovative bugs
  other stuff that i don't really remember

  Revision 1.132  1999/10/09 21:14:11  gozer
  Modified the popup-generating code a bit :-)

  Revision 1.131  1999/10/09 02:56:06  gozer
  Added pop-up windows first prototype, functionnal, but not very robust/configurable.  But they work!

  Revision 1.130  1999/10/08 23:00:34  gozer
  fixup of little () errors

  Revision 1.129  1999/10/08 22:35:10  krapht
  Removed the attribute subs from there and put them in SW::Constants

  Revision 1.128  1999/10/08 00:46:37  matju
  code clean-up

  Revision 1.127  1999/10/07 23:51:09  matju
  added: sub mangleText

  Revision 1.126  1999/10/07 22:50:01  matju
  `tagify' now known as `tag'

  Revision 1.125  1999/10/07 22:05:28  matju
  addElement, renderChat, tagify, tag_param

  Revision 1.124  1999/10/07 21:46:02  jzmrotchek
  Hacked so that renderLink applied class attribute to <a> tag as well as cell.

  Revision 1.123  1999/10/07 18:42:04  fhurtubi
  I mixed up width and height in the Spacer renderer...bad me..

  Revision 1.122  1999/10/01 17:05:09  jzmrotchek
  Changed "alt" property name to "text" for renderImage.

  Revision 1.121  1999/10/01 16:24:25  jzmrotchek
  Added support for an alt property of the image tag.  Defaults to:
  	ALT=""
  if no property gets specified.

  Revision 1.120  1999/09/30 11:38:54  gozer
  Added the support for cookies

  Revision 1.119  1999/09/29 20:33:39  jzmrotchek
  Backwards compatibility hack to make iwidth and iheight attributes break less things. :)

  Revision 1.118  1999/09/29 20:00:32  jzmrotchek
  Added hack in renderTextArea for rendering width and height seperately from width and height of enclosing
  cell.  Use iwidth and iheight.  (Input Width, Input Height)

  Revision 1.117  1999/09/29 19:06:32  jzmrotchek
  Changed renderImage some; to define image height and width, use iwidth and iheight instead of
  height and width (which will be applied to the panel the image is in).  Cures the annoying
  problem of having the damned image and cell width/height being set to the same value.

  Revision 1.116  1999/09/28 22:37:24  jzmrotchek
  Typo correction.

  Revision 1.115  1999/09/28 22:30:32  jzmrotchek
  Added onClick handler hack for renderLink.   If you can do better, please do.  Otherwise, I'll do better with it later myself.

  Revision 1.114  1999/09/28 16:12:19  fhurtubi
  Added JS libray change

  Revision 1.113  1999/09/28 04:59:28  matju
  rewrote renderChat

  Revision 1.112  1999/09/27 20:21:46  fhurtubi
  Added the spacer renderer

  Revision 1.111  1999/09/27 18:14:01  jzmrotchek
  Oops.  Stuck the parameter outside the anglebrackets.  Fixed.

  Revision 1.110  1999/09/27 18:10:30  jzmrotchek
  Added capability of targeting specifc frames for external links.
  (I seem to do a lot of this kind of thing)  See renderLinkExternal.
  Note however that since "target" is already used for the actual link
  destination, I've used "frame" as the parameter name, which will
  no doubt confuse the bejeesus out of anyone who knows a bit about
  HTML, which uses "target" as the frame target parameter.

  Revision 1.109  1999/09/24 00:06:53  scott
  debug code

  Revision 1.108  1999/09/23 18:17:42  krapht
  Added a > at the end of HorizontalRule

  Revision 1.107  1999/09/22 03:27:04  jzmrotchek
  Added code to allow a 'target' frame to be specified in an SW::GUIElement::Link object.   Note that the docs for that object are way out of date; they incorrectly describe the 'URI' parameter (called 'target' in the docs), which was the source of the some of the confusion that led to my fixing this.  Note that a value for SW::Config::FRAME_TARGET will overrule user-specified targets.

  Revision 1.106  1999/09/20 20:43:48  krapht
  Changed a line to remove the target tag in somewhere!! : )

  Revision 1.105  1999/09/20 15:02:04  krapht
  Replaced getRequest by SW->request

  Revision 1.104  1999/09/20 14:31:20  krapht
  Changed the way to get user (SW->user)

  Revision 1.103  1999/09/19 07:02:00  fhurtubi
  Buggy Maxlength rendering in renderTextBox

  Revision 1.102  1999/09/17 19:54:07  krapht
  Removed a useless space in the rendering of SelectBox

  Revision 1.101  1999/09/15 21:33:36  fhurtubi
  Added a class property to the radio button object.
  This will be able to overwrite Netscape stupid square around
  radiobuttons

  Revision 1.100  1999/09/14 02:18:22  fhurtubi
  Changed / Added CSS things

  Revision 1.99  1999/09/13 15:01:03  scott
  lots of changes, sorry this is bad documentation :-(

  Revision 1.98  1999/09/12 06:50:14  krapht
  Removed the import function, and BaseRenderer now uses SW::Exporter

  Revision 1.97  1999/09/12 01:21:20  fhurtubi
  Added a style and class parameter to both BaseRenderer and DHTMLRenderer
  (this is a CSS thing)

  Revision 1.96  1999/09/11 08:44:36  gozer
  Made a whole bunch of little kwirps.
  Fixed Handler to deal correctly with SW_App_Namespace without defaulting to SW::App when the var is set
  Fixed the bug that made Login.pm create an empty hidden argument on every login attempt
  Added a whole bunch of modules preloading in sw-perl-startup, good speed improvment
  Fixed a few warning here and there.  Only one missing the sweep.  Application.pm and AUTOLOAD warning ?!?
  Changed the SW::Util::flatten and circular_flatten to succesfully use Data::Dumper ;-} (-180 lines of code)
  Gone to bed very late

  Revision 1.95  1999/09/10 21:56:08  fhurtubi
  Ok, Sorry guys, I had a big error in there...
  It's fixed now.. (cssLib not being defined)

  Revision 1.94  1999/09/10 20:28:36  fhurtubi
  Changed CSS data collection so it can accept an anonymous array now. This will let
  developpers use multiple CSS.

  Revision 1.93  1999/09/10 19:43:56  fhurtubi
  Added CSS functionnality. Right now, there is a global hash ref that
  will be populated by panel defined CSS. If the asked CSS exists, it returns
  it, otherwise, it loads the file then returns it. That way, we don't need
  to open the file at every transaction. Problem is that it might take a lot
  of memory in the long run...

  In your app, just go:

  $panel->setValue("cssLib", "lib.css");

  that lib must be under the distribution css_lib directory
  (/smartworker/lib/css_lib/)

  Revision 1.92  1999/09/10 14:51:09  fhurtubi
  Added a valign property to renderImage

  Revision 1.91  1999/09/09 18:59:54  gozer
  Modified the -action argument to this
   for a submit on select, you do
   -action	=> "myPanel",
  when you add your item.  That way you can control what specific form gets submitted

  Revision 1.90  1999/09/08 18:42:13  krapht
  Fixed a problem with renderLink (swURI --> URI), and font and fontSize can
  now be declared for DHTMLRenderer

  Revision 1.89  1999/09/08 18:30:13  krapht
  Added the attributes in renderLink (they were commented out!)

  Revision 1.88  1999/09/08 18:13:06  krapht
  Fixed a form bug in BaseRenderer that caused an additional line to be added
  to tables, and changed the font attribute for Text and Link objects

  Revision 1.87  1999/09/08 02:11:00  krapht
  Fixed the problems with font attributes in BaseRenderer, and added a small
  line in DHTML (can't remember where!)

  Revision 1.86  1999/09/07 03:12:20  scott
  added a tiny feature so that if you pass an array ref to selected in the
  selectbox - it will re-select multiple selects properly

  Revision 1.85  1999/09/05 21:17:03  fhurtubi
  Re-added some code that someone really shouldn't have deleted...
  (maxlength in renderTextBox)

  Revision 1.84  1999/09/05 01:28:42  fhurtubi
  Text color can be set for the main panel by setting textColor to the color you want

  Revision 1.83  1999/09/03 19:59:32  jzmrotchek
  Added "enctype=multipart/form-data" to allow for file uploads.

  Revision 1.82  1999/09/03 01:05:41  scott
  Mods so we can remove the site specific configurations info
  (SW::Config) from the framework.

  Revision 1.81  1999/09/02 19:21:53  fhurtubi
  Fixed a bug that JF didn't see

  Revision 1.80  1999/09/02 19:08:41  krapht
  Added some features to HorizontalRule

  Revision 1.79  1999/09/02 18:48:09  krapht
  Added a renderer for horizontal rules : renderHorizontalRule

  Revision 1.78  1999/09/01 21:38:44  krapht
  Changed ref to name, target to signal for internal links!

  Revision 1.77  1999/09/01 01:26:56  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.76  1999/08/31 22:11:49  fhurtubi
  Fixed the double quote bug!!! Everywhere a text value is subject to be place inside
  "", I'm replacing " by the HTML equivalent of &quot;

  For now, this is fine, but don't forget that it might not be HTML forever...

  Revision 1.75  1999/08/31 18:14:39  jzmrotchek
  Changed name of "renderFileBrowse" method to "renderFileUpload".

  Revision 1.74  1999/08/30 23:32:36  fhurtubi
  Removed what Krapht just did because its not working

  Revision 1.73  1999/08/30 22:52:13  krapht
  *** empty log message ***

  Revision 1.72  1999/08/30 22:31:53  krapht
  Changed the way the attributes are implemented in renderText and renderLink

  Revision 1.71  1999/08/30 21:54:51  krapht
  Added a alink part to masterPanel

  Revision 1.70  1999/08/30 21:38:19  krapht
  Added the possibility to change the link colors!

  Revision 1.69  1999/08/30 16:32:57  krapht
  Changed some stuff in renderPanelCore

  Revision 1.68  1999/08/29 23:00:23  krapht
  Changed some lines in renderImageButton, so the image gets displayed
  correctly, and targets work

  Revision 1.67  1999/08/29 22:55:51  krapht
  Changed a line in renderImageButton, so the callbacks work OK!

  Revision 1.66  1999/08/27 22:33:44  fhurtubi
  Added a JS check in both BaseRenderer and DHTMLRenderer... we should have
  one inherit from the other one though :(((

  Revision 1.65  1999/08/27 20:08:13  fhurtubi
  Debugging, I must have removed an extra white line..

  Revision 1.64  1999/08/19 22:34:36  fhurtubi
  Commented out the settting of width size to 100% for HTML3 main panel that was
  causing ugly diplays

  Revision 1.63  1999/08/18 20:20:50  krapht
  Added a little hack to get centered text!  Might be done differently!

  Revision 1.62  1999/08/18 16:49:57  krapht
  Small modifs!

  Revision 1.61  1999/08/17 20:10:19  krapht
  Just removed the value thing in TextBox...text does the same thing

  Revision 1.60  1999/08/17 20:07:44  krapht
  Added a value part to the TextBox, so we can set its default value

  Revision 1.59  1999/08/17 05:21:16  scott
  tweaking the default color

  Revision 1.58  1999/08/16 17:49:54  fhurtubi
  Nothing really changed, just added a comment

  Revision 1.57  1999/08/12 14:45:29  fhurtubi
  Little bug correction

  Revision 1.56  1999/08/09 22:04:15  fhurtubi
  Added an optval parameter to selectBoxRender

  Revision 1.55  1999/07/19 20:28:44  fhurtubi
  Fixed a bug in order to get grow_x and grow_y to work

  Revision 1.54  1999/07/14 21:38:49  fhurtubi
  Add the value option in renderSelectBox

  Revision 1.53  1999/06/28 21:19:20  scott
  Fixed some bugs with the BODY tag in DHTML Renderer -- this is a mess!
  needs more attention

  Revision 1.52  1999/06/17 18:44:37  krapht
  Moved FileBrowse, PasswordField, ImageButton and ImageRollover from HTML3Renderer.pm

  Revision 1.51  1999/06/16 17:44:44  krapht
  The page title can now be set using $mainPanel->setValue('name',$the_name);

  Revision 1.50  1999/06/14 20:30:21  krapht
  Moved SubmitOnSelect inside SelectBox.  Other changes

  Revision 1.49  1999/06/11 21:37:17  krapht
  Some few indenting corrections again!

  Revision 1.48  1999/06/11 21:30:39  krapht
  Fixed a mess I did with indenting (spaces !!)

  Revision 1.47  1999/06/11 18:35:10  krapht
  Some minor changes

  Revision 1.45  1999/06/02 21:26:13  marcst
  Added check for empty 'args' in renderLink

  Revision 1.44  1999/06/01 21:20:30  krapht
  Minor changes to renderLink

  Revision 1.43  1999/06/01 19:24:05  krapht
  Yet another ugly space.  And some other very minor stuff

  Revision 1.42  1999/06/01 19:00:32  krapht
  Same thing.  Damn these ugly spaces

  Revision 1.41  1999/06/01 18:54:48  krapht
  Removed an ugly space in renderImage for the width

  Revision 1.40  1999/06/01 18:46:22  scott
  overhaul of renderLink

  Revision 1.39  1999/06/01 16:22:47  krapht
  Few changes made, especially C++ style comments

  Revision 1.38  1999/06/01 16:12:52  scott
  Modified renderLink so it works with new transaction model

  Revision 1.37  1999/05/20 13:54:30  scott
  Took out reference to XML renderer for now since I haven't added it yet

  Revision 1.36  1999/05/20 13:52:13  scott
  Changes for the new transaction model

  Revision 1.35  1999/05/19 20:25:14  krapht
  Fixed a bug with the attributes in renderText.
  Added attributes in renderLink

  Revision 1.34  1999/05/19 19:23:41  krapht
  Small code change to prevent useless HTML with font tags

  Revision 1.33  1999/05/19 19:08:09  krapht
  Added text attributes (bold and italic : see documentation) and table borders

  Revision 1.32  1999/05/14 16:28:59  krapht
  Small changes by krapht

  Revision 1.31  1999/05/11 14:37:44  scott
  Changes to support separate WinCE and Palm renderers

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
  Made BaseRenderer read out of the user's preferences for fonts and
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
