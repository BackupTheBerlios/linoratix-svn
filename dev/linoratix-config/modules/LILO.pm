#
# Linoratix module to manage base system prefs
# @author pr0gm4 <pr0gm4@linoratix.com>

package Linoratix::LILO;
use Linoratix;

use Data::Dumper;

use strict;

use vars qw(@ISA @EXPORT $MOD_VERSION);
use Exporter;
$MOD_VERSION = "0.1.1";
@ISA = qw(Exporter);
@EXPORT = qw(&new);

our $lilo_conf_global;
our $lilo_conf_images;
our $lilo_conf_others;

# namepsace [200-299]

sub new
{
	my $linoratix = shift;
	my $class     = ref($linoratix) || $linoratix;
	my $self      = { @_ };

	bless($self, $class);

	$self->help() if($self->option("help"));
	$self->generate_lilo_conf() if($self->option("generate-lilo.conf"));
	$self->read_lilo_conf();
	
	$self->get_global_option() if($self->param("get-global-option"));
	$self->set_global_option() if($self->param("set-global-option"));
	$self->list_images() if($self->option("list-images"));
	$self->list_others() if($self->option("list-others"));
	$self->list_all() if($self->option("list-all"));
	$self->get_image_option() if($self->param("get-image-option"));
	$self->set_image_option() if($self->param("set-image-option"));
	$self->get_other_option() if($self->param("get-other-option"));
	$self->set_other_option() if($self->param("set-other-option"));


	return $self;
}

sub help
{
	my $self = shift;

	$self->message("linoratix-config $BASE_VERSION\n");
	$self->message("	module: LILO $MOD_VERSION\n\n");
	print "	--get-global-option option				returns the value\n";
	print "	--set-global-option option --option value		sets the value\n";
	print "	--get-image-option option --id id			gets value of id'th image\n";
	print "	--set-image-option option --option value --id id	sets value of id'th image\n";
	print "	--get-other-option option --id id			gets value of id'th device (other)\n";
	print "	--set-other-option option --option value --id id	sets value of id'th device (other)\n";
	print "	--list-images						returns all bootable images\n";
	print "	--list-others						returns all other bootable devices\n";
	print "	--list-all						returns all bootable devices\n";
	print "	--help 							display help message\n\n";
}

sub generate_lilo_conf
{
	my $self = shift;
	$self->message("Autogenerating lilo.conf please wait ...\n");
	$self->_scan_devices();
}

sub _scan_devices
{
	my $self = shift;
	my @parts = ();
	my $prog = 0;
	my $jump = 0;
	my $lilo_dump;
	my $boot = $self->param("boot-device");
	my $vga  = $self->param("vga");
	my $resume = $self->param("resume");
	my $root = $self->param("linoratix-root");
	open(FH,"</proc/partitions");
	chomp(@parts = <FH>);
	close(FH);

	$jump = 100 / scalar(@parts);

	$lilo_dump = qq~
boot = /dev/$boot
vga = $vga
timeout = 10
prompt
change-rules
lba32

bitmap = /boot/linoratix.bmp
bmp-table = 23,16;1,15,16,4
bmp-colors = 7,,;20,,
bmp-timer = 7,29;20,1,
	
install=bmp



image = /boot/vmlinuz-linoratix
label = Linoratix
append = "root=/dev/ram0 real_root=$root init=/linuxrc resume2=$resume splash=silent"
initrd = /boot/initrd-linoratix
root = $root
read-only

		~;

	mkdir("/tmp_mnt");

	foreach(@parts) {
		my ($dummy, $dummy, $dummy, $part) = split(/\s+/);
		system("mount /dev/$part /tmp_mnt > /dev/null 2> /dev/null");
		if($? eq "0") {
			if(-f "/tmp_mnt/boot.ini") {
				# windows nt/2k/xp
				$lilo_dump .= qq~
other = /dev/$part
label = Windows

					~;
			}
		}
		system("umount /tmp_mnt > /dev/null 2>&1");
	}

	rmdir("/tmp_mnt");
	
	open(FH, ">".$self->param("prefix")."/etc/lilo.conf");
	print FH $lilo_dump;
	close(FH);
}

sub get_global_option
{
	my $self = shift;
	print $lilo_conf_global->{$self->param("get-global-option")} . "\n";
}

sub set_global_option
{
	my $self   = shift;
	my $option = $self->param("set-global-option");
	my $value  = $self->param($option);
	
	$lilo_conf_global->{$option} = $value;

	write_lilo_conf();
}

