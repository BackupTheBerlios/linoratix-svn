#!/usr/bin/perl -w

# <toactivate> beachten!!

use strict;
no strict "refs";
use File::Temp qw( :POSIX );
use Curses::UI;
use Storable;

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

# partitionsinfos
my $partinfo = {};
my $partinfo_values = [];
my $partinfo_labels = {};
my @partinfo = ();
my $selected_partition;
	
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
	'7' => _("SCR_CHOOSE_CATEGORIE"),
	'8' => _("SCR_INSTALL_BASE_SYSTEM"),
	'9' => _("SCR_BOOTMANAGER"),
	'10'=> _("SCR_BOOTMANAGER"),
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

sub really_install_mbr($;)
{
	my $buttons = shift;
	if($buttons->get eq "cancel")
	{
		$current_step++;  # mbr step überspringen
		goto_prev_step();
	}
	else
	{
		goto_next_step();
	}
}


sub partitions_callback($;)
{
	my $listbox = shift;
	$selected_partition = $listbox->get_active_value;
	$w{6}->getobj("part_desc")->text(_("MSG_FILESYSTEM") . ": ".$partinfo->{$listbox->get_active_value}->{"fs"}."\n"
				. _("MSG_SIZE") . ": ".sprintf("%.2f GiB", $partinfo->{$listbox->get_active_value}->{"size"} / 1024 / 1024)."\n"
				. _("MSG_TYPE") . ": ".$partinfo->{$listbox->get_active_value}->{"type"}."\n"
				. _("MSG_MOUNTPOINT") . ": ".$partinfo->{$listbox->get_active_value}->{"mountpoint"}."\n"
				. _("MSG_SEKTOREN") . ": " . $partinfo->{$selected_partition}->{"sector_start"} . " - " . $partinfo->{$selected_partition}->{"sector_end"});
	
}

