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

package SW::Data::Document;

#------------------------------------------------------------
# SW::Data::Document
# This abstracts the document class from the programmer.
# All major applications that have the concept of
# "Document" need to use or subclass this class
#------------------------------------------------------------
# $Id: Document.pm,v 1.9 1999/11/15 18:17:33 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::Data;


@ISA = qw(SW::Data);

$VERSION = '0.01';

my %icons = ();


#------------------------------------------------------------
# new
#------------------------------------------------------------

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);

	return $self;
}


#------------------------------------------------------------
# getIcon - function
#
# getIcon looks for the path of an icon related to a
# document type (passed as argument) in the %icons hash and
# returns the path.
#
# Returns a path to an icon, or undef if the icon doesn't
# exist.
#------------------------------------------------------------

sub getIcon
{
	my $doctype = $_[0];

	if(exists($icons{$_[0]}))
	{
		return $icons{$_[0]};
	}

	return undef;
}


1;

__END__

=head1 NAME

SW::Data::Document - SmartWorker Document class

=head1 SYNOPSIS

	use SW::Data::Document;

	my $document = new SW::Data::Document();

	or

	my $document = new SW::Data::Document($app,$doc);

=head1 DESCRIPTION

This either creates a new document in the database or loads an existing one if
the existing one is specified.

=head1 AUTHOR

Kyle Dawkins, kyle@hbe.ca

=head1 SEE ALSO

perl(1).

=cut
