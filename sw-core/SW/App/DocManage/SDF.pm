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


package SDF;

use strict;

sub get_test_sdf
{
	my @test = <<'EOF';
!init OPT_STYLE="paper"

# Define variables
!define DOC_NAME     "Mod Perl @ HBE"
!define DOC_AUTHOR   "Scott Wilson ({{EMAIL:scott@hbe.ca}}), Developer"
!define DOC_URL      "http://terrans.hardboiledegg.com/network/mod_perl.html"

# Build the title
!build_title

!block abstract
A brief overview of how mod_perl works, it's advantages, disadvantages, and
some standard practices I'd like us to adopt for developing in mod_perl.
!endblock

H1: Website Layout Recommendations


EOF

  return \@test;

}

sub convert
{
  my $input = shift;
  my $fname = "/tmp/".time.".sdf";

  open (OUTFILE, "> $fname") || die "Couldn't open $fname for writing: @!";
  foreach (@$input)
  {
		print OUTFILE;
  }
  close OUTFILE;

	my $html =  `/usr/bin/sdf -2html_ -o- $fname`;
  
	unlink($fname) ? print STDERR "deleted $fname\n\n" :
		print STDERR "couldn't unlink $fname\n\n";

	return $html;

}

1;

__END__

=head1 NAME

SW::App::DocManage::SDF - SDF

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 PARAMETERS

=head1 AUTHOR

=head1 REVISION HISTORY

$Log: SDF.pm,v $
Revision 1.3  1999/11/15 18:17:32  gozer
Added Liscence on pm files

Revision 1.2  1999/09/07 16:23:20  gozer
Fixed pod syntax errors


=head1 SEE ALSO

perl(1).

=cut



	
