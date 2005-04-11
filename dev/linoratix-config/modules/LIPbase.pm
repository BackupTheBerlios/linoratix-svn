#
# Linoratix module to build packages
#

package Linoratix::LIPbase;
use Linoratix;

use strict;
no strict "refs";

use Data::Dumper;
use Cwd;
use File::Basename;
use File::Copy;
use File::Find;
use Storable;
### use LWP::Simple;
use Sort::Versions;

use vars qw(@ISA @EXPORT $MOD_VERSION @COMPATIBLE);
use Exporter;
$MOD_VERSION = "0.0.20";
@COMPATIBLE = qw("0.0.20");
@ISA = qw(Exporter);
@EXPORT = qw(&new);

our $linoratix = Linoratix->new();
our $config;
our $pkgdb = {};
our $installed_packages = {};

our $WANTED_PACKAGE;
our $WANTED_PACKAGE_PATH;

# namespace 1000 - 1100

sub new
{
	my $linoratix = shift;
	my $class     = ref($linoratix) || $linoratix;
	my $self      = { @_ };

	bless($self, $class);
	$self->_read_config_file();
	$pkgdb = $self->load_caches();
	$installed_packages = $self->read_installed_packages();
	if($self->param("plugin") eq "LIPbase") {
		$self->add_server($self->param("add-server")) if($self->param("add-server"));
		$self->check_dep_int() if($self->option("check-deps"));
		$self->update_server() if($self->option("update-server"));
		$self->help() if($self->option("help"));
	}
	return $self;
}

sub help
{
	my $self = shift;
	
	$self->message("linoratix-config $BASE_VERSION\n");
	$self->message("	module: LIPbase $MOD_VERSION\n\n");
	print "	--add-server [server-url]		adds a new server to the package db\n";
	print "	--update-server				update package-db from all registered servers\n";
	print "	--check-deps				checks the package db integrity\n";
	print "\n";
	print "	--help					display help message\n\n";
}

sub update_server
{
	my $self = shift;
	my $servers = $self->get_servers();
	my $prefix  = $self->param("prefix");
	my $pdb     = {};
	my $rdb     = {};
	my $tempdb  = {};
	my $newdb   = {};
	my ($proto,$dummy,$url,$dummy2,$dummy3);
	
	$self->message("Updating server caches...\n");
	$self->message("This may take a while!\n");
	
	foreach my $server (@{$servers}) {
		print "\n";
		$self->message("server: $server\n");
		($proto, $dummy) = split("://", $server);
		$dummy3 = $dummy2 = $dummy;
		if($proto eq "media") {
			print "Insert $server - Media and press enter.\n";
			my $_i   = <STDIN>;
			$server .= "/Linoratix";
			$dummy  .= "/Linoratix";
			system("mount $dummy2");
			$server =~ s/^media:\/\//file:\/\//;
		}
		
		unless($self->_check_server($server)) {
			return 1012;
		}
		$self->message("Checking package dependencies.\n");
# jetzt muss erst die package.cache dem globalen cache temporaer hinzugefuegt werden
#
		$self->message("downloading cache file.\n");

		if($proto eq "media" || $proto eq "file") {
			my $_server = $server;
			$_server =~ s#^media://|file://##;
			copy("$_server/packages.cache", "$prefix/tmp/lip-tmp.cache");
		} elsif($proto eq "http") {
			system("wget -O $prefix/tmp/lip-tmp.cache $server/packages.cache");
		} elsif($proto eq "ftp") {
			system("wget --passive-ftp -O $prefix/tmp/lip.cache $server/package.cache");
		}

		if($proto eq "media") {
			$server =~ s/^file:/media:/;
		}

		$tempdb = retrieve("$prefix/tmp/lip-tmp.cache");
		unlink("$prefix/tmp/lip-tmp.cache");
		foreach my $group (keys %{$tempdb}) {
			next if($group eq "__global-information");
			foreach my $subgroup (keys %{$tempdb->{$group}}) {
				foreach my $pkg ( keys
					%{$tempdb->{$group}->{$subgroup}}
					) {
					foreach my $ver ( keys 
						%{$tempdb->{$group}->{$subgroup}->{$pkg}}
						) {
						$tempdb->{$group}->{$subgroup}->{$pkg}->{$ver}->
							{"__server"} = $server;
					}
					$pkgdb->{$group}->{$subgroup}->{$pkg}
						= $tempdb->{$group}->{$subgroup}->{$pkg};
					$newdb->{$group}->{$subgroup}->{$pkg}
						= $tempdb->{$group}->{$subgroup}->{$pkg};
				}
			}
		}

		if($self->check_dep_int()) {
			$self->message("Server succesfully updated.\n");
			# server cache datei speichern
			$dummy2 =~ s:/:_:g;
			if(-f "$prefix/var/cache/lip/ldb/".$proto."__".$dummy2."/packages.cache") {
				unlink("$prefix/var/cache/lip/ldb/".$proto."__".$dummy2."/packages.cache");
			}
			store($newdb, "$prefix/var/cache/lip/ldb/".$proto."__".$dummy2."/packages.cache");
			open(FH, ">$prefix/var/cache/lip/ldb/".$proto."__".$dummy2."/server.name") 
				or return 1051;
				print FH $server;
			close(FH);
#return 1011;
		} else {
# @todo: remove server by update failure
			$self->error("Unresolved dependencies!\n");
			$self->error(">>> TODO: Server ~removed~ from server list.\n\n");
			return 1013;
		}
		if($proto eq "media") {
			system("umount $dummy3");
		}

	}

	return 1;
}

