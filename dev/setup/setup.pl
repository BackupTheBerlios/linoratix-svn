#!/usr/bin/perl -w

use strict;
no strict "refs";
use File::Temp qw( :POSIX );
use Curses::UI;

require("lang/de.lang.pl");

# ---------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------
my $debug = 0;

# different options for curses
my %args = (
	-border		=> 1, 
	-titlereverse	=> 0, 
	-padtop		=> 2, 
	-padbottom	=> 3, 
	-ipad		=> 1,
	-tfg		=> "blue",
	-bfg		=> "red"
);

# Create the root object.
my $cui = new Curses::UI 
( 
	-clear_on_exit => 1, 
	-debug => $debug,
	-color_support => 1
);


$cui->progress(
	-max => 5,
	-message => _("MSG_INIT_SETUP"),
	%args
);

# ---------------------------------------------------------------------
# Init
# ---------------------------------------------------------------------

if (@ARGV and $ARGV[0] eq '-d')
{
	my $fh = tmpfile();
	open STDERR, ">&fh";
	$debug = 1;
}
else
{
	# We do not want STDERR to clutter our screen.
	my $fh = tmpfile();
	open STDERR, ">&fh";
}

$cui->setprogress(1);

# Wizard index
my $current_step = 1;

# Wizard  windows
my %w = ();

# menu structure
my $file_menu = [
	{ -label => _("MSG_QUIT"),		-value => sub {exit(0)}		},
];

my $menu = [
	{ -label => _("MNU_FILE"),		-submenu => $file_menu		}
];

# main  window
my $w0 = $cui->add(
	'w0', 'Window', 
	-border        => 1, 
	-y             => -1, #=
	-height        => 3,
);

# all the different screens
my %screens = (
	'1'	=> _("SCR_WELCOME"),
	'2'	=> _("SCR_TARGET_DISK"),
	'3'	=> _("SCR_HOWTO_PARTITION"),
	'4'	=> _("SCR_PARTITIONING")
);

# bring all screens to the right 
my @screens = sort {$a<=>$b} keys %screens;

my $disks = `/usr/sbin/shwdev.sh -disk`;
chomp($disks);
$cui->setprogress(2);

my @disks = split(/ /, $disks);
my $target_disk_values = [];
my $target_disk_labels = {};

my $target_disk_text1 = "";
my $target_disk_text2 = "";

my $all_partitions = `/usr/sbin/shwdev.sh -partition`;
chomp($all_partitions);
my @all_partitions = split(/ /, $all_partitions);

# ------------------------
# setup config
# ------------------------
my $setup_config;


$cui->setprogress(3);

foreach my $target_disk_key (@disks)
{
	push(@$target_disk_values, $target_disk_key);
	chomp($target_disk_text1 = `/usr/sbin/partinfo model /dev/$target_disk_key`);
	chomp($target_disk_text2 = `/usr/sbin/partinfo size /dev/$target_disk_key`);
	my $gerundet = sprintf("%i", $target_disk_text2 / 1024 / 1024);
	$target_disk_labels->{$target_disk_key} = "/dev/$target_disk_key - $gerundet GiB ($target_disk_text1)";
}

$cui->setprogress(4);

my $howto_partition_values = [ 1, 2, 3 ];
my $howto_partition_labels = {
	"1"	=> _("MSG_USE_ENTIRE_DISK"),
	"2"	=> _("MSG_USE_ONLY_FREE_SPACE"),
	"3"	=> _("MSG_PARTITION_BY_HAND")
};



$cui->setprogress(5);

# progress end
$cui->noprogress;

# ---------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------

sub goto_prev_step()
{
	$current_step--;
	$current_step = 1 if $current_step < 1;
	$w{$current_step}->focus;
}

sub goto_next_step()
{
	$current_step++;
	$current_step = @screens if $current_step > @screens;
	my $dialog_sub = "dialog_$current_step";
	&$dialog_sub();
	
	$w{$current_step}->focus;
}

sub select_step($;)
{
	my $nr = shift;
	$current_step = $nr;
	$w{$current_step}->focus;
}

sub target_disk_callback()
{
	my $listbox = shift;
	$setup_config->{"target_disk"} = $listbox->get;
	goto_next_step();
}

sub howto_partition_callback
{
	my $listbox = shift;
	$setup_config->{"howto_parition"} = $listbox->get;
	goto_next_step();
}

# ----------------------------------------------------------------------
# Create a menu
# ----------------------------------------------------------------------

$cui->add('menu', 'Menubar', -menu => $menu);

# ----------------------------------------------------------------------
# Create the explanation window
# ----------------------------------------------------------------------

