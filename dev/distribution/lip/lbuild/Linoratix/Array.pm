#
# @file_desc array objekt
#

package Linoratix::Array;

use strict;
use Data::Dumper;
use Exporter;

use vars qw(@ISA @EXPORT);


@ISA = qw(Exporter);
@EXPORT = qw();

my @this_array = [];
my $counter = 0;

# @desc konstruktor
# @param array init
sub new
{
	my $array = shift;
	my $class = ref($array) || $array;
	my $self = { @_ };

	bless($self, $class);

	@{$self->{"this_array"}} = @_;

	return $self;
}

sub push
{
	my $self = shift;
	
	push(@{$self->{"this_array"}}, @_);
}

sub get
{
	my $self = shift;
	my $index = shift;
	
	return $self->{"this_array"}[$index];
}

sub dump
{
	my $self = shift;
	use Data::Dumper;
	return Dumper(@{$self->{"this_array"}});
}

sub next_element
{
	my $self = shift;
	if(@{$self->{"this_array"}}[$counter])
	{
		$counter++;
		return @{$self->{"this_array"}}[$counter-1];
	} else
	{
		$counter = 0;
		return undef;
	}
}

# @desc ueberpruefen ob ein element vorkommt
# @return int position des gefunden elements
# @return_failed -1
sub exists
{
	my $self = shift;
	my $word = shift;
	
	my $count = 0;
	
	foreach(@{$self->{"this_array"}})
	{
		return $count if(m/$word/);
		$count++;
	}
	
	return -1;
}

# @desc array in string verwandeln
# @return string
sub to_string
{
	my $self = shift;
	return join("\n", @{$self->{"this_array"}});
}

sub is_array
{
	return 1;
}

1;
