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

package SW::GUIElement::CheckBox;

#------------------------------------------------------------
# SW::GUIElement::CheckBox
# SW Check Box form element
#------------------------------------------------------------
# $Id: CheckBox.pm,v 1.14 1999/11/15 18:17:33 gozer Exp $
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
		$self->{params}->{ref} = shift;
		$self->{params}->{value} = shift;
		$self->{params}->{text} = shift;
		$self->{params}->{selected} = shift;
	}
       
	$self->{renderCallback} = "renderCheckBox";
 
	return $self;
}

sub updateState
{
	my $self = shift;

	my $sessionData = $self->processSessionData();

	if ($sessionData ne "")
		{  $self->{params}->{checked} = 1; }
}


sub render
{
	my ($self, $renderer) = @_;

	my $renderCall = $self->{renderCallback};

	$renderer->${renderCall}($self);
}

sub processSessionData
{
	my $self = shift;

	my $returnValue = "";

	if ($self->{params}->{ref})
	{
		my $theApp = $self->{theApp}->{master};
		my $data = $theApp->getData();
		my $session = $theApp->getSession();

		my $name = $self->getValue('name');

		if ($theApp->{data}->{_submitted} eq $self->{panelName}) 
		{
			if ($data->{$name})
			{
				$session->{$name} = $data->{$name};
				$returnValue =  $data->{$name};
			}
			else
			{
				delete $session->{$name};
				$returnValue = "";
			}
		}
		elsif ($session->{$name})
		{
			$returnValue = $session->{$name};
		}
	}

	return $returnValue;
	print STDERR $returnValue;
}

sub setChecked
{
	my $self = shift;

	return ($self->{params}->{checked} = 1);
}

sub getChecked
{
	my $self = shift;
	
	return $self->{params}->{checked};
}


1;
__END__

=head1 NAME

SW::GUIElement::CheckBox - swCheckBox Form Element

=head1 SYNOPSIS

  use SW::GUIElement::CheckBox;

  my $CheckBox = new SW::GUIElement::CheckBox($app, { -ref=>'CheckBoxName',
                                                      -value=>'Value',
                                                      -text=>'Accompanying Text',
                                                      -checked=>'1',
                                                } );
  $panel->addElement($textarea);

=head1 DESCRIPTION

  Smart Worker TextArea object

=head1 METHODS

  new ($Application, { hash of properties });           preferred
  new ($Application, ref, value, text, checked);

  render -  Called by swBaseRenderer
  getValue([param_name]) -  without argument returns target, otherwise 
                                returns the parameter named param_name
  setValue([param_name],value) -  without argument sets target to value, 
                                otherwise sets named parameter to value

 

=head1 PROPERTIES

  ref => Name reference of check box
  value => value if the check box
  text => text description to accompany the check box
  checked => 1 or 0

=head1 AUTHOR

Scott Wilson    scott@hbe.ca
Jan 17/99

=head1 REVISION HISTORY

  $Log: CheckBox.pm,v $
  Revision 1.14  1999/11/15 18:17:33  gozer
  Added Liscence on pm files

  Revision 1.13  1999/10/01 16:02:33  krapht
  Removed TreeView, and the bless line in each GUIElement, which was useless
  anyways!

  Revision 1.12  1999/09/01 21:38:40  krapht
  Changed ref to name, target to signal for internal links!

  Revision 1.11  1999/09/01 01:26:50  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.10  1999/08/30 19:50:10  krapht
  Removed the use Exporter lines and associated code (@EXPORT, etc.)

  Revision 1.9  1999/06/17 21:46:30  krapht
  Code cleanup

  Revision 1.8  1999/05/20 13:51:49  scott
  Changes for the new transaction model
    Changed around the package and compnent internal naming scheme

  Revision 1.7  1999/04/13 16:35:13  scott
  Fixed session state retrieval

  Revision 1.6  1999/03/29 20:49:41  scott
  rendering tweaks...

  Revision 1.5  1999/02/18 10:42:50  scott
  New GUIElement components - LinkExternal, ListBox, SelectBox, TextBox, RadioButtonSet


=head1 SEE ALSO

perl(1).

=cut

