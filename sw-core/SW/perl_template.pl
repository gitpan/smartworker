package SW::Something::MyModule;


#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::Something::MyModule
#  Description of my module
#------------------------------------------------------------
#  CVS ID tag...
# $Id: perl_template.pl,v 1.5 1999/09/01 01:26:46 krapht Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);

use SW::Application;

@ISA = qw(SW::Application);

$VERSION = '0.01';


#------------------------------------------------------------
#  new
#------------------------------------------------------------

sub new
{
   my $classname = shift;

   my $self = $classname->SUPER::new(@_); 

   bless ($self, $classname);
	
   return $self;
}

#------------------------------------------------------------
#  some_other_function
#
#     brief description of function if not immediately obvious
#------------------------------------------------------------

sub some_other_function
{
	my $self = shift;

	return $something;
}

1;

__END__

=head1 NAME

SW::Something::MyModule - one line description of the module 

=head1 SYNOPSIS

   Give a simple example of the module's use

=head1 DESCRIPTION


=head1 METHODS

  new -  Creates a new instance
  some_other_function - ([param_name],value) -  detailed description of the use each function

=head1 PARAMETERS

	# well known parameters for this object, normally passed into the contruction as a hash, 
	# or gotten and set using the getValue() and setValue() calls.

  text - 
  image - 

=head1 AUTHOR

Scott Wilson
HBE	scott@hbe.ca
Jan 12/99

=head1 REVISION HISTORY

  $Log: perl_template.pl,v $
  Revision 1.5  1999/09/01 01:26:46  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.4  1999/08/17 05:22:34  scott
  changed comments

  Revision 1.3  1999/07/14 21:46:03  fhurtubi
  *** empty log message ***


  Revision 1.2  1999/06/18 15:27:18  scott
  Work on User is for some changes to the database layout ....

  Master and Registry are for the new debugging


=head1 SEE ALSO

perl(1).

=cut
