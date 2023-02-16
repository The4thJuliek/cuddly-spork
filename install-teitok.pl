# Perl script to help install TEITOK
use Config;

# Figure out which OS we are running
$os = $^O;
$user = getpwuid($<);

$tmp = shift;
if  ( $tmp eq "-v" ) { $verbose = 1; };
$curuser = `who`; chop($curuser); $curuser =~ s/ .*//smi;

# For in case PATH is missing, add all the weird ones
$ENV{PATH} = "$ENV{PATH}:/usr/sbin:/usr/local/bin";

if ( $user ne "root" ) { print "You are not running as root - most likely the script will not be allowed to perform certain tasks\n"; };

# Find out what system we are using and set some deviating standards
$homes = "/home";
$apacheroot = "/var/www/html";
$apacherestart = "apachectl -k restart";
$apachecheck = "service apache2 status";
$apachehttpd = "/etc/apache2/apache2.conf";
if ( -e "/etc/lsb-release" || -e "/etc/debian_version" ) {
	# TESTED
	$system = "debian/ubuntu";
	$apt = "apt-get"; $opts = "-y install";
	$pkg = "apache2 apache2-utils php php-xml libapache2-mod-php git g++ libxml-libxml-perl subversion";
	$apacherestart = "systemctl restart apache2";
	$apacheuser = "www-data";
} elsif ( -e "/etc/fedora-release" ) {
	# TESTED
	$system = "fedora";
	$apacherestart = "service httpd restart";
	$apachecheck = "service httpd status";
	$apacheuser = "apache";
	$apachehttpd = "/etc/httpd/conf/httpd.conf";
	$apachemore .= " sudo firewall-cmd --permanent --add-service=http; sudo firewall-cmd --permanent --add-service=https ; sudo firewall-cmd --reload";
	if ( checkif("which dnf") ) {
		$apt = "dnf"; $opts = "-y install";
		$pkg = "httpd php php-xml git g++ perl-XML-LibXML perl-Time-HiRes subversion";
	} else {
		$apt = "yum"; $opts = "install -y";
		$pkg = "httpd php php-xml git g++ perl-XML-LibXML perl-Time-HiRes subversion";
	};
} elsif ( -e "/etc/centos-release" ) {
	# TO TEST
	$apacherestart = "service httpd restart";
	$apachecheck = "service httpd status";
	$apacheuser = "apache";
	$apachehttpd = "/etc/httpd/conf/httpd.conf";
	$system = "centos";
	$apt = "yum"; $opts = "install -y";
	$apachemore = "systemctl enable httpd; ";
	$apachemore .= " sudo firewall-cmd --permanent --add-service=http; sudo firewall-cmd --permanent --add-service=https ; sudo firewall-cmd --reload";
	$pkg = "httpd php php-xml git gcc-c++ perl-XML-LibXML perl-Time-HiRes subversion";
} elsif ( -e "/etc/SUSE-brand" ) {
	# TESTED
	$apacherestart = "/sbin/service apache2 restart";
	$apachecheck = "systemctl status apache2";
	$apacheuser = "wwwrun";
	$apachehttpd = "/etc/apache2/httpd.conf";
	$apacheroot = "/srv/www/htdocs";
	$system = "suse";
	$apt = "zypper"; $opts = "install -y";
	$pkg = "apache2 php git gcc-c++ perl-XML-LibXML perl-Time-HiRes subversion";
	$apachemore = "a2enmod mod_access_compat env rewrite; ";
	$apachemore .= "sudo systemctl enable apache2; ";
	$apachemore .= " sudo firewall-cmd --permanent --add-service=http; sudo firewall-cmd --permanent --add-service=https ; sudo firewall-cmd --reload";
} elsif ( -e "/etc/alpine-release" ) {
	# TESTED
	$system = "alpine";
	$apt = "apk"; $opts = "add -q";
	$apacherestart = "rc-service apache2 restart";
	$pkg = "apache2 php php-xml php-simplexml php-dom php-mbstring php-apache2 apache2-utils php-session git g++ perl-xml-libxml perl-html-parser sudo subversion";
	$apacheuser = "apache";
	$apachemore .= "rc-update add apache2";
	$apachehttpd = "/etc/apache2/httpd.conf";
	$apacheroot = "/var/www/localhost/htdocs";
} elsif ( -e "/etc/arch-release" ) {
	# TO TEST (not working)
	$system = "arch";
	$apt = "pacman"; $opts = "--noconfirm -S";
	$apacherestart = "systemctl restart httpd";
	$pkg = "apache php php-apache php-xml apache2-utils git g++ perl-xml-libxml perl-html-parser sudo subversion";
	$apacheuser = "http";
	$apachemore .= "systemctl enable --now httpd";
	$apachecheck = "systemctl status httpd";
	$apachehttpd = "/etc/httpd/conf/httpd.conf";
	$apacheroot = "/srv/http";
	print "Updating pacman - this may take a while";
	`pacman -Syu --noconfirm`;
} elsif ( -e "/etc/freebsd-update.conf" ) {
	# TO TEST
	$system = "freebsd";
	$homes = "/home";
	$apacheuser = "www";
	$apacheroot = "/usr/local/www/apache24/data";
	$pkg = "apache24 php72 git gcc libxml2 sudo php72-xml php72-simplexml php72-dom php72-mbstring php72-session mod_php72 subversion";
	$apachehttpd = "/usr/local/etc/apache24/httpd.conf";
	$apacherestart = "service apache24 restart";
	$apachecheck = "service apache24 status";
	$apachemore = "sysrc apache24_enable=yes";
	if ( !-e "/usr/local/etc/apache24/Includes/php.conf" ) {
	open FILE, ">/usr/local/etc/apache24/Includes/php.conf";
	print FILE "<IfModule dir_module>
    DirectoryIndex index.php index.html
    <FilesMatch \"\.php\$\">
        SetHandler application/x-httpd-php
    </FilesMatch>
    <FilesMatch \"\.phps$\">
        SetHandler application/x-httpd-php-source
    </FilesMatch>
</IfModule>
"};

	$apt = "pkg"; $opts = "install -y";
} elsif ( "-e /usr/bin/sw_vers" ) {
	# TO TEST
	$system = "macosx";
	$homes = "/Users";
	$apacheuser = "_www";
	$apacheroot = "/Library/WebServer/Documents";
	$pkg = "httpd php git libxml2 subversion";
	$apachehttpd = "/etc/apache2/httpd.conf";
	$apachecheck = "";
	$apacherestart = "sudo /usr/sbin/apachectl restart";
	$apachemore .= "cpan HTML::Entities; cpan XML::LibXML";
	
	if ( !checkif("sudo -u $curuser brew commands") ) {
		if ( !checkif("sudo -u $curuser brew commands") ) {
			$hbcmd = 'ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"';
			print "Homebrew cannot be installed within this script - please run the following from the command line and re-run this script: \n$hbcmd; cpan -v\n";
			exit;
		};
	};
	$apt = "$gitfolder/homebrew/bin/brew"; $opts = "install";
	$installcmd = "sudo -u $curuser brew install";
} else {
	print "You are running an as of yet unsupported linux version\n";
	if ( !confirm("Do you have the following packages curretly running on your syste: - Apache2, PHP, Perl-LibXML, SVN, Git") ) {
		exit;
	};
};
if ( !$installcmd ) { $installcmd = "$apt $opts"; };

print "Setting up TEITOK for $system\n";

# Check SELinux and turn it off when needed
$tmp = `sestatus`;
if ( $tmp =~ /enforcing/ ) {
	if ( confirm("TEITOK is not currently compatible with SELinux - we can turn it off untill reboot (change yourself to modify permanently), do you want to do so?") ) {
		`setenforce 0`;
	};
};

print "TEITOK depends on the following packages which can be handled automatically with $apt: $pkg\n";
if ( confirm("Do you want to install those automatically when needed?", 1) ) {
	print "Running: $installcmd $pkg - this may take a while\n";
	installme($pkg);
} else {
	print "We will continue assuming you have all the above components correctly installed; if not, this installer will fail and you should install TEITOK manually\n";
};


# Check Apache
`$apacherestart`;
`$apachemore`;
`$apacherestart`;
if ( !checkif("$apachecheck") ) { print "Apache does not seem to be running - please correct manually\n"; exit; };

if ( $gitfolder eq "" ) { 
	print "Where do you want to save your Git files? ($homes/git) >";
	$gitfolder = <STDIN>; chop($gitfolder);
	if ( $gitfolder eq "" ) { $gitfolder = "$homes/git"; };
};

if ( !-d $gitfolder ) {
	mkdir($gitfolder);
	if ( !-d $gitfolder ) {
		print "Creating the folder $gitfolder failed; please create it and restart the script and select an existing folder for your Git file\n";
		exit;
	};
};

if ( !-d "$gitfolder/TEITOK" ) {
	print "TEITOK does not seem to be cloned; as which user do you want to clone it? ($apacheuser) ";
	$gituser = <STDIN>; chop($gituser);
	if ( $gituser eq "" ) { $gituser = $apacheuser or $gituser = `whoami`; };
	print "chown -R $gituser $gitfolder\n";
	`chown -R $gituser $gitfolder`;
	`cd $gitfolder; sudo -u $gituser git clone https://gitlab.com/maartenes/TEITOK.git`;
};
if ( $gituser eq "" ) { $gituser = $apacheuser; };

if ( -d "$gitfolder/smarty" ) {$smartyroot = "$gitfolder/smarty/libs/"; };
if ( !$smartyroot ) {
	$tmp = `locate Smarty.class.php`;
	if ( $tmp ) { $smartyroot = $tmp; $smartyroot =~ s/\/Smarty\.class\.php.*//; };

};
if ( !$smartyroot ) {
	# Smarty not installed - clone it using Git
	`cd $gitfolder; sudo -u $gituser git clone https://github.com/smarty-php/smarty.git`;
	$smartyroot = "$gitfolder/smarty/libs/";
};

print "What do you want the 'shared' TEITOK project to be called? [shared]";
$sharedfldr = <STDIN>; chop($sharedfldr);
if ( $sharedfldr eq '' ) { $sharedfldr = "shared"; };

if ( !-d "$apacheroot/teitok" ) {
	# Create the home for TEITOK under Apache
	mkdir("$apacheroot/teitok");
	open FILE, ">$apacheroot/teitok/.htaccess";
	print FILE 'DirectoryIndex index.php
RewriteEngine On
RewriteCond %{SCRIPT_FILENAME} !-f
RewriteCond %{SCRIPT_FILENAME} !-d
RewriteRule ^(.*?)/(.*)$ $1/index.php/$2
';

print FILE "\n\nSetEnv SMARTY_DIR $smartyroot
SetEnv TT_SHARED $apacheroot/teitok/$sharedfldr/
SetEnv TT_ROOT $gitfolder/TEITOK/";
close FILE;

	if ( !-d "$apacheroot/teitok" ) {
			print "Creating the folder $apacheroot/teitok failed; please create it and restart the script and select an existing folder for your Git file\n";
	};

	# `cp -R $gitfolder/TEITOK/check $apacheroot/teitok`; # Copy the checks folder
	# `chown -R $apacheuser $apacheroot/teitok/check`; # CHOWN it to Apache
	`ln -s $gitfolder/TEITOK/Scripts $apacheroot/teitok`; # Link the folder for the Javascript files

};

# Make sure mod_env and mod_rewrite are enabled in Apache
`a2enmod env rewrite`;
`$apacherestart`;

if ( !-e $apachehttpd ) { 
	print "\n\n!!!! Apache2 configuration file $apachehttpd not found - you will need to add something like the following yourself to the httpd.conf or apache2.conf in order to make allow TEITOK to change files:
	<Directory $apacheroot/teitok/>
		Options Indexes FollowSymLinks
		AllowOverride All
		</Directory>
	\n\n\n"
} else { 
	`cp $apachehttpd httpd.conf`;
	$tmp = `cat httpd.conf`;
	if ( $tmp !~ /TEITOK/ ) {
		$tmp .= "\n# Settings for TEITOK\n<Directory $apacheroot/teitok/>\n	Options FollowSymLinks\n	AllowOverride All\n</Directory>\n";		
	};
	
	$tmp =~ s/#(LoadModule\s+(env_module|php|rewrite))/\1/g;
	
	open HTTPDCONF, ">httpd-mod.conf";
	print HTTPDCONF $tmp;
	close HTTPDCONF;
	`cp httpd-mod.conf $apachehttpd`;
	`$apacherestart`;
};

if ( !-e "/usr/local/bin/tt-cwb-encode" ) {
	print "Installing C++ modules of TEITOK\n";
	`cd $gitfolder/TEITOK/src ; g++ -std=c++11 -o /usr/local/bin/tt-cwb-encode tt-cwb-encode.cpp pugixml.cpp functions-c11.cpp`;
	`cd $gitfolder/TEITOK/src ; g++ -std=c++11 -o /usr/local/bin/tt-cwb-xidx tt-cwb-xidx.cpp pugixml.cpp functions-c11.cpp`;
	`cd $gitfolder/TEITOK/src ; g++ -std=c++11 -o /usr/local/bin/tt-cqp tt-cqp.cpp pugixml.cpp functions-c11.cpp`;
};

# Try to install CWB
if ( !checkif("cqp -v") ) {
	if ( confirm("Corpus WorkBench does not seem to be installed - do you want to install it?", 1) ) {
		print "Attempting to install CWB via SVN\n";
		if ( !-d "cwb" ) {
			print "Downloading\n";
			`svn export http://svn.code.sf.net/p/cwb/code/cwb/trunk cwb`;
		};
		print "Installing\n";
		
		# This is a temporary local hack 
		if ( $system eq 'debian/ubuntu') {
			`$installcmd autoconf bison flex gcc make pkg-config libc6-dev libncurses5 libncurses5-dev libpcre3-dev libglib2.0-0 libglib2.0-dev libreadline8 libreadline-dev`;
		};
		
		if ( $system eq 'macosx' ) {
			print `cd cwb ; export CWB_LIVE_DANGEROUSLY=1 ; ./install-scripts/install-mac-osx --quiet`;
		} else {
			print `cd cwb ; export CWB_LIVE_DANGEROUSLY=1 ; ./install-scripts/install-linux --quiet`;
		};
		# We want the CQP executables in /usr/local/bin
		if ( !-e "/usr/local/bin/cqp" ) { `cp /usr/local/cwb-*/bin/* /usr/local/bin`; };
	};
}; 


# Make TEITOK root writable to allow creation of new projects
if ( confirm("Do you want to allow Apache to write to the TEITOK root? (less secure, more flexible)") ) {
	`chown -R $apacheuser $apacheroot/teitok`;
	$writable = 1;
};

# Create the settings for the shared project
if ( !-d "$apacheroot/teitok/shared" ) {
	`cp -R $gitfolder/TEITOK/projects/default-shared $apacheroot/teitok/$sharedfldr`;
	`chown -R $apacheuser $apacheroot/teitok/$sharedfldr`;
};

# Install shared password
print "Provide a user email (for your shared project folder) > ";
while ( $shareduser eq '' ) {
	$shareduser = <STDIN>; chop($shareduser);
};
print "Provide a password (for your shared project folder) > ";
while ( $sharedpwd eq '' ) {
	$sharedpwd = <STDIN>; chop($sharedpwd);
};
( $sharedcrypt = `htpasswd -bnBC 10 "" $sharedpwd` ) =~ s/:(.*?)\s+$/\1/;

$userxml = "<userlist>
	<user password=\"$sharedcrypt\" enc=\"1\" email=\"$shareduser\" permissions=\"admin\" projects=\"all\">Shared Admin</user>
</userlist>";
open USERLIST, ">$apacheroot/teitok/$sharedfldr/Resources/userlist.xml";
binmode(USERLIST, ":utf8");
print USERLIST $userxml;
close USERLIST;

# Finish and send user to online install environment
if ( $writable ) {
	# Find out who we are logged in as
	if ( $curuser ) {
		print "Opening the login page as $curuser - please finish the installation in the interface";
		`sudo -u $curuser firefox 'http://127.0.0.1/teitok/$sharedfldr/index.php?action=login'`;
	} else {
		print "Open http://127.0.0.1/teitok/$sharedfldr/index.php?action=login in a browser and create your first TEITOK project within the interface\n";
	};
} else {
	print "Open http://127.0.0.1/teitok/check/index.php in a browser and check that your installation is complete\n";
	
};

sub confirm($text, $noexit=0 ) {
	( $text, $noexit ) = @_;
	print $text. " [y]";
	#if ( !$noexit ) { print " *required"; };
	#print " > ";

	$tmp = <STDIN>; chop($tmp); $response = 0;
	if ( $tmp eq 'y' || $tmp eq 'yes' || $tmp eq '' ) { $response = 1; }

	if ( !$noexit && !$response ) {
		print "Please perform this action externally first and re-run this script";
		exit;
	};

	return $response;
}

sub checkif ($cmd) {
	$cmd = @_[0];
	if ($cmd eq '') { return 1; }; 
	$tmp = `$cmd`; chop($tmp);
	if ( $tmp ne '' ) { return 1; };
	return 0; 
};

sub lprint ($text) {
};

sub installme ($ilist) {
	$ilist = @_[0];
	
	foreach $ipkg ( split ( " ", $ilist ) ) {
		if ( $verbose ) {
			print `- Installing $ipkg`; print "\n";
		} else {
			`$installcmd $ipkg`;
		};		
	};
};