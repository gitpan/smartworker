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

package SW::Renderer::WinCERenderer;

#------------------------------------------------------------
# SW::Renderer::WinCERenderer
# Renders HTML suitable for display on win ce boxes with pocket IE 2.0
#------------------------------------------------------------
# $Id: WinCERenderer.pm,v 1.14 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::Renderer::BaseRenderer;
use LWP::UserAgent;


@ISA = qw(SW::Renderer::BaseRenderer);

$VERSION = '0.02';

my $STYLE = 'WinCE';


sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	bless ($self, $classname);

	$self->{style} = $STYLE;

	return $self;
}

#--------------------------------------------------------------
# renderPanel
#
# This version ignores background images, which cannot be
# displayed on PIE.
#--------------------------------------------------------------

sub renderPanel
{
	my ($self,$panel) = @_;
	my $data = "";
	my $title="SmartWorker for Windows CE";

	$self->{theApp}->debug("Rendering WinCE Panel");

	my $foreground = $self->{theApp}->{user}->preference("Foreground Colour");
	$foreground = "#000000" if $foreground eq "";

	my $link = "#0000ff";
	my $vlink = "#ff0000";

	if($panel->getValue("master"))
	{  # if it's the top level html

		my $col;

		if($panel->getValue("bgColor"))
		{
			$col=$panel->getValue("bgColor");

		} else {
			$col=$self->{prefs}->{"Background Color"};
		}

		$col = "#ffffff" if $col eq "";

		$data=<<EOF;
<HTML>\n<HEAD><TITLE>$title</TITLE></HEAD>\n<BODY bgcolor="$col" text="$foreground" link="$link" vlink="$vlink">
EOF

	}

	$data = $self->_renderPanelCore($panel,$data);
	$data .= "</TABLE>\n</BODY>\n</HTML>";

	return $data;

}

#---------------------------------------------------------------
# renderHTMLPanel
#---------------------------------------------------------------

sub renderHTMLPanel
{
	my $self=shift;
	my $panel=shift;
	my $data="";

	if(!$panel->{params}->{url})
	{
		$data = $self->_renderPanelCore($panel,$data);
		$data .= "</table>\n";

	} else {
		$self->{theApp}->debug("panel url is ".$panel->{params}->{url});
    
		my $ua = new LWP::UserAgent;
		$ua->agent("SmartWorker/0.1 " . $ua->agent);

		my $uri = $panel->{params}->{url};
		my $doc = get $uri;
		$data = $doc;

	}

	return $data;
}

#---------------------------------------------------------------
# renderFormPanel
#---------------------------------------------------------------

sub renderFormPanel
{
	my $self=shift;
	my $panel=shift;

	my $uri_target = SW->request->uri();
	my $data = qq/<form method=post name="name" action="$uri_target">\n/;

	my %appendages = %{$self->{theApp}->getAppendages()};

	while(my ($k,$v) = each(%appendages))
	{
		$data .= qq/<input type="hidden" name="$k" value="$v">\n/;
	}

	$data .= qq/<input type="hidden" name="_submitted" value="/.$panel->getValue("name").qq/">\n/;
	$data = $self->_renderPanelCore($panel,@_,$data);

	$data .= "</TABLE></FORM>\n";
	return $data;
}


#---------------------------------------------------------------
# _renderPanelCore
#
# This part might look like a really big piece of junk.
# It needs work and a paint job! 
#---------------------------------------------------------------

sub _renderPanelCore
{
	my $self=shift;
	my $panel=shift;
	my $data=shift;
	my $elements=$panel->{elements};
	my ($cols,$rows)=$panel->getSize();
	my $border=$panel->{border};
	my $spacing=$panel->getValue("spacing");
	my $panelBgColor = $panel->getValue("bgColor");

	my ($yLayout,$xLayout,$debugLayout)=$self->layoutPanel($panel);

	$data .= "<TABLE";

	my $tableBorder = $panel->getValue("border");
	($tableBorder) ? ($data .= " border=$tableBorder"):($data .= " border=0");

	$data .= " valign=top";

	if($panel->getValue("master") eq "true")
	{
		$data .= " width=100% height=100%";

	} else {
		if($panel->getValue("grow_x" eq "true"))
		{
			$data .= " width=100%";
		}

		if($panel->getValue("grow_y" eq "true"))
		{
			$data .= " height=100%";
		}
	}

	if($panel->getValue('BorderDebug'))
	{
		$data .= "><tr valign=top><td>\n<table cellspacing=0 cellpadding=1 border=0>";

	} else {
		$data .= ">\n";
	}

	#----------------------------------------------------------------------
	# Loop scanning the elements array and rendering each "cell"
	#----------------------------------------------------------------------
	my $tableOpening=0;

	for(my $y=0;$y<$rows;$y++)
	{
		$data .= "<tr>\n";

		for(my $x=0;$x<$cols;$x++)
		{

			if(! $yLayout->[$x][$y])
			{
				next;
			}

			if(!$panel->{elements}[$x][$y])
			{
				$data .= "<td></td>\n";

			} elsif(! $panel->{elements}[$x][$y]->visible) {
				$data .= "<td></td>\n";

			} else {

				my $elBgColor = $panel->{elements}[$x][$y]->getValue('bgColor');
				if($elBgColor eq "") { $elBgColor = $panelBgColor; }


				if($elBgColor!=$panelBgColor) { $tableOpening=1; }

				#-----------------------------------------------
				# get the information needed for the td tag
				#-----------------------------------------------

				my $elColspan = $xLayout->[$x][$y];
				my $elRowspan = $yLayout->[$x][$y];
				my $elAlign   = $panel->{elements}[$x][$y]->getValue('align');
				my $elVAlign = $panel->{elements}[$x][$y]->getValue('valign');
				my $elWidth  = $panel->{elements}[$x][$y]->getValue('width');
				my $elHeight = $panel->{elements}[$x][$y]->getValue('height');
				my $font = $self->{font};
				my $fontsize = $self->{fontsize};


				$data .= "<td";

				if($elColspan>1) { $data .= " colspan=$elColspan"; }
				if($elRowspan>1) { $data .= " rowspan=$elRowspan"; }
				if($elWidth) { $data .= " width=$elWidth"; }
				if($elHeight) { $data .= " height=$elHeight"; }
				if($elAlign && !$tableOpening) { $data .= " align=$elAlign"; }
				if($elVAlign && !$tableOpening) { $data .= " valign=$elVAlign"; }

				$data .=">";

				#---------------------------------------------------------------------
				# Pocket Internet Explorer does not recognize background colors in
				# tables, so custom table border must be made to separate the areas
				# where background colors are generally different
				#---------------------------------------------------------------------

				if($tableOpening)
				{
					$data .= "<table border=1><tr><td><table border=0><tr><td>";
				}

				$data .= $panel->{elements}[$x][$y]->render($self); 

				if($tableOpening)
				{
					$data .= "</td></tr></table></td></tr></table>";
					$tableOpening=0;
				}

				$data .= "</td>\n";

			}
		}

		$data .= "</tr>\n";
	}

	if($panel->getValue('BorderDebug')) { $data .= "</table></td></tr>\n"; }

	return $data;
}

