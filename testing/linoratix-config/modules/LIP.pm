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
	$self->remove() if($self->param("remove") && !$self->option("prepend"));
	$self->policy() if($self->param("policy"));
	$self->list_files() if($self->param("list-files"));
	$self->search() if($self->param("search"));
	$self->search_file() if($self->param("search-file"));
	$self->prepend_install() if($self->option("prepend") && $self->param("install"));
	$self->prepend_remove() if($self->option("prepend") && $self->param("remove"));

	return $self;
}

sub help
{
	my $self = shift;
	
	$self->message("linoratix-config $BASE_VERSION\n");
	$self->message("	module: LIP $MOD_VERSION\n\n");
	print "	--install [package]			install package\n";
	print "	--remove [package/version]			remove package\n";
	print "	--upgrade				upgrades all installed packages to the newest\n						available version.\n";
	print "	--policy [package]			show package policy\n";
	print "	--list-files [package]			list all files of a package\n";
	print "\n";
	print "	--search-file [filename]		search a file in the package db\n";
	print "	--search [string]			search the package db\n";
	print "\n";
	print "	--prepend --install [package]		display which packages we will install\n";
	print "	--prepend --remove [package]		display which packages we will remove\n";
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

	if(!$base->find_in_i_package_dep_by_name($pkg, $version)) {
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
	if(!$package) {
		$package = $base->find_package_by_name($self->param("install"));
	} else {
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
	my @versions = $base->get_versions_from_pkg($package);
	my($group, $subgroup, $pkg) = split(/\//, $package);

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
	
	my $package_to_install = $base->get_package_by_path($package);
	my $deps = $base->get_package_deps($version, $package_to_install);
	foreach my $d (@{$deps}) {
		chomp($d);
		my($n,$v) = split(/ /, $d);
		$self->install_by_version(
			$base->find_package_by_name($n),
			$v
			);
	}
	my($group, $subgroup, $pkg) = split(/\//, $package);
	my $file = $base->get_server_from_package($package, $version)
		. "/$pkg-$version.lip";

	# und das hauptpacket installieren
	if($self->_extract_files($version, $file, $base->get_package_by_path($package))) {

		# und in die liste der installierten packete aufnehmen
		$installed_packages->{$group}->{$subgroup}->{$pkg} = 
			$base->get_package_by_path($package);
		$installed_packages->{$group}->{$subgroup}->{$pkg}->{$version}->{"__installed-date"} = 
			time();
		$base->save_installed_packages($installed_packages);
	
		$self->message("$package successfully installed.\n");
	} else {
		$self->error("error installing $package");
		return 2;
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
			$base->find_package_by_name($package)); # gibt den pfad
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
	$self->message("Trying to remove $package\n");
	$self->message("Checking dependencies...\n");
	my @deps = ();
	my ($pkg, $ver) = split(/\//, $package);
	
	unless($base->check_if_installed($pkg,"=$ver")) {
		print "\n";
		$self->warning("Sorry but i cannot find $package in my database!\n");
		exit 177;
	}
	@deps = $base->check_if_package_is_required_by_installed_package($pkg, $ver);
	unless(@deps) {
		print "\n";
		$self->warning("ok seems i am not hurting anything...\n");
		my $count = 0;
		print "\n";
		for($count = 0; $count < 5; $count++) {
			$self->error("");
			sleep 1;
		}
		print "\n\n";
		$self->warning("hmm, ok you asked for it, i am going to remove $package NOW!\n");
		my $_path = $base->_find_in_i_package_by_name($pkg);
		my $_pkg = $base->get_in_package_by_path_and_version($_path, $ver);
		print "\n";
		foreach my $_all (@{$_pkg->{"files"}}) {
			my @_all = split(/\s+/, $_all);
			$_all[0] =~ s/\/FILES//;
			if(-f $_all[0]) {
# hier muss noch die abfrage rein, ob die datei nicht von einem anderen programm
# auch installiert worden ist.
				$self->warning("   remove: $_all[0]\n");
				unlink($_all[0]);
			}
		}
		$base->remove_installed_package_from_db($pkg, $ver);
		$base->save_installed_packages();
	} else {
		print "\n";
		$self->error("Cannot remove package $pkg, $ver.\n");
		print "   some packages need $pkg\n\n";
		foreach my $dep (@deps) {
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
	my $self    = shift;
	my $package = $self->param("install");
	$self->message("Prepend install $package\n");
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

