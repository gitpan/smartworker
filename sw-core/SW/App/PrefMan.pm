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

package SW::App::PrefMan;

#----------------------------------------------------------------------------------------------
#   SmartWorker - HBE Software, Montreal, Canada
#    for information contact smartworker@hbe.ca
#----------------------------------------------------------------------------------------------
# SW::App::Prefman
#  This module is what I refer to as an "app plugin".  With 
#  the inclusion of some extra code in any app, the set of
#  methods in this module become accessable, which will allow
#  the addition of preference manipulation (at the level of
#  user specific preferences both for the user and for any
#  instances of the user's apps).
#
#  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#  !!! N.B.  This is NOT an app unto itself.   !!!
#  !!!      Do NOT attempt to call it alone!!  !!!
#  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#----------------------------------------------------------------------------------------------
#  CVS ID tag...
# $Id: PrefMan.pm,v 1.24 1999/11/15 18:17:28 gozer Exp $
#----------------------------------------------------------------------------------------------
#Scrapped old docs.
#
#New ones coming.
#----------------------------------------------------------------------------------------

use strict;

use Exporter;
use vars qw( @ISA @EXPORT_OK $VERSION );
@ISA = ('Exporter');
@EXPORT_OK = ('swBuildPrefUI','saveAppPrefs','getAppPref','saveUserPrefs','getUserPref','changePassword');

$VERSION = '0.50';



