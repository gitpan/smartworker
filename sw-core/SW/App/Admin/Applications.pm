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

#!/usr/bin/perl -w

#------------------------------------------------------------
#  SW::App::Admin::Applications
#
#  admin tool to set up applications and their associated data types
#
#  $Id: Applications.pm,v 1.15 1999/11/15 18:17:32 gozer Exp $
#------------------------------------------------------------
package SW::App::Admin::Applications;

use strict;
use SW::Util::Prep;
use SW::Application;
use Data::Dumper;

use vars qw(@ISA $SW_FN_TABLE);

@ISA = qw(SW::Application);

sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);

	$self->buildTable;
	return $self;
}

sub dispatcher
#SW TransOrder 15
{
	my $self = shift;
	
	if (! SW->session->getPrivateValue('appstate'))
	{
		$self->buildMainUI;
	}
	else
	{
		my $state = SW->session->getPrivateValue('appstate');
		$self->$state();
	}
}

sub buildMainUI
{
	my $self = shift;

	my $p = $self->getPanel();
	$p->setValue('textColor', "000000");
	$p->setValue('bgColor', "FFFFFF");
	$p->addElement(0,0,$self->getTitlePanel("Application info editor"));

   my $al = $self->getAppListPanel();

	my $fp = new SW::Panel::FormPanel($self);
	$fp->addElement(0,10,new SW::GUIElement::Button($self,{-text=>"Add a New Application", -signal => "AddNewApp", }));
	$fp->addElement(1,10,new SW::GUIElement::Button($self,{-text=>"Add a Data Type", -signal => "AddDataType", }));

	$p->addElement(0,1,$al);
	$p->addElement(0,2,$fp);


	$p->updateState();
}	

sub buildAccessUI
{
   my $self = shift;
   
   my $p = $self->getPanel();
	$p->setValue('textColor', "FFFFFF");
	$p->addElement(0,0,$self->getTitlePanel("Application access control editor"));
   
   my $al = $self->getAccessListPanel();
   
   my $fp = new SW::Panel::FormPanel($self);
   $fp->addElement(0,10,new SW::GUIElement::Button($self,{-text=>"Add a New Rule", -signal => "AddNewRule", }));
	$fp->addElement(1,10,new SW::GUIElement::Button($self, { -text=>"Cancel", -signal=>'cancelApp', }));
   
   $p->addElement(0,1,$al);
   $p->addElement(0,2,$fp);
	
   $p->addElement(0,3, $self->RuleWarnings);
   #$p->updateState();
   
  
}

