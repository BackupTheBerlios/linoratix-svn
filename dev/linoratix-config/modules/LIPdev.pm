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
$MOD_VERSION = "0.0.10";
@COMPATIBLE = qw("0.0.1");
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

	$self->message("Retrieving information for installed packages...   ");
	if(-f $self->param("prefix") . "/var/cache/lip/installed_packages.cache") {
		$installed_packages = retrieve($self->param("prefix") . "/var/cache/lip/installed_packages.cache");
	}
	print "done.\n";

	$self->{"path"} = getcwd();

	$bin_dir = $self->param("bin-dir");

	$self->help() if($self->option("help"));
	$self->read_spec_file() if($self->param("rebuild"));
#	$self->create_bin_lip() if($self->param("bin-dir"));
	$self->build_package_cache() if($self->param("rebuild-package-cache"));
	$self->read_spec_file($ENV{"PORTS_PATH"}."/".$self->param("ports-build")) if($self->param("ports-build"));

	return $self;
}

sub help
{
	my $self = shift;
	
	$self->message("linoratix-config $BASE_VERSION\n");
	$self->message("	module: LIPdev $MOD_VERSION\n\n");
	print "	--rebuild <package> [--spec buildfile]	rebuild a Linoratix package from source\n";
	print "	--ports-build <package>				rebuild from ports\n";
	print "	--rebuild-package-cache [path]			rebuilds package cache for path\n";
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

	# clean up build dir
	$self->message("Cleaning up build directory\n");
	system("rm -rfv /var/cache/lip/mklip ");
	system("rm -rfv /var/cache/lip/build/* ");

	# make temp dir for lip creation
	mkdir("/var/cache/lip/mklip", 700);
	mkdir("/var/cache/lip/mklip/FILES", 700);
	mkdir("/var/cache/lip/mklip/PATCHES", 700);
	mkdir("/var/cache/lip/mklip/SCRIPTS", 700);

	# soapbox aktivieren, das nurnoch dahin geschrieben werden kann wo ich will :)=
	my $oldpreload = $ENV{"LD_PRELOAD"};
	$ENV{"LD_PRELOAD"} = "/lib/libsoapbox.so:".$ENV{"LD_PRELOAD"};
	$ENV{"SOAPBOXPATH"} = ":/var/cache/lip/mklip/FILES:/var/cache/lip/build:/dev:/tmp:/usr/src/LIPS/BUILDS";
	$ENV{"SOAPBOXACTION"} = "err";



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

	# REQUIRED
	if($build_script{"required"} ne "undef") {
		unless($build_script{"required"} =~ m/^\(/) {
			$self->error("Wrong required!\n");
			exit 2;
		}
		eval("\@required = ".$build_script{"required"});
		open(FH, ">/var/cache/lip/mklip/REQUIRED") or exit 300;
		print FH join("\n", @required);
		close(FH);
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
			system("/usr/bin/wget --passive-ftp -c -O " . $ENV{"DISTFILE_PATH"} . "/" . $build_script{"sourcefile"} . " " . $download_urls[$count_server] . "/" . $build_script{"sourcefile"});
			if($? eq "0") {
				$success_dl = 1;
				$count_server = 0;
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
			my $package_path = $base->find_package_by_name($n);
			$self->warning("$n, $v not installed. going to do this now!\n");
			$self->read_spec_file($ENV{"PORTS_PATH"}."/$package_path/$n-$v.src.lip");
		} else {
			$self->message("$n, $v already installed. skipping...\n");
		}
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

	$self->message("done.\n\n");
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
	
	system("tar --get $file -v -O -z -f " . $self->param("rebuild") ." > $to  2> /dev/tty9");
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
		
	system("patch -Np1 -i $parameter ");
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
	
	$self->message("cd $dir\n");
	chdir($dir);
	if($? ne "0") {
		$self->error("error in function lip_cd, line ".$REBUILD_LINE);
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
		$packages->{$main}->{$sub}->{$package_name[0]}->{$package_version[0]}->{"rebuild-url"} = $rebuild_url[0];
		$packages->{$main}->{$sub}->{$package_name[0]}->{$package_version[0]}->{"status"} = $status;
		$packages->{$main}->{$sub}->{$package_name[0]}->{$package_version[0]}->{"files"} = \@manifest;
		$packages->{$main}->{$sub}->{$package_name[0]}->{$package_version[0]}->{"required"} = \@required;
		$packages->{$main}->{$sub}->{$package_name[0]}->{$package_version[0]}->{"md5"} = $md5[0];
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

