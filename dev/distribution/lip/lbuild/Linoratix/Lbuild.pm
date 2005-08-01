#
# objekt um die lbuild strings zu lesen
#

package Linoratix::Lbuild;

use Linoratix::Array;

use strict;
#no strict "refs";
use Data::Dumper;

use Exporter;
use vars qw(@ISA @EXPORT);


@ISA = qw(Exporter);
@EXPORT = qw();

my $struct;   # hier drin wird die struktur der lbuild datei abgebildet

# sektionen die keine variablen zuordnung enthalten
my $keywords = Linoratix::Array->new(qw(PrepareBuild Build Install PreInstall PostInstall PreUninstall));

# @desc konstruktor
sub new
{
	my $lbuild = shift;
	my $class = ref($lbuild) || $lbuild;
	my $self = { @_ };

	bless($self, $class);

	$self->load_lbuild(@{$self->{"files"}});
	
	return $self;
}

# @desc laden der dateien
sub load_lbuild
{
	my $self = shift;
	my @files = @_;
	
	my $content = Linoratix::Array->new();
	
	foreach my $file (@files)
	{
		open(FH, "<$file") or die("$!\n");
		while(<FH>)
		{
			next if(/^\s*?;/); # kommentare ueberspringen
			next if(/^\s*$/);  # leere zeilen
			chomp;
			$content->push($_);
		}
		close(FH);
	}
	
	$self->read_lbuild($content);
}

# @desc auslesen des strings
sub read_lbuild
{
	my $self = shift;
	my $content = shift;

	my $section = undef;
	
	while(my $line = $content->next_element())
	{
		# ist es eine sektion?
		if($line =~ m/^\[(.*?)\]$/)
		{
			if($keywords->exists($1) >= 0)
			{ # eine spezielle sektion mit scripts
				$self->{"struct"}->{$1} = Linoratix::Array->new();
			} else
			{ # zuweisung
				$self->{"struct"}->{$1} = {};
			}
		
			$section = $1;
		} else
		{ # keine sektion
			if($keywords->exists($section) >= 0)
			{ # eine spezielle sektion mit scripts
				$self->{"struct"}->{$section}->push($line);
			} else
			{ # zuweisung
				$line =~ m/^(.*?)\s*=\s*(.*)$/;
				my $key = $1;
				my $val = $2;
				if($key =~ m/^(.*)\[.*?\]$/)
				{ # ein array
					if(exists($self->{"struct"}->{$section}->{$1}))
					{
						$self->{"struct"}->{$section}->{$1}->push($val);
					} else
					{
						$self->{"struct"}->{$section}->{$1} = Linoratix::Array->new();
						$self->{"struct"}->{$section}->{$1}->push($val);
					}
				} elsif($val =~ m/^\[(.*?)\]$/)
				{ # noch ein array
					my @a = split(/,\s?/, $1);
					$self->{"struct"}->{$section}->{$key} = Linoratix::Array->new();
					$self->{"struct"}->{$section}->{$key}->push($_) for(@a);
				} else
				{ # normaler string
					$self->{"struct"}->{$section}->{$key} = $val;
				}
			}
		}
	}
}

# @desc auslesen eines elements
sub get
{
	my $self = shift;
	my $path = shift;
	
	my ($section, $val, $arrindex) = split(/\//, $path);
	
	if($keywords->exists($section) >= 0)
	{ # ein schluesselwort
		return undef unless($self->{"struct"}->{$section});
		return $self->{"struct"}->{$section}->to_string();
	} else
	{
		return undef unless($self->{"struct"}->{$section});
		return undef unless($self->{"struct"}->{$section}->{$val});
		if(ref($self->{"struct"}->{$section}->{$val}) eq "Linoratix::Array")
		{
			return $self->{"struct"}->{$section}->{$val}->get($arrindex) if($arrindex && $arrindex ne '');
			return $self->{"struct"}->{$section}->{$val}->to_string();
		}
		return $self->{"struct"}->{$section}->{$val};
	}
	
	return undef;
}

sub script
{
	my $self = shift;
	my $path = shift;
	
	my ($section, $val) = split(/\//, $path);
	
	my $ret = "#!/bin/bash\n";
	$ret .= "\n# Section: $section\n\n";
	my $count=0;
	
	foreach my $key (keys %{$self->{"struct"}->{$section}})
	{
		$ret .= "${section}_key[$count]=\"$key\"\n";
		$ret .= "${section}_value[$count]=\"" . $self->{"struct"}->{$section}->{$key} . "\"\n";
		$count++;
	}
	
	$ret .= "ANZAHL_$section=$count\n\n";
	
	return $ret;
}

1;
