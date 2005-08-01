#!/usr/bin/perl -w

use strict;
use Data::Dumper;

push(@INC, ".");

use Linoratix::Lbuild;

# die übergabeparameter verarbeiten
my $i = 0;
my %params;

for($i = 0; $i < scalar(@ARGV); $i++)
{
	if($ARGV[$i] eq "-f")
	{ # welche datei verarbeitet werden soll (file)
		$params{"file"} = $ARGV[$i+1];
		$i++;
	}
	
	if($ARGV[$i] eq "-g")
	{ # einen wert auslesen (get)
		$params{"get"} = $ARGV[$i+1];
		$i++;
	}
	
	if($ARGV[$i] eq "-s")
	{ # ein shellscript soll erzeugt werden (script)
		$params{"script"} = $ARGV[$i+1];
		$i++;
	}
}

my $lbuild = Linoratix::Lbuild->new(
				'files' => [ $params{"file"} ]
					);

my $get;
if($params{"get"})
{
	$get = $lbuild->get($params{"get"});
}

if($params{"script"})
{
	$get = $lbuild->script($params{"script"});
}

if($get)
{
	print $get . "\n";
}

#print Dumper($lbuild);
