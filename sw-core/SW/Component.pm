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

package SW::Component;

use strict;
use vars qw($VERSION @ISA);

use SW::Util;


@ISA = qw();

$VERSION = '0.01';


sub new
{
	my $swClassName = shift;
	my $app = shift;
	my $self = {
			theApp => $app,
			params => {},
			};

	bless ($self, $swClassName);

	$self->{params}->{visible}=1;

	if (@_)		# more args
	{
		#$self->{theApp}->debug("Arguments to component creation:".SW::Util::flatten(@_));
		my $type = ref($_[0]);	
		if ($type eq "HASH")
		{
			my $args = shift;
			foreach my $name (keys (%$args))
			{
				my $value = $args->{$name};
				$name = _strip($name);
				$self->{params}->{$name} = $value;
#				$self->{theApp}->debug("SW::Component --> Added $name => $value to self");
			}
			$self->{hc} = 1;	# temporary hack - check how the onject was made
		} elsif ($type eq "ARRAY")
		{
		#	$self->debug("SW::Component --> it's a ARRAY - $type");
		} else 	# must be a SCALAR
		{	
		}
	}

	if ($self->{params}->{'ref'})
	{
		$self->{theApp}->addComponent($self, $self->{params}->{'ref'});
	}

	if ($self->getValue('name'))
	{
		$self->{package} = $app->{package}.'::'.$self->getValue('name');
	} else
	{
		$self->{package} = $app->{package}.'::'.($app->{childId})++.'::'.ref($self);
		$self->setValue('name', $self->{package});
	}


	return $self;
}

sub _strip
{
#	my $self = shift;
	my $arg = shift;
	$arg =~ s/^-//;
	return $arg;
}

sub getParams
{
	my $self = shift;
	return keys %{$self->{params}};	
}

sub setParams
{
	my $self = shift;
	my %params = @_;

	foreach my $k (keys %{$self->{params}}) 
	{
		delete $self->{params}->{$k};
	}

	while (my ($k, $v) = each(%params))
	{
		$self->{params}->{_strip($k)} = $v;
	}

}

sub appendParams
{
        my $self = shift;
        my %params = @_;

	while (my ($name, $value) = each(%params))
	{
		$self->{params}->{_strip($name)} = $value;
	}
}

sub getValue
{
	my $self = shift;
	my $name = shift;

	return $self->{params}->{$name};
}

sub setValue
{
	my $self = shift;
	my ($name, $value) = @_;

	$self->{params}->{_strip($name)} = $value;
}
	
sub visible
{
	my $self = shift;

	if (@_) {
		my $value = shift;

		if ($value == 1)
		{
			$self->{params}->{visible} = 1;
		} else
		{
			$self->{params}->{visible} = 0;	
		}
		return  $self->{params}->{visible};
	} else
	{
		if ($self->{params}->{visible} == 1)
		{
			return 1;
		} else
		{
			return undef;
		}
	}
}


sub delete
{
	my $self = shift;
	my $name = shift;

	return delete $self->{params}->{_strip($name)};
}


#-------------------------------------------------------------
#   trickleState('state')  - initiates a call down to all children 
#                               to execute code pertaining to 'state'
#
#	probably won't need this in component, unless we start embedding
#	 apps as parameters to gui components
#-------------------------------------------------------------
sub trickleState
{
        my $self = shift;
        my $state = shift;
        my $noTrickle = undef;

   #    $self->debug("[TrickState] going to $state");

        if ($state eq 'InitApplication')
        {
                $self->swInitApplication(@_);
        }
        elsif ($state eq 'InitInstance')
        {
                $self->swInitInstance(@_);
        }
        elsif ($state eq 'InitTransaction')
        {
                $self->swInitTransaction(@_);
        }
        elsif ($state eq 'PreTreeCallbacks')
        {
                $self->preTreeCallbacks(@_);
        }
        elsif ($state eq 'BuildUI')
        {
                $self->swBuildUI(@_);
		$self->updateState();
		$noTrickle = 'true';
        }
        elsif ($state eq 'PostTreeCallbacks')
        {
                $self->postTreeCallbacks(@_);
		$noTrickle = 'true';
        }
        elsif ($state eq 'SaveState')
        {
                $self->saveState(@_);
        }
        elsif ($state eq 'CleanUp')
        {
                $self->cleanup();
        }


	if (! $noTrickle)
	{

	#	my ($col, $row) = $self->getSize();

	#	for (my $i=0;  $i<$col; $i++)
	#	{
	#		for (my $j=0; $j<$row; $j++) 
	#		{
	#			my $el = $self->{elements}[$i][$j];
	#                        next unless $el;
	#			$el->trickleState($state);
	#		}
	#	}
	}

}


#------------------------------------------------------------
# cleanup
#------------------------------------------------------------

sub cleanup
{
	my $self = shift;

	foreach my $k (keys %$self)
	{
		delete($self->{$k});
	}
}

#------------------------------------------------------------
# debug   deprecated!!
#------------------------------------------------------------

sub debug
{  
   my ($self, $debugString) = @_;
   
   my $found = undef;
   foreach my $d ($self->{theApp}->{master}->{debug})
   {
      if (($d eq ref($self)) || ($d eq "ALL"))
      {
         $found = 1;
         last;
      }
   }
#   $self->{theApp}->reportDebug($debugString) if $found;

}

sub DESTROY
{
	my $self = shift;

	foreach my $k (keys %$self)
	{
		delete ($self->{$k});
	}
}	

