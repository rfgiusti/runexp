package rxplib::jobs;

use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(donejob);

use rxplib::verbose qw(verbose);

# Check if a job has already been executed. A job has been executed if its output file contains the string RES: or if
# a verification application returns 1
sub donejob {
	my $jobfile = shift;
	my $runpath = shift;
	my $outpath = shift;

	verbose "Checking if job '$jobfile' is done";

	my $resfile = $jobfile;
	$resfile =~ s{^$runpath}{$outpath};
	$resfile =~ s{\.[^.]*$}{.res};
	verbose "Searching output file '$resfile'";
	
	return 0 unless -f $resfile;

	my $done = 0;
	open OUTFILE, "<$resfile";
	while (my $line = <OUTFILE>) {
		if ($line =~ /RES:/ && $line !~ /RES:\s*fail/) {
			$done = 1;
			last;
		}
	}
	close OUTFILE;

	return $done;
}



return 1;
