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

package Register::Text;

#------------------------------------------------------------
# Register::Text
#------------------------------------------------------------
# $Id: Text.pm,v 1.2 1999/09/07 16:23:31 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use SW::Language;

@ISA = qw(SW::Language Exporter AutoLoader);
@EXPORT = qw(

);

sub new
{
	my $className = shift;

	my $self = 	$className->SUPER::new(@_);

	bless $self, $className;

	$self->{STRING_TABLE} = {
		"ENTER" => {
				"en" => "Enter your email address:",
				"fr" => "Entrez votre adresse &eacute;lectronique:",       
				"ch" => "Chow yun fat",
				},

		"THANK YOU" => {
				"en" => <<EOE
Thank you for registering with SmartWorker.<br>
Your password has been randomly generated and email to you.
EOE
,				"fr" => <<EOF
Merci pour vous &ecirc;tre enregistr&eacute; avec SmartWorker.  Votre mot de<br>
passe vous a &eacute;t&eacute; envoy&eacute;.     
EOF
,
				"ch" => <<EOC
Tsing tao sake chop suey yatakata nskjn as
EOC
,
				},
		"SUBMIT" => {
				"en" => "Sign me up!",
				"fr" => "Allons-y gaiement et tous en choeur!",
				"ch" => "hajshjhsh",
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

SW::App::FillIn - Fill In

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 PARAMETERS

=head1 AUTHOR

=head1 REVISION HISTORY

$Log: Text.pm,v $
Revision 1.2  1999/09/07 16:23:31  gozer
Fixed pod syntax errors


=head1 SEE ALSO

perl(1).

=cut


