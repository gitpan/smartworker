use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 	'SW::App',
	DISTNAME	=>	'smartworker-apps',
	VERSION_FROM	=> 	'App.pm',
	PREREQ_PM	=> {	'Data::Dumper'	=> 0,
				'Date::Manip'	=> 0,
				'Date::Calc'	=> 0,
				},
		);

			