sub part_button_box_callback($;)
{
	my $buttons = shift;
	if($buttons->get eq "mount")
	{
		my $mp = $buttons->root->question(
			-question => _("MSG_MOUNTPOINT") . ": ",
			-title => _("MSG_SPECIFY_MOUNTPOINT"),
		);
		$partinfo->{$selected_partition}->{"mountpoint"} = $mp;
		if($mp eq "swap")
		{
			$partinfo->{$selected_partition}->{"fs"} = "linux-swap";
		}
		elsif(! $partinfo->{$selected_partition}->{"fs"})
		{
			$partinfo->{$selected_partition}->{"fs"} = "ext3";
		}
		$w{6}->getobj("part_desc")->text(_("MSG_FILESYSTEM") . ": ".$partinfo->{$selected_partition}->{"fs"}."\n"
					. _("MSG_SIZE") . ": ".sprintf("%.2f GiB", $partinfo->{$selected_partition}->{"size"} / 1024 / 1024)."\n"
					. _("MSG_TYPE") . ": ".$partinfo->{$selected_partition}->{"type"}."\n"
					. _("MSG_MOUNTPOINT") . ": ".$partinfo->{$selected_partition}->{"mountpoint"}."\n"
					. _("MSG_SEKTOREN") . ": " . $partinfo->{$selected_partition}->{"sector_start"} . " - " . $partinfo->{$selected_partition}->{"sector_end"});
		$setup_config->{"partitions"}->{"/dev/".$setup_config->{"target_disk"} . $selected_partition}->{"mountpoint"} = $mp;
		if($mp eq "/")
		{
			$setup_config->{"root-partition"} = $setup_config->{"target_disk"} . $selected_partition;
		}
		if($mp eq "/boot")
		{
			$setup_config->{"boot-partition"} = $setup_config->{"target_disk"} . $selected_partition;
		}
		if($mp eq "/" || $mp eq "swap" || $setup_config->{"partitions"}->{"/dev/".$setup_config->{"target_disk"} . $selected_partition}->{"format"})
		{
			$setup_config->{"partitions"}->{"/dev/".$setup_config->{"target_disk"} . $selected_partition}->{"format"} = "1";
		}
		else
		{
			$setup_config->{"partitions"}->{"/dev/".$setup_config->{"target_disk"} . $selected_partition}->{"format"} = "";
		}
	}
	elsif($buttons->get eq "delete")
	{
		system("/usr/sbin/createpart remove_partition /dev/".$setup_config->{"target_disk"}." ".$selected_partition);
		@partinfo = ();
		$partinfo_values = [];
		$partinfo_labels = {};
		my $partinfo_intern = {};
			
		@partinfo = `/usr/sbin/partinfo getall /dev/$setup_config->{target_disk}`;
		my $size_all = `/usr/sbin/partinfo size /dev/$setup_config->{target_disk}`;
		chomp($size_all);
		$size_all *= 2;
			
		my ($sec_end1,$sec_end2,$sec_end3, $part_id1, $part_id2, $part_id3);
			
		chomp(@partinfo);
		foreach(@partinfo)
		{
			my($part_id, $part_start, $part_end, $part_type, $part_fs, $part_size) = split(/:/, $_);
			if($part_id1 && $part_id ne $part_id1+1 && $sec_end1)
			{
				$partinfo_intern->{$part_id-1}->{"sector_start"} = $sec_end1+1;
				$partinfo_intern->{$part_id-1}->{"sector_end"} = $part_start;
				$partinfo_intern->{$part_id-1}->{"type"} = "free";
				$partinfo_intern->{$part_id-1}->{"fs"} = "ext3";
				$partinfo_intern->{$part_id-1}->{"size"} = ($part_start - $sec_end1) / 2;
				$partinfo_intern->{$part_id-1}->{"mountpoint"} = "";
				push(@$partinfo_values, $part_id-1);
				$partinfo_labels->{$part_id-1} = $setup_config->{"target_disk"} . ($part_id-1) . " (".sprintf("%.2f", $partinfo_intern->{$part_id-1}->{"size"} / 1024 / 1024)." GiB) [" . substr("free", 0, 1)."]" ;
				$partinfo->{$selected_partition} = $partinfo_intern->{$part_id-1};
			}
			
			$partinfo_intern->{$part_id}->{"sector_start"} = $part_start;
			$partinfo_intern->{$part_id}->{"sector_end"} = $part_end;
			$partinfo_intern->{$part_id}->{"type"} = $part_type;
			$partinfo_intern->{$part_id}->{"fs"} = $part_fs;
			$partinfo_intern->{$part_id}->{"size"} = $part_size;
			$partinfo_intern->{$part_id}->{"mountpoint"} = "";
			push(@$partinfo_values, $part_id);
			$partinfo_labels->{$part_id} = $setup_config->{"target_disk"} . $part_id . " (".sprintf("%.2f", $part_size / 1024 / 1024)." GiB) [" . substr($part_type, 0, 1)."]" ;
			$part_id1 = $part_id;
			$sec_end1 = $part_end;
		}
		$sec_end1 = 0 unless($sec_end1);
		$part_id1 = 0 unless($part_id1);
		print STDERR "366: sec_end1: $sec_end1 || size_all: $size_all\n";
		if($sec_end1 < $size_all)
		{
			$partinfo->{$part_id1+1}->{"sector_start"} = $sec_end1+1;
			$partinfo->{$part_id1+1}->{"sector_end"} = $size_all-1;
			$partinfo->{$part_id1+1}->{"type"} = "free";
			$partinfo->{$part_id1+1}->{"fs"} = "";
			$partinfo->{$part_id1+1}->{"size"} = ($partinfo->{$part_id1+1}->{"sector_end"} - $partinfo->{$part_id1+1}->{"sector_start"}) / 2;
			$partinfo->{$part_id1+1}->{"mountpoint"} = "";
			push(@$partinfo_values, $part_id1+1);
			$partinfo_labels->{$part_id1+1} = $setup_config->{"target_disk"} . ($part_id1+1) . " (".sprintf("%.2f", $partinfo->{$part_id1+1}->{"size"} / 1024 / 1024)." GiB) [" . substr($partinfo->{$part_id1+1}->{"type"}, 0, 1)."]" ;
		}
		
		$w{6}->getobj('part_list')->values($partinfo_values);
		$w{6}->getobj('part_list')->labels($partinfo_labels);
		$w{6}->getobj('part_list')->draw;
	}
	elsif($buttons->get eq "add")
	{
		my $np = $buttons->root->question(
			-question => _("MSG_PART_SIZE") . ": ",
			-title => _("MSG_PART_TITLE"),
		);
		
		if($np eq "free")
		{
			system("/usr/sbin/createpart add_partition /dev/$setup_config->{target_disk} " . $partinfo->{$selected_partition}->{"sector_start"} . " " . $partinfo->{$selected_partition}->{"sector_end"} . " " . $partinfo->{$selected_partition}->{"fs"} . " >>/dev/null");
		}
		else
		{
			my $new_end_sector = $partinfo->{$selected_partition}->{"sector_start"};
			$new_end_sector = 0 unless($new_end_sector);
			$new_end_sector = $new_end_sector + ($np * 1024 * 2);
			$partinfo->{$selected_partition}->{"sector_start"} = 0 if($partinfo->{$selected_partition}->{"sector_start"} eq "1");
			#print STDERR "/usr/sbin/createpart add_partition /dev/$setup_config->{target_disk} " . $partinfo->{$selected_partition}->{"sector_start"} . " " . $new_end_sector . " " . $partinfo->{$selected_partition}->{"fs"} . " >>error.txt 2>&1";
			system("/usr/sbin/createpart add_partition /dev/$setup_config->{target_disk} " . $partinfo->{$selected_partition}->{"sector_start"} . " " . $new_end_sector . " " . $partinfo->{$selected_partition}->{"fs"} . " >>/dev/null");
		}
		
		@partinfo = ();
		$partinfo_values = [];
		$partinfo_labels = {};
		my $partinfo_intern = {};
			
		@partinfo = `/usr/sbin/partinfo getall /dev/$setup_config->{target_disk}`;
		my $size_all = `/usr/sbin/partinfo size /dev/$setup_config->{target_disk}`;
		chomp($size_all);
		$size_all *= 2;			
		my ($sec_end1,$sec_end2,$sec_end3, $part_id1, $part_id2, $part_id3);		

		chomp(@partinfo);
		foreach(@partinfo)
		{
			my($part_id, $part_start, $part_end, $part_type, $part_fs, $part_size) = split(/:/, $_);
			if($part_id1 && $part_id ne $part_id1+1 && $part_end)
			{
				$partinfo_intern->{$part_id-1}->{"sector_start"} = $sec_end1+1;
				$partinfo_intern->{$part_id-1}->{"sector_end"} = $part_start;
				$partinfo_intern->{$part_id-1}->{"type"} = "free";
				$partinfo_intern->{$part_id-1}->{"fs"} = "ext3";
				$partinfo_intern->{$part_id-1}->{"size"} = ($part_start - $sec_end1) / 2;
				$partinfo_intern->{$part_id-1}->{"mountpoint"} = "";
				push(@$partinfo_values, $part_id-1);
				$partinfo_labels->{$part_id-1} = $setup_config->{"target_disk"} . ($part_id-1) . " (".sprintf("%.2f", $partinfo_intern->{$part_id-1}->{"size"} / 1024 / 1024)." GiB) [" . substr("free", 0, 1)."]" ;
			}
			
			$partinfo_intern->{$part_id}->{"sector_start"} = $part_start;
			$partinfo_intern->{$part_id}->{"sector_end"} = $part_end;
			$partinfo_intern->{$part_id}->{"type"} = $part_type;
			$partinfo_intern->{$part_id}->{"fs"} = $part_fs;
			$partinfo_intern->{$part_id}->{"size"} = $part_size;
			$partinfo_intern->{$part_id}->{"mountpoint"} = "";
			push(@$partinfo_values, $part_id);
			$partinfo_labels->{$part_id} = $setup_config->{"target_disk"} . $part_id . " (".sprintf("%.2f", $part_size / 1024 / 1024)." GiB) [" . substr($part_type, 0, 1)."]" ;
			$part_id1 = $part_id;
			$sec_end1 = $part_end;
			
			if($partinfo->{$part_id}->{"mountpoint"} eq "")
			{
				$partinfo->{$part_id} = $partinfo_intern->{$part_id};
			}
		}
		$sec_end1 = 0 unless($sec_end1);
		$part_id1 = 0 unless($part_id1);
		if($sec_end1 < $size_all)
		{
			$partinfo->{$part_id1+1}->{"sector_start"} = $sec_end1+1;
			$partinfo->{$part_id1+1}->{"sector_end"} = $size_all-1;
			$partinfo->{$part_id1+1}->{"type"} = "free";
			$partinfo->{$part_id1+1}->{"fs"} = "";
			$partinfo->{$part_id1+1}->{"size"} = ($partinfo->{$part_id1+1}->{"sector_end"} - $partinfo->{$part_id1+1}->{"sector_start"}) / 2;
			$partinfo->{$part_id1+1}->{"mountpoint"} = "";
			push(@$partinfo_values, $part_id1+1);
			$partinfo_labels->{$part_id1+1} = $setup_config->{"target_disk"} . ($part_id1+1) . " (".sprintf("%.2f", $partinfo->{$part_id1+1}->{"size"} / 1024 / 1024)." GiB) [" . substr($partinfo->{$part_id1+1}->{"type"}, 0, 1)."]" ;
		}
		
		$setup_config->{"partitions"}->{"/dev/".$setup_config->{"target_disk"} . $selected_partition}->{"format"} = "1";		
		
		$w{6}->getobj('part_list')->values($partinfo_values);
		$w{6}->getobj('part_list')->labels($partinfo_labels);
		$w{6}->getobj('part_list')->draw;		
	}
	elsif($buttons->get eq "next")
	{
		my $max = 0;
		foreach(keys %{$setup_config->{"partitions"}})
		{
			if($setup_config->{"partitions"}->{$_}->{"format"} eq "1")
			{
				$max++;
			}
		}			
		foreach(keys %{$setup_config->{"partitions"}})
		{
			if($setup_config->{"partitions"}->{$_}->{"mountpoint"})
			{
				$max++;
			}
		}			
		
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
			-max => $max,
			-width => 70,
		);

		my $count = 0;
		
		foreach(keys %{$setup_config->{"partitions"}})
		{
			if($setup_config->{"partitions"}->{$_}->{"format"} eq "1" && $setup_config->{"partitions"}->{$_}->{"mountpoint"} ne "swap")
			{
				$w{6}->getobj('progress_partition')->pos($count);
				$w{6}->getobj('progress_label')->text(_("MSG_PART_FORMAT") . ": " . "$_");
				$w{6}->draw;
				system("/sbin/mkfs.ext3 $_ >>/dev/null" );
				$count++;
			}
			if($setup_config->{"partitions"}->{$_}->{"mountpoint"} eq "swap")
			{
				$w{6}->getobj('progress_partition')->pos($count);
				$w{6}->getobj('progress_label')->text(_("MSG_PART_FORMAT") . ": " . "$_");
				$w{6}->draw;
				system("/sbin/mkswap $_ >>/dev/null" );
				$count++;				
			}
		}
		
		foreach(keys %{$setup_config->{"partitions"}})
		{
			if($setup_config->{"partitions"}->{$_}->{"mountpoint"} eq "/")
			{
				system("/bin/mount $_ /mnt/root" . $setup_config->{"partitions"}->{$_}->{"mountpoint"} . "  >>/dev/null");				
			}
		}
		
		foreach(keys %{$setup_config->{"partitions"}})
		{
			if($setup_config->{"partitions"}->{$_}->{"mountpoint"} && $setup_config->{"partitions"}->{$_}->{"mountpoint"} ne "swap")
			{
				$w{6}->getobj('progress_partition')->pos($count);
				$w{6}->getobj('progress_label')->text(_("MSG_MOUNT_PART") . ": " . "$_");
				$w{6}->draw;
				system("mkdir -p /mnt/root" . $setup_config->{"partitions"}->{$_}->{"mountpoint"} . " >/dev/null 2>&1");
				system("/bin/mount $_ /mnt/root" . $setup_config->{"partitions"}->{$_}->{"mountpoint"} . "  >>/dev/null");
				$count++;
			}
			if($setup_config->{"partitions"}->{$_}->{"mountpoint"} eq "swap")
			{
				system("/sbin/swapon $_ >>/dev/null");
			}
		}
		
		goto_next_step();
	}
	
}

