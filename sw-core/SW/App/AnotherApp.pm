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

#!/usr/bin/perl -I/usr/local/apache/dev/v1

package SW::App::AnotherApp;

use strict;
use vars qw($VERSION @ISA);

use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;

@ISA = qw(SW::Application);


sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	bless ($self, $classname);
	return $self;
}

sub swInitApplication
{
	my $self = shift;
	
	my $leftPanel = new SW::Panel::FormPanel($self, "MainPanel" );

	my $text2 = new SW::GUIElement::Text($self, {	-text=>"<H2>Here is another app ...</H2><BR><BR><H3>Still with state</H3>", });

        my $link_plain = new SW::GUIElement::Link($self, { -target=>"/perl/MyApp.pm",
                                                           -text=>"Back again",
                                                        } );



	$leftPanel->addElement(0,0, $text2);
	$leftPanel->addElement(0,1, $link_plain);

	my $mainPanel = $self->getPanel();

	$mainPanel->addElement(0, 0, $leftPanel);

} #  end of draw sub

#------------------------------------------------------------
#  Test of a callback function
#------------------------------------------------------------

1;
__END__

=head1 NAME

SW::AnotherApp - Another Application

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

=head1 SEE ALSO

perl(1).

=head1 REVISION HISTORY

  $Log: AnotherApp.pm,v $
  Revision 1.3  1999/11/15 18:17:26  gozer
  Added Liscence on pm files

  Revision 1.2  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors


=cut
