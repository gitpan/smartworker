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

package SW::GUIElement::RadioButtonSet;

#------------------------------------------------------------
# SW::GUIElement::RadioButtonSet
# Creates and handles a set of SW::GUIElement::RadioButtons
#------------------------------------------------------------
# $Id: RadioButtonSet.pm,v 1.17 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::GUIElement;
use SW::Application;
use SW::Renderer::BaseRenderer;
use SW::Util;


@ISA = qw(SW::GUIElement);

$VERSION = '0.01';


sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_); # send theApp to super

	shift;  # get back in line ...

	$self->{renderCallback} = "renderRadioButtonSet"; 
	$self->{elements} = [];
	$self->{params}->{orientation} = "vertical" unless $self->{params}->{orientation};
	$self->{params}->{buttonCount} = 0;
	my $count = $self->{params}->{buttonCount};

	return $self unless $self->{params}->{buttons};

	while (@{$self->{params}->{buttons}})
	{
		my $val = shift(@{$self->{params}->{buttons}});
		my $text = shift(@{$self->{params}->{buttons}});

		my $button = SW::GUIElement::RadioButton->new($self->{theApp},
			{
				-set		=> $self, 
			   -value	=> $val, 
				-text		=> $text, 
				-name		=> $self->{params}->{name},
			});

		$self->{elements}[$count++] = $button;
	}

	return $self;
}

#------------------------------------------------------------
# addButton
#------------------------------------------------------------
sub addButton
{
	my ($self,$button) = @_;
	$self->{elements}[$self->{buttonCount}++] = $button;
}
#------------------------------------------------------------------
# updateState
#------------------------------------------------------------------ 

sub updateState
{
	my $sessionData = $_[0]->processSessionData();

	$_[0]->{params}->{checked} = $sessionData;
}

#------------------------------------------------------------------
# render
#------------------------------------------------------------------ 

sub render
{
	my ($self, $renderer) = @_;
	my $renderCall = $self->{renderCallback};

	$renderer->$renderCall($self);
}

#------------------------------------------------------------------
# setValue
#------------------------------------------------------------------ 

sub setValue
{
	my $self = shift;

	if (@_ > 1)
	{
		return $self->SUPER::setValue(@_);
	} else
	{
		my $newValue = shift;

		foreach my $b ($self->{elements})
		{
			if ($b->{value} eq $newValue)
			{
				$self->{params}->{checked} = $newValue;
				return $newValue;
			}
		}

		return $self->{checked};
	}
}

#------------------------------------------------------------------
# getValue
#------------------------------------------------------------------ 

sub getValue
{
	my $self = shift;

	if (@_)
	{
		return $self->SUPER::getValue(@_);
	} else
	{
		return $self->{params}->{checked};
	}
}

#------------------------------------------------------------------
# getButtons
#------------------------------------------------------------------ 

sub getButtons
{
	my $self = shift;

	return $self->{elements};
}

1;
__END__

=head1 NAME

SW::GUIElement::RadioButtonSet - SmartWorker object for a SET of Radio Buttons

=head1 SYNOPSIS

  use SW::GUIElement::RadioButtonSet;

  my $buttonSet = new SW::GUIElement::RadioButtonSet ( $Application,
				{  name => 'name',
				   buttons => ['val1','text1','val2','text2'...],
				   orientation => '[vertical|horizontal]',
				});


	$buttonSet->addButton(new SW::GUIElement::Button(...));

  for simple layout:

  $panel->addElement($buttonSet);

  or for complex layout:

  foreach my $button (@{$buttonSet->getButtons()})
  {
	$panel->addElement($button);
  }

  swResponseSomeCallback
  {
	$value = $buttonSet->getValue();

	$buttonSet->setValue('new_checked_value');
  }
				   

=head1 DESCRIPTION

  swRadioButtonSet manages the checked / unchecked'ness of the contained buttons and
	will lay them out in a simple vertical or horizontal pattern.
	
  To achieve more complex layouts:  create the buttons as an swRadioButtonSet, but rather
	adding the swRadioButtonSet to the panel, use getButtons() to return a list (in
	display order) of the buttons and add each one separately to the panel (DON'T
	ADD swRadioButtonSet)

=head1 METHODS

  new  -  takes an annonymous array of button names and texts in the buttons param
				eg ['buttonvalue1,'text1','buttonvalue2','text2']  (see SYNOPSIS)
  
  getValue(['name']) - returns the value of the checked button.  If 'name' is provided, returns the
			value of the property 'name'.

  setValue(['name',]'value') -  set the button with value 'value' as checked, if 'name' provided,
				sets that property to 'value'.  If a button with value 'value'
				does not exist, the call is ignored, sends a debug message, and 
				returns the current checked value.

  getButtons() - return a array ref of the constituent Radio Buttons (as
	references) in their insertion order.  To be used for more
	advanced layout than the group provides.

	addButton($button) - add a new button to the list.
  

=head1 PROPERTIES

  name => Reference name for the group
  orientation => vertical or horizontal (for simple layout)
		  Default: vertical
  checked => value of selected swRadioButton
  buttonCount => number of buttons in the button set

=head1 AUTHOR

Scott Wilson		scott@hbe.ca
Feb 17.99

=head1 REVISION HISTORY

  $Log: RadioButtonSet.pm,v $
  Revision 1.17  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.16  1999/10/01 16:02:33  krapht
  Removed TreeView, and the bless line in each GUIElement, which was useless
  anyways!

  Revision 1.15  1999/09/16 21:19:13  matju
  fixed the buggy documentation.

  Revision 1.14  1999/09/05 18:49:07  scott
  added an addButton method, allowed for creating an empty radiobuttonset,
  and updated the docs a bunch

  Revision 1.13  1999/09/03 21:49:36  scott
  updated set

  Revision 1.12  1999/09/03 16:20:12  scott
  docs bug

  Revision 1.11  1999/09/01 21:38:40  krapht
  Changed ref to name, target to signal for internal links!

  Revision 1.10  1999/09/01 01:26:50  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.9  1999/08/30 19:50:10  krapht
  Removed the use Exporter lines and associated code (@EXPORT, etc.)

  Revision 1.8  1999/08/12 14:45:26  fhurtubi
  Little bug correction

  Revision 1.7  1999/06/18 14:56:56  krapht
  Code cleanup...Removed SelectOnSubmit.pm (submit on select is in the selectbox now)

  Revision 1.6  1999/05/20 13:51:52  scott
  Changes for the new transaction model
    Changed around the package and compnent internal naming scheme

  Revision 1.5  1999/02/22 00:52:58  scott
  1)  added a $object->visible() method to enable hiding objects
  2)  created TreeView
  3)  implemented an easier, more flexible callback system to facilitate
  	callbacks calling other callbacks and better control over which
  	level of objects get the callbacks.  Also allows argument passing
  	to the callback.


=head1 SEE ALSO

perl(1).

=cut