sub swBuildPrefUI {
#--------------------------------------------------------------------------------
# Called instead of the normal UI builder when the preferences editor is invoked.
# Builds two forms that allow editing of user and application preferences.
#--------------------------------------------------------------------------------
    my $self   = shift;

    $self->{Language} = new Apache::Language($self);
    

#my $app_id = 	$self->{app}->APP_ID();
my $app_id = $self->{params}->{name};
#    my $app_id = $self->{appid};
    
    my $font_family = "arial,helvetica";


    my $mainPanel = $self->getPanel();
    $mainPanel->setValue("bgColor","ffffcc");
    $mainPanel->setValue("width", "100%");

    $mainPanel->addElement(0,0,new SW::GUIElement::Text($self,{-text      => $self->{Language}{PreferencesEditor},
							       -align     => "center",
							       -fontSize  => "+2",
							       -font      => $font_family,
							       -textColor => "white",
							       -bgColor   => "3333CC",
							   }));
    #---------------------------#
    # App prefs panel code here #
    #---------------------------#
    my $appPrefPanel = new SW::Panel::FormPanel($self,{-name        => 'AppPrefSelector',
						       -padding => '5',
						       -align       => 'center',
						       -border      => '1',
						       -width       => '90%',
						   });

    my $app_form_pos = 0;
    $appPrefPanel->addElement(0,($app_form_pos),new SW::GUIElement::Button($self,{-name    => "SaveAppPrefs",
										  -text    => $self->{Language}{SavePrefs},
										  -signal => "saveAppPrefs",
										  -align   => "center",
										  -bgColor => "goldenrod",
										  -font    => $font_family,
									      }));

    $app_form_pos++;
    $appPrefPanel->addElement(0,$app_form_pos,new SW::GUIElement::Text($self,{-text     => $self->{Language}{Preference},
									      -align    => 'Center',
									      -font     => $font_family,
								      }));
    $appPrefPanel->addElement(1,$app_form_pos,new SW::GUIElement::Text($self,{-text     => $self->{Language}{Value},
									      -align    => 'Center',
									      -font     => $font_family,
								      }));
    $appPrefPanel->addElement(2,$app_form_pos,new SW::GUIElement::Text($self,{-text     => $self->{Language}{Default},
									      -align    => 'Center',
									      -font     => $font_family,
								      }));

    $app_form_pos++;

    my $prefattrs;
    foreach (@{$self->{defaults}}) {
	my $currpref;
	if (SW->user->pref->getAppPref($app_id,$_->[0]) ne "") {
		$currpref = SW->user->pref->getAppPref($app_id, $_->[0]);
	} elsif (ref $_ eq "ARRAY") {
		$currpref = $_->[2];
	} else {
		$currpref = $_->[3];
	}


	my $inputText    = new SW::GUIElement::Text($self,{ -text   => $_->[0],
							    -align  => 'center',
							    -valign => 'center',
							    -font     => $font_family,
							});
#	my $inputElement = new SW::GUIElement::TextBox($self,{ -name   => $_->[0],
#							       -text   => $currpref,
#							       -valign => 'center',
#							       -width  => '20',
#							   });
#	my $inputDefault = new SW::GUIElement::Text($self,{ -align   => 'center',
#							    -text   => $_->[2],
#							    -valign => 'center',
#							    -font     => $font_family,
#							   });
	
	my $inputElement;
	my $inputDefault;

	if ($_->[1] eq "TEXT") {
	    $inputElement = new SW::GUIElement::TextBox($self,{ -name   => $_->[0],
								-text   => $currpref,
								-valign => 'center',
								-width  => '20',
							    });

	    $inputDefault = new SW::GUIElement::Text($self,{ -align   => 'center',
							    -text   => " " . $_->[2] . " ",
							    -valign => 'center',
							    -font     => $font_family,
							   });
	

	} else {
	    $inputElement = new SW::GUIElement::SelectBox($self, { -name=> $_->[0],
                                                         -options=> $_->[2],
                                                         -selected=> $_->[3],
                                                         });

	    $inputDefault = new SW::GUIElement::Text($self,{ -align   => 'center',
							    -text   => " " . $_->[3] . " ",
							    -valign => 'center',
							    -font     => $font_family,
							   });
	}

	$appPrefPanel->addElement(0,$app_form_pos,$inputText);
	$appPrefPanel->addElement(1,$app_form_pos,$inputElement);
	$appPrefPanel->addElement(2,$app_form_pos,$inputDefault);

	$prefattrs .= $_->[0] . "|";	
	
	$app_form_pos++;
    }
    
    $prefattrs =~ s/\|$//;
    my $caller = caller();
    SW->session->setPrivateValueOnBehalfOf($caller,'prefattrs',$prefattrs);

	
    #-----------------------#
    # User prefs panel code #
    #-----------------------#
    my $userPrefList = [
			['Name','TEXT',''],
			['Phone Number','TEXT',''],
			['Address','TEXT',''],
			['City','TEXT',''],
			['State or Province','TEXT',''],
			['Country','TEXT',''],
			['Zip Code','TEXT',''],
			['Lang','SELECT', {'en' => 'English' ,'fr' => 'French', 'zh' => 'Chinese'}],
			['Logout','SELECT',[1,5,10,15,20,30,60], 30 ],
		
			];


    my $userPrefPanel = new SW::Panel::FormPanel($self,{-name        => 'UserPrefSelector',
							-padding     => '5',
							-align       => 'center',
							-border      => '1',
							-width       => '90%',
						    });

    my $user_form_pos = 0;

    $userPrefPanel->addElement(0,$user_form_pos,new SW::GUIElement::Button($self,{-name     => 'SaveUserPrefs',
										  -text     => $self->{Language}{SaveUserPrefs},
										  -signal   => 'saveUserPrefs',
										  -align    => 'center',
										  -font     => $font_family,
										  -bgColor  => 'goldenrod',
									      }));

    $user_form_pos++;


    $userPrefPanel->addElement(0,$user_form_pos,new SW::GUIElement::Text($self,{-text     => $self->{Language}{Preference},
										-align    => 'Center',
										-font     => $font_family,
									    }));
    $userPrefPanel->addElement(1,$user_form_pos,new SW::GUIElement::Text($self,{-text     => $self->{Language}{Value},
										-align    => 'Center',
										-font     => $font_family,
									    }));
    $userPrefPanel->addElement(2,$user_form_pos,new SW::GUIElement::Text($self,{-text     => $self->{Language}{Default},
										-align    => 'Center',
										-font     => $font_family,
									    }));

    $user_form_pos++;

    foreach (@{$userPrefList}) {
	my $currpref;
	my $token = $_->[0];
	
	if (SW->user->pref->getUserPref($token) ne '') {
	    $currpref = SW->user->pref->getUserPref($token);
	} else {

	    if ($_->[1] eq "TEXT") {
		$currpref = $_->[2];
	    } elsif ($_->[1] eq "SELECT") {
		$currpref = $_->[3];;
	    } else {
		$currpref = "";
	    }
	}

	my $inputText    = new SW::GUIElement::Text($self,{ -text   => $self->{Language}{"$_->[0]"},
							    -align  => 'center',
							    -valign => 'center',
							    -font     => $font_family,
							});
	my $inputElement;
	my $inputDefault;

	if ($_->[1] eq "TEXT") {
	    $inputElement = new SW::GUIElement::TextBox($self,{ -name   => $_->[0],
								-text   => $currpref,
								-valign => 'center',
								-width  => '20',
							    });

	    $inputDefault = new SW::GUIElement::Text($self,{ -align   => 'center',
							     -text   => " " . $_->[2] . " ",
							     -valign => 'center',
							     -font     => $font_family,
							 });
	    
	    
	} else {
		my @sortValues;

		if (ref $_->[2] eq "ARRAY") { 
			@sortValues = ("-options", $_->[2]);
		} elsif (ref $_->[2] eq "HASH") {
			@sortValues = ("-optval", $_->[2]);
		}

	    $inputElement = new SW::GUIElement::SelectBox($self, { -name=> $_->[0],
							@sortValues,
                                                         -selected=> $currpref,
                                                         });

	    $inputDefault = new SW::GUIElement::Text($self,{ -align   => 'center',
							    -text   => " " . $currpref . " ",
							    -valign => 'center',
							    -font     => $font_family,
							   });
	}

	$userPrefPanel->addElement(0,$user_form_pos,$inputText);
	$userPrefPanel->addElement(1,$user_form_pos,$inputElement);
	$userPrefPanel->addElement(2,$user_form_pos,$inputDefault);

	$user_form_pos++;

	SW->master->deleteDataValue('appState');
}
    



    #---------------------------------#
    # Password change panel code here #
    #---------------------------------#
    my $passwordPanel = new SW::Panel::FormPanel($self,{-name    => 'PasswordSelector',
							-padding => '5',
							-align   => 'center',
							-border  => '1',
							-width   => '90%',
						   });
    

    $passwordPanel->addElement(0,0,new SW::GUIElement::Button($self,{-name     => 'ChangePassword',
								     -text     => $self->{Language}{"Change Password"},
								     -signal   => 'changePassword',
								     -align    => 'center',
								     -font     => $font_family,
								     -bgColor  => 'goldenrod',
								 }));

    my $oldPassText  = new SW::GUIElement::Text($self,{ -text    => $self->{Language}{"Old Password"},
							-font    => $font_family,
						    });
    my $oldPassInput = new SW::GUIElement::PasswordField($self,{ -name => 'OldPassword', });

    my $newPass1Text  = new SW::GUIElement::Text($self,{ -text    => $self->{Language}{"New Password"},
							 -font     => $font_family,
						     });
    my $newPass1Input = new SW::GUIElement::PasswordField($self,{ -name => 'NewPassword1', });

    my $newPass2Text  = new SW::GUIElement::Text($self,{ -text    => $self->{Language}{"Confirm New Password"},
							 -font     => $font_family});
    my $newPass2Input = new SW::GUIElement::PasswordField($self,{ -name => 'NewPassword2', });

    $passwordPanel->addElement(0,1,$oldPassText);
    $passwordPanel->addElement(1,1,$oldPassInput);
    
    $passwordPanel->addElement(0,2,$newPass1Text);
    $passwordPanel->addElement(1,2,$newPass1Input);

    $passwordPanel->addElement(0,3,$newPass2Text);
    $passwordPanel->addElement(1,3,$newPass2Input);
							 

    #---------------------------------#
    # Put the whole package together. #
    #---------------------------------#
    $mainPanel->addElement(0,1,new SW::GUIElement::Text($self,{-text     => $self->{Language}{"User Preferences"},
							       -fontSize => '+1',
							       -align    => 'center',
							       -font     => $font_family,
							       -valign   => 'bottom',
							   }));
    


    $mainPanel->addElement(2,1,new SW::GUIElement::Text($self,{-text     => $self->{Language}{"Application Preferences"},
							       -fontSize => '+1',
							       -align    => 'center',
							       -font     => $font_family,
							       -valign   => 'bottom',
							   }));


    $mainPanel->addElement(0,2,$userPrefPanel);
    $mainPanel->addElement(1,2,$appPrefPanel);


    my $passpos;
    if ($user_form_pos > $app_form_pos) {
	$passpos = 1;
    } else {
	$passpos = 0;
    }

    $mainPanel->addElement($passpos,4,new SW::GUIElement::Text($self,{-text     => $self->{Language}{"ChangePassword"},
								      -fontSize => '+1',
								      -align    => 'center',
								      -font     => $font_family,
								      -valign   => 'bottom',
								  }));

    $mainPanel->addElement($passpos,5,$passwordPanel);

#    $mainPanel->addElement(0,6,new SW::GUIElement::HorizontalRule($self,{}));
#    $mainPanel->addElement(1,6,new SW::GUIElement::HorizontalRule($self,{}));

    return 0;
}

