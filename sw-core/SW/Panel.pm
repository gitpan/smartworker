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

package SW::Panel;

#------------------------------------------------------------
# SW::Panel
# Main class for display panels.
#------------------------------------------------------------
# $Id: Panel.pm,v 1.25 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use Carp;
use SW::Application;
use SW::Renderer;
use SW::Component;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;


@ISA = qw(SW::Component);

$VERSION = '0.01';


sub new
{
	my $swClassName = shift;
	my $self = $swClassName->SUPER::new(@_);	# send theApp to the top to be received

	if (! $self->{hc}) 
	{
		$self->{theApp} = shift;
		$self->{params}->{name} = shift; 
	}

	my $theApp = $self->{theApp};

	$self->{className} = $swClassName;
	$self->{elements} = [];
	$self->{renderer} = undef;
	$self->{columns} = 1;
	$self->{rows} = 1;

	if (!$self->{params}->{valign})
	{
		$self->{params}->{valign} = 'top';
	}
	if (!$self->{params}->{align})
	{
		$self->{params}->{align} = 'left';
	}

	bless $self, $swClassName;

	# Set up basic Panel structures

	$self->{renderer} = new SW::Renderer ($theApp, SW->request->header_in("User-Agent") );		

	if ($self->{params}->{grid_x})
	{
		$self->{columns} = $self->{params}->{grid_x};
	}

	if (! $self->{params}->{grow_x})
	{
		$self->{params}->{grow_x} = 'true';
	}        

	if (! $self->{params}->{grow_y})
	{
		$self->{params}->{grow_y} = 'true';     
	}
	

	$self->setTheme();

	return $self;
}

sub DESTROY
{
	my $self = shift;

#	print STDERR "panel DESTROY \n";
}

sub render
{
	my $self = shift;

	my $data = $self->renderer()->renderPanel($self);
	
#	$self->exit();

	return $data;

}


#------------------------------------------------------------
# renderer
#
#------------------------------------------------------------

sub renderer
{
	my $self=shift;

	return $self->{renderer}->{renderer};
}


#------------------------------------------------------------
# setTheme
#
#------------------------------------------------------------

sub setTheme
{
	my $self=shift;
	
	#------------------------------------------------------------
	# Get theme info from user
	#------------------------------------------------------------

	if (!$self->{params}->{bgColor})
	{
		$self->{params}->{bgColor} = SW->user->preference('Background Colour');
	}

	$self->{params}->{textColor} = SW->user->preference('Foreground Colour');
}


#-------------------------------------------------------------
# trickleState
#
# Initiates a call down to all children to execute code
# pertaining to the argument, 'state'
#-------------------------------------------------------------

sub trickleState
{
	my $self = shift;
	my $state = shift;
	my $noTrickle = undef;

	if ($state eq 'InitApplication')
	{        
		#  $self->swInitApplication(@_);
	}        
	elsif ($state eq 'InitInstance')
	{        
		#  $self->swInitInstance(@_);
	}        
	elsif ($state eq 'InitTransaction')
	{        
		#  $self->swInitTransaction(@_);
	}        
	elsif ($state eq 'PreTreeCallbacks')
	{
		$self->preTreeCallbacks(@_);
	}
	elsif ($state eq 'BuildUI')
	{
		$self->swBuildUI(@_);
	}       
	elsif ($state eq 'PostTreeCallbacks')
	{
		$self->postTreeCallbacks(@_);
	}
	elsif ($state eq 'SaveState')
	{
		$self->saveState(@_);
	}
        
	if (! $noTrickle)
	{
		my ($col, $row) = $self->getSize();

		for (my $i=0;  $i<$col; $i++)
		{
			for (my $j=0; $j<$row; $j++) 
			{
				my $el = $self->{elements}[$i][$j];
				next unless $el;

#hack!
				$el->trickleState($state); 
			}
		}
	}

	if ($state eq 'CleanUp')
	{
		$self->cleanup();
	}

}


#------------------------------------------------------------
# cleanup
#------------------------------------------------------------

sub cleanup
{
	my $self = shift;
	
	my ($col, $row) = $self->getSize();

	for (my $i=0;  $i<$col; $i++)
	{
		for (my $j=0; $j<$row; $j++) 
		{
			$self->{elements}[$i][$j] = undef;
		}
	}

	foreach my $k (keys %$self)
	{
		delete ($self->{$k});
	}

	return;
}


