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

package SW::Language;

#------------------------------------------------------------
# SW::Language
# Language and string table class
#------------------------------------------------------------
# $Id: Language.pm,v 1.9 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::Util;


@ISA = qw();

$VERSION = '0.01';


sub new
{
	my $className = shift;
	my $default = shift;

	my $self = { default => $default };

	bless $self, $className;

	return $self;
}


sub getString
{
	my $self = shift;
	my $token = shift;
	my $language = shift;

	my $st;
	my $txt;

	if ($st = $self->{STRING_TABLE})
	{
		if ($st->{$token})
		{
			if ($txt = $st->{$token}->{$language})
			{
				return $txt;
			}
			else
			{
				return $st->{$token}->{$self->getDefault()};
			}
		}
		else
		{
			return "Token $token not found";
		}
	}
	
	return SW::Util::flatten($self);
}

#------------------------------------------------------------
# getCode
#------------------------------------------------------------

sub getCode
{
	my $lang = shift || "en"; # default this to en
	my $app = shift;

	foreach my $k (keys %SW::Config::Languages)
	{ 
		foreach my $j (@{$SW::Config::Languages{$k}})
		{
			if ($j eq $lang)
			{
				return $k;
			}
		}
	}

	#------------------------------------------------------------
	# This is a HACK:
	#------------------------------------------------------------

	return 'en';
}

#------------------------------------------------------------
# setDefault
#------------------------------------------------------------

sub setDefault
{
	my $self = shift;
	my $def = shift;

	$self->{default} = $def;
}

#------------------------------------------------------------
# getDefault
#------------------------------------------------------------

sub getDefault
{
	my $self = shift;

	return $self->{default};
}

1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::Language - SW Class for hndling multiple languages

=head1 SYNOPSIS

  use SW::Language;

  ...

  $stringTable = ThisApp::Text->new("en");

=head1 DESCRIPTION

SW::Language class represents a stringtable setup that makes it easy to
provide multilingual versions of applications.  Every app built using
the SW framework should use a stringtable like this to avoid hardcoding
text into applications.

The class is designed to encapsulate all strings that would be required
by an app. The general way to create a stringtable for an app is:

  1) create adirectory with the same name as the app's package, say
     "MyApp"
  2) create a class within that directory called "Text.pm" that
     contains the stringtable.
  3) within your app, "use" this file, then create an instance of it
     attached to your app from within the InitApplication callback.
     You pass in the default language as an argument.
  4) access strings by their token, and select which language as follows:

     my $str = $self->{stringTable}->getString("SUBMIT", "fr");

	  will return the correct string identified by the token "SUBMIT"
	  in French.

Some notes.  It might be better to import the stringtable into the namespace
of the app so you can access it much faster: getString("SUBMIT", "fr") is way easier
to type.

=head1 AUTHOR

Kyle "One-arm" Dawkins, kyle@hbe.ca

=head1 SEE ALSO

perl(1).

=cut