sub flavors_callback($;)
{
	my $listbox = shift;
	@{$setup_config->{"categories"}} = $listbox->get;
	#print STDERR Dumper($setup_config);
}

sub convert_to_grub($;)
{
	my $dev = shift;
	my $asc = "";
	my $id = 0;

	if($dev =~ m/^hd([a-z]+)(\d+)$/)
	{
		$asc = unpack("C", $1) - 97;
		$id = $2 - 1;
		return "(hd$asc,$id)";
	}
	elsif($dev =~ m/^hd([a-z]+)/)
	{
		$asc = unpack("C", $1) - 97;
		return "(hd$asc)";
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
	
	my @partitions = ();
	
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
		@partitions = `/usr/sbin/createpart onedisk /dev/$setup_config->{target_disk}`;
		chomp(@partitions);
		
		# alles in $setup_config speichern
		$setup_config->{"partitions"}->{"/dev/$setup_config->{target_disk}1"}->{"format"} = 1;
		$setup_config->{"partitions"}->{"/dev/$setup_config->{target_disk}1"}->{"mountpoint"} = "/boot";

		$setup_config->{"partitions"}->{"/dev/$setup_config->{target_disk}2"}->{"format"} = 1;
		$setup_config->{"partitions"}->{"/dev/$setup_config->{target_disk}2"}->{"mountpoint"} = "/";

		$setup_config->{"partitions"}->{"/dev/$setup_config->{target_disk}3"}->{"format"} = 1;
		$setup_config->{"partitions"}->{"/dev/$setup_config->{target_disk}3"}->{"mountpoint"} = "/home";
		
		$setup_config->{"partitions"}->{"/dev/$setup_config->{target_disk}4"}->{"format"} = 1;
		$setup_config->{"partitions"}->{"/dev/$setup_config->{target_disk}4"}->{"mountpoint"} = "swap";

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
		system("/bin/mount /dev/" . $setup_config->{"target_disk"} . "2 /mnt/root");
		mkdir("/mnt/root/boot");
		mkdir("/mnt/root/home");
		system("/bin/mount /dev/" . $setup_config->{"target_disk"} . "1 /mnt/root/boot");
		system("/bin/mount /dev/" . $setup_config->{"target_disk"} . "3 /mnt/root/home");
		system("/sbin/swapon /dev/" . $setup_config->{"target_disk"} . "4");
		
		
		goto_next_step();
	}
	elsif($setup_config->{"howto_partition"} eq "2") # freier speicher verwenden
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
			-max => 4,
			-width => 70,
		);
		
		$w{6}->getobj('progress_partition')->pos(1);
		$w{6}->draw;		
		
		if(-f "/tmp/.fifo_part")
		{
			unlink("/tmp/.fifo_part");
		}
		system("/usr/bin/mkfifo /tmp/.fifo_part");
		system("/usr/sbin/createpart remaindisk /dev/$setup_config->{target_disk} > /tmp/.fifo_part 2> /dev/null &");
		open(PART, "< /tmp/.fifo_part");
		while(<PART>)
		{
			chomp;
			push(@partitions, $_);
		}
		close(PART);
		
		foreach(@partitions)
		{
			my($key, $val) = split(/:/, $_);
			$setup_config->{"partitions"}->{$val}->{"format"} = 1;
			$setup_config->{"partitions"}->{$val}->{"mountpoint"} = $key;
			
			if($key eq "swap")
			{
				system("/sbin/mkswap $val > /dev/null 2>&1");
				next;
			}
			
			
			if($key eq "/")
			{
				$w{6}->getobj('progress_partition')->pos(2);
				$w{6}->getobj('progress_label')->text(_("MSG_PART_FORMAT_ROOT"));
				$w{6}->draw;
			}

			if($key eq "/home")
			{
				$w{6}->getobj('progress_partition')->pos(3);
				$w{6}->getobj('progress_label')->text(_("MSG_PART_FORMAT_ROOT"));
				$w{6}->draw;
			}
			
			if($key ne "/")
			{
				mkdir("/mnt/root$key");
			}
			system("/sbin/mkfs.ext3 $val > /dev/null 2>&1");
			system("/bin/mount $val /mnt/root$key > /dev/null 2>&1");
		}
		$w{6}->getobj('progress_partition')->pos(4);
		$w{6}->getobj('progress_label')->text("");
		$w{6}->draw;		
		
		goto_next_step();
	}
	elsif($setup_config->{"howto_partition"} eq "3") # selbschd ischd de mann
	{
		unless($w{6}->getobj("part_desc"))
		{
			@partinfo = `/usr/sbin/partinfo getall /dev/$setup_config->{target_disk}`;
			my $size_all = `/usr/sbin/partinfo size /dev/$setup_config->{target_disk}`;
			chomp($size_all);
			$size_all *= 2;
			
			my ($sec_end1,$sec_end2,$sec_end3, $part_id1, $part_id2, $part_id3);
			
			chomp(@partinfo);
			foreach(@partinfo)
			{
				my($part_id, $part_start, $part_end, $part_type, $part_fs, $part_size) = split(/:/, $_);
				#if($sec_end1 && ($part_start-1) > $sec_end1)
				#{#
				#	$part_id1 = $part_id;
				#	$sec_end1 = $part_start-1;
				#}
			#	if($part_id >= 2 && $sec_end1+1 ne $part_start) # hier ist ein freier bereich
				if($part_id1 && $part_id ne $part_id1+1)
				{
					#next if($part_id-1 eq $part_id1);
					$partinfo->{$part_id-1}->{"sector_start"} = $sec_end1+1;
					$partinfo->{$part_id-1}->{"sector_end"} = $part_start;
					$partinfo->{$part_id-1}->{"type"} = "free";
					$partinfo->{$part_id-1}->{"fs"} = "ext3";
					$partinfo->{$part_id-1}->{"size"} = ($partinfo->{$part_id-1}->{"sector_end"} - $sec_end1+1) / 2;
					$partinfo->{$part_id-1}->{"mountpoint"} = "";
					push(@$partinfo_values, $part_id-1);
					$partinfo_labels->{$part_id-1} = $setup_config->{"target_disk"} . ($part_id-1) . " (".sprintf("%.2f", $partinfo->{$part_id-1}->{"size"} / 1024 / 1024)." GiB) [" . substr("free", 0, 1)."]" ;
				}
				$partinfo->{$part_id}->{"sector_start"} = $part_start;
				$partinfo->{$part_id}->{"sector_end"} = $part_end;
				$partinfo->{$part_id}->{"type"} = $part_type;
				$partinfo->{$part_id}->{"fs"} = $part_fs;
				$partinfo->{$part_id}->{"size"} = $part_size;
				$partinfo->{$part_id}->{"mountpoint"} = "";
				push(@$partinfo_values, $part_id);
				$partinfo_labels->{$part_id} = $setup_config->{"target_disk"} . $part_id . " (".sprintf("%.2f", $part_size / 1024 / 1024)." GiB) [" . substr($part_type, 0, 1)."]" ;
				$part_id1 = $part_id;
				$sec_end1 = $part_end;
			}
			
			$sec_end1 = 0 unless($sec_end1);
			$part_id1 = 0 unless($part_id1);
			if($sec_end1 < $size_all)
			{
				$partinfo->{$part_id1+1}->{"sector_start"} = $sec_end1+1;
				$partinfo->{$part_id1+1}->{"sector_end"} = $size_all-1;
				$partinfo->{$part_id1+1}->{"type"} = "free";
				$partinfo->{$part_id1+1}->{"fs"} = "";
				$partinfo->{$part_id1+1}->{"size"} = ($partinfo->{$part_id1+1}->{"sector_end"} - $partinfo->{$part_id1+1}->{"sector_start"}) / 2;
				$partinfo->{$part_id1+1}->{"mountpoint"} = "";
				push(@$partinfo_values, $part_id1+1);
				$partinfo_labels->{$part_id1+1} = $setup_config->{"target_disk"} . ($part_id1+1) . " (".sprintf("%.2f", $partinfo->{$part_id1+1}->{"size"} / 1024 / 1024)." GiB) [" . substr($partinfo->{$part_id1+1}->{"type"}, 0, 1)."]" ;
			}

			$w{6}->add
			(
				'part_list', 'Listbox',
				-y          => 0, #==
				-x          => 2,
				-values     => $partinfo_values,
				-labels     => $partinfo_labels,
				-width      => 25,
				-border     => 1,
				-title      => _("MSG_PARTITIONS"),
				-height		=> 10,
				-vscrollbar => 1,
				-onselchange => \&partitions_callback,
			);
			

			$w{6}->add
			(
				'part_desc', 'Label',
				-text => _("MSG_FILESYSTEM") . ": \n"
					. _("MSG_SIZE") . ": \n"
					. _("MSG_TYPE") . ": \n"
					. _("MSG_MOUNTPOINT") . " \n",
				-y => 0, # ==
				-x => 30,
				-border => 1,
				-height => 10,
				-width => 43,
			);
			
			$w{6}->add
			(
				undef, 'Buttonbox',
				-y => 12, # ==
				-x => 2,
				-border => 1,
				-width => 71,
				-buttons => [
					{
						-label => _("BTN_PART_DELETE"),
						-value => "delete",
						-onpress => \&part_button_box_callback,
					},{
						-label => _("BTN_PART_ADD"),
						-value => "add",
						-onpress => \&part_button_box_callback,
					},{
						-label => _("BTN_PART_MOUNT"),
						-value => "mount",
						-onpress => \&part_button_box_callback,
					},{
						-label => _("BTN_NEXT"),
						-value => "next",
						-onpress => \&part_button_box_callback,
					},
				],
			);
		}
	}
	else
	{
	}
}

