#!/usr/bin/perl -w

use strict;
use File::Temp qw( :POSIX );
use Curses::UI;

require("lang/de.lang.pl");

# ---------------------------------------------------------------------
# Init
# ---------------------------------------------------------------------

my $debug = 0;
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


# Create the root object.
my $cui = new Curses::UI 
( 
	-clear_on_exit => 1, 
	-debug => $debug,
	-color_support => 1
);

# Wizard index
my $current_step = 1;

# Wizard  windows
my %w = ();
my %w_help = ();

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
	'1'	=> _("SCR_WELCOME")
);

# all the help messages
my %screens_help = (
	'1'	=> _("HLP_WELCOME")
);

# bring all screens to the right 
my @screens = sort {$a<=>$b} keys %screens;
my @screens_help = sort {$a<=>$b} keys %screens_help;

# different options for curses
my %args = (
	-border		=> 1, 
	-titlereverse	=> 0, 
	-padtop		=> 2, 
	-padbottom	=> 6, 
	-ipad		=> 1,
	-tfg		=> "blue",
	-bfg		=> "red"
);

my %args_help = (
	-border		=> 1, 
	-titlereverse	=> 0, 
	-padtop		=> 18,
	-padbottom	=> 3, 
	-ipad		=> 0,
	-tfg		=> "blue",
	-bfg		=> "red"
);

my $disks = `/usr/sbin/shwdev.sh -disk`;
chomp($disks);
my @disks = split(/ /, $disks);
my $target_disk_values = [];
my $target_disk_labels = [];

foreach my $target_disk_key (@disks)
{
	push(@$target_disk_values, $target_disk_key);
	$target_disk_labels->{$target_disk_key} = 
}


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
	$w{$current_step}->focus;
}

sub select_step($;)
{
	my $nr = shift;
	$current_step = $nr;
	$w{$current_step}->focus;
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
	
	$w_help{$nr} = $cui->add(
		"H_$id", 'Window',
		%args_help
	);
}

# ----------------------------------------------------------------------
# Greeting
# ----------------------------------------------------------------------

$w{1}->add(
	undef, 'Label',
	-text	=> _("MSG_GREETING")
);

$w_help{1}->add(
	undef, 'Label',
	-text	=> _("HLP_WELCOME")
);

# ----------------------------------------------------------------------
# Installationsziels
# ----------------------------------------------------------------------



# ----------------------------------------------------------------------
# Setup bindings and focus 
# ----------------------------------------------------------------------

# Bind <CTRL+X> to menubar.
$cui->set_binding( sub{ shift()->root->focus('menu') }, "\cX" );
$cui->set_binding( \&goto_next_step, "\cN" );
$cui->set_binding( \&goto_prev_step, "\cP" );

$w{$current_step}->focus();


# ----------------------------------------------------------------------
# Lets rock'n'roll...
# ----------------------------------------------------------------------

MainLoop;

