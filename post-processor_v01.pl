#!/usr/bin/perl -i
use strict;
use warnings;

# Always helpful
use Math::Round;
use POSIX qw[ceil floor];
use List::Util qw[min max];
use constant PI    => 4 * atan2(1, 1);

##########
# SETUP
# all you can do here is setting default values for printing parameters
# since you don't have to do much here, just scroll down to PROCESSING
##########

# printing parameters
my %parameters=();

# printing parameters, default values (if needed)
$parameters{"someParameter"}=0.2;

# gcode inputBuffer
my @inputBuffer=();
my @outputBuffer=();

# state variables, keeping track of what we're doing
my $start=0; # is set to 1 after ; start of print
my $end=0; # is set to 1 before ; end of print

##########
# INITIALIZE
# if you want to initialize variables based on printing parameters, do it here, all printing parameters are available in $parameters
##########

sub init{
	#for(my $i=0;$i<$parameters{"extruders"};$i++){
	#}
}

##########
# PROCESSING
# here you can define what you want to do with your G-Code
# Typically, you have $X, $Y, $Z, $E and $F (numeric values) and $thisLine (plain G-Code) available.
# If you activate "verbose G-Code" in Slic3r's output options, you'll also get the verbose comment in $verbose.
##########

sub process_start_gcode
{
	my $thisLine=$_[0];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub	process_end_gcode
{
	my $thisLine=$_[0];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_tool_change
{
	my $thisLine=$_[0],	my $T=$_[1], my $verbose=$_[2];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_comment
{
	my $thisLine=$_[0], my $C=$_[1], my $verbose=$_[2];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_layer_change
{
	my $thisLine=$_[0],	my $Z=$_[1], my $verbose=$_[2];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_retraction_move
{
	my $thisLine=$_[0], my $E=$_[1], my $F=$_[2], my $verbose=$_[3];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_printing_move
{
	my $thisLine=$_[0], my $X = $_[1], my $Y = $_[2], my $Z = $_[3], my $E = $_[4], my $F = $_[5], my $verbose=$_[6];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_travel_move
{
	my $thisLine=$_[0], my $X=$_[1], my $Y=$_[2], my $Z=$_[3], my $F=$_[4], my $verbose=$_[5];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_absolute_extrusion
{
	my $thisLine=$_[0], my $verbose=$_[1];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_relative_extrusion
{
	my $thisLine=$_[0], my $verbose=$_[1];
	# add code here or just return $thisLine;
	return $thisLine;
}

sub process_other
{
	my $thisLine=$_[0], my $verbose=$_[1];
	# add code here or just return $thisLine;
	return $thisLine;
}

##########
# FILTER THE G-CODE
# here the G-code is filtered and the processing routines are called
##########

sub filter_print_gcode
{
	my $thisLine=$_[0];
	if($thisLine=~/^\h*;(.*)\h*/){
		# ;: lines that only contain comments
		my $C=$1; # the comment
		return process_comment($thisLine,$C);
	}elsif ($thisLine=~/^T(\d)(\h*;\h*([\h\w_-]*)\h*)?/){
		# T: tool changes
		my $T=$1; # the tool number
		return process_tool_change($thisLine,$T);
	}elsif($thisLine=~/^G[01](\h+X(-?\d*\.?\d+))?(\h+Y(-?\d*\.?\d+))?(\h+Z(-?\d*\.?\d+))?(\h+E(-?\d*\.?\d+))?(\h+F(\d*\.?\d+))?(\h*;\h*([\h\w_-]*)\h*)?/){
		# G0 and G1 moves
		my $X=$2, my $Y=$4,	my $Z=$6, my $E=$8,	my $F=$10, my $verbose=$12;
		# regular moves and z-moves
		if($E){
			# seen E
			if($X || $Y || $Z){
				# seen X,Y or Z
				return process_printing_move($thisLine, $X, $Y, $Z, $E, $F, $verbose);
			}else{
				# seen E, but not X, Y or Z
				return process_retraction_move($thisLine, $E, $F, $verbose);
			}
		}else{
			# not seen E
			if($Z && !($X || $Y)){
				# seen Z, but not X or Y
				return process_layer_change($thisLine, $Z, $F, $verbose);
			}else{
				# seen X or Y (and possibly also Z)
				return process_travel_move($thisLine, $X, $Y, $Z, $F, $verbose);
			}
		}
	}elsif($thisLine=~/^G92(\h+X(-?\d*\.?\d+))?(\h*Y(-?\d*\.?\d+))?(\h+Z(-?\d*\.?\d+))?(\h+E(-?\d*\.?\d+))?(\h*;\h*([\h\w_-]*)\h*)?/){
		# G92: touching of axis
		my $X=$2,	my $Y=$4, my $Z=$6, my $E=$8, my $verbose=$10;
		return process_touch_off($thisLine, $X, $Y, $Z, $E, $verbose);
	}elsif($thisLine=~/^M82(\h*;\h*([\h\w_-]*)\h*)?/){
		my $verbose=$2;
		return process_absolute_extrusion($thisLine, $verbose);
	}elsif($thisLine=~/^M83(\h*;\h*([\h\w_-]*)\h*)?/){
		my $verbose=$2;
		return process_relative_extrusion($thisLine, $verbose);
	}elsif($thisLine=~/^; end of print/){
		$end=1;
	}else{
		/.*(\h*;\h*([\h\w_-]*)\h*)?/;
		my $verbose=$2;
		# all the other gcodes, such as temperature changes, fan on/off, acceleration
		return process_other($thisLine, $verbose);
	}
}

sub filter_parameters
{
	# collecting parameters from G-code comments
	if($_[0] =~ /^\h*;\h*([\w_-]*)\h*=\h*(\d*\.?\d+)\h*/){
		# all numeric variables are saved as such
		my $key=$1;
		my $value = $2*1.0;
		unless($value==0 && exists $parameters{$key}){
			$parameters{$key}=$value;
		}
	}elsif($_[0] =~ /^\h*;\h*([\h\w_-]*)\h*=\h*(.*)\h*/){
		# all other variables (alphanumeric, arrays, etc) are saved as strings
		my $key=$1;
		my $value = $2;
		$parameters{$key}=$value;
	}
}


sub print_parameters
{
	# this prints out all available parameters into the G-Code as comments
	print "; GCODE POST-PROCESSING PARAMETERS:\n\n";
	print "; OS: $^O\n\n";
	print "; Environment Variables:\n";
	foreach (sort keys %ENV) {
		print "; $_  =  $ENV{$_}\n";
	}
	print "\n";
	print "; Slic3r Script Variables:\n";
	foreach (sort keys %parameters) {
		print "; *$_*  =  $parameters{$_}\n";
	}
	print "\n";
}

sub process_buffer
{
	# applying all modifications to the G-Code
	foreach my $thisLine (@inputBuffer) {

		# start/end conditions
		if($thisLine=~/^; start of print/){
			$start=1;
		}elsif($thisLine=~/^; end of print/){
			$end=1;
		}

		# processing
		if($start==0){
			push(@outputBuffer,process_start_gcode($thisLine));
		}elsif($end==1){
			push(@outputBuffer,process_end_gcode($thisLine));
		}else{
			push(@outputBuffer,filter_print_gcode($thisLine));
		}
	}
}

sub print_buffer
{
	foreach my $outputLine (@outputBuffer) {
		print $outputLine;
	}
}

##########
# MAIN LOOP
##########

# Creating a backup file for windows
if($^O=~/^MSWin/){
	$^I = '.bak';
}

while (my $thisLine=<>) {
	filter_parameters($thisLine);
	push(@inputBuffer,$thisLine);
	if(eof){
		process_buffer();
		init();
		print_parameters();
		print_buffer();
	}
}