sub dialog_7
{
	$w{7}->add
	(
		undef, 'Label',
		-text => _("MSG_CHOOSE_CATEGORY")
	);
	
	$w{7}->add
	(
		'w7_label', 'Label',
		-text => "",
	);
	
			
	# basissystem entpacken
	my @flavors;
	my $flavors_values = [];
	my $flavors_labels = {};
	open(FH, "</install/flavors");
	while(<FH>)
	{
		chomp;
		last 
			if /^$/;
		my($file, $desc) = split(/\|/);
		push(@$flavors_values, $file);
		$flavors_labels->{$file} = $desc;
	}
	close(FH);
	
	$w{7}->add(
		undef, 'Listbox',
		-y => 4, #==
		-padbottom => 1,
		-x	=> 4,
		-width => 65,
		-border => 1,
		-multi 	=> 1,
		-title 	=> _("MSG_CATEGORY"),
		-labels => $flavors_labels,
		-values => $flavors_values,
		-onchange => \&flavors_callback,
	);
	
	# bootloader installieren
}

sub dialog_8
{
	$w{8}->add
	(
		undef, 'Label',
		-text => _("MSG_INSTALL_BASE_SYSTEM")
	);
	
	my $all_pkgs_count = 0;
	my @all_pkgs = @{$setup_config->{"categories"}};
	#print STDERR Dumper(@{$setup_config->{"categories"}});
	#print STDERR "-"x80;
	#print STDERR Dumper(@all_pkgs);
	#print STDERR "-"x80;
	foreach my $p (@all_pkgs)
	{
		open(FH, "</install/$p.pkgs");
			while(<FH>)
			{
				$all_pkgs_count++;
			}
		close(FH);
	}
	
	$w{8}->add
	(
		'setup_label', 'Label',
		-text => _("MSG_PART_DISK"),
		-x => 2,
		-y => 5, #==
		-width => 70,
	);
	$w{8}->add(
		'setup_progress', 'Progressbar',
		-x => 2,
		-y => 10, #==
		-max => $all_pkgs_count,
		-width => 70,
	);

	system("mkdir -p /mnt/root/etc/conf.d");
	system("mkdir -p /mnt/root/var/cache/lip/ldb");
	system("mkdir -p /mnt/root/root");
	system("mkdir -p /mnt/root/sys");
	system("mkdir -p /mnt/root/proc");
	system("mkdir -p /mnt/root/tmp");
	
	system("linoratix-config --plugin LIPbase --add-server file:///mnt/cdrom/Linoratix --prefix /mnt/root > /dev/null");
	
	my $akt_pos = 1;
	my $pkg = {};
	foreach my $p (@all_pkgs)
	{
		print STDERR "!! ".$p."\n";
		open(FH, "</install/$p.pkgs");
			while(<FH>)
			{
				chomp;
				my $l = $_;
				my $inhalt = "";
				my $version = "";
				my $VAR1 = {};
					
				$pkg = retrieve("/install/groups/$l");
				
				foreach my $k (keys %$pkg)
				{
					$version = $k;
				}
				$w{8}->getobj('setup_progress')->pos($akt_pos);
				$w{8}->getobj('setup_label')->text(_("MSG_INSTALLING") . ": " . $pkg->{$version}->{"name"} . "\n" . _("MSG_VERSION") . ": $version\n\n" . $pkg->{$version}->{"description"});
				$w{8}->draw;
				system("linoratix-config --plugin LIP --install " . $pkg->{"$version"}->{"name"} . " --prefix /mnt/root > /dev/null");
				$akt_pos++;
				$pkg = {};
			}
		close(FH);
	}	
	goto_next_step();
}