$w0->add('explain', 'Label', 
	-text => "CTRL+P: " . _("MSG_PREV") . "  CTRL+N: " . _("MSG_NEXT") . "  "
		. "CTRL+X: " . _("MSG_MENU")
);


# ----------------------------------------------------------------------
# Create the wizard windows
# ----------------------------------------------------------------------

while (my ($nr, $title) = each %screens)
{
	my $id = "window_$nr";
	$w{$nr} = $cui->add(
		$id, 'Window', 
		-title => "Linoratix Installation: $title ($nr/" . scalar(@screens) . ")",
		%args
	);
	
}

# ----------------------------------------------------------------------
# Setup bindings and focus 
# ----------------------------------------------------------------------

# Bind <CTRL+X> to menubar.
$cui->set_binding( sub{ shift()->root->focus('menu') }, "\cX" );
$cui->set_binding( \&goto_next_step, "\cN" );
$cui->set_binding( \&goto_prev_step, "\cP" );


# load 1st window

dialog_1();
$w{$current_step}->focus();


# ----------------------------------------------------------------------
# Lets rock'n'roll...
# ----------------------------------------------------------------------

MainLoop;

# ----------------------------------------------------------------------
# Greeting
# ----------------------------------------------------------------------
sub dialog_1
{
	$w{1}->add(
		undef, 'Label',
		-text	=> "dsfsdfsf"._("MSG_GREETING")
	);
}

# ----------------------------------------------------------------------
# Installationsziels
# ----------------------------------------------------------------------
sub dialog_2
{
	$w{2}->add
	(
		undef, 'Label',
		-text => _("HLP_TARGET_DISK")
	);
	
	
	$w{2}->add
	(
		undef, 'Radiobuttonbox',
		-y          => 5,
		-x          => 2,
		-values     => $target_disk_values,
		-labels     => $target_disk_labels,
		-width      => 50,
		-border     => 1,
		-title      => _("MSG_TARGET_DISK"),
		-vscrollbar => 1,
		-onchange   => \&target_disk_callback,
	);
}

# ----------------------------------------------------------------------
# partitionierung
# ----------------------------------------------------------------------	
sub dialog_3
{
	my $target_disk_model = `/usr/sbin/partinfo model /dev/$setup_config->{target_disk}`;
	chomp($target_disk_model);
	
	my $target_disk_size = `/usr/sbin/partinfo size /dev/$setup_config->{target_disk}`;
	chomp($target_disk_size);
	
	$target_disk_size = sprintf("%i GiB", $target_disk_size / 1024 / 1024);
	
	$w{3}->add
	(
		undef, 'Label',
		-text => _("MSG_TARGET_DISK") . ": /dev/" . $setup_config->{"target_disk"} . " - $target_disk_size ($target_disk_model)"
	);
	
	
	$w{3}->add
	(
		undef, 'Radiobuttonbox',
		-y          => 5,
		-x          => 2,
		-values     => $howto_partition_values,
		-labels     => $howto_partition_labels,
		-width      => 60,
		-border     => 1,
		-title      => _("MSG_HOWTO_PARTITION"),
		-vscrollbar => 1,
		-onchange   => \&howto_partition_callback,
	);
}

# ----------------------------------------------------------------------
# partitionieren teil 2
# ----------------------------------------------------------------------
sub dialog_4
{
	my $target_disk_model = `/usr/sbin/partinfo model /dev/$setup_config->{target_disk}`;
	chomp($target_disk_model);
	
	my $target_disk_size = `/usr/sbin/partinfo size /dev/$setup_config->{target_disk}`;
	chomp($target_disk_size);
	
	my $part_mod;
	
	if($setup_config->{"howto_parition"} eq "1")  # ganze platte verwenden
	{
		$part_mod = _("MSG_USE_ENTIRE_DISK");
	}
	elsif($setup_config->{"howto_parition"} eq "2") # nur freien platz verwenden
	{
		$part_mod = _("MSG_USE_ONLY_FREE_SPACE");
	}
	elsif($setup_config->{"howto_parition"} eq "3") # selbst partitionieren
	{
		$part_mod = _("MSG_PARTITION_BY_HAND");
	}
	
	$target_disk_size = sprintf("%i GiB", $target_disk_size / 1024 / 1024);
	$w{4}->add
	(
		undef, 'Label',
		-text => _("MSG_TARGET_DISK") . ": /dev/" . $setup_config->{"target_disk"} . " - $target_disk_size ($target_disk_model)\n"
			. _("MSG_PARTITION_MODI") . ": " . $part_mod
	);
}
