#
# Linoratix module to manage base system prefs
#

package Linoratix::base;
use Linoratix;

use strict;

use vars qw(@ISA @EXPORT $MOD_VERSION);
use Exporter;
$MOD_VERSION = "0.0.1";
@ISA = qw(Exporter);
@EXPORT = qw(&new);

our $linoratix = Linoratix->new();

# namespace [100-199]

sub new
{
	my $linoratix = shift;
	my $class     = ref($linoratix) || $linoratix;
	my $self      = { @_ };

	bless($self, $class);

	help() if($linoratix->option("help"));
	beep_on_off() if($linoratix->param("beep"));
	
	return $self;
}

sub help
{
	my $self = shift;

	$linoratix->message("linoratix-config $BASE_VERSION\n");
	$linoratix->message("	module: base $MOD_VERSION\n\n");
	print "	--help 			display help message\n";
	print "	--beep [on|off]		turns console beep on or off\n\n";
}

#
sub beep_on_off
{
	my $self = shift;
	
	open(FH, "</etc/conf.d/input.conf") or exit 100;
	{
		local $/;
		$_ = <FH>;
	}
	close(FH);

	# beep is on and should be on do nothing
	if(($linoratix->param("beep") eq "on" && m/set bell-style on/) || ($linoratix->param("beep") eq "none" && m/set bell-style none/)) {
	}
	# beep is on and should be off 
	elsif($linoratix->param("beep") eq "off" && m/set bell-style on/) {
		s/set bell-style on/set bell-style none/gmis;
	}
	# beep is none and should be on
	elsif($linoratix->param("beep") eq "on" && m/set bell-style none/) {
		s/set bell-style none/set bell-style on/gmis;
	}
	# beep is not defined and should be on
	elsif($linoratix->param("beep") eq "on") {
		$_ .= "\nset bell-style on\n";
	}
	# beep is not defined and should be off
	elsif($linoratix->param("beep") eq "off") {
		$_ .= "\nset bell-style none\n";
	} else {
		exit 101;
	}
	
	# write new input.conf
	open(FH, ">/etc/conf.d/input.conf") or exit 102;
		print FH $_;
	close(FH);

	exit 103;
}

1;

