#
# Linoratix module to build packages
#

package Linoratix::LIPdev;
use Linoratix;

use strict;
no strict "refs";

use Data::Dumper;
use Cwd;
use File::Basename;
use File::Copy;
use Storable;

use Linoratix::LIPbase;

use vars qw(@ISA @EXPORT $MOD_VERSION @COMPATIBLE);
use Exporter;
$MOD_VERSION = "0.0.20";
@COMPATIBLE = qw("0.0.20");
@ISA = qw(Exporter);
@EXPORT = qw(&new);

our $compile_dir;
our $start_date;
our $files;
our $REBUILD_LINE=0;
our $CONFIGURE_PATH=".";

our $base;
our $bin_dir;
our $installed_packages;

# namespcae 300 - 399

sub new
{
	my $linoratix = shift;
	my $class     = ref($linoratix) || $linoratix;
	my $self      = { @_ };

	bless($self, $class);

	$base = Linoratix::LIPbase->new();

	$self->get_installed_packages();
	
	$self->{"path"} = getcwd();

	$bin_dir = $self->param("bin-dir");

	$self->help() if($self->option("help"));
	$self->read_spec_file() if($self->param("rebuild"));
	$self->mkcd() if ($self->param("mkcd"));
#	$self->create_bin_lip() if($self->param("bin-dir"));
	$self->build_package_cache() if($self->param("rebuild-package-cache"));
	$self->read_spec_file($ENV{"PORTS_PATH"}."/".$self->param("ports-build")) if($self->param("ports-build"));

	return $self;
}

sub get_installed_packages
{
	my $self = shift;
	$self->message("Retrieving information for installed packages...   ");
	if(-f $self->param("prefix") . "/var/cache/lip/installed_packages.cache") {
		$installed_packages = retrieve($self->param("prefix") . "/var/cache/lip/installed_packages.cache");
	}
	
print "done.\n";
}

sub help
{
	my $self = shift;
	
	$self->message("linoratix-config $BASE_VERSION\n");
	$self->message("	module: LIPdev $MOD_VERSION\n\n");
	print "	--rebuild <package> [--spec buildfile]	rebuild a Linoratix package from source\n";
	print "	--ports-build <package> [--install [--fake]]	rebuild from ports\n";
	print "	--rebuild-package-cache [path]			rebuilds package cache for path\n";
	print "	--mkcd <path> --from-ports <package>				creates an installation cd\n";
	print "	--help						display help message\n\n";
}