#------------------------------------------------------------
# getSize
#------------------------------------------------------------

sub getSize
{
	my $self=shift;

	return ($self->{columns}, $self->{rows});
}


#------------------------------------------------------------
# getElementSize
#
# Returns the size of a given element in rows and columns
# which are in turn rendered by the renderer.  At present
# this allows only the most basic functionality but we will
# implement different preference systems that will allow
# the developer to choose which kind of dimensional
# preference to use.
# First model:  favour vertical columns first.
#------------------------------------------------------------

# now handled in the renderer

sub getElementSize
{
	my $self = shift;
	
	return ($self->getValue("colspan"), $self->getValue("rowspan"));
}	

sub oldgetElementSize
{
	my $self = shift;

	my $cellX = shift;
	my $cellY = shift;

	my $cols=1;
	my $rows=1;

	my $minX=$self->{columns};
	my $minY=$self->{rows};

	my $minDimX=1;
	my $minDimY=1;

	my $done = 0;

	# figure out how wide the cell can be

	for (my $xLoop=$cellX+1; $xLoop<$minX; $xLoop++)
	{
		for (my $yLoop=0; $yLoop<$minY; $yLoop++)
		{
			if ($self->{elements}[$xLoop][$yLoop])
			{
				if ($self->{elements}[$xLoop][$yLoop]->visible)
				{
					$done = 1;
					last;
				}
			}
		}

		last if ($done);

		$minDimX++;
	}

	$cols = $minDimX;

	# now height

	$done =0;

	for (my $yLoop=$cellY+1; $yLoop<$minY; $yLoop++)
	{
		for (my $xLoop=$cellX; $xLoop<($cellX+$cols); $xLoop++)
		{
			if ($self->{elements}[$xLoop][$yLoop])
			{
				if ($self->{elements}[$xLoop][$yLoop]->visible())
				{
					$done = 1;
					last;
				}
			}
		}

		last if $done;
		$minDimY++;
	}

	$rows = $minDimY;

	return ($cols, $rows);
}


#------------------------------------------------------------
# addElement
#
# Adds an element to a panel at a specific place.  This
# allows the panel to resize itself dynamically, and to
# track its dimensions prior to rendering.
#------------------------------------------------------------

sub addElement
{
	my ($self,$x,$y,$el,$width,$height) = @_;

	if (not defined $el) {
	  croak "addElement: try adding something real instead";}

	$el->{panelName} = $self->getValue("name");
	$el->{parent} = $self;

	$self->{elements}[$x][$y] = $el;

	if ($x >= $self->{columns})
	{
		$self->{columns} = $x+1;
	}

	if ($y >= $self->{rows})
	{
		$self->{rows} = $y+1;
	}

	$el->setValue('width', $width)		if $width;
	$el->setValue('height', $height)	if $height;
}

#------------------------------------------------------------
# addJSLib
#
# Adds a JavaScript library to the panel
#------------------------------------------------------------

sub addJSLib
{
	my $self = shift;
	my $libname = shift;

}


#------------------------------------------------------------
# updateState
#
#------------------------------------------------------------

sub updateState
{
	my $self = shift;
	
	my ($col, $row) = $self->getSize();

	for (my $i=0;  $i<$col; $i++)
	{
		for (my $j=0; $j<$row; $j++) 
		{
			my $el = $self->{elements}[$i][$j];
			next unless $el;
			if (ref($el) =~ /:/) { $el->updateState(); }
			else { SW::debug($self,"error - ".ref($el)." not blessed ",1); }
		}
	}
}


#------------------------------------------------------------
# go
#
#------------------------------------------------------------

sub go
{
	my $self = shift;
	my $initState = shift;
	
	my ($col, $row) = $self->getSize();

	for (my $i=0;  $i<$col; $i++)
	{
		for (my $j=0; $j<$row; $j++) 
		{
			my $el = $self->{elements}[$i][$j];

			next unless $el;
			next unless $el->can("go");
			$el->go($initState);
		}
	}
}


1;

__END__

=head1 NAME

