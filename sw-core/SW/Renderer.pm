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

package SW::Renderer;

#------------------------------------------------------------
# SW::Renderer
# Basic Rendering class for SW visible objects
#------------------------------------------------------------
# $Id: Renderer.pm,v 1.18 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::Renderer::BaseRenderer;
use SW::Component;
use SW::Application;


@ISA = qw(SW::Component);

$VERSION = '0.01';


#------------------------------------------------------------
# new - method
#
#------------------------------------------------------------

sub new 
{
	my $classname = shift;
	my $app = shift;

	my ($browser, $style, $os) = classifyBrowser(shift);

	my $self = { 
				style => $style,
				os => $os,
				browser => $browser,
				app => $app,
			};

	bless ($self, $classname);

	$self->{renderer} = $self->initRenderer();
	return $self;
}


#------------------------------------------------------------
# initRenderer - method
#
#------------------------------------------------------------

sub initRenderer
{
	my $self = shift;
	my $style = $self->{style};

	$style = $self->{app}->confirmRenderStyle($style);

	my $classtype = "SW::Renderer::$style" . "Renderer";

	return ($classtype->new($self->{app}, $self->{browser}));
}


#------------------------------------------------------------
# renderStyle - method
#
#------------------------------------------------------------

sub renderStyle
{
	my $self = shift;

	if(@_)
	{
		$self->{style} = shift;
	}

	return $self->{style};
}


#------------------------------------------------------------
# getBrowser - method
#
#------------------------------------------------------------

sub getBrowser
{
	return ($_[0])->{browser};
}


#------------------------------------------------------------
# getOs - method
#
#------------------------------------------------------------

sub getOs
{
	return ($_[0])->{os};
}


#------------------------------------------------------------
# getRenderer
#
#------------------------------------------------------------

sub getRenderer
{
	return ($_[0])->{renderer};
}


#------------------------------------------------------------
# renderPanel - method
#
#------------------------------------------------------------

sub renderPanel
{
		
	my ($self, $panel) = @_;
	return $self->{renderer}->renderPanel($panel);
}


#------------------------------------------------------------
# classifyBrowser - method
#
# This method will determine the browser name and version
# by doing regexes on the request.  This classification can
# then be used to select the most suitable renderer.
#
# Returns the browser name and the renderer that will be
# used.
#------------------------------------------------------------

sub classifyBrowser
{
	my $agent = $_[0];
	my $os = "Win";
	my $browser = "Unknown browser";
	my $version = -1;
	my $renderType = "HTML3";

	# Recognized browsers, and the associated renderer
	my %renderTypeMap = (
						"Netscape 4"	=> "DHTML",
						"Netscape 5"	=> "DHTML",
						"MSIE 4"			=> "DHTML",
						"MSIE 5"			=> "DHTML",
						"Opera"			=> "HTML3",  # Not sure about this one!
						"Lynx"			=> "Text",
						"ProxiWeb"		=> "Palm",
						"WinCE"			=> "WinCE",
					);

	# Let's try to figure out the OS first

	if($agent =~ /Unix/c)
	{
		$os = "Unix";
	}
	elsif($agent =~ /X11/c)
	{
		# This needs to be changed, as X is also available for other platforms
		$os = "Unix";
	}
	elsif($agent =~ /Linux/c)
	{
		$os = "Unix";
	}
	elsif($agent =~ /SOLARIS/c)
	{
		$os = "Unix";
	}
	elsif($agent =~ /Macintosh/c)
	{
		$os = "Mac";
	}


	# Here, we try to identify the browser with a regex on the agent
	# tag from the browser

	if($agent =~ /MSIE/c)
	{
		$agent = substr($agent,11);
		$browser = "MSIE";
	}
	elsif($agent =~ /Mozilla/c)
	{
		$browser = "Netscape";
	}
	elsif($agent =~ /Lynx/c)
	{
		$browser = "Lynx";
	}
	elsif($agent =~ /ProxiNet/c)
	{
		$browser = "ProxiWeb";
	}
	elsif($agent =~ /MSPIE 2.0/c)
	{
		$browser = "WinCE";
	}
	elsif($agent =~ /Opera/)
	{
		$browser = "Opera";
	}

	# Version info
	($browser, $version) = appendVersion($agent, $browser);


	if(exists($renderTypeMap{$browser}))
	{
		$renderType = $renderTypeMap{$browser};
	}

	return ($browser, $renderType, $os);
}


#------------------------------------------------------------
# appendVersion - function
#
#------------------------------------------------------------

sub appendVersion
{
	my $version = -1;
	my ($agent, $browser) = @_;

	if($agent =~ /[\s|\/]((\d)\.\d+)\b/g )
	{
		if($2 > 3)
		{
			$browser = "$browser $2";
		}

		$version = $1;
	}

	return ($browser, $version);
}

1;

__END__

=head1 NAME

SW::Renderer - SmartWorker publicly accessible Renderer class.

=head1 SYNOPSIS

  use SW::Renderer;

=head1 METHODS

=head2 Constructor:
  $self->{renderer} = new SW::Renderer($Application, $Agent_String);
  my $renderer = new SW::Renderer($Application, $Agent_String);

to set the render style:

=head2 To begin rendering:
  $self->{renderer}->render($Owner_Panel);
  renderStyle($new_render_style);


=head1 DESCRIPTION

Interface class to all the Renderers, performs browser detection/classification, initializes a renderer and returns a reference to it up to the panel.  Renderer always belongs to a Panel class. 

Set the render style manually or query it using renderer->renderStyle();
 
=head1 AUTHOR

Scott Wilson
HBE
Jan 8/99

=head1 HISTORY

$Log: Renderer.pm,v $
Revision 1.18  1999/11/15 18:17:33  gozer
Added Liscence on pm files

Revision 1.17  1999/11/02 23:36:41  fhurtubi
Ok, MSIE is detected before Mozilla now..otherwise, IE was rendred as Mozilla

Revision 1.16  1999/10/05 19:44:38  krapht
Put some more comments, shortcuts, etc.  Also removed appendVersion from
inside classifyBrowser.



=head1 SEE ALSO

perl(1).

=cut
