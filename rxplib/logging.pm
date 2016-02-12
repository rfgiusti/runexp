package rxplib::logging;

use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(verbose setverbose printfail printpct printmsg);

use threads::shared;

# Print detailed information if running verbosely
my $verbose :shared = 0;
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
	verbose "Entering verbose mode";
	$verbose = $mode;
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

	printf "$time [%5.1f%%] $host: $msg\n", $pct;
}


# Print information with host name information
sub printmsg {
	my $host = shift;
        my $msg = shift;

        my $time = `date "+%b %d %T"`;
        chomp $time;

	printf "$time [$host] Running $msg\n";
}



return 1;