sub read_spec_file
{
	my $self         = shift;
	my $spec_file = "";
	my $rebuild_file = "";

	if($_[0]) {
		$rebuild_file = $_[0];
	} else {
		$rebuild_file    = $self->param("rebuild");
	}
	
	if($_[1]) {
		$spec_file = $_[1];
	} else {
		$spec_file    = $self->param("spec");
	}
	$spec_file = "-$spec_file" if($spec_file);
	my $exec_string  = "/bin/tar --get REBUILD$spec_file -O -v -z -f " . $rebuild_file;
	my @dummy;
	my $build_script;
	my %build_script;
	my $id           = 0;
	my $this_dir     = getcwd();
	my $dummy;
	my @required;
	my @build_required;
	my @download_urls;

	
	$self->warning("see tty8 for output and tty9 for errors\n\n");


	if($rebuild_file) {
		$self->message("Building ports: $rebuild_file\n");
		open(FH, "<$rebuild_file/REBUILD") or exit 281;
		{
			local $/;
			$build_script = <FH>;
		}
		close(FH);
	} else {
		$self->message("Building " . basename($rebuild_file) . "\n");
		chomp(my $build_script = `$exec_string 2> /dev/tty9`);
	}

	#
	# %(.*?): var-name
	# :(.*?)\n string
	# ((".*?",)*) array
	#

	@dummy = ($build_script =~ m/\s*%(.*?)\s*:\s*(.*?)\n/g);
	for($id = 0; $id < @dummy; $id+=2) {
#	$dummy[$id] = quotemeta($dummy[$id]);
		if($dummy[$id+1] =~ m/^\$(.*)/) {
			my $s = $1;
			$build_script =~ m/__${s}__(.*?)__${s}__/gms;
			my $d = $1;
			$d =~ s^\n^\\n^gms if($s ne "DATA");
			$dummy[$id+1] = $d."\n";
		}
#	$dummy[$id] =~ s/\\//gms;
		$build_script{$dummy[$id]} = $dummy[$id+1];
	}
	foreach $dummy (keys %build_script) {
		foreach (keys %build_script) {
			$build_script{$dummy} =~ s/%$_/$build_script{$_}/gms;
		}
	}

	if($base->get_in_package_by_path_and_version($build_script{"name"}, $build_script{"version"}))
	{
		$self->warning("Package $build_script{name}, $build_script{version} allready installed.\n");
		exit 2;
	}

	system("rm -rfv /var/cache/lip/mklip ");
	system("rm -rfv /var/cache/lip/build/* ");
	mkdir("/var/cache/lip/mklip", 700);
	mkdir("/var/cache/lip/mklip/FILES", 700);
	mkdir("/var/cache/lip/mklip/PATCHES", 700);
	mkdir("/var/cache/lip/mklip/SCRIPTS", 700);



	# REQUIRED
	if($build_script{"required"} ne "undef") {
		unless($build_script{"required"} =~ m/^\(/) {
			$self->error("Wrong required!\n");
			exit 2;
		}
		eval("\@required = ".$build_script{"required"});
	}
	# Download servers
	if($build_script{"source-url"} ne "undef") {
		unless($build_script{"source-url"} =~ m/^\(/) {
			$self->error("Wrong source-url!\n");
			exit 2;
		}
		eval("\@download_urls = ".$build_script{"source-url"});
		my $success_dl = 0;
		my $count_server = 0;
		while($success_dl eq "0" or $count_server eq scalar(@download_urls)) {
			unless(-f $ENV{"DISTFILE_PATH"}."/".$build_script{"sourcefile"}) {
				system("/usr/bin/wget --passive-ftp -c -O " . $ENV{"DISTFILE_PATH"} . "/" . $build_script{"sourcefile"} . " " . $download_urls[$count_server] . "/" . $build_script{"sourcefile"});
				if($? eq "0") {
					$success_dl = 1;
					$count_server = 0;
					last;
				}
			} else {
				$success_dl = 1;
				last;
			}
			$count_server++;
		}
		if($success_dl ne "1") {
			$self->error("Error downloading sourcefile!... abording...\n");
			exit 3;
		}
	}

	# REQUIRED for building
	if($build_script{"build-required"} ne "undef") {
		unless($build_script{"build-required"} =~ m/^\(/) {
			$self->error("Wrong build-required!\n");
			exit 2;
		}
		eval("\@build_required = ".$build_script{"build-required"});
	}
	# abhaengikeiten ueberpruefen die fuer den 
	# build prozess gebraucht werden
	foreach my $d(@build_required) {
		chomp($d);
		my($n,$v) = split(/ /, $d);
		# kucken ob packet installiert + richtige version
		my $p = $base->_find_in_i_package_dep_by_name($n, $v);
		unless($p) {	# packet nicht installiert oder ein
				# falsche version
			#my $package_path = $base->find_package_by_name($n);
			my $package_path = $base->find_package_path_in_ports($n);
			$self->warning("$n, $v not installed. going to do this now!\n");
			#$self->read_spec_file($ENV{"PORTS_PATH"}."/$package_path/REBUILD");
			if($self->option("fake"))
			{
				system("linoratix-config --plugin LIPdev --ports-build $package_path --install --fake");
			}
			else
			{
				system("linoratix-config --plugin LIPdev --ports-build $package_path --install");
			}
		} else {
			$self->message("$n, $v already installed. skipping...\n");
		}
		$self->get_installed_packages();
	}

	my $count = 0;	
	my @orig_required = @required;
	foreach my $del (@required)
	{
		foreach my $todel (@build_required)
		{
			if($todel eq $del)
			{
				splice(@required, $count, 1);
			}
		}
		$count++;
	}

	# danach muessen noch die normalen abhaengikeiten jeprieft werden
	# aber nur bei der option --install
	if($self->option("install"))
	{
		foreach my $d(@required) 
		{
			chomp($d);
			my($n,$v) = split(/ /, $d);
			# kucken ob packet installiert + richtige version
			my $p = $base->_find_in_i_package_dep_by_name($n, $v);
			unless($p) {	# packet nicht installiert oder ein
					# falsche version
				#my $package_path = $base->find_package_by_name($n);
				my $package_path = $base->find_package_path_in_ports($n);
				$self->warning("$n, $v not installed. going to do this now!\n");
				if($self->option("fake"))
				{
					system("linoratix-config --plugin LIPdev --ports-build $package_path --install --fake");
				}
				else
				{
					system("linoratix-config --plugin LIPdev --ports-build $package_path --install");
				}
				$self->get_installed_packages();
			} else {
				$self->message("$n, $v already installed. skipping...\n");
			}
		}
	}
	# make temp dir for lip creation
	# soapbox aktivieren, das nurnoch dahin geschrieben werden kann wo ich will :)=
	my $oldpreload = $ENV{"LD_PRELOAD"};
	$ENV{"LD_PRELOAD"} = "/lib/libsoapbox.so:".$ENV{"LD_PRELOAD"};
	$ENV{"SOAPBOXPATH"} = ":/var/cache/lip/mklip/FILES:/var/cache/lip/build:/dev:/tmp:/usr/src/LIPS/BUILDS";
	$ENV{"SOAPBOXACTION"} = "err";

	# REQUIRED
	if(scalar(@orig_required) >= 1)
	{
		open(FH, ">/var/cache/lip/mklip/REQUIRED") or exit 300;
		print FH join("\n", @orig_required);
		close(FH);
	}

	# GROUP
	open(FH, ">/var/cache/lip/mklip/GROUP") or exit 302;
	print FH $build_script{"package-group"} . "/";
	print FH $build_script{"sub-group"};
	close(FH);

	# VERISON
	open(FH, ">/var/cache/lip/mklip/VERSION") or exit 303;
	print FH $build_script{"version"};
	close(FH);

	# NAME
	open(FH, ">/var/cache/lip/mklip/NAME") or exit 304;
	print FH $build_script{"name"};
	close(FH);

	# DESCRIPTION
	open(FH, ">/var/cache/lip/mklip/DESCRIPTION") or exit 305;
	print FH $build_script{"description"};
	close(FH);

	# PROVIDES
	if($build_script{"provides"})
	{
		open(FH, ">/var/cache/lip/mklip/PROVIDES") or exit 305;
		print FH $build_script{"provides"};
		close(FH);
	}



	mkdir("/var/cache/lip/build") unless(-d "/var/cache/lip/build");
	chdir("/var/cache/lip/build");

	unless($rebuild_file) {
		system("tar --get " . $build_script{"sourcefile"} . " -v -z -f " . $self->param("rebuild") . " ");
		system("tar --get PATCHES -v -z -f " . $rebuild_file . " ");
	} else {
		system("/bin/cp -R " . $ENV{"PORTS_PATH"} . "/" . $self->param("ports-build") . "/PATCHES /var/cache/lip/build") if(-d $ENV{"PORTS_PATH"} . "/" . $self->param("ports-build") . "/PATCHES" );
	}
	
	$self->execute_build_script(%build_script);

#	$self->message("Searching new files\n");
	# find what is newer than $start_date;
use File::Find;
#	find(\&changes, "/boot", "/bin", "/lib", "/etc", "/sbin", "/usr", "/lib", "/var", "/opt");

	# Creating Package
	$self->message("Creating binary package\n");
	if($self->param("bin-dir")) {
		chdir($self->param("bin-dir"));
	} else {
		chdir("/var/cache/lip/mklip");
	}
	
	# stripping
	$self->message("stripping debug symbols.\n");
	system("find /var/cache/lip/mklip -type f -exec strip --strip-debug '{}' ';'");

	# makeing tar archive from FILES/*
	$ENV{"LD_PRELOAD"} = $oldpreload;

	$self->message("Creating MANIFEST\n");
	# Create MANIFEST file
	find(\&manifest, "/var/cache/lip/mklip");

	$self->message("creating files archive.\n");
	chdir("/var/cache/lip/mklip/FILES");
	system("tar cvzf ../files.tgz *");

	if($self->param("bin-dir")) {
		chdir($self->param("bin-dir"));
	} else {
		chdir("/var/cache/lip/mklip");
	}

	system("rm -rf FILES");

	mkdir("/usr/src/LIPS") unless(-d "/usr/src/LIPS");
	mkdir("/usr/src/LIPS/BUILDS") unless(-d "/usr/src/LIPS/BUILDS");
	system("tar cvzf /usr/src/LIPS/BUILDS/" . $build_script{"name"} . "-" . $build_script{"version"} . ".lip * ");


	if($self->option("install"))
	{
		$self->message("now installing package: " . $build_script{"name"} . "-" . $build_script{"version"} . "\n");
		if($self->option("fake"))
		{
			system("linoratix-config --plugin LIP --install /usr/src/LIPS/BUILDS/".$build_script{"name"} . "-" . $build_script{"version"} . ".lip --fake");
		}
		else
		{
			system("linoratix-config --plugin LIP --install /usr/src/LIPS/BUILDS/".$build_script{"name"} . "-" . $build_script{"version"} . ".lip");
		}
	}

	$self->message("done.\n\n");
}

sub mkcd
{
	my $self = shift;
	my $from_port = $self->param("from-ports");
	my $cd_path = $self->param("mkcd");
	my @content = ();
	my @required = ();
	my @version = ();
	my @name = ();

	$self->message("Creating installation cd in $cd_path\n");

	system("mkdir -p $cd_path");
	system("rm -rf $cd_path/*");
	system("mkdir -p $cd_path/Linoratix");

	open(FH, "<$ENV{PORTS_PATH}/$from_port/REBUILD") or sub { print "--".$!; }; 
	chomp(@content = <FH>);
	close(FH);

	my @this_name = grep { /^\%name:(.*)$/ } @content;
	my @this_description = grep { /^\%description:(.*)$/ } @content;
	my @this_version = grep { /^\%version:(.*)$/ } @content;
	$this_name[0] =~ m/^\%name:(.*)$/;
	my $this_name = $1;
	$this_name =~ s/^\s+|\s+$//g;
	$this_version[0] =~ m/^\%version:(.*)$/;
	my $this_version = $1;
	$this_version =~ s/^\s+|\s+$//g;
	$this_description[0] =~ m/^\%description:(.*)$/;
	my $this_description = $1;

	@required = grep { /^\%required:/ } @content;
	$required[0] =~ m/^\%required:(.*)$/;

	eval("\@required = $1");

	$self->message("Copying Packages...\n");
	push(@required, "$this_name =$this_version");
	foreach(@required)
	{
		m/^(.*?) .*$/;
		my $name = $1;
		my $path = $ENV{"PORTS_PATH"} . $base->find_package_path_in_ports($name);
		open(FH, "<$path/REBUILD") or die($!);
		chomp(@content = <FH>);
		close(FH);
		@version = grep { /^\%version:(.*)$/ } @content;
		@name = grep { /^\%name:(.*)$/ } @content;
		$version[0] =~ m/^\%version:(.*)$/;
		my $v = $1;
		$name[0] =~ m/^\%name:(.*)$/;
		my $n = $1;
		$v =~ s/^\s+|\s+$//g;
		$n =~ s/^\s+|\s+$//g;
		if(-f "/usr/src/LIPS/BUILDS/$n-$v.lip", "$cd_path/Linoratix/$n-$v.lip")
		{
			print "	$n-$v.lip\n";
			copy("/usr/src/LIPS/BUILDS/$n-$v.lip", "$cd_path/Linoratix/$n-$v.lip");
		}
		else
		{
			$self->error("$n-$v not found...\n");
			exit(342);
		}
	}

	$self->message("Copying cd tools...\n");
	copy("/usr/src/LIPS/BUILDS/libpopt-1.7.lip", "$cd_path/Linoratix");
	copy("/usr/src/LIPS/BUILDS/libnewt-0.51.6.lip", "$cd_path/Linoratix");
	copy("/usr/src/LIPS/BUILDS/mingetty-1.06.lip", "$cd_path/Linoratix");
	copy("/usr/src/LIPS/BUILDS/python-2.4.lip", "$cd_path/Linoratix");
	copy("/usr/src/LIPS/BUILDS/libgdbm-1.8.3.lip", "$cd_path/Linoratix");
	copy("/usr/src/LIPS/BUILDS/libslang-1.4.9.lip", "$cd_path/Linoratix");
	copy("/usr/src/LIPS/BUILDS/hwdata-0.148.lip", "$cd_path/Linoratix");
	copy("/usr/src/LIPS/BUILDS/kudzu-1.1.67.lip", "$cd_path/Linoratix");

	$self->message("Rebuilding package-cache...\n");
	system("cd $cd_path/Linoratix; linoratix-config --plugin LIPdev --rebuild-package-cache . > /dev/null 2>&1");
	
	$self->message("Virtually tweaking the install-tree.\n");
	
	$base->load_caches($cd_path . "/Linoratix/packages.cache");

	my $package = $base->find_package_by_name($this_name);
	my $package_to_install = $base->get_package_by_path($package);

	my $check_version = 0;

	mkdir("$cd_path/install");
	mkdir("$cd_path/install/groups");
	open(PKGS, ">$cd_path/install/$this_name.pkgs");
	foreach($base->get_all_deps($this_version, $check_version, $package_to_install))
	{
		my($n,$v) = split(/\|/, $_);
		unless(-f "$cd_path/Linoratix/$n-$v.lip")
		{
			$self->error("No such file $n-$v.lip");
			die;
		}
		my ($group, $subgroup, $pkg) = split(/\//, $base->find_package_by_name($n));
		my $p = $base->get_package_by_path($group . "/" . $subgroup . "/" . $pkg);
		mkdir("$cd_path/install/groups/$group") unless(-d "$cd_path/install/groups/$group");
		print PKGS "$group/$subgroup.install\n";
		open(FH, ">$cd_path/install/groups/$group/$subgroup.install") or die($!);
			print FH Dumper($p);
		close(FH);
		copy($ENV{"PORTS_PATH"} . "/$group/DESC", "$cd_path/install/groups/$group");
	}
	close(PKGS);

	open(FH, ">$cd_path/linoratix_cd_1");
		print FH time();
	close(FH);

	mkdir("$cd_path/boot");
	mkdir("$cd_path/boot/grub");
	copy("/usr/share/linoratix/bootcd/miniroot.gz", "$cd_path/boot");
	copy("/usr/share/linoratix/bootcd/menu.lst", "$cd_path/boot/grub");
	system("/bin/cp -a /usr/share/grub/i386-pc/* $cd_path/boot/grub");

	system("mkdir -p $cd_path/etc/conf.d");
	system("mkdir -p $cd_path/var/cache/lip/ldb");
	system("mkdir -p $cd_path/sys");
	system("mkdir -p $cd_path/proc");
	system("mkdir -p $cd_path/tmp");

	system("linoratix-config --plugin LIPbase --add-server file:///$cd_path/Linoratix --prefix $cd_path");
	die if($? ne "0");

	system("linoratix-config --plugin LIP --install linoratix-base --prefix $cd_path");
	die if($? ne "0");

	print "\n\n";
	$self->message("Installing bootcd specific software...\n\n");
	system("linoratix-config --plugin LIP --install kudzu --prefix $cd_path");
	die if($? ne "0");
	
	print "\n\n";
	$self->message("Installing mingetty for autologin...\n\n");
	system("linoratix-config --plugin LIP --install mingetty --prefix $cd_path");
	die if($? ne "0");

	open(FH, ">$cd_path/etc/fstab");
		print FH "/proc	/proc	proc	defaults	0 0\n";
		print FH "/sys	/sys	sysfs	defaults	0 0\n";
		print FH "/dev/pts	/dev/pts	devpts	mode=0622	0 0\n";
		print FH "/dev/cdrom	/mnt/cdrom	auto	user,noauto,exec,ro	0 0\n\n";
	close(FH);

	open(FH, ">$cd_path/etc/HOSTNAME");
		print FH "ananas\n";
	close(FH);

	open(FH, ">$cd_path/etc/hosts");
		print FH "127.0.0.1	localhost.localdomain	localhost\n";
	close(FH);

	copy("$cd_path/sbin/init", "$cd_path/etc");

	open(FH, ">$cd_path/etc/conf.d/rc.conf");
		print FH "UTC=0\n";
		print FH "KEYMAP=de-latin1\n";
		print FH "EDITOR=vim\n";
		print FH "INPUTRC=/etc/inputrc";
	close(FH);

	unlink("$cd_path/etc/runlevels/boot/11mountother");
	unlink("$cd_path/etc/runlevels/shutdown/70mountroot");
	unlink("$cd_path/etc/runlevels/boot/50updatemodules");
	unlink("$cd_path/etc/runlevels/boot/65modules");

	open(FH, ">$cd_path/etc/issue");
		print FH "="x80;
		print FH "\n\n\n";
		print FH "Welcome to the Installation of Linoratix 0.8\n\n";
		print FH "Please login as root with no password.\n";
		print FH "After that you can run 'setup' to start the installation.\n\n";
		print FH "\n";
		print FH "="x80;
		print FH "\n\n";
	close(FH);

	open(FH, ">$cd_path/etc/rc.d/rc.network");
		print FH "#!/bin/sh\n\n";
		print FH "source /etc/rc.d/functions\n";
		print FH "write_message \"Setting up loopback networking...\"\n";
		print FH "/sbin/ifconfig lo 127.0.0.1 > /dev/tty9 2> /dev/tty9\n";
		print FH "/sbin/route add -net 127.0.0.0 netmask 255.0.0.0 lo > /dev/tty9 2> /dev/tty9\n";
		print FH "check_success \$?\n";
	close(FH);


	mkdir("$cd_path/root");

	system("chroot $cd_path /sbin/ldconfig");
	system("rm -rf $cd_path/usr/src/*");
	system("ln -s /usr/bin/whoami $cd_path/bin/whoami");

	open(FH, ">$cd_path/etc/passwd");
		print FH "root:x:0:0:root:/root:/bin/bash\n";
	close(FH);

	open(FH, ">$cd_path/etc/shadow");
		print FH "root:ZUpDME1T0vuUk:12789:0:99999:7:::\n";
	close(FH);
	
	#open(FH, ">$cd_path/setrootpw");
	#	print FH "#!/bin/bash\n\n";
	#	print FH "echo root: |/usr/sbin/chpasswd\n";
	#close(FH);
	#system("chmod 755 $cd_path/setrootpw");
	#system("chroot $cd_path /setrootpw");
	#unlink("$cd_path/setrootpw");

	#### autologin
	# unlink("$cd_path/etc/inittab");
	# copy("/usr/share/linoratix/bootcd/inittab", "$cd_path/etc");

	# die verschiedenen flavors
	open(FH, ">$cd_path/install/flavors");
		print FH "$this_name|$this_description\n";
	close(FH);
	
}

sub create_bin_lip
{
	my $self = shift;

use File::Find;
	$self->message("Creating MANIFEST\n");
	# Create MANIFEST file
	find(\&manifest, $self->param("bin-dir"));

	# Creating Package
	$self->message("Creating binary package\n");
	chdir($self->param("bin-dir"));

	system("tar cvzf /usr/src/LIPS/BUILDS/" . $self->param("bin-name") . "-" . $self->param("bin-version") . ".lip * ");

	$self->message("done.\n\n");
}

sub execute_build_script
{
	my $self         = shift;
	my $build_script = { @_ };
	my @script       = split(/\n/, $build_script->{"build"});
	my $function;
	my $parameter;
	my $dummy;

	$start_date      = time();

	foreach(@script) {
		$REBUILD_LINE++;
		next if /^#|^$/;
		if(m/^-(.*?)=(.*?)$/) {
			my $x = $2;
			my $var = $1;
			$self->warning("Setting \$$var to $x\n");
			$x =~ s^%compile_dir^/var/cache/lip/build/$compile_dir^g;
			$$var = $x;
		} else {
			($function, $parameter, $dummy) = (m/^(.*?) (.*)$|^(.*)?$/);
			$function = $dummy unless($function && !$dummy);
			$self->$function("$parameter");
		}
	}
}

# exports an environment variable
sub lip_export
{
	my $self      = shift;
	my $parameter = shift;
	my ($var,$val);

	$parameter = $self->parse_parameter($parameter);

	($var,$val)   = split(/=/, $parameter);
	$val =~ s/^\"|\"$//gms;

	$self->message("exporting $var => $val ($parameter)\n");
	system("export $parameter");
	$ENV{$var}    = $val;
}

# get file from sourcepackage
sub lip_get_file
{
	my $self      = shift;
	my $parameter = shift;
	my $file;
	my $to;

	$parameter = $self->parse_parameter($parameter);

	$self->message("Extracting $parameter\n");
	
	($file, $to)  = split(/ /, $parameter);
	if($self->param("ports-build"))
	{
		system("cp ".$ENV{"PORTS_PATH"}."/".$self->param("ports-build") . "/files/" . $file . " " . $to);
	}
	else
	{
		system("tar --get $file -v -O -z -f " . $self->param("rebuild") ." > $to  2> /dev/tty9");
	}
	if($? ne "0") {
		$self->error("error in function lip_get_file, line ".$REBUILD_LINE);
		exit 1;
	}
}

# extract the source file
sub lip_extract
{
	my $self = shift;
	my $file = shift;
	my $packmode;
	my @dir_1;
	my %dir_1;
	my @dir_2;
	my %dir_2;

	$file = $self->parse_parameter($file);
	if(-f $ENV{"DISTFILE_PATH"} . "/" . $file) {
		$file = $ENV{"DISTFILE_PATH"} . "/" . $file;
	}

	$packmode = "/bin/bunzip2" if($file =~ m/\.bz2$/);
	$packmode = "/bin/tar xjvf" if($file =~ m/\.tar\.bz2$/);
	$packmode = "/bin/tar xvf" if($file =~ m/\.tar$/);
	$packmode = "/bin/tar xzvf" if($file =~ m/\.tar\.gz$|\.tgz$/);
	$packmode = "/usr/bin/unzip" if($file =~ m/\.zip$/);

	@dir_1 = `ls -1`;
	$dir_1{$_} = "-" foreach(@dir_1);
	$self->message("extracting $file\n");
	system("$packmode $file ");
	if($? ne "0") {
		$self->error("error in function lip_extract, line ".$REBUILD_LINE);
		exit 1;
	}

	@dir_2 = `ls -1`;
	$dir_2{$_} = "-" foreach(@dir_2);
	unless($compile_dir) {
		foreach (keys %dir_2) {
			$compile_dir = $_ unless exists $dir_1{$_};
		}
		chomp($compile_dir);
	}
}


# rm
sub lip_rm
{
	my $self = shift;
	my $parameter = shift;

	$parameter = $self->parse_parameter($parameter);

	$self->message("rm $parameter\n");
	system("rm -v $parameter ");
	if($? ne "0") {
		$self->error("error in function lip_rm, line ".$REBUILD_LINE);
		exit 1;
	}

}

sub lip_cp
{
	my $self = shift;
	my $parameter = shift;

	$parameter = $self->parse_parameter($parameter);

	$self->lip_copy($parameter);
}

sub lip_copy
{
	my $self     = shift;
	my $parameter = shift;

	$parameter = $self->parse_parameter($parameter);

	$self->message("Copy $parameter\n");
	
	system("cp -v $parameter ");
	if($? ne "0") {
		$self->error("error in function lip_cp, line ".$REBUILD_LINE);
		exit 1;
	}

}

sub lip_patch
{
	my $self = shift;
	my $parameter = shift;
	
	$parameter = $self->parse_parameter($parameter);
	
	$self->message("Patching $parameter\n");
		
	system("patch $parameter ");
	if($? ne "0") {
		$self->error("error in function lip_patch, line ".$REBUILD_LINE);
		exit 1;
	}

}

sub lip_configure
{
	my $self      = shift;
	my $parameter = shift;
	
	$parameter = $self->parse_parameter($parameter);

	$self->message("configure $parameter\n");
	system("$CONFIGURE_PATH/configure $parameter ");
	if($? ne "0") {
		$self->error("error in function lip_configure, line ".$REBUILD_LINE);
		exit 1;
	}

}

sub lip_make
{
	my $self      = shift;
	my $parameter = shift;

	$parameter = $self->parse_parameter($parameter);

	$self->message("make $parameter\n");
	if($parameter eq "oldconfig" or $parameter eq "config") {
		system("yes |make $parameter ");
	} else {
		system("make $parameter ");
	}
	if($? ne "0") {
		$self->error("error in function lip_make, line ".$REBUILD_LINE);
		exit 1;
	}

}

sub lip_install
{
	my $self       = shift;
	my $parameter  = shift;

	$parameter = $self->parse_parameter($parameter);

	$self->message("make install $parameter\n");
	system("make install $parameter ");
	if($? ne "0") {
		$self->error("error in function lip_install, line ".$REBUILD_LINE);
		exit 1;
	}

}

sub lip_mkdir
{
	my $self  = shift;
	my $parameter   = shift;

	$parameter = $self->parse_parameter($parameter);
	$self->message("mkdir $parameter\n");
	system("mkdir -v $parameter ");
	if($? ne "0") {
		$self->error("error in function lip_mkdir, line ".$REBUILD_LINE);
		exit 1;
	}

}

sub lip_cd
{
	my $self = shift;
	my $dir  = shift;

	$dir = $self->parse_parameter($dir);
	
	$self->message("cd '$dir'\n");
	chdir($dir);
	if($!) {
		$self->error("error in function lip_cd $!, line ".$REBUILD_LINE);
		exit 1;
	}

}

# add a file from the footer to the filesystem
sub lip_add_file
{
	my $self      = shift;
	my $parameter = shift;

	$parameter = $self->parse_parameter($parameter);
	
	my ($file, $content) = split(/ (.*)/ms, $parameter);
	$self->message("Adding file $file\n");
	$content =~ s^\\n^\n^gms;
	open(FH, ">$file") or sub { exit 1; $self->error("error in function lip_add_file, line ".$REBUILD_LINE); };
		print FH $content;
	close(FH);
}

sub lip_append_file
{
	my $self      = shift;
	my $parameter = shift;

	$parameter = $self->parse_parameter($parameter);

	my ($file, $content) = split(/ (.*)/ms, $parameter);
	$self->message("Adding file $file\n");
	$content =~ s^\\n^\n^gms;
	open(FH, ">>$file") or sub { exit 1; $self->error("error in function lip_append_file, line ".$REBUILD_LINE); };
		print FH $content;
	close(FH);
}

sub lip_chmod
{
	my $self      = shift;
	my $parameter = shift;

	$parameter = $self->parse_parameter($parameter);
	$self->message("chmod $parameter\n");
	system("chmod -v $parameter ");
	if($? ne "0") {
		$self->error("error in function lip_chmod, line ".$REBUILD_LINE);
		exit 1;
	}

}

sub lip_mv
{
	my $self      = shift;
	my $parameter = shift;

	$parameter = $self->parse_parameter($parameter);
	$self->message("mv $parameter\n");
	system("mv -v $parameter ");
	if($? ne "0") {
		$self->error("error in function lip_mv, line ".$REBUILD_LINE);
		exit 1;
	}

}

sub lip_ln
{
	my $self      = shift;
	my $parameter = shift;

	$parameter = $self->parse_parameter($parameter);
	$self->message("ln $parameter\n");
	system("ln $parameter ");
	if($? ne "0") {
		$self->error("error in function lip_ln, line ".$REBUILD_LINE);
		exit 1;
	}

}

sub changes
{
	my $file = getcwd() . "/$_";
	my @stat = stat($file);
	my $target;
	
	#skip some directories
	return if($file =~ m:^/var/log:);
#	return if($file =~ m:^/usr/src:);
	return if($file =~ m:^/var/lock:);
	return if($file =~ m:^/var/mail:);
	return if($file =~ m:^/var/run:);
	return if($file =~ m:^/var/cache:);
	return if($file =~ m:^/var/spool:);

	if($stat[9] >= $start_date or $stat[10] >= $start_date) {
		if(-d "$file") {
			system("mkdir -p -v /var/cache/lip/mklip/FILES$file ");
			chmod($stat[2], "/var/cache/lip/mklip$file");
		} 
		else {
			my $d = dirname($file);
			unless(-d "/var/cache/lip/mklip/FILES$d") {
				system("mkdir -p -v /var/cache/lip/mklip/FILES$d ");
			}
			system("cp -dpRv $file /var/cache/lip/mklip/FILES$file ");
		}
	}
}

sub lip_other
{
	my $self    = shift;
	my $command = shift;

	$command = $self->parse_parameter($command);
#	$command =~ s^%compile_dir^/var/cache/lip/build/$compile_dir^g;
#	$command =~ s^%patch_dir^/var/cache/lip/build/PATCHES^g;
	$self->message("$command\n");
	system("$command");
	if($? ne "0") {
		$self->error("error in function lip_other, line ".$REBUILD_LINE);
		exit 1;
	}

}

sub lip_chown
{
	my $self    = shift;
	my $parameter = shift;

	$parameter = $self->parse_parameter($parameter);

	$self->message("chown $parameter\n");
	system("chown $parameter");
	if($? ne "0") {
		$self->error("error in function lip_chown, line ".$REBUILD_LINE);
		exit 1;
	}

}

sub lip_sed
{
	my $self        = shift;
	my $parameter   = shift;
	my $regexp;
	my $file;

	$parameter = $self->parse_parameter($parameter);

	$self->message("sed $parameter\n");
	system("sed $parameter 2> /dev/tty9");
	if($? ne "0") {
		$self->error("error in function lip_sed, line ".$REBUILD_LINE);
		exit 1;
	}

}

sub manifest
{
	my $file = getcwd() . "/$_";
	my @stat = stat($file);

	if($bin_dir) {
		$file =~ s/^$bin_dir//;
		open(FH, ">>".$bin_dir."/MANIFEST") or exit 340;
	} else {
		$file =~ s:^/var/cache/lip/mklip::;
		open(FH, ">>/var/cache/lip/mklip/MANIFEST") or exit 341;
	}

	print FH "$file\t";
	print FH "$_\t" foreach(@stat);
	print FH "\n";
	close(FH);
}

sub build_package_cache
{
	my $self                     = shift;
	my $dir                      = $self->param("rebuild-package-cache");
	my $packages;
	my $exec_get_manifest        = "/bin/tar --get MANIFEST -O -v -z -f $dir";
	my $exec_get_description     = "/bin/tar --get DESCRIPTION -O -v -z -f $dir";
	my $exec_get_provides        = "/bin/tar --get PROVIDES -O -v -z -f $dir";
	my $exec_get_group           = "/bin/tar --get GROUP -O -v -z -f $dir";
	my $exec_get_name            = "/bin/tar --get NAME -O -v -z -f $dir";
	my $exec_get_version         = "/bin/tar --get VERSION -O -v -z -f $dir";
	my $exec_get_rebuildurl      = "/bin/tar --get REBUILDURL -O -v -z -f $dir";
	my $exec_get_required        = "/bin/tar --get REQUIRED -O -v -z -f $dir";
	opendir(DH, $dir) or exit 370;
	my @files = grep { /\.lip$/ } readdir(DH);
	closedir(DH);

	# set header for cache file
	$packages->{"__global-information"}->{"cache-version"} = $MOD_VERSION;
	$packages->{"__global-information"}->{"cache-compatible"} = \@COMPATIBLE;
	
	foreach(@files) {
		print "$_\n";
		my @manifest        = `$exec_get_manifest/$_ 2> /dev/tty9`;
		my @description     = `$exec_get_description/$_ 2> /dev/tty9`;
		my @provides        = `$exec_get_provides/$_ 2> /dev/tty9`;
		my @group           = `$exec_get_group/$_ 2> /dev/tty9`;
		my @package_name    = `$exec_get_name/$_ 2> /dev/tty9`;
		my @package_version = `$exec_get_version/$_ 2> /dev/tty9`;
		my @rebuild_url     = `$exec_get_rebuildurl/$_ 2> /dev/tty9`;
		my @required        = `$exec_get_required/$_ 2> /dev/tty9`;
		chomp(@manifest); chomp(@description); chomp(@group);
		my($main, $sub)     = split(/\//, $group[0]);
		$main               =~s/ - ?$//;
		my $status          = "";
		if($sub =~ m/^.*\s([-!?])$/) {
			$status = $1;
		} else {
			$status = "-";
		}
		$sub =~ s/ [-!?]$//;
		
		@manifest = grep {/^\/FILES/} @manifest;
		my @md5sum = `/usr/bin/md5sum $_`;
		my @md5    = split(/\s+/, $md5sum[0]);
		$packages->{$main}->{$sub}->{$package_name[0]}->{$package_version[0]}->{"description"} = $description[0];
		$packages->{$main}->{$sub}->{$package_name[0]}->{$package_version[0]}->{"provides"} = $provides[0];
		$packages->{$main}->{$sub}->{$package_name[0]}->{$package_version[0]}->{"rebuild-url"} = $rebuild_url[0];
		$packages->{$main}->{$sub}->{$package_name[0]}->{$package_version[0]}->{"status"} = $status;
		$packages->{$main}->{$sub}->{$package_name[0]}->{$package_version[0]}->{"files"} = \@manifest;
		$packages->{$main}->{$sub}->{$package_name[0]}->{$package_version[0]}->{"required"} = \@required;
		$packages->{$main}->{$sub}->{$package_name[0]}->{$package_version[0]}->{"md5"} = $md5[0];
		$packages->{$main}->{$sub}->{$package_name[0]}->{$package_version[0]}->{"name"} = $package_name[0];
	}
	store($packages, "$dir/packages.cache");
}

sub parse_parameter
{
	my $self = shift;
	my $string = shift;

	$string =~ s^%patch_dir^/var/cache/lip/build/PATCHES^g;
	$string =~ s^%compile_dir^/var/cache/lip/build/$compile_dir^g;
	$string =~ s^%install_dir^/var/cache/lip/mklip/FILES^g;
	$string =~ s^%man_dir^/var/cache/lip/mklip/FILES/usr/share/man^g;
	$string =~ s^%info_dir^/var/cache/lip/mklip/FILES/usr/share/info^g;
	$string =~ s^%libexecdir_dir^/var/cache/lip/mklip/FILES/usr/lib^g;
	$string =~ s^%lib_dir^/var/cache/lip/mklip/FILES/usr/lib^g;
	$string =~ s^%include_dir^/var/cache/lip/mklip/FILES/usr/include^g;

	return $string;
}

1;

