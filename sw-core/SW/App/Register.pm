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

package SW::App::Register;

#------------------------------------------------------------
# Register
#  Basic Registration App
#------------------------------------------------------------
# $Id: Register.pm,v 1.4 1999/11/15 18:17:28 gozer Exp $
#------------------------------------------------------------


use strict;
use vars qw($VERSION @ISA);

use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;
use SW::Data;
use SW::Data::Document;
use SW::Util;
use SW::DB;

# Load the stringtables

use SW::App::Register::Text;

@ISA = qw(SW::Application);

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	bless ($self, $classname);

 	my $cb = sub { $self->swRegister(@_) };
 	$self->registerCallback("swRegister", $cb);

 	$self->{stringTable} = Register::Text->new("en");
	$self->{language} = $self->getLanguage();

	return $self;
}

sub swValidateUser
{
	my $self = shift;

	return 0 if ($self->{user}->{user} ne "guest");
	return 1;
}

sub swBuildUI
{
	my $self = shift;
	my $abort = shift;

	my $mainPanel = $self->getPanel();

	# set up the main screen

	if ($self->{regOk})
	{
		my $titlePanel = new SW::Panel::HTMLPanel($self, 
											{ "-name" => "Regsitration",
											  "-background" => "desktop.png"
											 });

		$titlePanel->addElement(0, 0, new SW::GUIElement::Text($self,
										$self->{stringTable}->getString("THANK YOU", $self->{language})
										));

		if ($mainPanel->{renderer}->{Style} =~ /DHTML/)
		{
			$titlePanel->addElement(0, 1, new SW::GUIElement::Text($self,
										"<input type=button onClick='window.close()' value='OK'>"
										));
		}
		else
		{
			$titlePanel->addElement(0, 1, new SW::GUIElement::Link($self,
										{ -target => '/perl/Demo1.pm',
										  -text => 'OK',
										 }
										));
		}

		$mainPanel->addElement(0, 0, $titlePanel);
	}
	else
	{
		my $formPanel = new SW::Panel::FormPanel($self,
									{ "-name" =>"RegisterPanel",
										"-target" => "swRegister",
									});
		
		$formPanel->addElement(0, 0, new SW::GUIElement::TextBox($self, 
									{	"-ref" => "email",
										"-name" => "email",
										"-width" => 30,
									}));
		$formPanel->addElement(0, 1, new SW::GUIElement::Button($self,
									{	"-target" => "swRegister",
										"-text" => 
												$self->{stringTable}->getString("SUBMIT",
														$self->{language}),
										"-type" => "submit",
										"-preBuild" => 1,
									}));

		my $titlePanel = new SW::Panel::HTMLPanel($self);

		if ($self->{regError})
		{
			$titlePanel->addElement(0, 0, new SW::GUIElement::Text($self,
										$self->{regError},
										"White", "Black"));
			$titlePanel->addElement(0, 1, new SW::GUIElement::Text($self,
										$self->{stringTable}->getString("ENTER", $self->{language})
										));

		}
		else
		{
			$titlePanel->addElement(0, 0, new SW::GUIElement::Text($self,
										$self->{stringTable}->getString("ENTER", $self->{language})
										));
		}

		$mainPanel->addElement(0, 0, $titlePanel);
		$mainPanel->addElement(0, 1, $formPanel);
	}
} #  end of draw sub

#------------------------------------------------------------
# swTranslate
#------------------------------------------------------------

sub swRegister
{
	my $self = shift;

	my $email = $self->getDataValue('Register::email');

	if (SW::User::isUnique($self, $email))
	{
		# It's an OK address	

		my $dbh = $self->getDbh();
		
		# Create the home object

		my $home = new SW::Data($self);

		if ($home)
		{
			# Create the user

			my $profile = {
								"preferences" => {
									"system" => {
													"Full Name" => "",
													"Email Address" => $email,
													"Font" => "Verdana",
													"Font Size" => "Medium",
													"Background Colour" => "#200020",
													"Foreground Colour" => "#ffffff",
													"Screen Size" => "1024x768",
													"Language" => "en",
													},
												},
								};


			my $query = SW::Util::buildQuery("INSERT", "users",
											"user", $dbh->quote($email),
											"password", $dbh->quote("turnip"),
											"groups", $dbh->quote("[]"),
											"profile", $dbh->quote(SW::Util::flatten($profile)),
											"home", $dbh->quote($home->{uid}),
											"objects", $dbh->quote("[".$home->{uid}."]"),
											"quota", $dbh->quote("128"),
											"ocount", $dbh->quote("1"),
											"level", $dbh->quote("0"),
											);

			my $sth = $dbh->prepare($query);

			if ($sth->execute)
			{
				# Update the home object

				$home->{creator} = $email;
				$home->{title} = "Home";
				$home->{access} = { "users" => {
															"r" => [$email],
															"w" => [$email],
															},
											"groups" => {
															"r" => [],
															"w" => [],
															},
										};

				$home->{dirty} = 1;

				# send email

				SW::Util::sendMail($email, "SmartWorker Registration <registration\@smartworker.com>", <<EOM
Congratulations on registering with SmartWorker!  You can now log on
to the system using your email address as your login and the word
"turnip" as your password.  We hope to see you soon!
EOM
);
				$self->{regOk} = 1;
			}
			else
			{
				$self->{regError} = "Unable to create new user.";
			}
		}
		else
		{
			$self->{regError} = "Couldn't create workspace object.";
		}
	}
	else
	{
		$self->{regError} = "A user exists already with that email address.";
	}
}

#------------------------------------------------------------
# return true
#------------------------------------------------------------
1;
__END__

=head1 NAME

SW::Application - Main framework class for SmartWorker applications

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Kyle Dawkins, kyle@hbe.ca

=head1 SEE ALSO

perl(1).

=head1 REVISION HISTORY

  $Log: Register.pm,v $
  Revision 1.4  1999/11/15 18:17:28  gozer
  Added Liscence on pm files

  Revision 1.3  1999/09/20 14:30:08  krapht
  Changes in most of the files to use the new way of referring to session,
  user, etc. (SW->user, SW->session).

  Revision 1.2  1999/09/07 16:23:17  gozer
  Fixed pod syntax errors

  Revision 1.1  1999/09/02 20:11:05  gozer
  New namespace convention

  Revision 1.1  1999/04/21 06:12:51  kiwi
  A couple of basic apps

  Revision 1.2  1999/04/17 21:30:11  kiwi
  Fixed up Browse to use document names, fixed View to correctly display
  document info.

  Revision 1.1  1999/04/16 18:09:14  kiwi
  Basic app components

  Revision 1.2  1999/04/13 21:57:31  kiwi
  Changed it to use stringtables.

  Revision 1.1  1999/04/13 16:40:05  scott
  Test applications altered to work in the new Master / Application model



=cut


