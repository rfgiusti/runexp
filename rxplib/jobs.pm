package rxplib::jobs;

use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(donejob runjob getjobname setaftermath saveaftermaths loadaftermaths);

use threads::shared;

use threads::shared;

use rxplib::logging qw(verbose printfail printmsg);

# This is a list of jobs outcomes (1 indicates the job was completed successfully, 0 indicates the job was finished
# with a failure status. This list is only used by the manager.
my %aftermaths :shared;

# This flag is raised to 1 if the MATLAB stack tracer has been written to /tmp/runexpstacktracer
my $hastracer :shared = 0;

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


# Load aftermath table from a file
sub loadaftermaths {
	my $file = shift;

	lock %aftermaths;
	open FILE, "<$file" or die "Error loading aftermath table at $file: $!\n";
	my @filedata = <FILE>;
	close FILE;
	%aftermaths = map { my $s = $_; chomp $s; $s } @filedata;
	verbose "Loaded aftermath results for " . scalar (keys %aftermaths) . " job(s)";
}


# Write aftermath table to a file
sub saveaftermaths {
	my $file = shift;

	lock %aftermaths;
	my @aftermaths = %aftermaths;
	open FILE, ">$file" or die "Error saving aftermath table to '$file': $!\n";
	print FILE join("\n", @aftermaths);
	close FILE;
	verbose "Saved aftermath results for " . scalar (keys %aftermaths) . " job(s)";
}


# Set aftermath status after a job has been executed
sub setaftermath {
	my $job = shift;
	my $aftermath = shift;

	lock %aftermaths;
	$aftermaths{$job} = $aftermath;
	verbose "Set aftermath of job '$job' to '$aftermath'";
}


# Check if a job has already been executed. A job has been executed if:
# 	1. It has an output file
# 	2. Either:
# 	2.1. It is listed as "1" in the aftermath table, OR
# 	2.2. It contains a runexp summary string in the beginning of the output, OR
# 	2.3. It contains the RES: string in the output
sub donejob {
	my $jobfile = shift;
	my $runpath = shift;
	my $outpath = shift;

	verbose "Checking if job '$jobfile' is done";

	my $resfile = $jobfile;
	$resfile =~ s{^$runpath}{$outpath};
	$resfile =~ s{\.[^.]*$}{.res};
	verbose "Searching output file '$resfile'";

	# If no output exists, then the job is undone
	return 0 unless -f $resfile;

	# Otherwise, check if it is listed in the aftermath table
	{
		lock %aftermaths;
		my $jobname = getjobname($jobfile, $runpath);
		verbose "Checking job '$jobname' on aftermaths table";
		return $aftermaths{$jobname} if defined $aftermaths{$jobname};
	}

	# If all fails, read the output log, starting with the runexp summary, and then proceeding to scan
	# the entire output for the RES: string
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

	# Failure message in case writing to file failes

	# Write the job data into a temporary file
	my $jobfile = `mktemp /tmp/runexp/runexp_XXXXXXXXXX$jobtype`;
	chomp $jobfile;
	open FILE, ">$jobfile" or return ("failure", "Host $host was unable to write job file for $job\n" .
			"Attempt to open temporary file '$jobfile' failed: $!\n");
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
		$outcome = "failure";
		$output = "runexp: Invalid job type '$jobtype' for job '$job'";
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

	# Create a function in /tmp/runexpstacktracer only once
	{
		lock $hastracer;
		unless ($hastracer) {
			mkdir '/tmp/runexpstacktracer' unless -d '/tmp/runexpstacktracer';
			open FILE, ">/tmp/runexpstacktracer/runexpstacktracer.m" or last;
			print FILE "function runexpstacktracer(e)\n";
			print FILE "fprintf('Stack trace available (most recent calls last):\\n');\n";
			print FILE "for i = numel(e.stack):-1:1\n";
			print FILE "  fprintf('Function ''%s'' at file ''%s'', line %d\\n', ...\n";
			print FILE "      e.stack(i).name, e.stack(i).file, e.stack(i).line);\n";
			print FILE "end;\n";
			close FILE;
			$hastracer = 1;
		}
	}

	# Prepare a MATLAB wrapper to call the job
	$job =~ s/\.m$//;
	$job =~ s{^/tmp/runexp/}{};
	my $matlabcmd ="try; addpath('/tmp/runexp'); $job; catch e, fprintf('Failed: %s\\n', e.message); addpath('/tmp/runexpstacktracer'); runexpstacktracer(e); end";
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
