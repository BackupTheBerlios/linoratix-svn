#
# Linoratix module to manage the kernel
#

package Linoratix::Kernel;

use Linoratix;

use Data::Dumper;
use File::Copy;
use Fcntl ':mode';

use vars qw(@ISA @EXPORT $MOD_VERSION);
use Exporter;

$MOD_VERSION = "0.0.1";
@ISA = qw(Exporter);
@EXPORT = qw(&new);

sub new
{
	my $linoratix = shift;
	my $class     = ref($linoratix) || $linoratix;
	my $self      = { @_ };

	bless($self, $class);

	$self->help() if($self->option("help"));
	$self->build_initrd() if($self->option("build-initrd"));

	return $self;
}

sub help
{
	my $self = shift;
	
	$self->message("linoratix-config $BASE_VERSION\n");
	$self->message("	module: Kernel $MOD_VERSION\n\n");
	print "	--build-initrd			install new initrd\n";
	print "\n";
}


sub build_initrd
{
	my $self = shift;
	my $version = `uname -r`;
	chomp($version);
	$version = $self->param("version") unless($version);

	$self->message("Building initrd. This may take a while ...\n");
	system("mount /boot > /dev/null 2> /dev/null");
	system("dd if=/dev/zero of=/boot/initrd-$version count=10k bs=1024");

	system("yes |mkfs.ext2 /boot/initrd-$version");
	mkdir("/mnt/loop");
	system("mount /boot/initrd-$version /mnt/loop -o loop");
	chdir("/mnt/loop");
	system("tar xzf /usr/share/linoratix/initrd.tar.gz");
	my @modules = `lsmod |awk -F " " '{ print \$1 }'`;
	chomp(@modules);

	open(FH, ">/mnt/loop/modules.conf") or die($!);
	foreach(@modules) {
		s/_/-/gm;
		print FH "$_.ko\n";
		my $locate = `find /lib/modules/$version -iname $_.ko`;
		chomp($locate);
		copy($locate, "/mnt/loop/lib/modules/$_.ko");
	}
	close(FH);
}


1;

