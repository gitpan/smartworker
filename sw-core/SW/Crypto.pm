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

package SW::Crypto;

#------------------------------------------------------------
# SmartWorker - HBE Software, Montreal, Canada
# for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::Crypto
#
# Module dealing with cryptography in SmartWorker.  This
# module provides an interface to encryption algorithms
# and useful functions.
#
# WARNING : Before commiting any changes to this module,
#           make sure your code is good.  Having a security
#           problem in a security module is not ideal : (
#------------------------------------------------------------
# $Id: Crypto.pm,v 1.4 1999/11/15 18:17:32 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);


#------------------------------------------
# Algorithm implementation classes
#------------------------------------------

#use SW::Crypto::Blowfish;  # commented out because it doesn't compile!!!!!!!!!!!
#use SW::Crypto::3DES;   # Gotta work on that one


@ISA = qw();

$VERSION = '0.01';



#------------------------------------------------------------
# endian types
#------------------------------------------------------------
 
sub LITTLE() { 0x01; }
sub BIG() { 0x02; }
sub UNKNOWN() { 0x04; }


#------------------------------------------------------------
# new
#
# Creates a new instance of SW::Crypto and returns a
# reference to the object.
#------------------------------------------------------------

sub new
{
	my $classname = shift;
	my $algo;
	my $keysize;

	if(@_)
	{
		$algo = shift;
		$keysize = shift;
	}

	my $self = {
		algo		=> $algo,
		keysize	=> $keysize,
	};

	bless($self, $classname);

	# Do some initialization

	$self->_getEndian();

	return $self;
}


#------------------------------------------------------------
# getAlgo
#
# Returns a string describing the current algorithm used for
# encryption, undef if no algorithm has been specified.
#------------------------------------------------------------

sub getAlgo
{
	return (shift)->{algo};
}


#------------------------------------------------------------
# setAlgo
#
# Sets the current algorithm to the parameter string.
#
# Returns a string describing the algorithm, or undef if the
# algorithm is not available.
#
# NOTE: When changing the value of the algorithm, a new
#       engine is automatically reloaded.
#------------------------------------------------------------

sub setAlgo
{
	my $self = shift;
	my $algo = shift;

	$self->{algo} = $algo;

	# Reload the engine accordingly to the new algorithm
	$self->_loadEngine();

	return $self->{algo};
}


#------------------------------------------------------------
# getAvailableAlgos
#
# Returns an array containing the algorithms available.
#------------------------------------------------------------

sub getAvailableAlgos
{
	my $self = shift;



}


#------------------------------------------------------------
# getKeysize
#
# Returns the current keysize.
#------------------------------------------------------------

sub getKeysize
{
	return (shift)->{keysize};
}


#------------------------------------------------------------
# setKeysize
#
# Sets the key size to the value passed as argument.
#
# Returns the new keysize.
#------------------------------------------------------------

sub setKeysize
{
	my $self = shift;
	my $newsize = shift;

	if($newsize)
	{
		$self->{keysize} = $newsize;
	}

	return $self->{keysize};
}


#------------------------------------------------------------
# encrypt
#
# If no engine is present, takes care of loading one.
#
# Encrypts the string passed as first argument using the key
# provided as the second argument.
#
# Returns the encrypted string, or undef if there was a
# problem.
#------------------------------------------------------------

sub encrypt
{
	my $self = shift;
	my $plaintext = shift;
	my $key = shift;

	# If the engine is not loaded yet, load it

	if(!$self->{_engine})
	{
		if(!$self->_loadEngine())
		{
			return;
		}
	}

	if(!$key)
	{
		return;
	}

	return ($self->{_engine}->_crypt($plaintext,$key));
}


#------------------------------------------------------------
# decrypt
#
# If no engine is present, takes care of loading one.
#
# Decrypts the string passed as first argument using the key
# provided as the second argument.
#
# Returns the decrypted string, or undef if there was a
# problem.
#------------------------------------------------------------

sub decrypt
{
	my $self = shift;
	my $ciphertext = shift;
	my $key = shift;

	# If the engine is not loaded yet, load it

	if(!$self->{_engine})
	{
		if(!$self->_loadEngine())
		{
			return;
		}
	}

	if(!$key)
	{
		print STDERR "In SW::Crypto --> no key provided in decrypt\n";
		return;
	}

	return ($self->{_engine}->_decrypt($ciphertext,$key));
}


