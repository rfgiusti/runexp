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
	my $runpath = shift;
	my $job = shift;

	my ($shortname, $longname) = getjobname($job, $runpath);

	# Get the job directory (full path)
	my $jobdir = $job;
	$jobdir =~ s{(.*/)[^/]+}{$1};

	# Run the job according to its type (based on the extension)
	my ($outcome, $output);
	my $type = $job =~ /\.[^.]+/ ? $& : '';
	if ($type eq ".m") {
		($outcome, $output) = runmatlab($host, $longname, $shortname, $jobdir);
	}
	elsif ($type eq ".sh") {
		($outcome, $output) = runbash($host, $longname, $job);
	}
	else {
		printfail("Invalid job type '$type'");
		$outcome = "failed";
		$output = "runexp: Invalid job type '$type'";
	}

	return ($outcome, $output);
}


# Actually run a job and log its output
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
	my $longname = shift;
	my $shortname = shift;
	my $jobdir = shift;

	if (-f "$shortname.m") {
		printfail "A script named '$shortname.m' in the current working dir causes conflict";
		return;
	}

	my $matlabcmd ="try; $shortname; catch e, fprintf('Failed: %s\\n', e.message); end";
	my $cmdline = "matlab -singleCompThread -nodisplay -nodesktop -nosplash -r \"addpath('$jobdir'); $matlabcmd; quit;\"";
	return runandlog($host, $longname, $cmdline);
}


# Run a bash job
sub runbash {
	my $host = shift;
	my $longname = shift;
	my $job = shift;

	my $cmdline = "bash '$job'";
	return runandlog($host, $longname, $cmdline);
}



return 1;
