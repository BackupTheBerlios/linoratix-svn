#!/usr/bin/perl -w

use strict;
no strict "refs";
use File::Temp qw( :POSIX );
use Curses::UI;

use Data::Dumper;

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
	-min => 0,
	-max => 8,
	-title => _("MSG_INIT_SETUP"),
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

$cui->setprogress(1, _("MSG_INIT_DISKS"));

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
	-y             => -1, #==
	-height        => 3,
);

# all the different screens
my %screens = (
	'1'	=> _("SCR_WELCOME"),
	'2'	=> _("SCR_TIMEZONE"),
	'3'	=> _("SCR_TARGET_DISK"),
	'4'	=> _("SCR_HOWTO_PARTITION"),
	'5'	=> _("SCR_PARTITIONING"),
	'6' => _("SCR_PREPARE_DISK"),
	'7' => _("SCR_INSTALL_BASE_SYSTEM"),
);

# bring all screens to the right 
my @screens = sort {$a<=>$b} keys %screens;

my $disks = `/usr/sbin/shwdev.sh -disk`;
chomp($disks);
$cui->setprogress(2, _("MSG_INIT_PARTITIONS"));

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


$cui->setprogress(3, _("MSG_READ_DISK_INFO"));

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



$cui->setprogress(5, _("MSG_SEARCH_HARDWARE"));

my $hardware = `/usr/sbin/kudzu -p`;


$cui->setprogress(6);
scan_hardware();

$cui->setprogress(7, _("MSG_READ_TIMEZONE"));
	
	
my @zonen = ();
chomp(@zonen = `find /usr/share/zoneinfo`);
@zonen = grep {/^\/usr\/share\/zoneinfo\/[A-Z]/} @zonen;
my @sorted = ();
foreach my $zone (@zonen)
{
	$zone =~ s:/usr/share/zoneinfo/::gms;
	push(@sorted, $zone);
}

@sorted = sort { $a cmp $b } @sorted;

my $timezone_values = [];
my $timezone_labels = {};

foreach my $zone (@sorted)
{
	push(@$timezone_values, $zone);
	$timezone_labels->{$zone} = $zone;
}	


$cui->setprogress(8);


# progress end
$cui->noprogress;

# ---------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------

sub scan_hardware()
{
	my @hardware = split(/-\n/, $hardware);
	chomp(@hardware);

	my $setup_config = {};

	my %class;

	foreach my $hw_section (@hardware)
	{
		my @lines = split(/\n/, $hw_section);
		foreach my $line (@lines)
		{
			my($key, $val) = split(/: /, $line);
			$class{$key} = $val;
		}
		if($class{"class"})
		{
			push(@{$setup_config->{"hardware"}->{$class{"class"}}}, $class{"driver"});
		}
	}
}

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

sub howto_partition_callback($;)
{
	my $listbox = shift;
	$setup_config->{"howto_partition"} = $listbox->get;
	goto_next_step();
}

sub timezone_callback($;)
{
	my $listbox = shift;
	$setup_config->{"timezone"} = $listbox->get;
	goto_next_step();
}

sub really_part_callback($;)
{
	my $buttons = shift;
	if($buttons->get eq "cancel")
	{
		goto_prev_step();
	}
	else
	{
		goto_next_step();
	}
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
		-text	=> _("MSG_GREETING")
	);
}

# ----------------------------------------------------------------------
# Zeitzone
# ----------------------------------------------------------------------
sub dialog_2
{
	$w{2}->add(
		undef, 'Label',
		-text	=> _("MSG_SELECT_TIMEZONE")
	);	
	$w{2}->add(
		undef, 'Listbox',
		-y		=> 4, #==
		-padbotton	=> 2,
		-values	=> $timezone_values,
		-labels => $timezone_labels,
		-width 	=> 60,
		-border	=> 1,
		-title	=> _("MSG_TIMEZONE"),
		-vscrollbar	=> 1,
		-onchange => \&timezone_callback,
	);
}