sub buildRuleEditUI
{
   my $self = shift;	
	my $row = {};
   my ($action , $target  , $groupid , $uid  ,$appname);
	
   
   
   my $aid = SW->session->getPrivateValue("AppEditorID");
	
	
   if (! $self->{newRule})
	{
      $action = $self->getDataValue('rule_action');
      $target = $self->getDataValue('rule_target');
      $groupid = $self->getDataValue('rule_groupid');
      $uid  = $self->getDataValue('rule_uid');  
	}
   
   my $p = new SW::Panel::FormPanel($self, { -name=>"editPanel"});
   
   #ALLOW/DENY
   
      $p->addElement(0,0, new SW::GUIElement::SelectBox($self, {
                           -name       => 'action',
                           -options    => ['ALLOW','DENY'],
                           -values     => ['ALLOW','DENY'],
                           -selected   => $action,
                           }));

   #USER?GROUP?ANY/GUEST
   
      $p->addElement(1,0, new SW::GUIElement::SelectBox($self, {
                           -name       => 'target',
                           -options    => ['GUEST','ANY','GROUP','USER'],
                           -values     => ['GUEST','ANY','GROUP','USER'],
                           -selected   => $target,
                           }));
  
      
#GROUP PICKER      
         {
         my $dbh = SW::DB->getDbh();
         my $sth = $dbh->prepare("select groupid, groupname from groups order by groupname");
         $sth->execute;
         
         my ($ar, $as);
         
         for (my $i=0; my $row = $sth->fetchrow_hashref; $i++)
            {
            push @$ar, $row->{groupid};
            push @$as, $row->{groupname};
            }
         
         $p->addElement(2,0, new SW::GUIElement::SelectBox($self, {
                           -name       => 'groupid',
                           -options    => $as,
                           -values     => $ar,
                           -selected   => $groupid,
                           }));
        
         }
      
#USER PICKER 
         {       
         my $dbh = SW::DB->getDbh();
         my $sth = $dbh->prepare("select uid, username from authentication order by username");
         $sth->execute;
         
         my ($ar, $as);
         
         for (my $i=0; my $row = $sth->fetchrow_hashref; $i++)
            {
            push @$ar, $row->{uid};
            push @$as, $row->{username};
            }
         
         $p->addElement(3,0, new SW::GUIElement::SelectBox($self, {
                           -name       => 'uid',
                           -options    => $as,
                           -values     => $ar,
                           -selected   => $uid,
                           }));
         
         }
   
   
   
   if ($self->{newRule})
	{																
		$p->addElement(0,8,new SW::GUIElement::Button($self, { -text => "Submit",
																			 -signal => "saveNewRule",
																	}));
	} else
	{
		$p->addElement(0,8,new SW::GUIElement::Button($self, { -text => "Submit",
																			 -signal => "saveEditedRule",
																	}));
		$p->addElement(2,8,new SW::GUIElement::Button($self, { -text => "Delete This Rule",
																			 -signal => "deleteRule",
																	}));
	}
	$p->addElement(1,8,new SW::GUIElement::Button($self, { -text=>"Cancel", -signal=>'cancelRuleEdit', -args=> { selected_appid => $aid }}));

   
   
   
   my $mp = $self->getPanel();
   $mp->setValue('textColor', "FFFFFF");
   $mp->addElement(0,0,$self->getTitlePanel("Editing rules for $appname"));
	$mp->addElement(0,1, $p);
	$mp->addElement(0,2, $self->RuleWarnings);
}

