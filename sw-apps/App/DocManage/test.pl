#!/usr/bin/perl -w

use SDF;

my $sdf = SDF::get_test_sdf;

print SDF::convert($sdf);