#------------------------------------------------------------
# _loadEngine
#
# INTERNAL USE ONLY
#
# This function takes care of loading the appropriate
# encryption engine, based on the value of the algorithm and
# provided by the algo classes.
#
# It creates a new object from the specified algorithm class.
#------------------------------------------------------------

sub _loadEngine
{
	my $self = shift;

	if(!$self->{algo})
	{
		return;
	}

	my $class = 'SW::Crypto::' . $self->{algo};

	print STDERR "Request to load a new crypto engine from module $class\n";

	$self->{_engine} = $class->new($self->{algo},$self->{keysize});

	if(!$self->{_engine})
	{
		print STDERR "In SW::Crypto --> error in loading crypto engine of type " . $self->{algo} . "\n";
		return;
	}

	return 1;
}


#------------------------------------------------------------
# _getEndian
#
# INTERNAL USE ONLY
#
# Looks up the system type and sets the endian accordingly.
#------------------------------------------------------------

sub _getEndian
{
	my $self = shift;

	my $sys = `uname -a`;

	if(($sys =~ /alpha/) || ($sys =~ /i\d86/))
	{
		# We found an Alpha or an Intel CPU

		print STDERR "In SW::Crypto --> found a little-endian machine\n";

		$self->{endian} = LITTLE;
	}
	elsif(($sys =~ /sparc/) || ($sys =~ /motorola/))
	{
		$self->{endian} = BIG;
	}
	else
	{
		# What the hell is that system?
		$self->{endian} = UNKNOWN;
	}

	return $self->{endian};
}


1;

__END__


=head1 SYNOPSIS

use SW::Crypto;

my $crypto = new SW::Crypto($user,$algorithm,$keysize);

my $encrypted_data = $crypto->encrypt($data,$key);



=head1 DESCRIPTION

SW::Crypto provides an interface to encryption algoritms, and hides the internals
of the algorithm.  It does NOT do any kind of encryption.  All the dirty job of
encrypting is performed by subclasses (in SW::Crypto).

The module takes care of determining the endian type of the machine (necessary for certain
algorithms), loading the appropriate encryption engine, depending on the algorithm requested.


Engines

The engine is the cryptographic functions provided by the algorithm modules.  An engine is
mainly defined by a set of two functions : _crypt and _decrypt.  These two methods must be
present in the module implementing the algorithm, or Crypto will die.

What Crypto does with these engines is create a new instance of the class corresponding to
the algorithm requested.  To reduce overhead, this engine is only loaded if an actual
encryption or decryption request is performed, because some algorithms are very CPU-hungry.


=head1 METHODS

new

Creates a new object of 


getAlgo

Returns a string describing the current algorithm loaded for encryption.

setAlgo

Sets the currently used algorithm to the one passed as an argument.
If the requested algorithm is not available, returns undef.
Otherwise, returns the string describing the new algorithm.



getKeysize

Returns the value of the current keysize used for encryption.


setKeysize

Sets the current keysize to the one passed as a parameter.
Returns the old value.




encrypt

Takes two arguments : a plaintext string to encrypt, and a key
The key must be of length equal to the length specified.
Calls the appropriate function for encryption of the plaintext
string and returns the encrypted result.

decrypt

Takes two arguments : a ciphertext string to decrypt, and a key
Same thing for the key here.
Calls the appropriate function for decryption of the ciphertext
string and returns the decrypted result.



=head1 PARAMETERS

n/a

=head1 REVISION HISTORY

$Log: Crypto.pm,v $
Revision 1.4  1999/11/15 18:17:32  gozer
Added Liscence on pm files

Revision 1.3  1999/09/25 16:30:28  scott
commented out useing blowfish because it's broken

Revision 1.2  1999/09/20 14:30:00  krapht
Changes in most of the files to use the new way of referring to session,
user, etc. (SW->user, SW->session).

Revision 1.1  1999/09/12 12:20:17  krapht
New module that provides an interface to cryptographic algorithms.


=head1 AUTHOR

Jean-Francois Brousseau
krapht@hbe.ca
September 1/99

=head1 SEE ALSO

perl(1)

=cut