# ----------------------------------------------------------------------
# Installationsziels
# ----------------------------------------------------------------------
sub dialog_3
{
	$w{3}->add
	(
		undef, 'Label',
		-text => _("HLP_TARGET_DISK")
	);
	
	
	$w{3}->add
	(
		undef, 'Listbox',
		-y          => 5,
		-x          => 2,
		-values     => $target_disk_values,
		-labels     => $target_disk_labels,
		-width      => 60,
		-border     => 1,
		-title      => _("MSG_TARGET_DISK"),
		-vscrollbar => 1,
		-onchange   => \&target_disk_callback,
	);
}

# ----------------------------------------------------------------------
# partitionierung
# ----------------------------------------------------------------------	
sub dialog_4
{
	my $target_disk_model = `/usr/sbin/partinfo model /dev/$setup_config->{target_disk}`;
	chomp($target_disk_model);
	
	my $target_disk_size = `/usr/sbin/partinfo size /dev/$setup_config->{target_disk}`;
	chomp($target_disk_size);
	
	$target_disk_size = sprintf("%i GiB", $target_disk_size / 1024 / 1024);
	
	$w{4}->add
	(
		undef, 'Label',
		-text => _("MSG_TARGET_DISK") . ": /dev/" . $setup_config->{"target_disk"} . " - $target_disk_size ($target_disk_model)"
	);
	
	
	$w{4}->add
	(
		undef, 'Listbox',
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
sub dialog_5
{
	my $target_disk_model = `/usr/sbin/partinfo model /dev/$setup_config->{target_disk}`;
	chomp($target_disk_model);
	
	my $target_disk_size = `/usr/sbin/partinfo size /dev/$setup_config->{target_disk}`;
	chomp($target_disk_size);
	
	my $part_mod;
	
	if($setup_config->{"howto_partition"} eq "1")  # ganze platte verwenden
	{
		$part_mod = _("MSG_USE_ENTIRE_DISK");
	}
	elsif($setup_config->{"howto_partition"} eq "2") # nur freien platz verwenden
	{
		$part_mod = _("MSG_USE_ONLY_FREE_SPACE");
	}
	elsif($setup_config->{"howto_partition"} eq "3") # selbst partitionieren
	{
		$part_mod = _("MSG_PARTITION_BY_HAND");
	}
	
	$target_disk_size = sprintf("%i GiB", $target_disk_size / 1024 / 1024);
	
	if($w{5}->getobj('w5_label'))
	{
		$w{5}->getobj('w5_label')->text("\n"._("MSG_TARGET_DISK") . ": /dev/" . $setup_config->{"target_disk"} . " - $target_disk_size ($target_disk_model)\n"
				. _("MSG_PARTITION_MODI") . ": " . $part_mod . "\n\n" . _("MSG_REALLY_PARTITION"));
	}
	else 
	{
		$w{5}->add
		(
			'w5_label', 'Label',
			-text => "\n"._("MSG_TARGET_DISK") . ": /dev/" . $setup_config->{"target_disk"} . " - $target_disk_size ($target_disk_model)\n"
				. _("MSG_PARTITION_MODI") . ": " . $part_mod . "\n\n" . _("MSG_REALLY_PARTITION")
		);
		
		$w{5}->add
		(
			undef, 'Buttonbox',
			-y => 14, # ==
			-x => 45,
			-buttons => [
				{
					-label => _("BTN_CANCEL"),
					-value => "cancel",
					-onpress => \&really_part_callback,
				},{
					-label => _("BTN_NEXT"),
					-value => "next",
					-onpress => \&really_part_callback,
				},
			],
		);
	}
}

# ----------------------------------------------------------------------
# partitionieren teil 3
# ----------------------------------------------------------------------
sub dialog_6
{
	my $target_disk_model = `/usr/sbin/partinfo model /dev/$setup_config->{target_disk}`;
	chomp($target_disk_model);
	
	my $target_disk_size = `/usr/sbin/partinfo size /dev/$setup_config->{target_disk}`;
	chomp($target_disk_size);
	my $part_mod;
	
	if($setup_config->{"howto_partition"} eq "1")  # ganze platte verwenden
	{
		$part_mod = _("MSG_USE_ENTIRE_DISK");
	}
	elsif($setup_config->{"howto_partition"} eq "2") # nur freien platz verwenden
	{
		$part_mod = _("MSG_USE_ONLY_FREE_SPACE");
	}
	elsif($setup_config->{"howto_partition"} eq "3") # selbst partitionieren
	{
		$part_mod = _("MSG_PARTITION_BY_HAND");
	}
	
	$target_disk_size = sprintf("%i GiB", $target_disk_size / 1024 / 1024);
	
	if($setup_config->{"howto_partition"} eq "1")   # ganze platte
	{
		$w{6}->add
		(
			undef, 'Label',
			-text => _("MSG_TARGET_DISK") . ": /dev/" . $setup_config->{"target_disk"} . " - $target_disk_size ($target_disk_model)\n"
				. _("MSG_PARTITION_MODI") . ": " . $part_mod . "\n\n" . _("MSG_THIS_MAY_TAKE_A_MINUTE"),
		);
			
		$w{6}->add
		(
			'progress_label', 'Label',
			-text => _("MSG_PART_DISK"),
			-x => 2,
			-y => 9, #==
			-width => 70,
		);
		$w{6}->add(
			'progress_partition', 'Progressbar',
			-x => 2,
			-y => 10, #==
			-max => 6,
			-width => 70,
		);
		
		$w{6}->draw;
		$w{6}->getobj('progress_partition')->pos(1);
		$w{6}->draw;
		my @partitions = `/usr/sbin/createpart onedisk /dev/$setup_config->{target_disk}`;
		chomp(@partitions);
		
		$w{6}->getobj('progress_partition')->pos(2);
		$w{6}->getobj('progress_label')->text(_("MSG_PART_FORMAT_BOOT"));
		$w{6}->draw;
		system("/sbin/mkfs.ext3 /dev/" . $setup_config->{"target_disk"} . "1 >/dev/null 2>&1" );
		
		$w{6}->getobj('progress_partition')->pos(3);
		$w{6}->getobj('progress_label')->text(_("MSG_PART_FORMAT_ROOT"));
		$w{6}->draw;
		system("/sbin/mkfs.ext3 /dev/" . $setup_config->{"target_disk"} . "2 >/dev/null 2>&1" );
		
		
		$w{6}->getobj('progress_partition')->pos(4);
		$w{6}->getobj('progress_label')->text(_("MSG_PART_FORMAT_HOME"));		
		$w{6}->draw;
		system("/sbin/mkfs.ext3 /dev/" . $setup_config->{"target_disk"} . "3 >/dev/null 2>&1" );
		
		$w{6}->getobj('progress_partition')->pos(5);
		$w{6}->getobj('progress_label')->text(_("MSG_PART_FORMAT_SWAP"));		
		$w{6}->draw;
		system("/sbin/mkswap /dev/" . $setup_config->{"target_disk"} . "4 >/dev/null 2>&1");
		
		$w{6}->getobj('progress_partition')->pos(5);
		$w{6}->getobj('progress_label')->text(_("MSG_PART_MOUNT"));
		$w{6}->draw;
		system("/sbin/mount /dev/" . $setup_config->{"target_disk"} . "2 /mnt/root >/dev/null 2>&1");
		mkdir("/mnt/root/boot");
		mkdir("/mnt/root/home");
		system("/sbin/mount /dev/" . $setup_config->{"target_disk"} . "1 /mnt/root/boot >/dev/null 2>&1");
		system("/sbin/mount /dev/" . $setup_config->{"target_disk"} . "3 /mnt/root/home >/dev/null 2>&1");
		system("/sbin/swapon /dev/" . $setup_config->{"target_disk"} . "4");
		
		
		goto_next_step();
	}
}

sub dialog_7
{
	$w{7}->add
	(
		undef, 'Label',
		-text => _("MSG_INSTALL_BASE_SYSTEM")
	);
	
	# basissystem entpacken
	
	# bootloader installieren
	
}