sub saveAppPrefs {
#---------------------------
# Does exactly what it says.
#---------------------------
    my $self = shift;
 
    my $appid = $self->{params}->{name};
    my $caller = caller();
    my @prefattrs = split(/\|/,SW->session->getPrivateValueOnBehalfOf($caller,'prefattrs'));

    foreach (@prefattrs) {
	SW->user->pref->setAppPref($appid,$_,$self->getDataValue($_));
    }

	SW->user->{_dirty} = 1;
 
    return 1;
}


sub getAppPref {
#---------------------------------------------------------------------------
# Gets the preference from user preferences is such is defined, and from the 
# internal app defaults if not.
#---------------------------------------------------------------------------
    my $self   = shift;
    my $app_id = shift; 
    my $pref   = shift;

    my $prefValue;

    if (SW->user->pref->getAppPref($app_id,$pref) ne '') {
	# Return the user-set value for that preference.
	$prefValue = SW->user->pref->getAppPref($app_id,$pref);
    } else {
	# Return default value for that preference.
	my $default_index = 0;
	foreach (@{$self->{defaults}}) {
	    if ($_->[0] eq $pref) {
		$prefValue = $_->[2];
		last;
	    } else {
		$default_index++;
	    }
	}
    }
    return $prefValue;
}

sub saveUserPrefs {

    my $self = shift;
    my $caller = caller();
    
    my @prefattrs = ('Name','Phone Number','Address','City','State/Province','Country','Zip Code','Lang','Logout');

    foreach (@prefattrs) {
	#print STDERR "Handling preference $_ ...\n";
	SW->user->pref->setUserPref($_ ,$self->getDataValue($_));
	SW->user->{_dirty} = 1;
    }

    return 1;
}