sub read_lilo_conf
{
	my @dummy;
	my $image;
	my $image_count = -1;
	my $other;
	my $other_count = -1;

	open(FH, "/etc/lilo.conf") or exit 200;
	while(<FH>) {
		# as soon as image = .* or other = .* begins the global section has ended
		chomp;
		next if($_ eq "");
		next if(m/^#/);
		if(m/^\s*image/i) { $image = 1; $other = 0; $image_count++ }
		if(m/^\s*other/i) { $image = 0; $other = 1; $other_count++ }
		@dummy = (m/^\s*(.*?)\s*(=\s*(.*?))?\s*(#.*?)?$/gms);
		if($image) {
			$lilo_conf_images->[$image_count]->{$dummy[0]} = $dummy[2];
		}
		elsif($other) {
			$lilo_conf_others->[$other_count]->{$dummy[0]} = $dummy[2];
		}
		else {
			$lilo_conf_global->{$dummy[0]} = $dummy[2];
		}
	}
	close(FH);
}

sub write_lilo_conf
{
	my $self = shift;
	my $image;
	my $other;
	my @sort_images_array = qw(image append);

	open(FH, ">/etc/lilo.conf") or exit 201;
	# write global config
	print FH "boot = ";
	print FH $lilo_conf_global->{"boot"} && delete($lilo_conf_global->{"boot"});
	print FH "\n";
	if($lilo_conf_global->{"message"}) {
		print FH "message = ";
		print FH $lilo_conf_global->{"message"} && delete($lilo_conf_global->{"message"});
		print FH "\n";
	}
	if($lilo_conf_global->{"vga"}) {
		print FH "vga = ";
		print FH $lilo_conf_global->{"vga"} && delete($lilo_conf_global->{"vga"});
		print FH "\n";
	}
	if($lilo_conf_global->{"timeout"}) {
		print FH "timeout = ";
		print FH $lilo_conf_global->{"timeout"} && delete($lilo_conf_global->{"timeout"});
		print FH "\n";
	}
	if(exists $lilo_conf_global->{"prompt"}) {
		print FH "prompt";
		delete($lilo_conf_global->{"prompt"});
		print FH "\n";
	}
	if(exists $lilo_conf_global->{"change-rules"}) {
		print FH "change-rules";
		delete($lilo_conf_global->{"change-rules"});
		print FH "\n";
	}
	foreach(keys %{$lilo_conf_global}) {
		if($lilo_conf_global->{$_}) {
			print FH "$_ = " . $lilo_conf_global->{$_} . "\n";
		} else {
			print FH "$_\n";
		}
	}
	# write image section
	print FH "\n";
	foreach(@{$lilo_conf_images}) {
		print FH "image = ";
		print FH $$_{"image"} && delete($$_{"image"});
		print FH "\n";
		foreach $image (keys %$_) {
			if($$_{$image}) {
				print FH "$image = ".$$_{$image}."\n";
			} else {
				print FH "$image\n";
			}
		}
	}
	print FH "\n";
	# write other section
	foreach(@{$lilo_conf_others}) {
		foreach $other (keys %$_) {
			if($$_{$other}) {
				print FH "$other = ".$$_{$other}."\n";
			} else {
				print FH "$other\n";
			}
		}
	}
	close(FH);
	
	exit 202;
}

sub list_images
{
	my $self = shift;
	my $id   = 0;
	foreach(@{$lilo_conf_images}) {
		print $id."=".$_->{"label"}."\n";
		$id++;
	}
}

sub list_others
{
	my $self = shift;
	my $id   = 0;
	foreach(@{$lilo_conf_others}) {
		print $id."=".$_->{"label"}."\n";
		$id++;
	}
}

sub list_all
{
	my $self = shift;
	$self->list_images(); $self->list_others();
}

sub set_image_option
{
	my $self   = shift;
	my $id     = $self->param("id");
	my $key    = $self->param("set-image-option");
	my $option = $self->param($key);
	
	$lilo_conf_images->[$id]->{$key} = $option;

	write_lilo_conf();
}

sub get_image_option
{
	my $self = shift;
	my $id   = $self->param("id");
	my $key  = $self->param("get-image-option");
	
	print $lilo_conf_images->[$id]->{$key}."\n";
}

sub set_other_option
{
	my $self   = shift;
	my $id     = $self->param("id");
	my $key    = $self->param("set-other-option");
	my $option = $self->param($key);
	
	$lilo_conf_others->[$id]->{$key} = $option;

	write_lilo_conf();
}

sub get_other_option
{
	my $self = shift;
	my $id   = $self->param("id");
	my $key  = $self->param("get-other-option");
	
	print $lilo_conf_others->[$id]->{$key}."\n";
}


1;


