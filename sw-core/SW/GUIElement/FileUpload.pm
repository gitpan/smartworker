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

package SW::GUIElement::FileUpload;

#------------------------------------------------------------
# SW::GUIElement::FileUpload
# File upload form element
#------------------------------------------------------------
# $Id: FileUpload.pm
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

	shift; # theApp, caught in the base class

	$self->{renderCallback} = "renderFileUpload";

	if (! $self->{hc}) { 
		$self->{params}->{name} = shift;
		$self->{params}->{size} = shift;
		$self->{params}->{maxlen} = shift;
	}

	return $self;
}

sub render
{
	my ($self, $renderer) = @_;
	my $renderCall = $self->{renderCallback};
	$renderer->${renderCall}($self );
}


1;

__END__

=head1 NAME

SW::GUIElement::FileUpload - File upload input type element

=head1 SYNOPSIS

  use SW::GUIElement::FileUpload;

  my $file = new SW::GUIElement::FileUpload($Application, {
							-name=>'name',
							-size=>'size',
							-maxlen=>'maxlen'
							});

  $panel->addElement($file);

=head1 DESCRIPTION

	Smartworker file upload input type.  This widget can be used to select files on the
	local machine and upload them to the server as part of a form.  Note that Internet
	Explorer 3 does not display the Browse button next to the text input box, and the 
	problem is corrected with Beta 2.

=head1 METHODS

  new ($Application, {hash of values for parameters});

  setValue('prop','value') - sets the value of property to 'value'.

=head1 PROPERTIES

  name - the name of the input field
  size - the size of the text input field on the screen.  This has nothing to do with
         the length of the filename.  It is only for displaying purposes
  maxlen - the maximum length of the filename (including path)

=head1 TODO

  add a property for the mime-types that can be accepted, but this property is often
  ignored by browsers, so not urgent

=head1 AUTHOR

Jean-Francois Brousseau (krapht@hbe.ca)
June 1999
Renamed (though not much revised) by John F. Zmrotchek (zed@hbe.ca)
August 1999

=head1 REVISION HISTORY

$Log: FileUpload.pm,v $
Revision 1.5  1999/11/15 18:17:33  gozer
Added Liscence on pm files

Revision 1.4  1999/10/01 16:02:33  krapht
Removed TreeView, and the bless line in each GUIElement, which was useless
anyways!

Revision 1.3  1999/09/10 16:17:22  jzmrotchek
Bugfix.

Revision 1.2  1999/09/09 19:13:06  krapht
Removed the Autoloader stuff in there!

Revision 1.1  1999/08/31 18:22:41  jzmrotchek
Took JF's module and renamed it more in keeping with the model we're
using.  Not a whole lot else.


=head1 SEE ALSO

perl(1).

=cut