sub getUserPref {
    my $self   = shift;
    my $pref   = shift;

    if (SW->user->pref->getUserPref($pref) ne '') {
	# Return the user-set value for that preference.
	return SW->user->pref->getUserPref($pref);
    } else {
	# Return default value for that preference.
	return $SW::Config::UserPrefs[$SW::Config::UserPrefIndex{$pref}]->[2];
    }
}

sub changePassword {
#------------------------------------
# Processes password change requests
#------------------------------------
    my $self           = shift;

    my $caller         = caller();
    my $old_password   = $self->getDataValue("OldPassword");
    my $new_password_1 = $self->getDataValue("NewPassword1");
    my $new_password_2 = $self->getDataValue("NewPassword2");

	if ($new_password_1 eq $new_password_2) 
		{
		if(SW->user->authenticate->set($old_password, $new_password_1))
			{
			SW->session->setPrivateValueOnBehalfOf($caller,'prefManPasswordError','');
			}
		else 
			{
			SW->session->setPrivateValueOnBehalfOf($caller,'prefattrs',"The old password you entered didn't seem to be correct.  Please re-enter it?");
			}
		}
		
	else 
		{
	    # Redisplay prefman page with error message
	    SW->session->setPrivateValueOnBehalfOf($caller,
						   'prefManPasswordError',
						   "The passwords you entered didn't match.  Please try again.");	    
		}
	
return 1;
}

1;


__END__

=head1 NAME

SW::App::PrefMan - SW User/App Preference Manager "plugin"

=head1 SYNOPSIS

    Setting up/calling the Preference Manager is beyond the scope of a basic synopsis,
    and is covered below in the Description section.

    Getting preferences:

    $bgColor = $self->getAppPref(APP_ID(),'bgcolor'))
    $name    = $self->getUserPref('name');


=head1 DESCRIPTION

Docs scrapped due to code rewrite.   New ones coming soon...

Importing module:

    use SW::App::PrefMan('swBuildPrefUI','saveAppPrefs','getAppPref');

