package SW::Something::MyModule;
# or
package MySWApp;


#------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for internal use only!!
#    for information contact smartworker@hbe.ca
#------------------------------------------------------------
# SW::Something::MyModule
#  Description of my module
#------------------------------------------------------------
#  CVS ID tag...
# $Id: perl_template.pl,v 1.1 1999/09/02 19:53:55 gozer Exp $
#------------------------------------------------------------

use strict;
use vars qw($VERSION @ISA);
use SW::Application;

@ISA = qw(SW::Application AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.01';


# Preloaded methods go here.

# new takes no args or a Link String
sub new
{
   my $classname = shift;

   my $self = $classname->SUPER::new(@_); 
	# or
	my $self = {};

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

1;    # All perl module must return true at the completion of loading
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
  Revision 1.1  1999/09/02 19:53:55  gozer
  New Namespace

  Revision 1.2  1999/08/18 21:25:59  jzmrotchek
  Cleaned up some code in the event_set() and event() methods of vCalendar.pm

  Revision 1.1  1999/06/11 19:24:00  scott
  new file
   

=head1 SEE ALSO

perl(1).

=cut
