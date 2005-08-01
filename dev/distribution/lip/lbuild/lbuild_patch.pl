#!/usr/bin/perl

use strict;
use Data::Dumper;

my @s = split(/\//, $ARGV[1]);

print "Patching...\n";
my $cwd = `pwd`;
chomp $cwd;
print "pwd: $cwd\n";

print Dumper($ARGV);

sleep 30;

system("wget -O ../../patches/$s[-1] $ARGV[1]");

system($ARGV[0] . " " . $s[-1]);