sub dialog_9
{
	$w{9}->add
	(
		undef, 'Label',
		-text => _("MSG_INSTALL_BOOTMANAGER")
	);
	
	$w{9}->add
	(
		undef, 'Buttonbox',
		-y => 14, # ==
		-x => 45,
		-buttons => [
			{
				-label => _("BTN_CANCEL"),
				-value => "cancel",
				-onpress => \&really_install_mbr,
			},{
				-label => _("BTN_NEXT"),
				-value => "next",
				-onpress => \&really_install_mbr,
			},
		],
	);
}

sub dialog_10
{
	my $partitions = `/usr/sbin/shwdev.sh -partion`;
	my @partitions = split(/ /, $partitions);
	
	$w{10}->add
	(
		undef, 'Label',
		-text => _("MSG_PREPARE_BOOTMANAGER")
	);
	
	$w{10}->add
	(
		'mbr_label', 'Label',
		-text => _("MSG_PART_DISK"),
		-x => 2,
		-y => 5, #==
		-width => 70,
	);
	$w{10}->add(
		'mbr_progress', 'Progressbar',
		-x => 2,
		-y => 10, #==
		-max => 2 + scalar(@partitions),
		-width => 70,
	);
	
	$w{10}->getobj('mbr_progress')->pos(1);
	$w{10}->getobj('mbr_label')->text(_("MSG_SCANNING_PARTITIONS"));
	$w{10}->draw;

	
	system("mkdir -p /mnt/root/boot/grub");
	open(GRUB, ">/mnt/root/boot/grub/menu.lst");
	print GRUB "timeout 10\ndefault 0\n\n";
	
	my $boot_p = $setup_config->{"boot-partition"}?$setup_config->{"boot-partition"}:$setup_config->{"root-partition"};
	
	print GRUB "title Linoratix 0.8\n";
	print GRUB "root " . convert_to_grub($boot_p) . "\n";
	print GRUB "kernel /boot/bzImage-2.6.10-kernel-linoratix-ide root=/dev/" . $setup_config->{"root-partition"} . "\n\n";
	# <toactive> ^^^^   das richtige kernel image
	
	my $_p = 1;
	foreach my $part (@partitions)
	{
		$part =~ m/^([a-z]+)(\d+)$/;
		my $fp = $1;
		my $id = $2;
		my @fs = `/usr/sbin/partinfo fstype /dev/$fp $id`;
		chomp(@fs);
		if($fs[0] eq "ntfs" 
			|| $fs[0] eq "vfat" 
			|| $fs[0] eq "fat32" 
			|| $fs[0] eq "fat"
			|| $fs[0] eq "fat16"
			|| $fs[0] eq "fat12")
		{
			# windows eintrag in grub
			print GRUB "title Windows ($fp$id)\n";
			print GRUB "rootnoverify " . convert_to_grub($fp.$id) . "\n";
			print GRUB "makeactive\nchainloader +1\n\n";
		}
		$w{10}->getobj('mbr_progress')->pos($_p);
		$w{10}->getobj('mbr_label')->text(_("MSG_SCANNING_PARTITIONS"));
		$w{10}->draw;
		$_p++;
	}
	$_p++;
	
	# <toactivate> 
	system("mount -o bind /proc /mnt/root/proc");
	system("mount -o bind /sys /mnt/root/sys");
	
	open(FH, ">/mnt/root/etc/mtab") or die($!);
	open(MTAB, "</etc/mtab") or die($!);
		while(<MTAB>)
		{
			chomp;
			$_ =~ s:/mnt/root::;
			print FH $_."\n";
		}
	close(MTAB);
	close(FH);
	
	system("chroot /mnt/root /sbin/ldconfig");
	system("ln -sf /boot /mnt/root/boot");
	system("chroot /mnt/root /usr/sbin/grub-install hd0 > /dev/null");
	
	$w{10}->getobj('mbr_progress')->pos($_p);
	$w{10}->getobj('mbr_label')->text(_("MSG_INSTALL_GRUB"));
	$w{10}->draw;
}