Setting up preflist/defaults:

    # In the new() method, add this...
    $self->{defaults} = [
    ['width','TEXT',10],
    ['height','TEXT','5'],
    ['bgcolor','SELECT',['black','red','blue']
    ];

To retrieve a preference:

    # To get an application-specific preference...
    SW->user->pref->getAppPref(APP_ID(), "height");

    # To get a user-specific preference...
    SW->user->pref->getUserPref("name");

To set up a call to the Preference Manager plugin applet...

    $layoutPanel->addElement(0, $row++, new SW::GUIElement::Link ($self, {
	-text   => "Prefs editor",
	-signal => "swBuildPrefUI",
    }));


=head1 METHODS

    getAppPref($app_id,$prefname)  Gets the $prefname app preference for the app whose name is $app_id
    getUserPref($prefname)         Gets the $prefname user preference for the current user

    (For the rest, see Description above...)

=head1 AUTHOR

John F. Zmrotchek
HBE	zed@hbe.ca
September 19/1999

=head1 REVISION HISTORY

  $Log: PrefMan.pm,v $
  Revision 1.24  1999/11/15 18:17:28  gozer
  Added Liscence on pm files

  Revision 1.23  1999/11/12 22:02:12  jzmrotchek
  Added Apache::Language support.  Note that this requires the Text.pm file in SW/App/PrefMan to be present as well.

  Revision 1.22  1999/11/12 18:06:41  jzmrotchek
  Cosmetic changes.  Makes the interface more OD::Registrar-like, without extending it beyond SW-ness.

  Revision 1.21  1999/10/29 21:58:55  gozer
  Fixed logout duration in preferences

  Revision 1.20  1999/10/25 21:44:03  fhurtubi
  Added some fonts, corrected some bugs with the select option,
  and hacked the language value (I cant understand why Lang always have an empty value)

  Revision 1.19  1999/10/03 18:39:31  scott
  added a line in to delete appState after it's used

  Revision 1.18  1999/09/28 16:29:37  gozer
  Changed a bit more authentication to have password changing/checking thru swauthd

  Revision 1.17  1999/09/27 15:15:45  fhurtubi
  Added a new argument (default) to the selectbox options

  Revision 1.16  1999/09/24 19:36:27  jzmrotchek
  Bugfix to getAppPref.

  Revision 1.15  1999/09/24 17:21:04  jzmrotchek
  Changed a few little bits in getAppPref that weren't getting the default properly.
  Will probably not work with SELECT style default menu, needs work.

  Revision 1.14  1999/09/23 19:53:09  jzmrotchek
  Added ability to define select-box prefs.   This is for you, Fred.

  Revision 1.13  1999/09/23 17:39:38  jzmrotchek
  Changed a few references to App prefs instead of User prefs in various user pref methods.

  Revision 1.12  1999/09/23 04:52:30  gozer
  Modified to include the new PasswordReminder

  Revision 1.11  1999/09/23 01:50:21  jzmrotchek
  PrefMan working (with skeletal docs on use) up to and almost including password change.

  Revision 1.10  1999/09/22 23:27:50  jzmrotchek
  User prefs now up and running.   Make sure your use SW::App::PrefMan imports the proper methods.

  Revision 1.9  1999/09/22 19:33:59  fhurtubi
  Added a couple of return values and made this compatible with the dispatcher usage

  Revision 1.8  1999/09/21 03:48:05  jzmrotchek
  Bug fixes to bring it inline with the update Session, User and so on model.  (Thanks Gozer!)

  Of course, this makes the docs completely wrecked...  This will be fixed.

  Revision 1.7  1999/09/20 21:19:49  jzmrotchek
  Bugtest version

  Revision 1.6  1999/09/20 16:43:32  jzmrotchek
  It's broken.   It was broken when I came in today, and I'm not sure why.   I'm on it, though.

  Don't use until you see a comment here that says it works.

  Revision 1.5  1999/09/20 02:17:04  jzmrotchek
  A bit of tweaking; some weirdness experienced after CVS update.  Still tracking down the cause.

  Revision 1.4  1999/09/20 00:25:37  jzmrotchek
  Minor tweaks to the code.  Expect more to follow.

  Revision 1.3  1999/09/20 00:08:19  jzmrotchek
  Oops again.  Made reference to old name of package in the docs.  Fixed now.

  Revision 1.2  1999/09/19 22:41:40  jzmrotchek
  Oh yeah...

  Forgot the docs on putting a button to trigger the PrefMan menu page.  Now it's there.
  Feel free to experiment; it's the signal that's the important part.

  Revision 1.1  1999/09/19 22:26:39  jzmrotchek
  First version of the Preference Manager app "plugin".   Feel free to use and abuse it; right now, it only deals with app based preferences, but once we've gotten a fixed list of user preferences, we'll be adding a form to deal with those as well.

  Comments, criticisms, change requests, and showers of adulation all accepted with varying degrees of welcome.


=head1 SEE ALSO

perl(1).

=cut








