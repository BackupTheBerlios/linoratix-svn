#
# Linoratix module to manage network devices
#

package Linoratix::eth;
use Linoratix;

use strict;
no strict "refs";

use Data::Dumper;

use vars qw(@ISA @EXPORT $MOD_VERSION @COMPATIBLE);
use Exporter;
$MOD_VERSION = "1.0.0";
@COMPATIBLE = qw("0.0.1");
@ISA = qw(Exporter);
@EXPORT = qw(&new);


# namespcae 400 - 499
sub new
{
	my $linoratix = shift;
	my $class     = ref($linoratix) || $linoratix;
	my $self      = { @_ };

	bless($self, $class);

	$self->help() if($self->option("help"));
	$self->list_devices() if($self->option("list-devices"));
	$self->get_ip() if($self->param("get-ip"));
	$self->get_netmask() if($self->param("get-netmask"));
	$self->get_gateway() if($self->param("get-gateway"));
	$self->set_ip() if($self->param("set-ip"));
	$self->set_netmask() if($self->param("set-netmask"));
	$self->set_gateway() if($self->param("set-gateway"));
	$self->add_device() if($self->param("add-device"));
	$self->del_device() if($self->param("del-device"));

	return $self;
}

sub help
{
	my $self = shift;
	$self->message("linoratix-config $BASE_VERSION\n");
	$self->message("	module: eth $MOD_VERSION\n\n");

	print "	--help					display help message\n";
	print "\n";
	print "	--add-device dev			adds a new device config\n";
	print "	--del-device dev			delete a device config\n";
	print "	--list-devices				list all known network devices\n";
	print "\n";
	print "	--get-ip device				get ip from device\n";
	print "	--get-netmask device			get netmask from device\n";
	print "	--get-gateway device			get gateway from device\n";
	print "\n";
	print "	--set-ip device	     --ip ip		set ip for device\n";
	print "	--set-netmask device --netmask mask	set netmask for device\n";
	print "	--set-gateway device --gateway gw	set gateway for device\n";
	print "\n";
}

sub add_device
{
	my $self = shift;
	my $dev  = $self->param("add-device");
	open(FH, ">/etc/conf.d/net.$dev") or exit 410;
		print FH "# config for $dev\n";
	close(FH);
	$self->message("Added device $dev\n");
}

sub del_device
{
	my $self = shift;
	my $dev  = $self->param("del-device");
	unlink("/etc/conf.d/net.$dev") or exit 411;
}

sub list_devices
{
	my $self = shift;
	my @devices;
	
	@devices = $self->get_devices();
	foreach(@devices) {
		print $_."\n";
	}
}

sub get_ip
{
	my $self = shift;
	my $dev  = $self->param("get-ip");

	# open config file
	open(FH, "</etc/conf.d/net.$dev") or exit 402;
	while(<FH>) {
		chomp;
		if(m/^IP=(.*?)$/) {
			print $1."\n";
			return 0;
		}
	}
	close(FH);
}

sub set_ip
{
	my $self = shift;
	my $dev  = $self->param("set-ip");
	my $ip   = $self->param("ip");
	my @oldfile;
	my $_ok=0;

	open(FH, "</etc/conf.d/net.$dev") or exit 402;
		chomp(@oldfile = <FH>);
	close(FH);

	open(FH, ">/etc/conf.d/net.$dev") or exit 403;
	foreach(@oldfile) {
		if(m/^IP=.*?$/) {
			$_ok = 1;
			print FH "IP=" . $ip ."\n";
		} else {
			print FH $_ . "\n";
		}
	}
	print FH "IP=$ip\n" unless($_ok); 
	close(FH);
	return 0;
}

sub get_netmask
{
	my $self = shift;
	my $dev  = $self->param("get-netmask");

	# open config file
	open(FH, "</etc/conf.d/net.$dev") or exit 402;
	while(<FH>) {
		chomp;
		if(m/^NETMASK=(.*?)$/) {
			print $1."\n";
			return 0;
		}
	}
	close(FH);
}

sub set_netmask
{
	my $self = shift;
	my $dev  = $self->param("set-netmask");
	my $mask = $self->param("netmask");
	my @oldfile;
	my $_ok=0;

	open(FH, "</etc/conf.d/net.$dev") or exit 402;
		chomp(@oldfile = <FH>);
	close(FH);

	open(FH, ">/etc/conf.d/net.$dev") or exit 403;
	foreach(@oldfile) {
		if(m/^NETMASK=.*?$/) {
			print FH "NETMASK=" . $mask ."\n";
		} else {
			print FH $_ . "\n";
		}
	}
	print FH "NETMASK=$mask\n" unless($_ok); 
	close(FH);
	return 0;
}

sub get_gateway
{
	my $self = shift;
	my $dev  = $self->param("get-gateway");

	# open config file
	open(FH, "</etc/conf.d/net.$dev") or exit 402;
	while(<FH>) {
		chomp;
		if(m/^GATEWAY=(.*?)$/) {
			print $1."\n";
			return 0;
		}
	}
	close(FH);
}

sub set_gateway
{
	my $self = shift;
	my $dev  = $self->param("set-gateway");
	my $gw   = $self->param("gateway");
	my @oldfile;
	my $_ok=0;

	open(FH, "</etc/conf.d/net.$dev") or exit 402;
		chomp(@oldfile = <FH>);
	close(FH);

	open(FH, ">/etc/conf.d/net.$dev") or exit 403;
	foreach(@oldfile) {
		if(m/^GATEWAY=.*?$/) {
			print FH "GATEWAY=" . $gw ."\n";
		} else {
			print FH $_ . "\n";
		}
	}
	print FH "GATEWAY=$gw\n" unless($_ok); 
	close(FH);
	return 0;
}

sub get_devices
{
	my $self = shift;
	my @lines;
	my @devices;
	
	open(FH, "</proc/net/dev") or exit 401;
		chomp(@lines = <FH>);
	close(FH);

	foreach(@lines) {
		m/^\s+(eth\d+):/;
		if($1) {
			push(@devices, $1);
		}
	}
	
	return @devices;
}

1;

