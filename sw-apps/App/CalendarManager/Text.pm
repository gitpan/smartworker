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

package SW::App::CalendarManager::Text;

#------------------------------------------------------------
# Calendar::Text
#------------------------------------------------------------
# $Id: Text.pm,v 1.2 1999/09/07 16:23:18 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::Language;

@ISA = qw(SW::Language );

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	bless $self, $classname;

	$self->{STRING_TABLE} = {
		"menuWelcome" => {
				"en" => "Welcome",
				"fr" => "Bienvenue",
				},
		"optionGo" => {
				"en" => "Go",
				"fr" => "Go",
				},
		"optionSave" => {
				"en" => "Save",
				"fr" => "Sauvegarder",
				},
		"optionCancel" => {
				"en" => "Cancel",
				"fr" => "Annuler",
				},
	};

	return $self;
};

#------------------------------------------------------------
# return true
#------------------------------------------------------------
1;

__END__

=head1 NAME

SW::App::CalendarManager::Text - Text

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 PARAMETERS

=head1 AUTHOR

=head1 REVISION HISTORY

=head1 SEE ALSO

perl(1).

=cut
