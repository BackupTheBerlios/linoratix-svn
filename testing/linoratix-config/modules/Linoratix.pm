#
# Linoratix Module for the different Scripts
#

package Linoratix;

use strict;
use vars qw(@ISA @EXPORT $BASE_VERSION);
use Exporter;
$BASE_VERSION = "0.0.1";
@ISA = qw(Exporter);
@EXPORT = qw(&new &param &option &message &warning &error &msg_package $BASE_VERSION);

use Data::Dumper;
use Term::ANSIColor;

sub new
{
	my $linoratix = shift;
	my $class     = ref($linoratix) || $linoratix;
	my $self      = { @_ };
	
	bless($self, $class);

	return $self;
}

sub param
{
	my $self = shift;
	my $p    = shift;
	my $argv = join(",", @ARGV) . ",";

	if($argv =~ m/--$p,(.*?),/) {
		return $1;
	} else {
		return "";
	}
}

sub option
{
	my $self = shift;
	my $p    = shift;
	my $argv = join(",", @ARGV);	
	
	if($argv =~ m/--$p/) {
		return 1;
	} else {
		return "";
	}
}

sub message
{
	my $self = shift;
	my $m    = shift;

	$m = $self unless($m);

	print color "bold green";
	print " >> ";
	print color "reset";
	print $m;
}

sub warning
{
	my $self = shift;
	my $m    = shift;

	print color "bold yellow";
	print " >> ";
	print color "reset";
	print $m;
}

sub error
{
	my $self = shift;
	my $m    = shift;

	print color "bold red";
	print " !! ";
	print color "reset";
	print "$m";
}

sub msg_package
{
	my $self = shift;
	my $m    = shift;

	print color "bold blue";
	print " >> ";
	print color "reset";
	print "$m";
}

1;

