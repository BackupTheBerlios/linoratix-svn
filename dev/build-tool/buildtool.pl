#!/usr/bin/perl -w

use strict;
use File::Temp qw( :POSIX );
use Curses::UI;

require("lang/de.lang.pl");

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
);

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
	'1'  => _("SCR_WELCOME"),
	'2'  => _("SCR_OPTIMIZE")
);

# bring all screens to the right 
my @screens = sort {$a<=>$b} keys %screens;

# different options for curses
my %args = (
	-border       => 1, 
	-titlereverse => 0, 
	-padtop       => 2, 
	-padbottom    => 3, 
	-ipad         => 1,
);

my $optimization_values = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 ];
my $optimization_labels = 
{
	1   => _("MSG_OPTIMIZED_FOR_NONE"),
	2   => _("MSG_OPTIMIZED_FOR_i386"),
	3   => _("MSG_OPTIMIZED_FOR_i486"),
	4   => _("MSG_OPTIMIZED_FOR_via_cyrix_3_via_c3"),
	5   => _("MSG_OPTIMIZED_FOR_via_c3_2_nemiah"),
	6   => _("MSG_OPTIMIZED_FOR_intel_pentium"),
	7   => _("MSG_OPTIMIZED_FOR_intel_pentium_mmx"),
	8   => _("MSG_OPTIMIZED_FOR_intel_pentium_pro"),
	9   => _("MSG_OPTIMIZED_FOR_intel_pentium_2"),
	10  => _("MSG_OPTIMIZED_FOR_intel_pentium_3"),
	11  => _("MSG_OPTIMIZED_FOR_intel_pentium_4"),
	12  => _("MSG_OPTIMIZED_FOR_amd_k6"),
	13  => _("MSG_OPTIMIZED_FOR_amd_k6_2"),
	14  => _("MSG_OPTIMIZED_FOR_amd_k6_3"),
	15  => _("MSG_OPTIMIZED_FOR_amd_athlon"),
	16  => _("MSG_OPTIMIZED_FOR_amd_athlon_thunderbird"),
	17  => _("MSG_OPTIMIZED_FOR_amd_athlon_4"),
	18  => _("MSG_OPTIMIZED_FOR_amd_athlon_xp"),
	19  => _("MSG_OPTIMIZED_FOR_amd_athlon_mp"),
};


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

sub optimize_callback()
{
	my $listbox = shift;
	my $sel = $listbox->get;
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
		-title => "Linoratix Customizing: $title ($nr/" . scalar(@screens) . ")",
		%args
	);
}

# ----------------------------------------------------------------------
# Greeting
# ----------------------------------------------------------------------

$w{1}->add(
	undef, 'Label',
	-text	=> _("MSG_GREETING")
);


# ----------------------------------------------------------------------
# Choose Optimization
# ----------------------------------------------------------------------


$w{2}->add
(
	undef, 'Label',
	-text => _("MSG_OPTIMIZE")
);

$w{2}->add
(
	undef, 'Radiobuttonbox',
	-y          => 6,
	-x          => 2,
	-values     => $optimization_values,
	-labels     => $optimization_labels,
	-width      => 50,
	-border     => 1,
	-title      => _("MSG_CPU"),
	-vscrollbar => 1,
	-onchange   => \&optimize_callback,
);




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


