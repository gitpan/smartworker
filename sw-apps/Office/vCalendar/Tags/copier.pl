#!/usr/bin/perl;

opendir(THIS,".");

while ($x = readdir(THIS)) {
    if (
	!(
	  ($x eq ".") || ( $x eq "..") || ($x =~ "capper") || ($x =~ "Created") || ($x =~ "copier")
	 )
	) {
	#`mv $x $y`;
	`cp Created.pm $x`;
    }
}
