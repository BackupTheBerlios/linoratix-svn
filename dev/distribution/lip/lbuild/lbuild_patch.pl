#!/usr/bin/perl

use strict;

my @s = split(/\//, $ARGV[1]);

system("wget -O ../../patches/$s[-1] $ARGV[1]");

system($ARGV[0] . " " . $s[-1]);
