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

package SW::GUIElement::ListBox;

#------------------------------------------------------------
# SW::GUIElement::ListBox
# Select Box Form Element
#------------------------------------------------------------
# $Id: ListBox.pm,v 1.6 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::GUIElement;
use SW::Application;
use SW::Renderer::BaseRenderer;


@ISA = qw(SW::GUIElement);

$VERSION = '0.01';


sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_); # send theApp to super

	shift; # get back in line ...

	if (! $self->{hc})
	{
		$self->{params}->{name} = shift;
		$self->{params}->{selected} = shift;
	}

	$self->{renderCallback} = "renderListBox";

	return $self;
}

sub updateState
{
	my $self = shift;

	my $sessionData = $self->processSessionData();

	if ($sessionData ne "")
	{
		$self->{params}->{value} = $sessionData;
	}
}

sub render
{
	my ($self, $renderer) = @_;

	my $renderCall = $self->{renderCallback};

	$renderer->${renderCall}( $self );
}


1;
__END__

=head1 NAME

SW::GUIElement::ListBox - swSelectBox element

=head1 SYNOPSIS

  use SW::GUIElement::ListBox;

  my $list = new SW::GUIElement::ListBox($Application, {
							-name=>'name',
							-options=>(choice1,choice2,choice3),
							-selected=>(choice2,..),
							});

  $list->setValue('choice3');
    -- short for ---
  $list->setValue('selected','choice3');

  $panel->addElement($list);
	

=head1 DESCRIPTION

  SmartWorker List Box form component.  Pass an array of possible values to the options 
	property.  Pass a list of the selected elements (if applicable) to selected, or
	use the setValue() function to set them.

=head1 METHODS

  new ($Application, {hash of values including @options } );

  setValue('prop','value') - sets the property to value, or with only one argument, set 
				the selected element.


=head1 PROPERTIES

  ref - SmartWorker name reference
  options - array of choices
  selected - value of item selected


=head1 TODO

  addOption() -  add an option to the list
  removeOption() -  remove an option from the list
  select() -   Select another option
  deselect() -   Deselect an option 

=head1 AUTHOR

Scott Wilson	scott@hbe.ca
Feb 17/99

=head1 REVISION HISTORY

  $Log: ListBox.pm,v $
  Revision 1.6  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.5  1999/10/01 16:02:33  krapht
  Removed TreeView, and the bless line in each GUIElement, which was useless
  anyways!

  Revision 1.4  1999/09/01 21:38:40  krapht
  Changed ref to name, target to signal for internal links!

  Revision 1.3  1999/09/01 01:26:50  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.2  1999/08/30 19:50:10  krapht
  Removed the use Exporter lines and associated code (@EXPORT, etc.)

  Revision 1.1  1999/02/18 10:42:51  scott
  New GUIElement components - LinkExternal, ListBox, SelectBox, TextBox, RadioButtonSet


=head1 SEE ALSO

perl(1).

=cut
