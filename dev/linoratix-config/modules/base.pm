#
# Linoratix module to manage base system prefs
#

package Linoratix::base;
use Linoratix;

use strict;

use vars qw(@ISA @EXPORT $MOD_VERSION);
use Exporter;
$MOD_VERSION = "0.0.2";
@ISA = qw(Exporter);
@EXPORT = qw(&new);

# namespace [100-199]

sub new
{
	my $linoratix = shift;
	my $class     = ref($linoratix) || $linoratix;
	my $self      = { @_ };

	bless($self, $class);

	$self->help() if($self->option("help"));
	$self->beep_on_off() if($self->param("beep"));
	$self->set_motd() if($self->param("motd"));
	$self->set_issue() if($self->param("issue"));
	
	return $self;
}

sub help
{
	my $self = shift;

	$self->message("linoratix-config $BASE_VERSION\n");
	$self->message("	module: base $MOD_VERSION\n\n");
	print "	--help 			display help message\n";
	print "	--beep <on|off>		turns console beep on or off\n";
	print "	--motd <filename>	set a new message of the day\n";
	print "	--issue <filename>	set a issue file\n\n";
}

sub set_motd
{
	my $self = shift;
	my $file = $self->param("motd");
		
	unless(-f "$file") {
		$self->error("Sorry, but $file is not a valid file!\n");
		return 155;
	}
	system("/bin/cp -f $file /etc/motd");
	print "\n";
	$self->message("New message of the day installed.\n");
}

sub set_issue
{
	my $self = shift;
	my $file = $self->param("issue");
		
	unless(-f "$file") {
		$self->error("Sorry, but $file is not a valid file!\n");
		return 155;
	}
	system("/bin/cp -f $file /etc/issue");
	print "\n";
	$self->message("New issue file installed.\n");
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
	if(($self->param("beep") eq "on" && m/set bell-style on/) || ($self->param("beep") eq "none" && m/set bell-style none/)) {
	}
	# beep is on and should be off 
	elsif($self->param("beep") eq "off" && m/set bell-style on/) {
		s/set bell-style on/set bell-style none/gmis;
	}
	# beep is none and should be on
	elsif($self->param("beep") eq "on" && m/set bell-style none/) {
		s/set bell-style none/set bell-style on/gmis;
	}
	# beep is not defined and should be on
	elsif($self->param("beep") eq "on") {
		$_ .= "\nset bell-style on\n";
	}
	# beep is not defined and should be off
	elsif($self->param("beep") eq "off") {
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

