package rxplib::verbose;

use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(verbose setverbose);

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


return 1;
