#
# Linoratix module to manage packages
#

package Linoratix::LIP;
use Linoratix;
use Linoratix::LIPbase;

use strict;

use Storable;
use Data::Dumper;
use File::Basename;
use Fcntl ':mode';

use vars qw(@ISA @EXPORT $MOD_VERSION);
use Exporter;
$MOD_VERSION = "0.0.2";
@ISA = qw(Exporter);
@EXPORT = qw(&new);

our $installed_packages;
our $base;
our $pkgdb;
our @durchlauf;

our $FROM_DB=1;

sub new
{
	my $linoratix = shift;
	my $class     = ref($linoratix) || $linoratix;
	my $self      = { @_ };

	bless($self, $class);

	$base = Linoratix::LIPbase->new();
	
	$self->message("Retrieving information for available packages...   ");
	$pkgdb = $base->load_caches();
	print "done.\n";
	$self->message("Retrieving information for installed packages...   ");
	$installed_packages = $base->read_installed_packages();
	print "done.\n";

	$self->help() if($self->option("help"));
	$self->install() if($self->param("install") && !$self->option("prepend"));
	$self->update() if($self->param("update") && !$self->option("prepend"));
	$self->remove() if($self->param("remove") && !$self->option("prepend"));
	$self->policy() if($self->param("policy"));
	$self->list_files() if($self->param("list-files"));
	$self->search() if($self->param("search"));
	$self->search_file() if($self->param("search-file"));
	$self->prepend_install($self->param("install")) if($self->option("prepend") && $self->param("install"));
	$self->prepend_remove() if($self->option("prepend") && $self->param("remove"));
	$self->upgrade() if($self->option("upgrade"));

	return $self;
}

sub help
{
	my $self = shift;
	
	$self->message("linoratix-config $BASE_VERSION\n");
	$self->message("	module: LIP $MOD_VERSION\n\n");
	print "	--install <package> [--fake]			install package\n";
	print "	--remove <package/version>			remove package\n";
	print "	--upgrade				upgrades all installed packages to the newest\n						available version.\n";
	print "	--policy <package>			show package policy\n";
	print "	--list-files <package>			list all files of a package\n";
	print "\n";
	print "	--search-file <filename>		search a file in the package db\n";
	print "	--search <string>			search the package db\n";
	print "\n";
	print "	--prepend --install <package>		display which packages we will install\n";
	print "	--prepend --remove <package>		display which packages we will remove\n";
	print "\n";
	print "	--help					display help message\n\n";
}

