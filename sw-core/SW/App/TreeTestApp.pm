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

#!/usr/bin/perl -I/usr/local/apache/dev/v1

package SW::App::TreeTestApp;

use strict;
use vars qw($VERSION @ISA );

use SW::Application;
use SW::Panel;
use SW::GUIElement;
use Data::Dumper;
use SW::Data::Document;

@ISA = qw(SW::Application);


sub new
{
	my $classname = shift;
	my $self = $classname->SUPER::new(@_);
	bless ($self, $classname);

	my $cb = sub { $self->swResponseTree(@_) };
	$self->registerCallback("mySwResponseTree", $cb);

	$self->{master}->syncState($self);
	return $self;
}

sub swInitApplication
{
	my $self = shift;
	my $data = new SW::Data::Document($self);
	my $appRegistry = $self->{master}->{appRegistry};

	$appRegistry->register(ref $self, [ $data->getFullPath() ] , [], "SW Documentation Tree Viewer");;

	my $dir = '/usr/local/php3_apache/htdocs/smartworker/tech/classes';

	opendir(CLASSES, $dir) || $self->debug("ERROR: Couldn't open directory $dir");
	my @files = grep { /^sw.+\.html$/ } readdir(CLASSES);
	closedir(CLASSES);

	@files = sort @files;

	foreach my $f (@files)
	{
		open(FH, "< $dir/$f") || $self->debug("Couldn't open file $dir/$f\t$!");
		my ($fn) = grep { /SW::/ } <FH>;
		$fn =~ /(SW[::[A-Za-z]+]*)/;
      $data->{storage}->{$1} = "http://father.hardboiledegg.com:8080/smartworker/tech/classes/$f";
		$self->debug("Added ".$data->{storage}->{$1});
	}

	$data->{dirty} = 1;	

	$self->{session}->{dataDocumentPath} = $data->getFullPath();
	$self->{dataDocument} = $data;
	
	return 1;
}

sub swInitTransaction
{
    my $self = shift;

    if (! $self->{dataDocument})
    {
	$self->debug("[TreeTest] No doc getting ".$self->{session}->{dataDocumentPath});
	$self->{dataDocument} = new SW::Data::Document($self, $self->{session}->{dataDocumentPath});
    }

    return 1;
}

sub swInitInstance
{
    my $self = shift;

    my $objList = $self->{master}->{appRegistry}->dataObjects($self, ref $self);
    $self->{session}->{dataDocumentPath} = shift @$objList;
    $self->debug("[TreeTest - InitInstance] Added ". $self->{session}->{dataDocumentPath}." to session");
    $self->debug("Retrieving document ".$self->{session}->{dataDocumentPath});

    return 1;

}

sub fillTree
{
	my $self = shift;
	my $tree = shift;
	my $doc = $self->{dataDocument};

	foreach my $el (keys %{$doc->{storage}})
	{
		$self->debug("adding child $el");
		$tree->addChild($el, $doc->{storage}->{$el});
	}
}

sub swBuildUI
{
	my $self = shift;

	$self->debug("Starting main layout");	
	my $leftPanel = new SW::Panel::HTMLPanel($self, "TreePanel" );
	my $rightPanel = new SW::Panel::HTMLPanel($self, "DisplayPanel" );
	$self->addComponent($rightPanel,"DisplayPanel");

	my $treeView = new SW::GUIElement::TreeView($self, "my1stTree","mySwResponseTree");
	$treeView->setValue("bgColor", "#9090b0");
	$self->addComponent($treeView,"Tree");

    	$self->debug("Filling tree from ".$self->{dataDocument});
    	$self->fillTree($treeView);

	$self->syncState($treeView);


	$leftPanel->addElement(0,0, $treeView);
#	$leftPanel->addElement(0,1, $link_plain);

	my $mainPanel = $self->getPanel();

	$mainPanel->addElement(0, 0, $leftPanel);
	$mainPanel->addElement(1, 0, $rightPanel);

	$self->debug("Done main layout");

}

sub postTreeCallbacks
{
	my $self = shift;

	if ($self->{data}->{_submitted} ne 'TreePanel')
	{
		if ($self->{session}->{viewing})
		{
			$self->doCallback("mySwResponseTree", $self->{session}->{viewing});
		}
	}
}

#------------------------------------------------------------
# callback functions
#------------------------------------------------------------

sub swResponseTree
{
	my $self = shift;
	my $node = shift;

	my $panel = $self->getComponent("DisplayPanel");
	my $tree = $self->getComponent("Tree");
	$self->debug("$self retrieved $tree and $panel ");

	$self->debug("Got a view callback on node $node");
	$self->debug("Link is ".$tree->{links}->{$node});
	
	$panel->setValue("url",	"$tree->{links}->{$node}");
	$self->debug("set panel url to: ".$panel->getValue("url"));

	$self->debug("Done swResponseView callback");
	
}
1;

__END__

=head1 NAME

SW::App::FillIn - Fill In

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 PARAMETERS

=head1 AUTHOR

=head1 REVISION HISTORY

$Log: TreeTestApp.pm,v $
Revision 1.3  1999/11/15 18:17:28  gozer
Added Liscence on pm files

Revision 1.2  1999/09/07 16:23:17  gozer
Fixed pod syntax errors


=head1 SEE ALSO

perl(1).

=cut



