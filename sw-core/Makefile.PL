#use strict;
use ExtUtils::MakeMaker;

#there should be a way hidden in Apache::* to get this right all the time
my $apache_lib = "/usr/local/apache";

print "A smartworker/ directory will be created in that dir\n";
print "Pick your installation dir [" , $apache_lib , "]:";

my $pick = <>;
chomp $pick;
$apache_lib = $pick || $apache_lib;
$apache_lib_sw = $apache_lib . "/smartworker";

#run every substitutions listed as args in the config file to reflect installation params in it.
mod_config_file( "sw-perl-startup.pl", "./conf/",
                  (
                  FILL_IN_BASE_LOCATION   => "$apache_lib",
                  FILL_IN_DEFAULT_DB	  => "LOCAL",
		  FILL_IN_DB_LIST	  => getDBList(),
				  )
               );

mod_config_file("smartworker.conf", "./conf/",
		                  (
                  FILL_IN_BASE_LOCATION   => "$apache_lib",
			)
	);


print "Preparing to install into : $apache_lib_sw\n";

print <<'EOF';
##############################################################################
#   During the make process, you will notice some errors from pod2man,       #
#   that's because some module are not 100% pod-syntax error correct.        #
#----------------------------------------------------------------------------#
#   They will install correctly anyway.                                      #
##############################################################################
EOF

#Modification to install non-perl specific directories
sub MY::install { 
	my $self = shift;
	local *install;
	$_=$self->MM::install;
	$_ =~ s/(install.*)/$1 sw_install/;
	$_ .= <<"EOF";

sw_install: extra_sw_install
	\@echo Installing SmartWorker specific files
	\@\${MOD_INSTALL} \\
	./sw_lib  $apache_lib_sw/lib \\
	./docs 	$apache_lib_sw/docs \\
	./conf  $apache_lib_sw/conf \\
	./apps  $apache_lib_sw/apps \\
	./logs  $apache_lib_sw/logs
	\@echo Don\\'t forget to add "ResourceConfig $apache_lib_sw/conf/smartworker.conf" to your httpd.conf
 
	
extra_sw_install:
	\@echo Installing extra customized CPAN modules
	\@echo Patches for each of there were sent to their author and are waiting to be included in future releases
	\@cd extra && ./install.sh
	
EOF
	return $_;
	}


print << 'EOF';
##############################################################################
#      Take note that the dependency check for Apache::DBI will fail         #
#      even if you have it installed.  So you can ignore the warning         #
#      if you already have it installed                                      #
##############################################################################
EOF

sleep 5;

WriteMakefile(
	NAME      		=> 'SW',
	DISTNAME		=> 'sw-core',
	VERSION_FROM	=> 'SW.pm',
#	LIB			=>	$apache_lib,
#	INSTALLMAN1DIR	=>  $apache_lib . '/man/man1',
#	INSTALLMAN3DIR	=>  $apache_lib . '/man/man3',
	PREREQ_PM		=> {
	'Data::Dumper'			=> 0,
	'Net::Cmd'			=> 0,
	'LWP'				=> 0,
	'DBI'				=> 0,
	'CGI'				=> 0,
	'Filter::Util::Call'		=> 0,
	'Apache::Language'		=> 0.05,
	'Date::Manip'			=> 0,
	'Date::Calc' 			=> 0,
	'Apache::Status'		=> 0,
	'BSD::Resource'			=> 0,
	'Apache'			=> 0,
	'Storable'			=> 0,
	'Apache::DBI'			=> 0,
	'Apache::Session'		=> 0,
	},
);
   
   
sub mod_config_file {
   my $filename = shift;
   my $location = shift;
   my %translations = @_;
   open FILE, "./templates/$filename.tmpl" or die "Can't open ./templates/$filename.tmpl";
   my $new_file;
   while (<FILE>) 
      { 
      foreach $key (keys %translations) {
         s/$key/$translations{$key}/g;
         }
      $new_file .= $_;
      }
   close FILE;
   open FILE, ">$location$filename" or die "Can't open $location$filename for writing";
   print FILE $new_file;
   close FILE;
}

sub getDBList {
print "Enter your DataBase Host [localhost]: ";
	my $host = <>;
	chomp $host;
	$host ||= 'localhost';

print "Enter the DB type [mysql]: ";
	my $dbtype = <>;
	chomp $dbtype;
	$dbtype ||= 'mysql';
	
print "Enter the DB port [3306]: ";
	my $port = <>;
	chomp $port;
	$port ||= '3306';
	
print "Enter the DB name [smartworker]: ";
	my $dbname = <>;
	chomp $dbname;
	$dbname ||= 'smartworker';
	
print "Enter the username [sw]: ";
	my $username = <>;
	chomp $username;
	$username ||= 'sw';
	
print "Enter the password for $username\@$host [sw]: ";
	my $password = <>;
	chomp $password;
	$password ||= 'sw';

print "Would you like to create and populate the database automatically ? [no] :";
	my $populateDB = <>;
	chomp $populateDB;
	$populateDB = (lc $populateDB) eq 'y' ? 1 : 0;

&fillDB($host,$dbname,$username,$password) if($populateDB);

return <<"EOF";
"LOCAL" => 
		{  
		"host" => 	"$host",
		"port" => 	$port, 
		"database" => 	"$dbname",
		"username" => 	"$username",
		"password" => 	"$password",
		"dbType" => 	"$dbtype",
		},

	"REMOTE" =>
		{  
		"host" => "testdb.smartworker.org",
		"port" => 3306, 
		"database" => "smartworker",
		"username" => "sw",
		"password" => "TestSWDB",
		"dbType" => "mysql",
		}
EOF
}

sub fillDB {
	my ($hostname,$dbname,$old_username,$old_password) = @_;
	print "Username for db creation [$old_username]: ";
		my $username = <>;
		chomp $username;
		$username ||= $old_username;
		
	print "Password for db creation [$old_password]: ";
		my $password = <>;
		chomp $password;
		$password ||= $old_password;
		
	system("mysqladmin -u$username -p$password -h$hostname create $dbname");
	system("cat ./templates/cleanDump.sql | mysql -u$username -p$password -h$hostname $dbname");
}