sub RuleWarnings {
	my $self = shift;
 my $p = new SW::Panel::FormPanel($self, {
                                                -name   => "RulesWarnings",
																-bgColor => "666666",
 
                                         });
$p->addElement(0,0, new SW::GUIElement::Text($self, { -text => <<"EOF" }));
This is a very important usage information message regarding the new access Authorization process
<BR>
Now, the modules don't have to deal with authorization anymore.  No more swValidateUser.
Now, for every new module you want to be able to acces, you will have to use this application to register
it and set acces restrictions for it.
<BR><P>
Here is how it works, is't DENY/ALLOW, wich means it first try do match an user against the DENY clauses, a match means no acces grantes
and if nothing matched, it tries to match the user against the ALLOW clauses, a match meaning acces granted and if nothing
matched, the acces is denied as a last resort.
<BR><P>
<B>Special types</B>
<P>GUEST matches anybody not authenticated, i.e. DENY GUEST means deny everyone and ALLOW GUEST means no login prompt at all.
<P>ANY means any registered user, i.e. DENY ANY will ask for a passowrd and deny eveeryone, ALLOW ANY will accept anybody that can provide a valid username/password
<PRE>IN those 2 special cases the user and group pull-down menus are ignored.</PRE>
<P>GROUP matches on a per group basis, but right now, there are 2 users registered in 2 groups :-(
<P>USER matches a specific user name
<P>You can add as many rules as you want, but think that they will be evaluated top-down if you look at the list.
Enjoy!

EOF
return $p;
}

sub buildEditUI
{
	my $self = shift;	
	my $row = {};

	if (! $self->{newApp})
	{
		my $aid = $self->getDataValue('selected_appid');

		SW->session->setPrivateValue('AppEditorID', $aid);

		my $dbh = SW::DB->getDbh();
		my $query = "select * from apps where aid=$aid";
		my $sth = $dbh->prepare($query);
		if (! $sth->execute) { SW::debug($self, "error, could not execute query $query",1); return undef; }
		$row = $sth->fetchrow_hashref;
	}

	my $p = new SW::Panel::FormPanel($self, { -name=>"editPanel", });

my $col = 2;

# name	
	$p->addElement(0,$col,new SW::GUIElement::Text($self,"Name"));
	$p->addElement(2,$col++,new SW::GUIElement::TextBox($self,{ -name=>"appname",
																		-text=>"$row->{name}",
																		-width=>'40',
																		}));
# APPID
	$p->addElement(0,$col,new SW::GUIElement::Text($self,"App ID"));
	$p->addElement(2,$col++,new SW::GUIElement::TextBox($self,{ -name=>"appid",
																		-text=>"$row->{appid}",
																		-width=>16,
																		}));
                                                      
# PackageName
   $p->addElement(0,$col,new SW::GUIElement::Text($self, "Package"));
   $p->addElement(2,$col++,new SW::GUIElement::TextBox($self, {  -name => "package",
                                                            -text=>"$row->{package}",
                                                            -width=>40
                                                            }));
                                                      
# Data Types
	$p->addElement(0,$col,new SW::GUIElement::Text($self,"Data Types"));
	my $sel = $self->getDataTypesSelect();
	$sel->setValue('selected',eval($row->{datatypes}));
	$p->addElement(2,$col,$sel);

	$p->addElement(5,$col++,new SW::GUIElement::Button($self,{-text=>"Add a Data Type", -signal => "AddDataType", }));
	

# icon name

	$p->addElement(0,$col,new SW::GUIElement::Text($self,"Icon Name"));
   
	$p->addElement(2,$col++,new SW::GUIElement::TextBox($self,{ -name=>"icon_name",
																		-text=>"$row->{icon_name}",
																		-width=>'40',
																		}));


# Certified?
	$p->addElement(0,$col,new SW::GUIElement::Text($self,"Certified?"));
	my $bs = new SW::GUIElement::RadioButtonSet($self,{ -name=>'certified',
																				 -buttons=>['true','true','false','false'],
																				-orientations=>'horizontal',
																				-checked=>$row->{certified},
																		});
	print STDERR "certified - ".$row->{certified}."\n";
	print STDERR "certified - ".$bs->getValue('checked')."\n";
	
	$p->addElement(2,$col++,$bs);


# Comments
	$p->addElement(0,$col,new SW::GUIElement::Text($self,"Comments"));
	$p->addElement(2,$col++,new SW::GUIElement::TextArea($self,{ -name=>"comment",
																		-text=>"$row->{comment}",
																		-width=>60,
																		-height=>10,
																		}));


	if ($self->{newApp})
	{																
		$p->addElement(0,$col,new SW::GUIElement::Button($self, { -text => "Submit",
																			 -signal => "saveNewApp",
																	}));
	} else
	{
		$p->addElement(0,$col,new SW::GUIElement::Button($self, { -text => "Submit",
																			 -signal => "saveEditedApp",
																	}));
		$p->addElement(2,$col,new SW::GUIElement::Button($self, { -text => "Delete This App",
																			 -signal => "deleteApp",
																	}));
	}
	$p->addElement(1,$col++,new SW::GUIElement::Button($self, { -text=>"Cancel", -signal=>'cancelApp', }));


	
	my $mp = $self->getPanel();
   $mp->setValue('textColor', "FFFFFF");
   $mp->addElement(0,0,$self->getTitlePanel("Editing application ".$row->{name}));
	$mp->addElement(0,1, $p);



#	$mp->updateState();

}

sub drawAddDataType
{
	my $self = shift;

	my $p = new SW::Panel::FormPanel($self);
	
	my $row = 0;
	$p->addElement(0,$row++,new SW::GUIElement::Text($self,"Creating a Data Type"));
	$p->addElement(0,$row,new SW::GUIElement::TextBox($self, { -name=>"NewDataType", -width=>'16', }));
	$p->addElement(1,$row++,new SW::GUIElement::CheckBox($self, { -name=>"Hidden", -value=>"true", -text=>"Hidden?", }));

# Icon URI
   $p->addElement(0,$row,new SW::GUIElement::Text($self, "Icon URI"));
   $p->addElement(1,$row++,new SW::GUIElement::TextBox($self, {  -name => "iconuri",
                                                            -width=>40
                                                            }));
# dataype table
   $p->addElement(0,$row,new SW::GUIElement::Text($self, "Table"));
   $p->addElement(1,$row++,new SW::GUIElement::TextBox($self, {  -name => "tbl",
                                                            -width=>40
                                                            }));

# type package name
   $p->addElement(0,$row,new SW::GUIElement::Text($self, "Package name"));
   $p->addElement(1,$row++,new SW::GUIElement::TextBox($self, {  -name => "pkg",
                                                            -width=>40
                                                            }));
	$p->addElement(0,$row,new SW::GUIElement::Button($self, { -text=>"Save", -signal=>'saveNewDataType', }));
	$p->addElement(1,$row++,new SW::GUIElement::Button($self, { -text=>"Cancel", -signal=>'cancelApp', }));

	$self->getPanel()->addElement(0,0,$p);
	$self->getPanel()->setValue('bgcolor','FFFFFF');
}

sub getDataTypesSelect
{
	my $self = shift;

	my $values;
	my $texts;

   my $dbh = SW::DB->getDbh();
   my $query = "select * from datatypes";
   my $sth = $dbh->prepare($query);
	$sth->execute();

	while (my $row  = $sth->fetchrow_hashref)
	{
		print STDERR "Added ".$row->{datatype}."\n";
		push (@{$self->{dtvalues}}, $row->{datatype});
	}
	return new SW::GUIElement::SelectBox($self, {
															-name => "datatypes",
															-options => $self->{dtvalues},
															-values => $self->{dtvalues},
															-multiple  => 1,
															-size => 20,
															});
}


sub getAccessListPanel
{
   my $self = shift;
	my $aid;
	
   if($aid = $self->getDataValue('selected_appid'))
		{
		SW->session->setPrivateValue('AppEditorID', $aid);
		}
	else
		{
		$aid = SW->session->getPrivateValue('AppEditorID');
		}	
	
	
   my $dbh = SW::DB->getDbh();
   my $query = qq/SELECT action, target, username, ap.uid, ap.aid, groupname, g.groupid from appaccess ap 
                  LEFT JOIN authentication au ON ap.uid=au.uid 
                  LEFT JOIN groups g ON ap.groupid=g.groupid 
                  WHERE ap.aid='$aid'
                  ORDER by action, target/;
   
   my $sth = $dbh->prepare($query);
   
   if (! $sth->execute) { SW::debug($self, "error, could not execute query $query",1); return undef; }
	
   my $p = new SW::Panel::FormPanel($self, {
                                                -name   => "AccessListPanel",
                                                -border => 1,
                                                -padding => 2,
                                          });
   my $i;
   for ($i=0; my $row = $sth->fetchrow_hashref; $i++)
      {
      my $text = "$row->{action} $row->{target}"; 
      $p->addElement(0,$i, new SW::GUIElement::Link($self, { -text=>"Delete", -signal=>'deleteRule', -args => {
                                                                                                               rule_action => $row->{"action"},
                                                                                                               rule_target => $row->{"target"},
                                                                                                               rule_groupid => $row->{"groupid"},
                                                                                                               rule_uid => $row->{"uid"},
                                                                                                               
                                                                                                                }}));
      $p->addElement(1,$i, new SW::GUIElement::Text($self, { -text=>$text, }));
		if ($row->{target} eq "USER" || $row->{target} eq "GROUP")
			{
			$p->addElement(2,$i, new SW::GUIElement::Text($self, { -text=>$row->{groupname} || $row->{username} || "&nbsp;", }));
			}
		
      
      }
		
		
	$p->addElement(0,0, new SW::GUIElement::Text($self, {-text => "No access policies currently defined" })) unless $i;
   return $p;
   
}

sub getAppListPanel
{
	my $self = shift;

	my $dbh = SW::DB->getDbh();

	my $query = "select * from apps where package !='SW::App::Admin::Applications'";
	my $sth = $dbh->prepare($query);

	if (! $sth->execute)   { SW::debug($self, "couldn't execute query $query",1); return undef; }

	my $p = new SW::Panel::FormPanel($self, "AppListPanel");
	my $i;
	for ($i=0; my $row = $sth->fetchrow_hashref; $i++)
	{
		my $certified; 
		if ($row->{'certified'} eq 'true')
		{ 
			$certified = "Certified";
		} else
		{  
			$certified = "Un-Certified";
		}
		my $col = 0;

		my $image_url = $OD::Config::ICON_URI."/".$row->{icon_name}.$OD::Config::ICON_SMALL_EXT;

		$p->addElement($col++,$i, new SW::GUIElement::Image($self, { -url=>$image_url }));
		$p->addElement($col++,$i, new SW::GUIElement::Link($self, { -text=>$row->{appid}, -signal=>'EditApp',  -args => { selected_appid => $row->{'aid'}, }    }));
		$p->addElement($col++,$i, new SW::GUIElement::Text($self, { -text=>$row->{name},  }));
		$p->addElement($col++,$i, new SW::GUIElement::Text($self, { -text=>$certified, }));
		$p->addElement($col++,$i, new SW::GUIElement::Link($self, { -text=> "Acces list", -signal=>'EditAccess', -args => { selected_appid => $row->{'aid'}, }  }));
      $p->addElement($col++,$i, new SW::GUIElement::Text($self, { -text=>$row->{comments}, }));
	}

	return $p;

}	

#------------------------------------------------------------------#
#------------------------------------------------------------------#
sub getTitlePanel
{
   my $self = shift;
   my $title = shift;

   my $userName = SW->user->getName();

   # The header panel
        my $titlePanel = new SW::Panel::FormPanel($self, {
                -bgColor        => "000000",
                -name           => "titlePanel",
      -align      => "center",
      -height     => "1% ",
        });

   # The app title and welcome message to the current user
        $titlePanel->addElement(0,0, new SW::GUIElement::Text($self, {
                -text           => "$title  - ",  
      -fontSize   => 5,
      -textColor  => "c0c0c0",
      -attrib     => "bold",
        }));
   $titlePanel->addElement(3,0, new SW::GUIElement::Text($self, {
                -text           => $userName,
      -attrib     => "ital",
      -attrib     => "bold",
      -align      => "center",
      -textColor  => "ffffff",
      -fontSize   => "+1",
      -grow_x     => "false",
         }));

	SW::debug($self,"Completed build of Title Panel",5);

   return ($titlePanel);
}

sub  editApp
#SW Callback EditApp 10
{
	my $self = shift;

	SW->session->setPrivateValue('appstate',"buildEditUI");
}

sub editRule
#SW Callback EditRule 10
{
   my $self = shift;
   
   SW->session->setPrivateValue('appstate','buildRuleEditUI');
}

sub editAccess
#SW Callback EditAccess 10
{
   my $self = shift;
   SW->session->setPrivateValue('appstate','buildAccessUI');
}

sub  addApp
#SW Callback AddNewApp 10
{
	my $self = shift;

	$self->{newApp} = 1;
	SW->session->setPrivateValue('appstate',"buildEditUI");
}

sub addRule
#SW Callback AddNewRule 10
{
   my $self = shift;

	$self->{newRule} = 1;
	SW->session->setPrivateValue('appstate',"buildRuleEditUI");

}

sub cancelRuleEdit
#SW Callback cancelRuleEdit 10
{
   my $self=shift;
   SW->session->setPrivateValue('appstate','buildAccessUI');

}

sub cbCancelEdit
#SW Callback cancelApp 10
{
	my $self = shift;
	SW->session->deletePrivateValue('appstate');
}

sub cbAddDataType
#SW Callback AddDataType  10
{
	my $self = shift;
	SW->session->setPrivateValue('laststate',SW->session->getPrivateValue('appstate'));
	SW->session->setPrivateValue('appstate',"drawAddDataType");
}

sub cbSaveNewDataType
#SW Callback saveNewDataType 10
{
	my $self = shift;
	my $dbh = SW::DB->getDbh();
	my $name = $self->getDataValue('NewDataType');
	my $hidden = $self->getDataValue('Hidden');
	my $iconuri = $self->getDataValue("iconuri");
	my $tbl = $self->getDataValue("tbl");
	my $pkg = $self->getDataValue("pkg");

	my $query = qq/insert into datatypes (datatype, hidden, iconuri, tbl, pkg) 
		values ("$name", "$hidden", "$iconuri", "$tbl", "$pkg")/;
	my $sth=$dbh->prepare($query);
	if ($sth->execute())
	{
		SW::debug($self, "Creation of new data type succeeded",1);
	} else
	{
		SW::debug($self, "Creation of new data type failed - $query - ".$dbh->errstr,1);
	}

	if (SW->session->setPrivateValue('laststate'))
	{
		SW->session->setPrivateValue('appstate',SW->session->setPrivateValue('laststate'));
	} else {
		SW->session->deletePrivateValue('appstate');
	}

}
	
   
sub deleteRule
#SW Callback deleteRule 10
{
   my $self=shift;
	my $aid = SW->session->getPrivateValue("AppEditorID");
	my $action = $self->getDataValue("rule_action");
	my $target = $self->getDataValue("rule_target");
	my $groupid = $self->getDataValue("rule_groupid");
	my $uid = $self->getDataValue("rule_uid");
	
	my $dbh = SW::DB->getDbh();
	
	my $query = qq/DELETE from appaccess WHERE aid="$aid" and action="$action" and target="$target"/;
	if ($groupid)
   	{
   		$query .= qq/ and groupid="$groupid"/;
   	}
	elsif ($uid)
   	{
   		$query .= qq/ and uid="$uid"/;
   	}
	my $sth = $dbh->prepare($query);
	$sth->execute();	
   SW->session->setPrivateValue('appstate','buildAccessUI');
}
   	
sub deleteApp
#SW Callback deleteApp 10
{
	my $self = shift;
	
   my $dbh = SW::DB->getDbh();
   my $aid = SW->session->getPrivateValue('AppEditorID');

	my $query = "delete from apps where aid=$aid";
	my $sth = $dbh->prepare($query);
	$sth->execute();

	my $query = "delete from appaccess where aid=$aid";
	my $sth = $dbh->prepare($query);
	$sth->execute();

	$self->{newApp} = 0;
	SW->session->deletePrivateValue('appstate');
}
	
sub saveNewRule
#SW Callback saveNewRule 10
{
my $self = shift;
my $dbh = SW::DB->getDbh();

my $aid = SW->session->getPrivateValue("AppEditorID");

my $action = $self->getDataValue("action");
my $target = $self->getDataValue("target");
my $groupid=$self->getDataValue("groupid");
my $uid=$self->getDataValue("uid");

my $query = qq/INSERT into appaccess SET aid="$aid", action="$action", target="$target"/;

if ($target eq "GROUP")
   {
   $query .= qq/, groupid="$groupid"/;
   }
elsif ($target eq "USER")
   {
   $query .= qq/, uid="$uid"/;
   }
	
my $sth = $dbh->prepare($query);
$sth->execute() ? SW::debug($self,"Save rule successful",1) : SW::debug($self,"Save failed for rule - $query, ".$dbh->errstr,1);
SW->session->setPrivateValue('appstate', 'buildAccessUI');
}

sub saveEditedRule
#SW Callback saveEditedRule 10
{
my $self = shift;
print STDERR "Entering save edited rule (NOT IMPLEMENTED YET)\n";

SW->session->setPrivateValue('appstate', 'buildAccessUI');
}


sub saveNewApp
#SW Callback saveNewApp 10
{
	my $self = shift;

	my $dbh = SW::DB->getDbh();

	my $appid = $self->getDataValue('appid');
	my $name = $self->getDataValue('appname');
   my $package = $self->getDataValue('package');
	my $datatypes = $dbh->quote(SW::Util::flatten($self->getDataValue('datatypes')));
	my $comments = $self->getDataValue('comment');
	my $cert = $self->getDataValue('certified');
	my $icon = $self->getDataValue('icon_name');


	my $query = qq/insert into apps set appid="$appid", name="$name", package="$package", datatypes=$datatypes, comment="$comments", certified="$cert"/;
	my $sth = $dbh->prepare($query);
	$sth->execute() ? SW::debug($self,"Save successful",1) : SW::debug($self,"Save failed for - $query, ".$dbh->errstr,1);
	$self->{newApp} = 0;
	SW->session->deletePrivateValue('appstate');
}


sub saveApp
#SW Callback saveEditedApp 10
{
	my $self = shift;

	my $dbh = SW::DB->getDbh();

	my $aid = SW->session->getPrivateValue('AppEditorID');

	my $appid = $self->getDataValue('appid');
	my $name = $self->getDataValue('appname');
   my $package = $self->getDataValue('package');
	my $datatypes = $dbh->quote(SW::Util::flatten($self->getDataValue('datatypes')));
	my $comments = $self->getDataValue('comment');
	my $cert = $self->getDataValue('certified');

	my $query = qq/update apps set appid="$appid", name="$name", package="$package", datatypes=$datatypes, comment="$comments", certified="$cert" where aid=$aid/;
	my $sth = $dbh->prepare($query);
	$sth->execute() ? SW::debug($self,"Save successful",1) : SW::debug($self,"Save failed for - $query, ".$dbh->errstr,1);
	SW->session->setPrivateValue('appstate','buildAccessUI');
}





#SW end

1;
__END__

=head1 NAME 

SmartWorker Applications Admin Tool

=head1 SYNOPSIS

Used for setting applications up and associating data types with them.  In the future this will also be used to configure
the access models for applications.

=head1 DESCRIPTION


=head1 METHODS

=head1 PARAMETERS


=head1 AUTHOR

Scott Wilson
HBE   scott@hbe.ca
Sept 6/99

=head1 REVISION HISTORY

  $Log: Applications.pm,v $
  Revision 1.15  1999/11/15 18:17:32  gozer
  Added Liscence on pm files

  Revision 1.14  1999/10/14 04:55:01  scott
  adding icon support

  Revision 1.13  1999/09/30 20:59:57  fhurtubi
  Changed the label of the package name in the add dataype screen

  Revision 1.12  1999/09/28 20:33:24  fhurtubi
  I suck, had a typo :(

  Revision 1.11  1999/09/28 20:31:39  fhurtubi
  Removed appPkg

  Revision 1.10  1999/09/28 20:05:39  fhurtubi
  Fixed Typos

  Revision 1.9  1999/09/28 16:50:10  fhurtubi
  Changed appuri to apppkg

  Revision 1.8  1999/09/22 19:23:18  gozer
  Fixed a stupid logig bug that was allowing you only to modify one application per session :-/

  Revision 1.7  1999/09/22 07:49:50  fhurtubi
  Added info for data types (icon, app URIs)

  Revision 1.6  1999/09/20 21:04:10  gozer
  Removed another $self->{user}

  Revision 1.5  1999/09/17 21:18:16  gozer
  This is a major modification on the whole SW structure
  New methods in SW:
  SW->master	: returns the current Master o bject
  SW->session	: returns the current session object
  SW->user	: returns the current user
  SW->data	: returns the current URL/URI parsed data (getDataValue, setDataValue) but it's incomplete for now

  Now, no object needs to get a hold on any of those structures, they can access them thru the global methods instead.  Thus fixing a lot of problems with circular dependencies.

  Completed the User class with User::Authen for authentication User::Authz for authorization and User::Group for group membership.

  I modified quite many files to use the new SW-> methods instead of holding on them.  Still some cleaning up to do

  Tonight, I debug this change and tommorrow I'll document everything in details.

  SW::Session now has 2 accesses  set/get/delGlobalValues and set/get/deletePrivateValues for private(per application class) and global.

  Revision 1.4  1999/09/17 00:44:44  fhurtubi
  Modified an erroneous insert SQL query

  Revision 1.3  1999/09/12 19:41:33  gozer
  Fixed a little SQL bug

  Revision 1.2  1999/09/12 18:59:40  gozer
  EMERGENCY UPDATE BEFORE MY MACHINES CRASHES FOR REAL

  Moved user Authorization outside everything and inside it's own package SW::AppAccess
  The swValidateUser should be removed from the code now.
  Removed login info from smartworker.conf, not needed anymore
  added $SW::CONFIG::LOGIN_HANDLER = "SW::Login"
  added to the new SW::App::Admin::Applications so you can edit the access privlieges for your app in there

  Revision 1.1  1999/09/07 03:17:22  scott
  first addition


=head1 SEE ALSO

SW::Application,  perl(1).

=cut