sub swInitApplication
{
	return 1;
}

sub swInitInstance
{
        return 1;
}

sub swInitTransaction
{
        return 1;
}

sub preTreeCallbacks
{
        return 1;
}

sub swBuildUI
{
        return 1;
}

sub postTreeCallbacks
{
        return 1;
}

sub saveState
{
        return 1;
}


1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SW::Component - SmartWorker parameter reception logic, parent class to almost
		 everything

=head1 SYNOPSIS

  use SW::Component;

  my $com = new SW::Component($Application, {	-name=>'value',
						-name2=>'value2',
						});

  my @params = $com->getParams();
  $com->setParams(%params_hash);
  $com->appendParams(%params_hash);

  my $val = $com->getValue('name');

  $com->setValue('name', 'value');

  $com->delete('name');



=head1 DESCRIPTION

  Used to receive parameters into the hash of developer defined parameters. 
  Also provides a destructor that sends a debug message for tracking the death
  of objects in the tree.


=head1 PROPERTIES

	bgColor - default panel background for this element

	fgColor - default foreground color if applicable for this element 

=head1 METHODS

  new - 

  getValue -  one argument 'name'  returns the value of $self->{params}->{name}

  setValue -   args 'name','value'  set the parameter ($self->{params}->{name}) to 
		value

  visible - returns 1 if the element if visible, undef if not.  With an argument (0 or 1) set
		the visibility of the element

=head1 AUTHOR

Scott Wilson	scott@hbe.ca
Feb 9/99

=head1 REVISION HISTORY

  $Log: Component.pm,v $
  Revision 1.24  1999/11/15 18:17:32  gozer
  Added Liscence on pm files

  Revision 1.23  1999/10/10 04:02:48  fhurtubi
  Changed parameter retrieval for getParams and setParams (which aren't used anyways)

  Revision 1.22  1999/09/11 08:44:36  gozer
  Made a whole bunch of little kwirps.
  Fixed Handler to deal correctly with SW_App_Namespace without defaulting to SW::App when the var is set
  Fixed the bug that made Login.pm create an empty hidden argument on every login attempt
  Added a whole bunch of modules preloading in sw-perl-startup, good speed improvment
  Fixed a few warning here and there.  Only one missing the sweep.  Application.pm and AUTOLOAD warning ?!?
  Changed the SW::Util::flatten and circular_flatten to succesfully use Data::Dumper ;-} (-180 lines of code)
  Gone to bed very late

  Revision 1.21  1999/09/01 01:26:46  krapht
  Hahahahha, removed this %#*(!&()*$& autoloader shit!

  Revision 1.20  1999/08/30 20:04:00  krapht
  Removed the Exporter stuff

  Revision 1.19  1999/08/12 14:45:11  fhurtubi
  Little bug correction

  Revision 1.18  1999/07/19 13:29:19  scott
  Lots of clean-up work, debugged and improved the desctructor calling of all
  copmonents so none should be left lingering after the transaction completes.

  This in turn solved the session problem (destructor wasn't being called
  because it was persisting past the end of the transaction)

  Revision 1.17  1999/07/08 15:45:27  scott
  oops - should have done these separately ...

  Working on changes to the database code for users, groups, and objects

  as well as debugging and signals

  Revision 1.16  1999/06/14 20:17:09  scott
  oops - bg fixc

  Revision 1.15  1999/06/14 19:01:04  scott
  changed so we force every component to have a name

  Revision 1.14  1999/06/02 17:10:34  scott
  debugging code

  Revision 1.13  1999/06/01 18:45:29  scott
  fixed the argument assing to receive an hash within

  Revision 1.12  1999/05/20 13:51:40  scott
  Changes for the new transaction model
    Changed around the package and compnent internal naming scheme

  Revision 1.11  1999/05/05 16:06:17  scott
  fixed for panel cell backgrounds

  Revision 1.10  1999/05/04 15:53:20  scott
  -New Apache::Session based database session tracking
  -New debugging scheme

  Revision 1.9  1999/04/20 05:01:29  kiwi
  Changed some basic stuff to do with colors and themes

  Revision 1.8  1999/04/13 16:33:29  scott
  added trickleState method - all classes that don't re-implement it inherit it
  from Component.  trickleState is fairly benign in Component - doesn't pass on
  many calls.  Update state should possibly be rewritten to take advantage of
  trickle state rather than doing the nested calls itself.

  Revision 1.7  1999/02/22 00:52:58  scott
  1)  added a $object->visible() method to enable hiding objects
  2)  created TreeView
  3)  implemented an easier, more flexible callback system to facilitate
  	callbacks calling other callbacks and better control over which
  	level of objects get the callbacks.  Also allows argument passing
  	to the callback.

  Revision 1.6  1999/02/17 22:50:12  kiwi
  Fixed some ref problems, added line in constructor to add component to
  app's list

  Revision 1.3  1999/02/12 00:04:21  scott
  *** empty log message ***

  Revision 1.2  1999/02/11 18:58:13  scott
  changed debug lines

  Revision 1.1.1.1  1999/02/10 19:49:10  kiwi
  SmartWorker

  Revision 1.2  1999/02/10 00:02:10  scott
  trivial - changed debug code

  Revision 1.1  1999/02/09 23:52:29  scott
  New Module,  base class to all gui elements and panels (so far)

  Manages the developers' adding parameters for their display code as hashes or lists of vars,

  Also provides a top level debug message in the DESTROY() function


=head1 SEE ALSO

perl(1).

=cut
