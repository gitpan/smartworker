#!/usr/bin/perl;

opendir(THIS,".");

while ($x = readdir(THIS)) {
    if (!(($x eq ".") || ( $x eq "..") || ($x =~ "capper"))) {
	$firstletter = substr($x,0,1);
	$firstletter =~ tr/[a-z]/[A-Z/;
	$rest = substr($x,1);
	$y = $firstletter . $rest;
	print $x . " = " . $y . "\n";
	#`mv $x $y`;
	`cp Class.pm $x`
    }
}