SW::Panel - Panel class for SmartWorker rendering system 

=head1 SYNOPSIS

  use SW::Panel;

  my $newPanel = new SW::Panel();
  my $secondPanel = new SW::Panel();
  $newPanel->addElement(0, 0, $secondPanel);
  $newPanel->render();

=head1 DESCRIPTION

The Panel class is a container class from which the other panel types are
derived.  It provides basic formatting and layout, and in this respect it
performs much like the Java Layout classes.  Elements such as other panels, GUI elements,
and text can be added to the panel's two-dimensional element array, which is then
rendered into browser-adapted HTML by the renderer. 

=head1 PROPERTIES

	bgColor - Background Color for the panel
	fgColor - Default text color for the panel

=head1 AUTHOR

Kyle Dawkins, kyle@hbe.ca

=head1 REVISION HISTORY

  $Log: Panel.pm,v $
  Revision 1.25  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.24  1999/10/07 21:33:21  matju
  a smarter addElement

  Revision 1.23  1999/09/20 15:01:36  krapht
  Removed getRequest from Panel, and removed that useless "All done" in Util

  Revision 1.22  1999/09/20 14:30:00  krapht
  Changes in most of the files to use the new way of referring to session,
  user, etc. (SW->user, SW->session).

  Revision 1.21  1999/09/11 07:07:23  scott
  Made substantial changes to the database schema and data storage models.
  Now there's three global tables called datamap, dataaccess, and
  datainfo.  These hide the many other more data specific tables
  where the infomation is actually stored.

  Revision 1.20  1999/09/01 01:26:46  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.19  1999/08/30 20:04:00  krapht
  Removed the Exporter stuff

  Revision 1.18  1999/07/23 16:30:22  scott
  changed debug message

  Revision 1.17  1999/07/19 13:29:19  scott
  Lots of clean-up work, debugged and improved the desctructor calling of all
  copmonents so none should be left lingering after the transaction completes.

  This in turn solved the session problem (destructor wasn't being called
  because it was persisting past the end of the transaction)

  Revision 1.16  1999/06/17 21:46:26  krapht
  Code cleanup

  Revision 1.15  1999/06/14 20:10:37  scott
  fixed so guielements can find the panel they belong to with $element->{parent}

  Revision 1.14  1999/05/20 13:52:04  scott
  Changes for the new transaction model

  Revision 1.13  1999/05/05 16:06:20  scott
  fixed for panel cell backgrounds

  Revision 1.12  1999/05/04 15:53:46  scott
  -New Apache::Session based database session tracking
  -New debugging scheme

  Revision 1.11  1999/04/20 20:30:52  kiwi
  Changed default alignment to be read out of the 'align' parameter

  Revision 1.10  1999/04/20 05:03:00  kiwi
  Changed the basic colour scheme a bit

  Revision 1.9  1999/04/13 16:37:15  scott
  modified to implement trickleState

  Revision 1.8  1999/03/29 20:50:10  scott
  rendering tweaks

  Revision 1.7  1999/02/22 00:52:58  scott
  1)  added a $object->visible() method to enable hiding objects
  2)  created TreeView
  3)  implemented an easier, more flexible callback system to facilitate
  	callbacks calling other callbacks and better control over which
  	level of objects get the callbacks.  Also allows argument passing
  	to the callback.

  Revision 1.6  1999/02/17 22:50:37  kiwi
  Added go() method.

  Revision 1.5  1999/02/17 17:08:45  kiwi
  Altered class to use hierarchical parent/child app relationships

  Revision 1.4  1999/02/12 22:44:41  scott
  added updateState(), set up some default color combinations

  Revision 1.3  1999/02/12 00:06:24  scott
  added a name argument to the constructor and added it to each child element as ->{panelName}

  Revision 1.2  1999/02/11 20:59:03  kiwi
  Removed log at the top.

  Revision 1.1.1.1  1999/02/10 19:49:10  kiwi
  SmartWorker

  Revision 1.3  1999/02/09 23:54:14  scott
  Changed to inherit from SW::Component

  Revision 1.2  1999/02/09 18:15:23  kiwi
  Added revision history to perldoc file


=head1 SEE ALSO

SW::Application(1), perl(1).

=cut
