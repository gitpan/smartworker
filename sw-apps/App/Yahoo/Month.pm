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
use SW::Util::Prep;

#------------------------------------------------------------
# Yahoo Month mock-up
#------------------------------------------------------------
#  $Id: Month.pm,v 1.2 1999/09/07 16:23:34 gozer Exp $
#------------------------------------------------------------


package Month;

use strict;
use vars qw($VERSION @ISA $SW_FN_TABLE @EXPORT @EXPORT_OK);

use SW::Application;
use SW::Panel;
use SW::GUIElement;
use SW::Panel::HTMLPanel;
use SW::Panel::FormPanel;
use SW::Data;
use SW::GUIElement::RadioButtonSet;
use SW::Data::Document;

@ISA = qw(SW::Application Exporter AutoLoader);
@EXPORT = qw(

);

sub new
{
	my $cname = shift;
	my $self = $cname->SUPER::new(@_);

	$self->buildTable;
	return $self;
}

sub swBuildUI
#SW TransOrder 15
{
	my $self = shift;
	
	my $leftPanel = new SW::Panel::FormPanel($self, {
															-name => "Left",
															-grow_x => "true",
															-bgColor => "white",
															-layoutPriority => -1,
																} );
	my $yearPanel = new SW::Panel::FormPanel($self, {
														-name=> "Year",
														-grid_x=> 3,
														-bgColor=> "white",
														-layoutPriority=> 3,
														-layoutName=> "MonthSelector"
																} );
   my $todoPanel = new SW::Panel::FormPanel($self, {
															-name=> "Todo",
															-bgColor=> "#eeeeee",
															-textColor=> "black",
															-layoutPriority=> 2,
															-layoutName=> "TodoList",
																	});
	my $rightPanel = new SW::Panel::FormPanel($self, {
								-name=>"Month",
#								-debug_layout_grid=>"true",
								-grid_x=>12,
								-grow_x => "true",
								-spacing => 1,
								-bgColor => "white",
								-layoutPriority => 1,
								-layoutName => "MonthView",
							}  );

	$leftPanel->addElement(0,0,$yearPanel);
	$leftPanel->addElement(0,1,$todoPanel);


	my $mainPanel = $self->getPanel();
#	$mainPanel->setValue("bgColor", "white");

   my $hostname = $self->{master}->{r}->get_remote_host();

	my $text = new SW::GUIElement::Text($self, {	-text=>"Welcome $hostname, to our SW-Yahoo Calendar",
							-textColor=>"black",
						   -bgColor => "#dcdcdc",
						  } );
	
	
	$mainPanel->addElement(0, 0, $text);
	$mainPanel->addElement(0, 1, $leftPanel);
	$mainPanel->addElement(4, 1, $rightPanel);


#------  Building the month view  -----------


	my $y = 1900 + (localtime)[5];
	my @months = qw(January February March April May June July August September Octiber November December);
	my $m = $months[(localtime)[4]];

	my $titlePanel = new SW::Panel::HTMLPanel($self, {
															-bgColor=> "#a2b9c9",	
																});
	$titlePanel->addElement(0,0,new SW::GUIElement::Text($self,{
																					-text=> "$m $y",
																				   -textColor=> "black",
																					}));
	$titlePanel->addElement(9,0,new SW::GUIElement::Button($self, {
																				-text=> "Add Event",
																				-align=> "right",
																				-grow_x=> "true",
																				-textColor=> "black",
																				}));

	$rightPanel->addElement(0,0,$titlePanel);

	my $add =  new SW::GUIElement::Text($self, {
                                          -bgColor => "#dcdcdc",
                                          -textColor => "blue",
														-fontSize => 1,
														-text => "Add",
                                    });


	my $count = 0;
	for (my $y = 1; $y < 8; $y++)
	{
		for (my $x=0; $x < 8; $x++)
		{
			my $text = new SW::GUIElement::Text($self, {
														-bgColor => "#dcdcdc",
														-textColor => "black",
												});
			my $text2 =  new SW::GUIElement::Text($self, {
                                          -bgColor => "#eeeeee",
                                          -textColor => "red",
                                    });
#	Top row ....
			if ($y == 1)
			{
				($x == 0) ? $text->setValue("text", "Wk") : 0;
				($x == 1) ? $text->setValue("text", "Sun") : 0;	
				($x == 2) ? $text->setValue("text", "Mon") : 0;
				($x == 3) ? $text->setValue("text", "Tue") : 0;
				($x == 4) ? $text->setValue("text", "Wed") : 0;
				($x == 5) ? $text->setValue("text", "Thu") : 0;
				($x == 6) ? $text->setValue("text", "Fri") : 0;
				($x == 7) ? $text->setValue("text", "Sat") : 0;

				$rightPanel->addElement($x,$y,$text);
			}				
# remaining rows...
			else
			{
				if ($x == 0)
				{
					$text->setValue("text", "...");
					$rightPanel->addElement($x, $y, $text);
				}
				else
				{	
					$text->setValue("text", $count++."   ");
					$text->setValue("textColor", "blue");
					$text2->setValue("text", ".      .");					
					my $p = new SW::Panel::HTMLPanel($self, { -grow_x=>"true", });
					$p->addElement(0,0,$text);
					$p->addElement(1,0,$add);
					$p->addElement(0,1,$text2);
					$rightPanel->addElement($x,$y,$p);	
				}	
			}

		}
	
	}


#------  Building the year view  -----------

	my $grainPanel = new SW::Panel::HTMLPanel($self, {
																		-name=> "grain",
																		-grow_x=> "true",	
																		-bgColor=> "white",
																		-spacing=> 3,
																		-border=> 1,
																				} );

	my $count=0;
	foreach my $grain ( qw(Day Week Month Year) )
	{
		$grainPanel->addElement($count++,0,new SW::GUIElement::Link($self, "$grain"));
	}

	$yearPanel->addElement(0,0,$grainPanel);
	
	my $year = 1900 + (localtime)[5];
	$yearPanel->addElement(0,1,new SW::GUIElement::Text($self,{ -text=>"$year",
																					-bgColor=> "#dcdcdc",
																					-textColor=> "black",
																					-grow_x=> "true",
																					-align=> "center",
																					}));

	my $row = 2;
	my $col = 0;
	foreach my $month (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))
	{
		$yearPanel->addElement($col++,$row,new SW::GUIElement::Link($self, "$month"));
		if ($col > 2) 
		{
			$col=0;$row++;
		}
	}
	
	$yearPanel->addElement(0,7,new SW::GUIElement::Text($self, {
																-text=> "Today is May 5, 1999",
																-bgColor=> "fffed1",	
																-textColor=> "black",
																			} ));
		

