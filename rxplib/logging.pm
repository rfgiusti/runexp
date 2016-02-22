package rxplib::logging;

use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(verbose setverbose printfail printpct printmsg setquiet setaftermath printaftermath);

use threads::shared;

# Print detailed information if running verbosely
my $verbose :shared = 0;
my $quiet :shared = 0;
my $aftermath :shared = "none";
sub verbose {
	return 1 unless $verbose;

	lock $verbose;

	my $msg = shift;
	my $time = `date "+%b %d %T"`;
	chomp $time;
	printf "$time [ INFO ] $msg\n";

	return 1;
}


# Set verbose mode on/off
sub setverbose {
	my $mode = shift;

	lock $verbose;
	lock $quiet;

	$verbose = $mode;
	verbose "Entering verbose mode";
	die "Can't enter verbose mode and quiet mode simultaneously\n" if $verbose && $quiet;
}


# Set quiet mode on/off
sub setquiet {
	my $mode = shift;

	lock $verbose;
	lock $quiet;

	$quiet = $mode;
	die "Can't enter verbose mode and quiet mode simultaneously\n" if $verbose && $quiet;
}


# Set printaftermath flag on/off
sub setaftermath {
	my $mode = shift;

	die "aftermath mode '$mode' is invalid\n" unless $mode =~ /^(all|none|success|failure)$/;
	
	lock $aftermath;
	$aftermath = $mode;

	verbose "Set --aftermath: $aftermath";
}


# Print a fail log
sub printfail {
	my $id = shift;
	my $failmessage = shift;
        
	my $time = `date "+%b %d %T"`;
        chomp $time;
        printf "$time [$id] ERROR: $failmessage\n";
}


# Print message with done% information 
sub printpct {
	my $host = shift;
	my $pct = shift;
	my $msg = shift;

	my $time = `date "+%b %d %T"`;
	chomp $time;

	printf "$time [%5.1f%%] $host: $msg\n", $pct unless $quiet;
}


# Print message with job result if $aftermath flag is true
sub printaftermath {
	my $host = shift;
	my $job = shift;
	my $res = shift;

	return if $aftermath eq "none";
	return if $aftermath ne "all" && $aftermath ne $res;

	my $time = `date "+%b %d %T"`;
	chomp $time;

	printf "$time [RESULT] $host: finished $job with $res\n";
}


# Print information with host name information
sub printmsg {
	my $host = shift;
        my $msg = shift;

        my $time = `date "+%b %d %T"`;
        chomp $time;

	printf "$time [$host] Running $msg\n" unless $quiet;
}



return 1;
