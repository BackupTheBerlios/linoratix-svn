#
# Linoratix module to manage openvpn
#

package Linoratix::OpenVPN;
use Linoratix;

use strict;
no strict "refs";


use Data::Dumper;

use vars qw(@ISA @EXPORT $MOD_VERSION @COMPATIBLE);
use Exporter;
$MOD_VERSION = "0.1.0";
@COMPATIBLE = qw("0.0.1");
@ISA = qw(Exporter);
@EXPORT = qw(&new);


# namespcae 500 - 599

sub new
{
	my $linoratix = shift;
	my $class     = ref($linoratix) || $linoratix;
	my $self      = { @_ };

	bless($self, $class);

	$self->help() if($self->option("help"));
	$self->list_keys() if($self->option("list-keys"));
	$self->list_computers() if($self->option("list-computers"));
	$self->delete_key() if($self->param("delete-key"));
	$self->delete_computer() if($self->param("delete-computer"));
	$self->generate_key() if($self->param("generate-key"));

	return $self;
}

sub help
{
	my $self = shift;

	$self->message("linoratix-config $BASE_VERSION\n");
	$self->message("	module: OpenVPN $MOD_VERSION\n\n");
	print "	--help						display help message\n";
	print "\n";
	print "	--list-keys					list all vpn keys\n";
	print "	--delete-key key				delete vpn keys\n";
	print "	--generate-key key				generate a vpn key\n";
	print "\n";
	print "	--list-computers				list all computers\n";
	print "	--delete-computer computer			delete a computer\n";
	print "	--add-computer computer	\\			add a computer\n";
	print "		--remote		[host|ip]	vpn gateway extern ip\n";
	print "		--key 			key-file	encryption key\n";
	print "		--dev 			dev		device\n";
	print "		--local-ip		ip		local intern ip\n";
	print "		--remote-ip		ip		remote intern ip of the vpn gateway\n";
	print "		--port 			port		port the vpn should use.\n";
	print "		--lzo 					if set compression will be used\n";
	print "		--remote-mask		netmask		remote netmask\n";
	print "		--remote-network	network		remote network\n";
	print "\n";
}


sub list_keys
{
	my $self = shift;
	opendir(DH, "/etc/openvpn") or exit 501;
	my @files = grep { /\.key$/ } readdir(DH);
	closedir(DH);

	foreach(@files) {
		print $_."\n";
	}
}

sub delete_key
{
	my $self = shift;
	my $key  = $self->param("delete-key");
	my @inhalt;
	
	# testen ob ein computer den key verwendet
	opendir(DH, "/etc/openvpn") or exit 501;
	my @files = grep { /\.conf$/ } readdir(DH);
	closedir(DH);
	
	foreach my $file (@files) {
		open(FH, "</etc/openvpn/$file") or exit 502;
		while(<FH>) {
			if(/secret $key\.key/) {
				exit 550;
			}
		}
		close(FH);
	}

	unlink("/etc/openvpn/$key.key");
	return 0;
}

sub generate_key
{
	my $self = shift;
	my $key  = $self->param("generate-key");
	system("openvpn --genkey --secret /etc/openvpn/$key.key");
	if( $? ne "0") {
		exit 560;
	}
	return 0;
}

sub list_computers
{
	my $self = shift;

	opendir(DH, "/etc/openvpn") or exit 501;
		my @files = grep { /\.conf$/ } readdir(DH);
	closedir(DH);

	foreach(@files) {
		print "$_\n";
	}
}

sub add_computer
{
	my $self        = shift;
	my $comp        = $self->param("add-computer");
	my $remote      = $self->param("remote");
	my $key         = $self->param("key");
	my $dev         = $self->param("dev");
	my $local_ip    = $self->param("local-ip");
	my $remote_ip   = $self->param("remote-ip");
	my $port        = $self->param("port");
	my $lzo         = $self->option("lzo");
	my $remote_mask = $self->option("remote-netmask"); 
	my $remote_net  = $self->option("remote-network");

	open(FH, ">/etc/openvpn/$comp.conf") or exit 590;
		print FH "remote $remote\n";
		print FH "dev $dev\n";
		print FH "ifconfig $local_ip $remote_ip\n";
		print FH "secret $key\n";
		print FH "up /etc/openvpn/$comp.sh\n";
		print FH "port $port\n";
		if($lzo) {
			print FH "comp-lzo\n";
		}
		print FH "ping 15\n";
		print FH "ping-restart 45\n";
		print FH "ping-timer-rem\n";
		print FH "persist-tun\n";
		print FH "persist-key\n";
		print FH "verb 3\n";
	close(FH);

	open(FH, ">/etc/openvpn/$comp.sh") or exit 595;
		print FH "#!/bin/bash\n\n";
		print FH ". /etc/rc.d/rc.vpn-functions\n";
		print FH "free_tun_dev\n";
		print FH "route add -net $remote_net gw $remote_ip netmask $remote_mask dev \$TUN_DEV\n";
	close(FH);
}

sub delete_computer
{
	my $self = shift;
	my $comp = $self->param("delete-computer");

	unlink("/etc/openvpn/$comp.conf") or exit 570;
}


1;