sub install_by_version
{
	my $self = shift;
	my $package = shift;
	my $version = shift;
	my($group, $subgroup, $pkg) = split(/\//, $package);
	my $iversion;

	$FROM_DB=1;
	# ??? if(!$base->find_in_i_package_dep_by_name($pkg, $version)) {
	my $x = $base->find_package_dep_by_name($pkg, $version);
	if($x) {
		my $p = $base->get_package_by_path($package);
		$iversion = $base->_check_version($version, $p);
		$self->_install($package, $iversion);
	}
	return 1;
}

sub install
{
	my $self    = shift;
	my $package = shift;

	if(!$package) 
	{
		$package = $self->param("install");
	}

	if(-f "$package" && $package =~ m/\.lip$/)
	{
		my @_package = `tar xOzf $package GROUP`;
		my @_name = `tar xOzf $package NAME`;
		chomp(@_package);
		chomp(@_name);
		my @_ps = split(/\//, $_package[0]);
		$_ps[0] =~ s/ [!?-]$//;
		$_ps[1] =~ s/ [!?-]$//;
		$package = $_ps[0] . "/" . $_ps[1] . "/" . $_name[0];
		$FROM_DB=0;
	}
	else 
	{
		$package = $base->find_package_by_name($package);
	}

	my $ret = 0;
	return $self->_install($package);
}

sub _install
{
	my $self = shift;
	my $package = shift;
	my $version = shift;
	my @versions = ();
	my $bin_install = 0;
	my($group, $subgroup, $pkg);
	my $bin_pkg = "";
	#soll ein binaer packet direkt installiert werden

	if(-f $self->param("install") && $FROM_DB eq "0")
	{
		$bin_pkg = $self->param("install");
		chomp(@versions = `tar xzOf $bin_pkg VERSION`);
		$bin_install = 1;
	}
	else
	{	
		@versions = $base->get_versions_from_pkg($package);
		($group, $subgroup, $pkg) = split(/\//, $package);
	}

	# ueberpruefen ob das aktuelle packet schonmal installiert werden sollte.
	# z.b. durch falsche eingetragene dependencies (kreis)
	if(grep { /^$package$/ } @durchlauf) {
		return 0;
	} else {
		push(@durchlauf, $package);
	}

	$self->message("Trying to install $package\n");

	if(!$version) {
		if(scalar(@versions) > 1) {
			# abfragen welche version installiert werden soll
		} else {
			$version = $versions[0];
		}
	}

	if($base->get_in_package_by_path_and_version($package, $version)) {
		$self->warning("Package $package, $version allready installed.\n");
		return 2;
	}
	my $package_to_install;

	if($bin_install)
	{
		$package_to_install->{$version}->{"__server"} = "file://".dirname($bin_pkg);
		$package_to_install->{$version}->{"rebuild-url"} = undef;
		my $_prov = `/bin/tar xzOf $bin_pkg PROVIDES`;
		chomp($_prov);
		$package_to_install->{$version}->{"provides"} = $_prov;
		my @_req = `/bin/tar xzOf $bin_pkg REQUIRED`;
		chomp(@_req);
		$package_to_install->{$version}->{"required"} = \@_req;
		my @_files = `/bin/tar xzOf $bin_pkg MANIFEST | grep ^/FILES`;
		chomp(@_files);
		$package_to_install->{$version}->{"files"} = \@_files;
		$package_to_install->{$version}->{"status"} = "-";
		$package_to_install->{$version}->{"md5"} = "";
		my @_desc = `/bin/tar xzOf $bin_pkg DESCRIPTION`;
		chomp(@_desc);
		$package_to_install->{$version}->{"description"} = \@_desc;
	}
	else
	{
		$package_to_install = $base->get_package_by_path($package);
	}

	my $deps = $package_to_install->{$version}->{"required"};

	foreach my $d (@{$deps}) {
		chomp($d);
		my($n,$v) = split(/ /, $d);
		$self->install_by_version(
			$base->find_package_by_name($n),
			$v
			);
	}
	my($group, $subgroup, $pkg) = split(/\//, $package);
	# my $file = $base->get_server_from_package($package, $version)
	my $file = $package_to_install->{$version}->{"__server"}
		. "/$pkg-$version.lip";

	# und das hauptpacket installieren
	unless($self->option("fake"))
	{
		if($self->_extract_files($version, $file, $package_to_install)) {

			# und in die liste der installierten packete aufnehmen
			$installed_packages->{$group}->{$subgroup}->{$pkg}->{$version} = 
				$package_to_install->{$version};
			$installed_packages->{$group}->{$subgroup}->{$pkg}->{$version}->{"__installed-date"} = 
				time();
			$base->save_installed_packages($installed_packages);
		
			$self->message("$package successfully installed.\n");
		} else {
			$self->error("error installing $package");
			return 2;
		}
	}
	else
	{
		$self->warning("Only fake install...\n");
		$installed_packages->{$group}->{$subgroup}->{$pkg}->{$version} = 
			$package_to_install->{$version};
		$installed_packages->{$group}->{$subgroup}->{$pkg}->{$version}->{"__installed-date"} = 
			time();
		$base->save_installed_packages($installed_packages);
		
		$self->message("$package successfully installed.\n");
	}

	return 1;
}

# komplettes system update
sub upgrade
{
	my $self = shift;
	$self->message("Downloading update-script.\n");
	system("/usr/bin/wget http://download.linoratix.com/");
}

# update einer einzelnen software
sub update
{
	my $self = shift;
	my $package = shift;

	if(!$package) 
	{
		$package = $self->param("update");
	}

	if(-f "$package" && $package =~ m/\.lip$/)
	{
		my @_package = `tar xOzf $package GROUP`;
		my @_name = `tar xOzf $package NAME`;
		chomp(@_package);
		chomp(@_name);
		my @_ps = split(/\//, $_package[0]);
		$_ps[0] =~ s/ [!?-]$//;
		$_ps[1] =~ s/ [!?-]$//;
		$package = $_ps[0] . "/" . $_ps[1] . "/" . $_name[0];
		$FROM_DB=0;
	}
	else 
	{
		$package = $base->find_package_by_name($package);
	}

	my $ret = 0;
	return $self->_update($package);
}

sub _update
{
	my $self = shift;
	my $package = shift;
	my $version = shift;
	my @versions = ();
	my $bin_install = 0;
	my($group, $subgroup, $pkg);
	my $bin_pkg = "";
	#soll ein binaer packet direkt installiert werden

	if(-f $self->param("update") && $FROM_DB eq "0")
	{
		$bin_pkg = $self->param("update");
		chomp(@versions = `tar xzOf $bin_pkg VERSION`);
		$bin_install = 1;
	}
	else
	{	
		@versions = $base->get_versions_from_pkg($package);
		($group, $subgroup, $pkg) = split(/\//, $package);
	}

	# ueberpruefen ob das aktuelle packet schonmal installiert werden sollte.
	# z.b. durch falsche eingetragene dependencies (kreis)
	if(grep { /^$package$/ } @durchlauf) {
		return 0;
	} else {
		push(@durchlauf, $package);
	}

	$self->message("Trying to install $package\n");

	if(!$version) {
		if(scalar(@versions) > 1) {
			# abfragen welche version installiert werden soll
		} else {
			$version = $versions[0];
		}
	}

	if($base->get_in_package_by_path_and_version($package, $version)) {
		$self->warning("Package $package, $version allready installed.\n");
		return 2;
	}
	my $package_to_install;

	my @i_version = $base->find_in_i_package_version_by_name($package);
	if(scalar(@i_version) > 1)
	{
		$self->error("Side by Side installation detected!!\n");
		die("Side by Side installation. Aborting.\n");
	}

	if($bin_install)
	{
		$package_to_install->{$version}->{"__server"} = "file://".dirname($bin_pkg);
		$package_to_install->{$version}->{"rebuild-url"} = undef;
		my $_prov = `/bin/tar xzOf $bin_pkg PROVIDES`;
		chomp($_prov);
		$package_to_install->{$version}->{"provides"} = $_prov;
		my @_req = `/bin/tar xzOf $bin_pkg REQUIRED`;
		chomp(@_req);
		$package_to_install->{$version}->{"required"} = \@_req;
		my @_files = `/bin/tar xzOf $bin_pkg MANIFEST | grep ^/FILES`;
		chomp(@_files);
		$package_to_install->{$version}->{"files"} = \@_files;
		$package_to_install->{$version}->{"status"} = "-";
		$package_to_install->{$version}->{"md5"} = "";
		my @_desc = `/bin/tar xzOf $bin_pkg DESCRIPTION`;
		chomp(@_desc);
		$package_to_install->{$version}->{"description"} = \@_desc;
	}
	else
	{
		$package_to_install = $base->get_package_by_path($package);
	}

	my $deps = $package_to_install->{$version}->{"required"};

	foreach my $d (@{$deps}) {
		chomp($d);
		my($n,$v) = split(/ /, $d);
		$self->install_by_version(
			$base->find_package_by_name($n),
			$v
			);
	}
	my($group, $subgroup, $pkg) = split(/\//, $package);
	# my $file = $base->get_server_from_package($package, $version)
	my $file = $package_to_install->{$version}->{"__server"}
		. "/$pkg-$version.lip";

	# und das hauptpacket installieren
	unless($self->option("fake"))
	{
		if($self->_extract_files($version, $file, $package_to_install)) {

			# und in die liste der installierten packete aufnehmen
			$installed_packages->{$group}->{$subgroup}->{$pkg}->{$version} = 
				$package_to_install->{$version};
			$installed_packages->{$group}->{$subgroup}->{$pkg}->{$version}->{"__installed-date"} = 
				time();
			$base->save_installed_packages($installed_packages);
		
			my @new_files_list = $installed_packages->{$group}->{$subgroup}->{$pkg}->{$version}->{"files"};
			my @old_files_list = $installed_packages->{$group}->{$subgroup}->{$pkg}->{$i_version[0]}->{"files"};

			@new_files_list = grep { /^\/FILES\// } @new_files_list;
			@old_files_list = grep { /^\/FILES\// } @old_files_list;

			my @new_files;
			my @old_files;
			foreach my $file (@new_files_list)
			{
				$file =~ m/^\/FILES(.*?)\s/;
				push(@new_files, $file);
			}

			foreach my $file (@old_files_list)
			{
				$file =~ m/^\/FILES(.*?)\s/;
				push(@old_files, $file);
			}


			my @aonly;
			my %seen;

			@seen{@new_files} = ();

			foreach my $item (@old_files)
			{
				push(@aonly, $item) unless exists $seen{$item};
			}

			print "Entferne:\n";
			print Dumper(@aonly);

			# und die ueberlfuessigen dateien loeschen
		
			$self->message("$package successfully updated.\n");
		} else {
			$self->error("error updateing $package");
			return 2;
		}
	}
	else
	{
		$self->warning("Only fake update...\n");
		$installed_packages->{$group}->{$subgroup}->{$pkg}->{$version} = 
			$package_to_install->{$version};
		$installed_packages->{$group}->{$subgroup}->{$pkg}->{$version}->{"__installed-date"} = 
			time();
		$base->save_installed_packages($installed_packages);
		
		$self->message("$package successfully updated.\n");
	}

	return 1;
}



sub _extract_files
{
	my $self = shift;
	my $version = shift;
	my $file = shift;
	my $package = $_[0];
	my @files = @{$package->{$version}->{"files"}};
	my $prefix = $self->param("prefix");
	my($proto, $dummy) = split(/:\/\//, $file);

	$prefix="/" unless($prefix);
	
	if($proto eq "file" or $proto eq "media") {
		$file =~ s/^media:/file:/;
		$file =~ s/^file:\/\///;
	} elsif($proto eq "http" or $proto eq "ftp") {
		my $_b = basename($file);
		unless(-f "$prefix/var/cache/lip/distfiles/$_b") {
			$self->message("downloading $file...   ");
			my $_c = get($file);
			print "done.\n";
			mkdir("$prefix/var/cache/lip/distfiles")
				unless(-d "$prefix/var/cache/lip/distfiles");
			open(FH, ">$prefix/var/cache/lip/distfiles/$_b") or return 1077;
				binmode(FH);
				print FH $_c;
			close(FH);
		}
		$file = "$prefix/var/cache/lip/distfiles/$_b";
	}

	chdir($prefix);
	system("tar xzOf $file files.tgz | tar xz");
	if($? eq "0") {
		return 1;
	} else {
		return 0;
	}
	
}

sub search_file 
{
	my $self = shift;
	my $filename = $self->param("search-file");

	$self->message("Found $filename in: \n\n");

	foreach my $group (keys %{$pkgdb}) {
		foreach my $subgroup (keys %{$pkgdb->{$group}}) {
			foreach my $pkg (keys %{$pkgdb->{$group}->{$subgroup}}) {
				foreach my $ver (keys %{$pkgdb->{$group}->{$subgroup}->{$pkg}}) {
					foreach my $file (@{$pkgdb->{$group}->{$subgroup}->{$pkg}->{$ver}->{"files"}}) {
						if($file =~ m/$filename/i) {
							my @file = split(/\t/, $file);
							$file[0] =~ s/^\/FILES//;
							$self->msg_package("$pkg, $ver ($file[0])\n");
						}
					}
				}
			}
		}
	}
}

sub list_files
{
	my $self = shift;
	my $package = $self->param("list-files");

	my ($group, $subgroup, $pkg) = split(/\//, 
			$base->find_package_by_name($package)); # gibt den pfad
	print "\n";
	$self->msg_package("files in $package\n");

	foreach my $ver (values %{$installed_packages->{$group}->{$subgroup}->{$pkg}}) {
		foreach my $file_row(@{$ver->{"files"}}) {
			my @file_row = split(/\t/, $file_row);
			$file_row[0] =~ s/^\/FILES//;
			print "   " . $file_row[0]."\n";
		}
	}
}

sub policy
{
	my $self = shift;
	my $package = $self->param("policy");

	my ($group, $subgroup, $pkg) = split(/\//, 
			$base->_find_in_i_package_by_name($package)); # gibt den pfad
	print "\n";
	
	
	$self->msg_package("Policy information for $package\n");
	print "\n";
	my $i_package = $base->_find_in_i_package_by_name($package);
	my @i_version = $base->find_in_i_package_version_by_name($package);
	push(@i_version, "none") unless(@i_version);
	my $i_idate = $base->get_installation_date("$group/$subgroup/$pkg/$i_version[0]");
	print "   Package_fullname:	$group/$subgroup/$pkg\n";
	print "   Version_installed:	" . join(", ", @i_version) . "\n" ;
	print "   Install_date:	" . localtime($i_idate) . "\n";

}

sub remove
{
	my $self    = shift;
	my $package = $self->param("remove");
	my @aonly = ();
	$self->message("Trying to remove $package\n");
	$self->message("Checking dependencies...\n");
	my @deps = ();
	my ($pkg, $ver) = split(/\//, $package);
	
	unless($base->check_if_installed($pkg,$ver)) {
		print "\n";
		$self->warning("Sorry but i cannot find $package in my database!\n");
		exit 177;
	}
	# kucken ob eine side by side installation vorliegt
	my @versions = $base->find_in_i_package_version_by_name($pkg);
	my @i_deps = $base->get_all_i_packages_that_require($pkg);
	my @aonly3;
	
	# jetzt alle i_deps durchlaufen und den required string besorgen
	my %package_required = {};
	
	foreach my $s_req (@i_deps)
	{
		my($s_group, $s_subgroup, $s_pkg, $s_ver) = split(/\//, $s_req);
		my $u_pkg = $base->get_in_package_by_path_and_version("$s_group/$s_subgroup/$s_pkg", $s_ver);
		foreach my $t_dep (@{$u_pkg->{"required"}})
		{
			if($t_dep =~ m/$pkg/i)
			{
				$package_required{$s_pkg} = $t_dep;
			}
		}
	}

	my @v_ok = ();
	foreach my $c_pkg (keys %package_required)
	{
		print "\n\npackage: $c_pkg\n";
		print "ueberpruefen auf: " . $package_required{$c_pkg} . "\n";
		print "vorhanden: " . Dumper(@versions);

		push(@v_ok, $base->check_needs($package_required{$c_pkg}, @versions));
	}

	# kucken ob ihrgendwo das zu loeschende packet auftaucht
	foreach my $v_ok (@v_ok)
	{
		if($v_ok eq $ver)
		{
			push(@aonly3, $v_ok);
		}
	}


	unless(@aonly3) {
		print "\n";
		$self->warning("ok seems i am not hurting anything...\n");
		my $count = 0;
		print "\n";
		for($count = 5; $count > 0; $count--) {
			$self->error("$count ", 1);
			sleep 1;
		}
		print $self->error("go ", 1);
		print "\n\n";
		$self->warning("hmm, ok you asked for it, i am going to remove $package NOW!\n");
		my $_path = $base->_find_in_i_package_by_name($pkg);
		my $_pkg = $base->get_in_package_by_path_and_version($_path, $ver);
		my %not_remove = $base->check_files_in_i_packages($_pkg);
		print "\n";
		foreach my $_all (@{$_pkg->{"files"}}) {
			my @_all = split(/\s+/, $_all);
			$_all[0] =~ s/\/FILES//;
			if(-f $_all[0] && !$not_remove{"/FILES".$_all[0]}) 
			{
# hier muss noch die abfrage rein, ob die datei nicht von einem anderen programm
# auch installiert worden ist.
				$self->message("   remove: $_all[0]\n");
				unlink($_all[0]);
			} else
			{
				$self->warning("  Not removing $_all[0] due to side by side installation.\n");
			}
		}
		$base->remove_installed_package_from_db($pkg, $ver);
		$base->save_installed_packages();
	} else {
		print "\n";
		$self->error("Cannot remove package $pkg, $ver.\n");
		print "   some packages need $pkg\n\n";
		foreach my $dep (@aonly3) {
			my $p = $base->_find_in_i_package_by_name($dep);
			my @v = $base->find_in_i_package_version_by_name($dep);
			my ($group, $subgroup, $pack) = split(/\//, $p);
			my $desc = substr($installed_packages->{$group}->{$subgroup}->{$pack}->{$v[0]}->{"description"}, 0, 60)."...";

			print "      ";
			$self->msg_package("$dep, $desc\n");
		}
	}
}

sub search
{
	my $self   = shift;
	my $search = $self->param("search");
	$self->message("Searching $search\n\n");
	foreach my $group (keys %{$pkgdb}) {
		next if($group eq "__global-information");
		foreach my $subgroup (keys %{$pkgdb->{$group}}) {
			foreach my $pkg ( keys
				%{$pkgdb->{$group}->{$subgroup}}
				) {
				if($self->_is_in_pkg($search, %{$pkgdb->{$group}->
							{$subgroup}->{$pkg}})
						|| $pkg =~ m/$search/i) {
					# es wurde was gefunden
					print "$pkg - ";
					my @v = $base->get_versions_from_pkg(
						"$group/$subgroup/$pkg"
							);
					my $d = $pkgdb->{$group}->{$subgroup}->{$pkg}->
							{$v[0]}->{"description"};
					print substr($d, 0, 50);
					print "..." if(length($d)>50);
					print "\n";
				}
			}
		}
	}
	print "\n";
}

sub _is_in_pkg
{
	my $self = shift;
	my $search = shift;
	my $p =  { @_ }; 
	my $desc;
	foreach(keys %{$p}) {
		$desc = $p->{$_}->{"description"};
		if($desc =~ m/$search/i) {
			return 1;
		}
	}
	
	return 0;
}

sub prepend_install
{
	my $self = shift;
	my $package = shift;
	my $version = "";

	$self->message("Prepend install $package\n");
	$package = $base->find_package_by_name($package);

	$self->_prepend_install($package, $version);
}

sub _prepend_install
{
	my $self    = shift;
	my $package = shift;
	my $version = shift;

	my $package_to_install = {};
	my @versions = ();
	my $bin_install = 0;
	my($group, $subgroup, $pkg);
	my $check_version = 1;
	my $bin_pkg = "";
	#soll ein binaer packet direkt installiert werden

	if(-f $self->param("install") && $FROM_DB eq "0")
	{
		$bin_pkg = $self->param("install");
		chomp(@versions = `tar xzOf $bin_pkg VERSION`);
		$bin_install = 1;
	}
	else
	{	
		@versions = $base->get_versions_from_pkg($package);
		($group, $subgroup, $pkg) = split(/\//, $package);
	}

	if(!$version) {
		if(scalar(@versions) > 1) {
			# abfragen welche version installiert werden soll
		} else {
			$version = $versions[0];
		}
		$check_version = 0;
	}


	if($bin_install)
	{
		$package_to_install->{$version}->{"__server"} = "file://".dirname($bin_pkg);
		$package_to_install->{$version}->{"rebuild-url"} = undef;
		my $_prov = `/bin/tar xzOf $bin_pkg PROVIDES`;
		chomp($_prov);
		$package_to_install->{$version}->{"provides"} = $_prov;
		my @_req = `/bin/tar xzOf $bin_pkg REQUIRED`;
		chomp(@_req);
		$package_to_install->{$version}->{"required"} = \@_req;
		my @_files = `/bin/tar xzOf $bin_pkg MANIFEST | grep ^/FILES`;
		chomp(@_files);
		$package_to_install->{$version}->{"files"} = \@_files;
		$package_to_install->{$version}->{"status"} = "-";
		$package_to_install->{$version}->{"md5"} = "";
		my @_desc = `/bin/tar xzOf $bin_pkg DESCRIPTION`;
		chomp(@_desc);
		$package_to_install->{$version}->{"description"} = \@_desc;
	}
	else
	{
		$package_to_install = $base->get_package_by_path($package);
	}

	foreach($base->get_all_deps($version, $check_version, $package_to_install))
	{
		print "\t$_\n";
	}


}


sub prepend_remove
{
	my $self    = shift;
	my $package = $self->param("remove");
	$self->message("Prepend remove $package\n");
}

sub is_installed
{
}

# builds list of packages to be installed
sub build_package_list
{
}

1;