# installiertes packet aus der db loeschen

sub remove_installed_package_from_db
{
	my $self = shift;
	my $package = shift;
	
	my ($group,$subgroup,$pkg,$ver) = split(/\//, $package);
	delete($installed_packages->{$group}->{$subgroup}->{$pkg}->{$ver});

	return 1; # alles ok
}

sub read_installed_packages
{
	my $self = shift;
	my $p = {};
	my $prefix = $self->param("prefix");
	if(-f "$prefix/var/cache/lip/ldb/installed.cache") {
		$p = retrieve("$prefix/var/cache/lip/ldb/installed.cache");
	}
	
	return $p;
}

sub save_installed_packages
{
	my $self = shift;
	my $p    = $_[0];
	my $prefix = $self->param("prefix");

	$installed_packages = $p if($p);
	store($installed_packages, "$prefix/var/cache/lip/ldb/installed.cache");
}

sub load_caches
{
	my $self = shift;
	
	my $virtual = shift;
	if($virtual)
	{
		$pkgdb = retrieve($virtual);
	}
	else
	{
		$pkgdb = $self->_load_caches();
	}
	return $pkgdb;
}

# alle packete in ein grosses array laden
# das man dann durchwandern kann
# load all available caches
sub _load_caches
{
	my $self    = shift;
	my $servers = $self->get_servers();
	my $pdb     = {};
	my $rdb     = {};
	my ($proto,$dummy,$url);
	my $prefix = $self->param("prefix");

	foreach (@{$servers}) {
		($proto, $dummy) = split("://");
#		if($proto eq "file") {
			$dummy =~ s:/:_:g;
			$pdb = retrieve("$prefix/var/cache/lip/ldb/".$proto."__".$dummy.
					"/packages.cache");
			foreach my $group (keys %{$pdb}) {
				next if($group eq "__global-information");
				foreach my $subgroup (keys %{$pdb->{$group}}) {
					foreach my $pkg ( keys
						%{$pdb->{$group}->{$subgroup}}
						) {
						$rdb->{$group}->{$subgroup}->
						   {$pkg} = $pdb->{$group}->
						   {$subgroup}->{$pkg};
					}
				}
			}
	
#		} else {
#			$self->warning("The protocol '$proto' is not implemented yet.\n\n");
#		}
	}
	return $rdb;
}

# check dependencie integrity
sub check_dep_int
{
	my $self = shift;
	$self->message("Checking package-db integrity.\n");
	return $self->_check_all_pkgs_deps();
}

# liefert 0 oder 1 zurueck
sub _check_all_pkgs_deps
{
	my $self = shift;
	my $server = $self->get_servers();
	my ($proto,$dummy,$url);
	my @deps = ();
	my $unres = 1; my $ap = 1;

	# http und andere methoden muessen noch implementiert werden
	# da in $all_pkgs jetzt alles drin steht wird es durchlaufen
	foreach my $group (keys %{$pkgdb}) {
		foreach my $subgroup (keys %{$pkgdb->{$group}}) {
			foreach my $pkg ( keys 
					%{$pkgdb->{$group}->{$subgroup}}) {
				@deps = $self->_get_deps_from_pkg(
					$group.
					"/".$subgroup.
					"/".$pkg);
				# ab hier haben wir die 
				# abhaengikeiten des jeweiligen
				# packets. jetzt wird geprueft
				# ob diese deps auch geloest werden
				# koennen.
				my @unresdeps = $self->_can_resolv_deps(@deps);
				if(@unresdeps) {
					if($ap) {
						$self->error("unresolved");
						print " dependencies:\n";
						$ap = 0;
					}
					print "	PACKAGE: $pkg\n";
					print "		NEED:\n";
					foreach (@unresdeps) {
						print "			$_\n";
					}
					print "\n";
					$unres = 0;
				}
			}
		}
	}
	return $unres;
}

# check wether the dependecies are ok
sub _can_resolv_deps
{
	my $self = shift;
	my ($pkgname, $pkgversion, $striped_version);
	my @return_list = ();
	
	foreach(@_) {
		($pkgname, $pkgversion) = split(/ /);
		if(!$self->_find_package_dep_by_name($pkgname, $pkgversion)) {
			push(@return_list, $_);
		}
	}
	return @return_list;
}

# sucht nach einem packet namesn $name und version $version
# in den verfuegbaren packeten
sub find_package_by_name_and_version
{
	my $self = shift;
	my $name = shift;
	my $version = shift;
	
	return $self->_find_package_by_name_and_version($name, $version);
}

sub _find_package_by_name_and_version
{
	my $self = shift;
	my $name = shift;
	my $version = shift;
	my $provide = "";
	my $do_provide = "";
	
	foreach my $group (keys %{$pkgdb}) {
		foreach my $subgroup (keys %{$pkgdb->{$group}}) {
			next
				if($subgroup eq "cache-version"
					|| $subgroup eq "cache-compatible");
			foreach my $pkg ( keys %{$pkgdb->{$group}->{$subgroup}}) {
				foreach my $ver (keys %{$pkgdb->{$group}->{$subgroup}->{$pkg}}) {
					$provide = $pkgdb->{"$group"}->{"$subgroup"}->{"$pkg"}->{"$ver"}->{"provides"};
					if($provide)
					{
						$do_provide = $provide;
					}
					else
					{
						$do_provide = ""; #$pkg;
					}
					if($ver eq $version && ($do_provide eq $name || $pkg eq $name)) {
						return "$group/$subgroup/$pkg/$ver";
					}
				}
			}
		}
	}

	my $installed_p = $self->_find_in_i_package_by_name_and_version($name."/".$version);
	return $installed_p if($installed_p);

	return 0;
}

# uebergabe: pfade
# es kommt nen hash zurueck der das packet enthaellt
sub get_package_by_path
{
	my $self = shift;
	my $path = shift;
	my($group, $subgroup, $pkg, $ver) = split(/\//, $path);
	$pkgdb->{$group}->{$subgroup}->{$pkg}->{$ver}->{"version"} = $ver;
	return $pkgdb->{$group}->{$subgroup}->{$pkg}->{$ver};
}

# dependencies aus packet (hash) und version (string) holen
sub get_package_deps
{
	my $self = shift;
	my $version = shift;
	my $package = shift;

	return $package->{$version}->{"required"};
}

# @strange
# uebergabe: string, packetname
# uebergabe: string, version
# kuckt ob das packete ($package) die versionsanforderung von ($version) erfuellt
# zurueckgegeben werden die packete die es giebt von dem packet (also alle versionen...)
sub find_package_dep_by_name
{
	my $self = shift;
	my $package = shift;
	my $version = shift;

	return $self->_find_package_dep_by_name($package, $version);
}

# returns the package-hash
sub _find_package_dep_by_name
{
	my $self = shift;
	my $package = shift;
	my $version = shift;
	foreach my $group (keys %{$pkgdb}) {
		foreach my $subgroup (keys %{$pkgdb->{$group}}) {
			foreach my $pkg ( keys %{$pkgdb->{$group}->{$subgroup}}) {
				# wir muessen auch auf provides ueberpruefen
				foreach my $ver (keys %{$pkgdb->{$group}->{$subgroup}->{$pkg}}) {
					my $provides = $pkgdb->{$group}->{$subgroup}->{$pkg}->{$ver}->{"provides"};
					my $do_provide = "";
					if($provides)
					{
						$do_provide = $provides;
					}
					else
					{
						$do_provide = ""; # $pkg;
					}
					if( ($do_provide eq $package || $pkg eq $package)  && $self->_check_version($version,
							$pkgdb->{$group}->{$subgroup}->{$pkg}
						)
					) {
						return $pkgdb->{$group}->{$subgroup}->{$pkg}->{$ver};
					}
				}
			}
		}
	}
	return 0;
}

# das gleiche fuer installierte packete
sub find_in_i_package_dep_by_name
{
	my $self = shift;
	my $package = shift;
	my $version = shift;

	return $self->_find_in_i_package_dep_by_name($package, $version);
}

# installierte packetversion holen
sub find_in_i_package_version_by_name
{
	my $self = shift;
	my $package = shift;
	my @versions = ();
	my ($group, $subgroup, $pkg) = split(/\//, $package);

	foreach my $ver ( sort keys %{$installed_packages->{$group}->{$subgroup}->{$pkg}}) {
		push(@versions, $ver);
	}

	return @versions;
}

# liefert das installationsdatum
sub get_installation_date
{
	my $self = shift;
	my ($group, $subgroup, $pkg, $version) = split(/\//, $_[0]);
	return $installed_packages->{$group}->{$subgroup}->{$pkg}->{$version}->{"__installed-date"};
}

# kucken ob packet von einem installiertem packet benoetigt wird
sub check_if_package_is_required_by_installed_package
{
	my $self = shift;
	my $package = shift;
	my $version = shift;
	my $ip = $installed_packages;
	my @needed = ();
	
	my $pkg_to_remove_path = $self->find_package_by_name($package);
	my $pkg_to_remove = $self->get_package_by_path($pkg_to_remove_path);
	my $provide = $pkg_to_remove->{$version}->{"provides"};
	my $do_provide = "";
	if($provide)
	{
		$do_provide = $provide;
	}
	else
	{
		$do_provide = ""; #$package;
	}

	foreach my $group (keys %{$ip}) {
		next if($group eq "__global-information");
		foreach my $subgroup (keys %{$ip->{$group}}) {
			foreach my $pkg ( keys %{$ip->{$group}->{$subgroup}}) {
				foreach my $ver ( keys %{$ip->{$group}->{$subgroup}->{$pkg}}) {
						my $deps = $self->get_package_deps($ver, 
							$ip->{$group}->
						{$subgroup}->{$pkg});
						foreach my $d(@{$deps}) {
							my($p,$v) = split(/ /, $d);
							# kucken ob provides da ist
							if($p eq $do_provide || $p eq $package) {
								if($self->_check_version($v, $ip->{$group}->{$subgroup}->{$pkg})) {
									push(@needed, [$pkg, $ver]);
								}
							}
						}
				}
			}
		}
	}
	return @needed;
}

# suchen in installierten packeten
# hier wird gekuckt ob das packet + version installiert ist
# und ob es die verlangte version hat!
# @return packet hash
sub _find_in_i_package_dep_by_name
{
	my $self = shift;
	my $package = shift;
	my $version = shift;
	my $ip = $installed_packages;
	foreach my $group (keys %{$ip}) {
		next if($group eq "__global-information");
		foreach my $subgroup (keys %{$ip->{$group}}) {
			foreach my $pkg ( keys %{$ip->{$group}->{$subgroup}}) {
				foreach my $ver (keys %{$ip->{$group}->{$subgroup}->{$pkg}})
				{
					my $provide = $ip->{$group}->{$subgroup}->{$pkg}->{$ver}->{"provides"};
					my $do_provide = "";
					if($provide)
					{
						$do_provide = $provide;
					}
					else
					{
						$do_provide = ""; # $package;
					}
					
					if(($package eq $do_provide || $package eq $pkg) && $self->_check_version($version,
							$ip->{$group}->{$subgroup}->{$pkg}
						)
					) {
						print "\npackage: $package\n";
						print "do_provide: $do_provide\n";
						print "provide: $provide\n";
						print "pkg: $pkg\n";
						print "version: $version\n";
						print "group: $group\n";
						print "subgroup: $subgroup\n";

						return $ip->{$group}->{$subgroup}->{$pkg}->{$ver};
					}
				}
			}
		}
	}
	return 0;
}

# 1. benoetigte version (>=2.3.4)
# 2. verfuegbare version
sub _check_version_vs_version
{
	my $self = shift;
	my $want_version = shift;
	my $avail_version = shift;

	my $vergleich;
	my $eval;

	if($want_version =~ m/^\>=/) {
		$want_version =~ s/^\>=//;
		$vergleich = 1;
	} elsif($want_version =~ m/^\<=/) {
		$want_version =~ s/^\<=//;
		$vergleich = 2;
	} elsif($want_version =~ m/^\>/) {
		$want_version =~ s/^\>/gt \"/;
		$eval = $want_version
	} elsif($want_version =~ m/^\</) {
		$want_version =~ s/^\</lt \"/;
		$eval = $want_version;
	} elsif($want_version =~ m/^=/) {
		$want_version =~ s/^=/eq \"/;
		$eval = $want_version;
	}

	if($vergleich == 1) {
		print "      check_v_vs_v: $want_version => $avail_version\n";
		my $c = $self->_compare_versions($want_version, $avail_version);
		print "      erg: $c\n";	
		if($c == 1 || $c == 2)
		{
			return $avail_version;
		}
		else
		{
			return 0;
		}
		
	} elsif($vergleich == 2) {
		my $c = $self->_compare_versions($avail_version, $want_version);
		if($c == 1 || $c == 2)
		{
			return $avail_version;
		}
		else
		{
			return 0;
		}
	} else {
		return $avail_version;
	}
}
# uebergabe wenn ich das richtig sehe
# version die das zu installierende packet verlangt und dann das 
# installierte packet
sub _check_version
{
	my $self = shift;
	my $version = shift;
	my $package = $_[0];
	my $eval;
	my $vergleich;
	my $r;


	# rausbekommen ob groesser, kleiner, ...
	if($version =~ m/^\>=/) {
		$version =~ s/^\>=//;
		$vergleich = 1;
	} elsif($version =~ m/^\<=/) {
		$version =~ s/^\<=//;
		$vergleich = 2;
	} elsif($version =~ m/^\>/) {
		$version =~ s/^\>/gt \"/;
		$eval = $version
	} elsif($version =~ m/^\</) {
		$version =~ s/^\</lt \"/;
		$eval = $version;
	} elsif($version =~ m/^=/) {
		$version =~ s/^=/eq \"/;
		$eval = $version;
	}

	foreach (keys %{$package}) {
		if($vergleich == 1) {
			my $c = $self->_compare_versions($version, $_);
			#$eval = "if(\"$_\" gt \"$version\" || \"$_\" eq \"$version\") { 
			#		return \"$_\"; 
			#	}";

			if($c == 1 || $c == 2)
			{
				return $_;
			}
			else
			{
				return 0;
			}
			
		} elsif($vergleich == 2) {
			my $c = $self->_compare_versions($_, $version);
			if($c == 1 || $c == 2)
			{
				return $_;
			}
			else
			{
				return 0;
			}
	
		#	$eval = "if(\"$_\" lt \"$version\" || \"$_\" eq \"$version\") { 
		#			return \"$_\"; 
		#		}";
		} else {

			$eval = "if(\"$_\" $eval\") {
					return \"$_\";
				}";
		}
		if($r = eval($eval)) {
			return $r;
		}
		else
		{
			print "hmm... $eval :: ".print(eval($eval))."\n @!\n $!\n";
		}
	}
	return 0;
}

# wenn die 2. "zahl" groesser ist kommt 1 zurueck
#  wenn sie gleich sind kommt 2 zurueck
#  wenn zahl 1 groesser ist kommt 0
sub _compare_versions
{
	my $self = shift;
	my $v1 = shift;
	my $v2 = shift;


#	my @vall = ();
#	$v1 = "2.3.4-r1";
#	$v2 = "2.3.4";

#	push(@vall, $v1, $v2);

#	my @erg = sort versions @vall;
	#print "\n#########\nv1: $v1, v2: $v2\n" . Dumper(@erg) . "\n##########\n";

	print "         compare: $v1 => $v2\n";
#	print "            1: $erg[0]\n";
#	print "            2: $erg[1]\n";
#	print Dumper(@erg);

	return 1 if versioncmp($v2, $v1)==1;
	return 2 if versioncmp($v2, $v1)==0;
	return 0 if versioncmp($v2, $v1)==-1;

#	return 2 if($v1 eq $v2);
#	return 1 if($erg[1] eq $v2);
#	return 0 if($erg[1] eq $v1);
}

sub blub
{
	my $self = shift;
	my $v1 = "2.3.4-r1";
	my $v2 = "2.3.4";

	print "groesser" if versioncmp($v1, $v2)==1;
}

# wenn die 2. "zahl" groesser ist kommt 1 zurueck
#  wenn sie gleich sind kommt 2 zurueck
#  wenn zahl 1 groesser ist kommt 0
# @deprecated! das machen wir jetzt mit Sort::Versions...
sub _compare_versions__deprecated
{
	my $self = shift;
	my $i = 0;
	my $v1 = shift;
	my $v2 = shift;

	if($v1 eq $v2) { return 2; }

	$v1 =~ s/-(.*?)$//;
	my $m1 = $1;
	$v2 =~ s/-(.*?)$//;
	my $m2 = $1;

	my @d1_maj = split(/\./, $v1);
	my @d2_maj = split(/\./, $v2);

	my $iterations_maj = 0;

	if(scalar(@d1_maj) >= scalar(@d2_maj))
	{
		$iterations_maj = scalar(@d1_maj);
	}
	else
	{
		$iterations_maj = scalar(@d2_maj);
	}


	for($i = 0; $i < $iterations_maj; $i++)
	{
		if($d1_maj[$i] < $d2_maj[$i])
		{
			return 1;
		}
	}

	if(unpack("C", $m1) < unpack("C", $m2))
	{
		return 1;
	}

	return 0;

}

sub get_deps_from_pkg
{
	my $self = shift;
	my $package = shift;

	return $self->_get_deps_from_pkg($package);
}

# returns the package dependencies
sub _get_deps_from_pkg
{
	my $self = shift;
	my $package = shift;
	my ($group, $subgroup, $pkg) = split(/\//, $package);	
	my @versions = $self->_get_versions_from_pkg($package);
	my @deps = ();
	foreach my $v (@versions) {
		foreach(@{$pkgdb->{$group}->{$subgroup}->{$pkg}->{$v}->{"required"}}) {
			chomp;
			push(@deps, $_);
		}
	}
	return @deps;
}

sub check_if_installed
{
	my $self = shift;
	my $package = shift;
	
	return $self->_check_if_installed($package);
}

# checks if a package is alreday installed
sub _check_if_installed
{
	my $self = shift;
	my $package = shift;
	
	my($group, $subgroup, $pkg, $ver) = split(/\//, $package);
	if($installed_packages->{$group}->{$subgroup}->{$pkg}->{$ver})
	{
		return 1;
	} else
	{
		return 0;
	}
}


sub get_in_package_by_path
{
	my $self = shift;
	my $package = shift;
	my($group, $subgroup, $pkg, $ver) = split(/\//, $package);

	return $installed_packages->{$group}->{$subgroup}->{$pkg}->{$ver};
}


sub find_in_i_package_by_name
{
	my $self = shift;
	my $name = shift;
	my ($provide, $do_provide);
	
	my $ip = $installed_packages;
	my($group, $subgroup, $pkg) = split(/\//, $name);

	foreach my $ver (keys %{$ip->{$group}->{$subgroup}->{$pkg}}) {
		$provide = $ip->{"$group"}->{"$subgroup"}->{"$pkg"}->{"$ver"}->{"provides"};
		if($provide)
		{
			$do_provide = $provide;
		}
		else
		{
			$do_provide = ""; #$pkg;
		}
		if($do_provide eq $name || $pkg eq $name)
		{
			return "$group/$subgroup/$pkg";
		}
	}

	return 0;
}


sub find_in_i_package_by_name_and_version
{
	my $self = shift;
	my $name = shift;
	my $version = shift;

	return $self->_find_in_i_package_by_name_and_version($name, $version);
}

sub _find_in_i_package_by_name_and_version
{
	my $self = shift;
	my $name = shift;
	my $version = shift;
	my ($provide, $do_provide);
	
	my $ip = $installed_packages;

	foreach my $group (keys %{$ip}) {
		next if($group eq "__global-information");
		foreach my $subgroup (keys %{$ip->{$group}}) {
			foreach my $pkg ( keys %{$ip->{$group}->{$subgroup}}) {
				foreach my $ver (keys %{$ip->{$group}->{$subgroup}->{$pkg}}) {
					$provide = $ip->{"$group"}->{"$subgroup"}->{"$pkg"}->{"$ver"}->{"provides"};
					if($provide)
					{
						$do_provide = $provide;
					}
					else
					{
						$do_provide = ""; #$pkg;
					}
					if($ver eq $version && ($do_provide eq $name || $pkg eq $name)) {
						return "$group/$subgroup/$pkg/$ver";
					}
				}
			}
		}
	}

	return 0;
}

sub ___find_in_i_package_by_name_and_version
{
	my $self = shift;
	my $name = shift;
	my $version = shift;

	my $ip = $installed_packages;

	foreach my $group (keys %{$ip}) {
		next if($group eq "__global-information");
		foreach my $subgroup (keys %{$ip->{$group}}) {
			foreach my $pkg ( keys %{$ip->{$group}->{$subgroup}}) {
				if($pkg eq $name) {
					foreach my $ver ( keys %{$ip->{$group}->{$subgroup}->{$name}} )
					{
						if($ver eq $version)
						{
							return "$group/$subgroup/$pkg/$ver";
						}
					}

					return 0;
				}
			}
		}
	}

	return 0;
}

# returns all available versions of a package
# hier wird der pfad uebergeben!
sub get_versions_from_pkg
{
	my $self = shift;;
	my $package = shift;

	return $self->_get_versions_from_pkg($package);
}

# returns all available versions of a package
sub _get_versions_from_pkg
{
	my $self = shift;
	my $package = shift;
	my @versions = ();
	my ($group, $subgroup, $pkg) = split(/\//, $package);	
	foreach(keys %{$pkgdb->{$group}->{$subgroup}->{$pkg}}) {
		push(@versions, $_);
	}

	return @versions;
}

sub get_in_versions_from_pkg
{
	my $self = shift;
	my $package = shift;
	my @versions = ();
	my ($group, $subgroup, $pkg) = split(/\//, $package);	
	foreach(keys %{$installed_packages->{$group}->{$subgroup}->{$pkg}}) {
		push(@versions, $_);
	}

	return @versions;
}

sub _read_config_file
{
	my $self = shift;
	my $prefix = $self->param("prefix");
	if(-f "$prefix/etc/conf.d/linoratix-config.conf") {
		$config = retrieve("$prefix/etc/conf.d/linoratix-config.conf");
	}
}

sub _save_config_file
{
	my $self = shift;
	my $prefix = $self->param("prefix");
	store($config, "$prefix/etc/conf.d/linoratix-config.conf");
}


sub get_server_from_package
{
	my $self = shift;
	my $path = shift;
	my $version = shift;

	return $self->_get_server_from_package($path, $version);
}

sub _get_server_from_package
{
	my $self = shift;
	my $path = shift;
	my $version = shift;
	
	my $package = $self->get_package_by_path($path);
	return $package->{$version}->{"__server"};
}

# get all servers from the config
sub get_servers
{
	my $self = shift;

	return $config->{"plugin"}->{"LIP"}->{"server"};
}

# add a package-server to the config

sub add_server
{
	my $self = shift;
	my $server = shift;
	my $newdb = {};
	my $prefix = $self->param("prefix");
	my $tempdb;
	my $server2;
	my ($dummy2, $dummy3);
	
	$self->message("Adding server: $server\n");
	
	$server = $self->param("add-server") unless($server); 
	my  ($proto, $dummy) = split("://", $server);
	$server2 = $server;
	$dummy3 = $dummy2 = $dummy;
	if($proto eq "media") {
		print "Insert $server - Media and press enter.\n";
		my $_i = <STDIN>;
		system("mount $dummy2");
		$server .= "/Linoratix";
		$dummy  .= "/Linoratix";
		$server  =~ s/^media:\/\//file:\/\//;
	}
	
	unless($self->_check_server($server)) {
		return 1012;
	}
	$self->message("Checking package dependencies.\n");
	push(@{$config->{"plugin"}->{"LIP"}->{"server"}}, $server2);
# jetzt muss erst die package.cache dem globalen cache temporaer hinzugefuegt werden
#
	$self->message("downloading cache file.\n");
	if($proto eq "media" || $proto eq "file") {
		my $_server = $server;
		$_server =~ s#^media://|file://##;
		copy("$_server/packages.cache", "$prefix/tmp/lip-tmp.cache");
	} elsif($proto eq "http") {
		system("wget -O $prefix/tmp/lip-tmp.cache $server/packages.cache");
	} elsif($proto eq "ftp") {
		system("wget --passive-ftp -O $prefix/tmp/lip.cache $server/package.cache");
	}
	if($proto eq "media") {
		$server =~ s/^file:/media:/;
	}

	$tempdb = retrieve("$prefix/tmp/lip-tmp.cache");
	unlink("$prefix/tmp/lip-tmp.cache");
	foreach my $group (keys %{$tempdb}) {
		next if($group eq "__global-information");
		foreach my $subgroup (keys %{$tempdb->{$group}}) {
			foreach my $pkg ( keys
				%{$tempdb->{$group}->{$subgroup}}
				) {
				foreach my $ver ( keys 
					%{$tempdb->{$group}->{$subgroup}->{$pkg}}
					) {
					$tempdb->{$group}->{$subgroup}->{$pkg}->{$ver}->
						{"__server"} = $server;
				}
				$pkgdb->{$group}->{$subgroup}->{$pkg}
					= $tempdb->{$group}->{$subgroup}->{$pkg};
				$newdb->{$group}->{$subgroup}->{$pkg}
					= $tempdb->{$group}->{$subgroup}->{$pkg};
			}
		}
	}

	if($self->check_dep_int()) {
		$self->message("Server succesfully added.\n");
		$self->_save_config_file();
		# server cache datei speichern
		$dummy2 =~ s:/:_:g;
		mkdir("$prefix/var/cache/lip/ldb/".$proto."__".$dummy2) or die($!);
		if(-f "$prefix/var/cache/lip/ldb/".$proto."__".$dummy2."/packages.cache") {
			unlink("$prefix/var/cache/lip/ldb/".$proto."__".$dummy2."/packages.cache");
		}
		store($newdb, "$prefix/var/cache/lip/ldb/".$proto."__".$dummy2."/packages.cache");
		open(FH, ">$prefix/var/cache/lip/ldb/".$proto."__".$dummy2."/server.name") 
			or return 1051;
			print FH $server;
		close(FH);
		return 1011;
	} else {
		$self->error("Unresolved dependencies!\n");
		$self->error("Server ~not~ added to server list.\n\n");
		return 1013;
	}
	if($proto eq "media") {
		system("umount $dummy3");
	}
}




# checks if a server is a valid package-server
sub _check_server
{
	my $self = shift;
	my $server = shift;

	my  ($proto, $dummy) = split("://", $server);
	
	if($proto eq "file") {
		if(-f "$dummy/packages.cache") {
			return 1;
		} else {
			$self->warning("The server '$server' is not valid.\n");
		}
	} elsif($proto eq "http" || $proto eq "ftp") {
		system("HEAD $server/packages.cache");
		if($?) {
			$self->warning("The server '$server' is not valid.\n");
		} else {
			return 1;
		}
	} else {
		$self->warning("The protocol '$proto' is not implemented yet.\n");
		print "\n";
	}

	return 0;
}

sub find_package_path_in_ports
{
	my $self = shift;
	$WANTED_PACKAGE = shift;
	find(\&get_name_from_rebuild, $ENV{"PORTS_PATH"});
	return $WANTED_PACKAGE_PATH;
}

sub get_name_from_rebuild
{
	my @inhalt;
	if(/^REBUILD$/)
	{
		open(FH, "<REBUILD");
		chomp(@inhalt = <FH>);
		close(FH);
		foreach my $zeile (@inhalt)
		{
			$zeile =~ m/^\%(name|provides): (.*?)$/;
			if($2 eq $WANTED_PACKAGE)
			{
				chomp($WANTED_PACKAGE_PATH = `pwd`);
				$WANTED_PACKAGE_PATH=~s/$ENV{"PORTS_PATH"}//;
				last;
			}
		}
	}
}

sub get_all_deps
{
	my $self = shift;
	my $version = shift;
	my $check_version = shift;
	my $package_to_install = shift;
	my @ret_p = ();

	if($version && $check_version)
	{
		$version = $self->_check_version($version, $package_to_install);
	}


	my $deps = $package_to_install->{$version}->{"required"};
	foreach my $d (@{$deps}) 
	{
		chomp($d);
		my($n,$v) = split(/ /, $d);
		#push(@ret_p, "$n-$v");
		push(@ret_p, $self->get_all_deps($v, 1, $self->get_package_by_path($self->find_package_by_name($n))));
	}

	push(@ret_p, $package_to_install->{$version}->{"name"} . "|" . $version);

	my %uniq = ();
	@ret_p = grep { ! $uniq{$_} ++ } @ret_p;
	return @ret_p;
}

# alle packete (installierten) zurückliefern die $package benoetigen
sub get_all_i_packages_that_require
{
	my $self = shift;
	my $package = shift;

	my @req_p = ();
	
	my $ip = $installed_packages;

	foreach my $group (keys %{$ip}) {
		next if($group eq "__global-information");
		foreach my $subgroup (keys %{$ip->{$group}}) {
			foreach my $pkg ( keys %{$ip->{$group}->{$subgroup}}) {
				foreach my $ver ( keys %{$ip->{$group}->{$subgroup}->{$pkg}} )
				{ 
					foreach my $req ( @{$ip->{$group}->{$subgroup}->{$pkg}->{$ver}->{"required"}} )
					{
						if($req =~ m/$package/i)
						{
							push(@req_p, "$group/$subgroup/$pkg/$ver");
						}
					}
				}
			}
		}
	}
	
	return @req_p;
}

# kucken ob $package mit einer der versionen laufen kann
sub check_needs
{
	my $self = shift;
	my $package = shift;
	my @deinstall_package_versions = @_;

	my @s_v;
	
	my ($p_name, $p_ver) = split(/ /, $package);
	
	my @versions_ok = ();
	
	foreach my $version (@deinstall_package_versions)
	{
		print "   checke: $p_ver => $version\n";
		my $check_ret = $self->_check_version_vs_version($p_ver, $version);
		if($check_ret)
		{
			push(@versions_ok, $check_ret);
		}
		@s_v = sort versions @versions_ok;
	}
	return $s_v[-1];
}

# kuckt in welchem packet die dateien noch drin sind.
sub check_files_in_i_packages
{
	my $self = shift;
	my $package = shift;

	my $files = $package->{"files"};

	my $ip = $installed_packages;
	my @all_files; # ohne ruecksicht asuf den arbeitsspeicher ;-)
	my %req_p;
	my @r_file;
	my @i_file;

	foreach my $group (keys %{$ip}) {
		next if($group eq "__global-information");
		foreach my $subgroup (keys %{$ip->{$group}}) {
			foreach my $pkg ( keys %{$ip->{$group}->{$subgroup}}) {
				print ">> ".$pkg."\n";
				foreach my $ver ( keys %{$ip->{$group}->{$subgroup}->{$pkg}} )
				{ 
					next if ($pkg eq $package->{"name"} && $ver eq $package->{"version"});
					push @all_files, @{$ip->{$group}->{$subgroup}->{$pkg}->{$ver}->{"files"}};
				}
			}
		}
	}

	my @f_p2;
	my @x;
	my %f_p2;
	foreach my $x (@all_files)
	{
		@x = split(/\s/, $x);
		$f_p2{$x[0]} = 1;
	}

	my @if_p2;
	my @y;
	foreach my $y (@{$files})
	{
		@y = split(/\s/, $y);
		push @if_p2, $y[0];
	}
	
	foreach my $if ( @if_p2 )
	{
		if ( $f_p2{$if} )
		{
			$req_p{$if} = 1;
		}
	}

	return %req_p;
}


# bestes verfuegbares packet holen
# uebergabe 1: packetname (pfad)
# uebergabe 2: version (>=2.5, <2.3, ...)
# @return hash packet
sub get_best_version_available
{
	my $self = shift;
	my $package = shift;
	my $version = shift;
	my @avail_v = ();

	print "package: $package\n";
	print "version: $version\n";
	print "\n";

	my($group, $subgroup, $pkg) = split(/\//, $package);

	foreach my $ver (keys %{$pkgdb->{$group}->{$subgroup}->{$pkg}})
	{
		if($self->_check_version_vs_version($version, $ver))
		{
			push(@avail_v, $ver);
		}
	}

	my @sorted = sort { versioncmp($a, $b) } @avail_v;

	return $self->get_package_by_path("$package/" . $sorted[-1]);
}

1;
