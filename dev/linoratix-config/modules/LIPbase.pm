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
use LWP::Simple;

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
		$self->add_server() if($self->param("add-server"));
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
			my $_dl = get("$server/packages.cache");
			open(TH, ">$prefix/tmp/lip-tmp.cache") or exit 1070;
				print TH $_dl;
			close(TH);
		} elsif($proto eq "http") {
			system("wget -O /tmp/lip-tmp.cache $server/packages.cache");
		} elsif($proto eq "ftp") {
			system("wget --passive-ftp -O /tmp/lip.cache $server/package.cache");
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
	my $version = shift;
	
	my ($group,$subgroup,$pkg) = split(/\//, $self->_find_in_i_package_by_name($package));
	delete($installed_packages->{$group}->{$subgroup}->{$pkg}->{$version});

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
	$pkgdb = $self->_load_caches();
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

sub find_package_by_name
{
	my $self = shift;
	my $name = shift;
	
	return $self->_find_package_by_name($name);
}

sub _find_package_by_name
{
	my $self = shift;
	my $name = shift;

	foreach my $group (keys %{$pkgdb}) {
		foreach my $subgroup (keys %{$pkgdb->{$group}}) {
			foreach my $pkg ( keys %{$pkgdb->{$group}->{$subgroup}}) {
				if($pkg eq $name) {
					return "$group/$subgroup/$pkg";
				}
			}
		}
	}

	return 0;
}

sub get_package_by_path
{
	my $self = shift;
	my $path = shift;
	my($group, $subgroup, $pkg) = split(/\//, $path);
	return $pkgdb->{$group}->{$subgroup}->{$pkg};
}

sub get_package_deps
{
	my $self = shift;
	my $version = shift;
	my $package = shift;

	return $package->{$version}->{"required"};
}

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
						$do_provide = $pkg;
					}
					if( $do_provide eq $package && $self->_check_version($version,
							$pkgdb->{$group}->{$subgroup}->{$pkg}
						)
					) {
						return $pkgdb->{$group}->{$subgroup}->{$pkg};
					}
				}
			}
		}
	}
	return 0;
}

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
	my ($group, $subgroup, $pkg) = split(/\//, 
			$self->_find_in_i_package_by_name($package)); # gibt den pfad
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
		$do_provide = $package;
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
#							print ">>$d = $package"."\n";
							if($p eq $do_provide) {
								if($self->_check_version($v, $ip->{$group}->{$subgroup}->{$pkg})) {
									push(@needed, $pkg);
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
						$do_provide = $package;
					}
					if($pkg eq $do_provide && $self->_check_version($version,
							$ip->{$group}->{$subgroup}->{$pkg}
						)
					) {
						return $ip->{$group}->{$subgroup}->{$pkg};
					}
				}
			}
		}
	}
	return 0;
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
			$eval = "if(\"$_\" gt \"$version\" || \"$_\" eq \"$version\") { 
					return \"$_\"; 
				}";
		} elsif($vergleich == 2) {
			$eval = "if(\"$_\" lt \"$version\" || \"$_\" eq \"$version\") { 
					return \"$_\"; 
				}";
		} else {
			$eval = "if(\"$_\" $eval\") {
					return \"$_\";
				}";
		}
		if($r = eval($eval)) {
			return $r;
		}
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
	my $version = shift;
	
	return $self->_check_if_installed($package, $version);
}

# checks if a package is alreday installed
sub _check_if_installed
{
	my $self = shift;
	my $package = shift;
	my $version = shift;

	return $self->_find_in_i_package_dep_by_name($package, $version);
}


sub get_in_package_by_path_and_version
{
	my $self = shift;
	my $package = shift;
	my $version = shift;
	my($group, $subgroup, $pkg) = split(/\//, $package);

	return $installed_packages->{$group}->{$subgroup}->{$pkg}->{$version};
}

sub _find_in_i_package_by_name
{
	my $self = shift;
	my $name = shift;
	
	my $ip = $installed_packages;

	foreach my $group (keys %{$ip}) {
		next if($group eq "__global-information");
		foreach my $subgroup (keys %{$ip->{$group}}) {
			foreach my $pkg ( keys %{$ip->{$group}->{$subgroup}}) {
				if($pkg eq $name) {
					return "$group/$subgroup/$pkg";
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
		my $_dl = get("$server/packages.cache");
		open(TH, ">$prefix/tmp/lip-tmp.cache") or exit 1070;
			print TH $_dl;
		close(TH);
	} elsif($proto eq "http") {
		system("wget -O /tmp/lip-tmp.cache $server/packages.cache");
	} elsif($proto eq "ftp") {
		system("wget --passive-ftp -O /tmp/lip.cache $server/package.cache");
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
		mkdir("$prefix/var/cache/lip/ldb/".$proto."__".$dummy2);
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
			$zeile =~ m/^\%name: (.*?)$/;
			if($1 eq $WANTED_PACKAGE)
			{
				chomp($WANTED_PACKAGE_PATH = `pwd`);
				$WANTED_PACKAGE_PATH=~s/$ENV{"PORTS_PATH"}//;
				last;
			}
		}
	}
}

1;
