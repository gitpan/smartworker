#!/usr/bin/perl

#===================================================================#
#
# generateData.pl v0.1
# Temporary vCard generator that doesn't follow the specs at all :)
#
# Author: Frederic Hurtubise (fred@hbe.ca)
# July 1999
#
#===================================================================#

my (@letters) = (a..z, A..Z);   
my (@numbers) = (0..9);

use strict;

srand(time() ^ ($$ + ($$ <<15)) );

chdir ("/usr/local/apache/dev/fhurtubi/smartworker/apps/ContactManager");
                         
my $maxCards = $ARGV[1] || (int(rand(26)) + 5);

my $self;

open (FILE, ">$ARGV[0]-list.txt") || &erreur ("$!");
for (my $CID = 1; $CID <= $maxCards; $CID++)
{
	$self->{vCard}->{$CID}->{lastName} = &genRandStr(\@letters, 8);
	$self->{vCard}->{$CID}->{firstName} = &genRandStr(\@letters, 5);
	$self->{vCard}->{$CID}->{email}->{primary} = &genRandStr(\@letters, 8)."\@".&genRandStr(\@letters, 8).".".&genRandStr(\@letters, 3);
	$self->{vCard}->{$CID}->{company} = &genRandStr(\@letters, 8);
	$self->{vCard}->{$CID}->{title} = &genRandStr(\@letters, 8);
	$self->{vCard}->{$CID}->{adress}->{home}->{street} = &genRandStr(\@numbers, 4).", ".&genRandStr(\@letters, 8);
	$self->{vCard}->{$CID}->{adress}->{home}->{city} = &genRandStr(\@letters, 8);
	$self->{vCard}->{$CID}->{adress}->{home}->{province} = &genRandStr(\@letters, 8);
	$self->{vCard}->{$CID}->{adress}->{home}->{zip} = &genRandStr(\@numbers, 5);
	$self->{vCard}->{$CID}->{phone}->{home} = "(".&genRandStr(\@numbers, 3).") ".&genRandStr(\@numbers, 3)."-".&genRandStr(\@numbers, 4);
	$self->{vCard}->{$CID}->{adress}->{work}->{street} = &genRandStr(\@numbers, 4).", ".&genRandStr(\@letters, 8);
	$self->{vCard}->{$CID}->{adress}->{work}->{city} = &genRandStr(\@letters, 8);
	$self->{vCard}->{$CID}->{adress}->{work}->{province} = &genRandStr(\@letters, 8);
	$self->{vCard}->{$CID}->{adressde}->{work}->{zip} = &genRandStr(\@numbers, 5);
	$self->{vCard}->{$CID}->{phone}->{work} = "(".&genRandStr(\@numbers, 3).") ".&genRandStr(\@numbers, 3)."-".&genRandStr(\@numbers, 4);
	$self->{vCard}->{$CID}->{phone}->{pager} = "(".&genRandStr(\@numbers, 3).") ".&genRandStr(\@numbers, 3)."-".&genRandStr(\@numbers, 4);
	$self->{vCard}->{$CID}->{phone}->{cellular} = "(".&genRandStr(\@numbers, 3).") ".&genRandStr(\@numbers, 3)."-".&genRandStr(\@numbers, 4);

	my @printArray = (
		${CID},
		$self->{vCard}->{$CID}->{lastName},
		$self->{vCard}->{$CID}->{firstName},
		$self->{vCard}->{$CID}->{email}->{primary},
		$self->{vCard}->{$CID}->{company},
		$self->{vCard}->{$CID}->{title},
		$self->{vCard}->{$CID}->{adress}->{home}->{street},
		$self->{vCard}->{$CID}->{adress}->{home}->{city},
		$self->{vCard}->{$CID}->{adress}->{home}->{province},
		$self->{vCard}->{$CID}->{adress}->{home}->{zip},
		$self->{vCard}->{$CID}->{phone}->{home},
		$self->{vCard}->{$CID}->{adress}->{work}->{street},
		$self->{vCard}->{$CID}->{adress}->{work}->{city},
		$self->{vCard}->{$CID}->{adress}->{work}->{province},
		$self->{vCard}->{$CID}->{adressde}->{work}->{zip},
		$self->{vCard}->{$CID}->{phone}->{work},
		$self->{vCard}->{$CID}->{phone}->{pager},
		$self->{vCard}->{$CID}->{phone}->{cellular},
	);

	print FILE join ("::", @printArray)."\n";
}
close (FILE);          

1;

sub erreur
{
	my $msg_erreur = shift;

	open (FILE, ">erreur.fred");
	print FILE "$msg_erreur\n";
	close (FILE);

	exit;
}

sub genRandStr
{
	my $arrayRef = shift;
	my $nbChars = shift || 5;
	my $string;
         
	for (my $x = 0; $x < $nbChars; $x++)
	{
		$string .= @$arrayRef[int(rand(@$arrayRef))];
	}
                
	return ($string);
}