#------  Building the todo view  -----------
   my $todoTitlePanel = new SW::Panel::HTMLPanel($self, {
                                             -bgColor=> "#a2b9c9",   
                                                });
   $todoTitlePanel->addElement(0,0,new SW::GUIElement::Text($self,{
                                                               -text=> "ToDo",
                                                               -textColor=> "black",
                                                               }));
   $todoTitlePanel->addElement(9,0,new SW::GUIElement::Button($self, {
                                                            -text=> "Add",
                                                            -align=> "right",
                                                            -grow_x=> "true",
                                                            -textColor=> "black",
                                                            }));

   $todoPanel->addElement(0,0,$todoTitlePanel);


   my $removeButton = new SW::GUIElement::Button($self, {
								-text=>"Remove Checked",
							  });
						
	my $check1 = new SW::GUIElement::CheckBox($self, {	-ref=>"bindings",
								-value=>"bindings",
								-text=>"1 Some Todo Item",
							} );

	$todoPanel->addElement(0,1,$check1);
	$todoPanel->addElement(0,2,$removeButton);
							
	$self->debug("Completed Build UI");
} #  end of draw sub

#------------------------------------------------------------
#  Test of a callback function
#------------------------------------------------------------

#SW end

1;
__END__

=head1 NAME

Yahoo::Month - A Month

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Scott Wilson
scott@hbe.ca		May 1999

=head1 REVISION HISTORY

	$Log: Month.pm,v $
	Revision 1.2  1999/09/07 16:23:34  gozer
	Fixed pod syntax errors
	
	Revision 1.1  1999/09/02 20:11:25  gozer
	New namespace convention
	
	Revision 1.3  1999/08/20 02:13:29  scott
	changed so we get the blue (default) background
	
	Revision 1.2  1999/05/20 13:53:54  scott
	Updated Yahoo Month to work with the new transaction model
	
	Revision 1.1  1999/05/14 16:42:58  scott
	Newly added, yahoo month mockup
	

=cut

