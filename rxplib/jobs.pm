package rxplib::jobs;

use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(donejob runjob getjobname);

use rxplib::logging qw(verbose printfail printmsg);


# Return the job short name and the job long name
sub getjobname {
	my $job = shift;
	my $runpath = shift;

	# Separate /path/runs/subpath/job.ext into long name (subpath/job) and shortname (job)
	$job =~ m{^$runpath/(.+)} or die "Can't match job '$job' against m{^$runpath/(.+)}";
	my $longname = $1;
	$longname =~ s{\.[^.]+$}{};
	my $shortname = $longname;
	$shortname =~ s{(.*/)?([^/]+)}{$2};

	return ($shortname, $longname);
}


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

	open OUTFILE, "<$resfile";

	# See if the first line has a runexp summary
	my $line = <OUTFILE>;
	if ($line =~ /^runexp summary: (success|failure)/) {
		my $status = $1;
		return $status eq "success";
	}

	# Otherwise, load everything and search for the string from the end to the start
	my @lines = <OUTFILE>;
	close OUTFILE;
	return _hasdonestring(@lines);
}


# Check if the RES:done string is found in the output
sub _hasdonestring {
	my @lines = @_;

	my $p = scalar @lines;
	while ($p--) {
		if ($lines[$p] =~ /RES:/) {
			return $lines[$p] !~ /RES:\s*failed/i;
	       }
	}

	return 0;
}


# Run a new job
sub runjob {
	my $host = shift;
	my $job = shift;
	my $jobtype = shift;
	my $jobdata = shift;

	# Write the job data into a temporary file
	my $jobfile = `mktemp /tmp/runexp/runexp_XXXXXXXXXX$jobtype`;
	chomp $jobfile;
	open FILE, ">$jobfile" or return ("failure", "Run error: $!");
	print FILE $jobdata;
	close FILE;

	# Run the job according to its type (based on the extension)
	my ($outcome, $output);
	if ($jobtype eq ".m") {
		($outcome, $output) = runmatlab($host, $job, $jobfile);
	}
	elsif ($jobtype eq ".sh") {
		($outcome, $output) = runbash($host, $job, $jobfile);
	}
	else {
		printfail("Invalid job type '$jobtype'");
		$outcome = "failed";
		$output = "runexp: Invalid job type '$jobtype'";
	}

	unlink $jobfile;

	return ($outcome, $output);
}


# Actually run a job and log its output
# FIXME: replace job spawning system with proper functions instead of backticks 
sub runandlog {
	my $hostname = shift;
	my $longname = shift;
	my $cmdline = shift;

	printmsg($hostname, "Running $longname");
	verbose("Running job $longname with command line $cmdline");

	my $starttime = `date`;
	chomp $starttime;
	verbose "Running job $longname";
	my $progoutput = `$cmdline`;
	my $progstatus = $?;
	my $endtime = `date`;
	chomp $endtime;

	# See if the output has the RES:done flag	
	my $outcome = (_hasdonestring(split /\n/, $progoutput) ? "success" : "failure");
	verbose "Finished job $longname with $outcome";

	# Compose the output in a string that will be sent back to the server
	my $outstr = "runexp summary: $outcome\n\n";
	$outstr .= "$starttime -- [$hostname] Running $longname\n";
	$outstr .= "> $cmdline\n";
	$outstr .= "$endtime -- Finished running\n";
	$outstr .= "Program exited with status $progstatus\n";
	$outstr .= "Program output follows\n\n";
	$outstr .= $progoutput;

	return ($outcome, $outstr);
}


# Run a MATLAB job
sub runmatlab {
	my $host = shift;
	my $jobname = shift;
	my $job = shift;

	# Prepare a MATLAB wrapper to call the job
	$job =~ s/\.m$//;
	$job =~ s{^/tmp/runexp/}{};
	my $matlabcmd ="try; addpath('/tmp/runexp'); $job; catch e, fprintf('Failed: %s\\n', e.message); end";
	my $matlabcall = "matlab -singleCompThread -nodisplay -nodesktop -nosplash -r \"$matlabcmd; quit;\"";

	# Make a proxy bash file to call the MATLAB wrapper
	my $proxyjob = `mktemp /tmp/runexp/matlabproxy_XXXXXXXXXX.sh`;
	open FILE, ">$proxyjob" or return ("failure", "Error creating MATLAB proxy job $proxyjob: $!");
	print FILE "#!/bin/bash\n";
	print FILE "output=\$(mktemp /tmp/runexp/output_XXXXXXXXXXXX.txt)\n";
	print FILE "$matlabcall \&> \$output\n";
	print FILE "cat \$output\n";
	print FILE "rm \$output\n";
	close FILE;
	
	# Run the proxy job
	my $cmdline = "bash $proxyjob";
	my ($runoutcome, $runoutput) = runandlog($host, $jobname, $cmdline);

	# Unlink the proxy job and return the execution data
	unlink $proxyjob;
	return ($runoutcome, $runoutput);
}


# Run a bash job
sub runbash {
	my $host = shift;
	my $jobname = shift;
	my $job = shift;

	my $cmdline = "bash '$job'";
	return runandlog($host, $jobname, $cmdline);
}



return 1;