#------------------------------------------------------------------
# renderText
#------------------------------------------------------------------

sub renderText
{
	my $self=shift;
	my $swText=shift;
	my $data = "";
	my $panelFontColor = $self->{theApp}->{user}->preference("Foreground Color");
	$panelFontColor ||= "#000000" ;

	my $text=$swText->getValue('text');

	my $font = $self->{font};
	my $fontColor = $swText->getValue('textColor') || $self->{prefs}->{"Foreground Color"};
	my $fontSize = $swText->getValue('fontSize') || $self->{prefs}->{"Font Size"};
	my $attrib = $swText->getValue('attrib');

	my $fontTag=0;

	if($font eq "" && ($fontColor eq "" || $fontColor eq $panelFontColor) && $fontSize eq "")
	{
    # $data .= $text;
    # do nothing

	} else {
		$data .= "<font";
		$fontTag = 1;

		if($font) { $data .= " face=\"$font\""; }
		if($fontColor) { $data .= " color=\"$fontColor\""; }
		if($fontSize) { $data .= " size=$fontSize"; }

		$data .= ">";
	}

	if($attrib eq "bold")
	{
		$data .= "<b>$text</b>";

	} elsif($attrib eq "ital") {
		$data .= "<i>$text</i>";

	} else { $data .= $text; }

	if($fontTag) { $data .= "</font>"; }

	return $data;
}

#---------------------------------------------------------------------------
# sub renderBorders
#
# Because PIE doesn't recognize background table colors, we need to create
# a new layout so borders are added where background colors would normally
# delimit cells
#---------------------------------------------------------------------------

sub renderBorders
{
	my $self=shift;
	my $panel=shift;

	my @bordersLayout=undef;

	return @bordersLayout;
}


1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::Renderer::WinCERenderer - HTML renderer for Pocket Internet Explorer 

=head1 SYNOPSIS

  use SW::Renderer::WinCERenderer;

=head1 DESCRIPTION

HTML renderer for the Windows CE platform, adapted for Pocket Internet
Explorer.

=head1 AUTHOR

Jean-Francois Brousseau   May 11/1999
krapht@hbe.ca

=head1 REVISION HISTORY

	$Log: WinCERenderer.pm,v $
	Revision 1.14  1999/11/15 18:17:33  gozer
	Added Liscence on pm files
	
	Revision 1.13  1999/09/20 15:02:04  krapht
	Replaced getRequest by SW->request
	
	Revision 1.12  1999/09/11 08:44:37  gozer
	Made a whole bunch of little kwirps.
	Fixed Handler to deal correctly with SW_App_Namespace without defaulting to SW::App when the var is set
	Fixed the bug that made Login.pm create an empty hidden argument on every login attempt
	Added a whole bunch of modules preloading in sw-perl-startup, good speed improvment
	Fixed a few warning here and there.  Only one missing the sweep.  Application.pm and AUTOLOAD warning ?!?
	Changed the SW::Util::flatten and circular_flatten to succesfully use Data::Dumper ;-} (-180 lines of code)
	Gone to bed very late
	
	Revision 1.11  1999/09/01 01:26:56  krapht
	Hahahahha, removed this %#*(!&()*$& autoloader shit!
	
	Revision 1.10  1999/08/30 19:59:22  krapht
	Removed the Exporter stuff
	
	Revision 1.9  1999/07/25 02:41:03  scott
	nothing
	
	Revision 1.8  1999/06/18 19:48:02  krapht
	Code cleanup
	
	Revision 1.7  1999/06/18 15:14:33  krapht
	Code cleanup
	
	Revision 1.6  1999/05/19 20:27:06  krapht
	Fixed a bug with attributes in renderText
	
	Revision 1.5  1999/05/19 19:22:04  krapht
	Added attributes to renderText (bold and italic : see documentation)
	
	Revision 1.4  1999/05/19 19:07:20  krapht
	Changed a few features concerning the table creation instead of
	background colors in tables
	
	Revision 1.3  1999/05/14 16:45:29  krapht
	Other changes
	
	Revision 1.2  1999/05/14 16:29:19  krapht
	Small changes by krapht
	Still work to do
	
	Revision 1.1  1999/05/11 14:38:10  scott
	New Files for WinCE  (Pocket IE 2.0)
	

=head1 SEE ALSO

perl(1).

=cut
