package rxplib::logging;

use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(verbose setverbose printfail printprogress setprintprogress printmsg setquiet setprintaftermath
	printaftermath memsize2string);

use threads::shared;


# Return a string that represents an amount of memory in human readable form (goes up to
# a specified power of 2 or defaults to KB)
sub memsize2string {
	my $bytes = shift;
	my $maxpower = shift or 1;

	my @prefixes = qw(N K M G T P E Z Y);
	while ($maxpower > 1 && $bytes < 1024 ** $maxpower) {
		$maxpower--;
	}

	my $mem = sprintf "%.1f", $bytes / (1024 ** $maxpower);
	if ($mem - int($mem) > 0.1) {
		return sprintf("%.1f $prefixes[$maxpower]B", $mem);
	}
	else {
		return sprintf("%d $prefixes[$maxpower]B", $mem);
	}
}



# Print detailed information if running verbosely
my $verbose :shared = 0;
my $quiet :shared = 0;
my $aftermath :shared = "none";
my $printprogress :shared = 0;
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


# Set print-progress or print-jobs mode
sub setprintprogress {
	my $mode = shift;

	lock $printprogress;

	$printprogress = $mode;
	setquiet(1) if $mode;
}


# Set printaftermath flag on/off
sub setprintaftermath {
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
sub printprogress {
	my $host = shift;
	my $done = shift;
	my $total = shift;
	my $msg = shift;

	my $time = `date "+%b %d %T"`;
	chomp $time;

	my $pct = int(1000 * ($done / $total)) / 10;
	if ($printprogress) {
		printf "[%5.1f%%] $done/$total\r", $pct;
	}
	else {
		printf "$time [%5.1f%%] $host: $msg\n", $pct unless $quiet;
	}
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

	printf "$time [$host] $msg\n" unless $quiet;
}



return 1;
