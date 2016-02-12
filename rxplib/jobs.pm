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


# Run a new job
sub runjob {
	my $host = shift;
	my $runpath = shift;
	my $outpath = shift;
	my $job = shift;

	my ($shortname, $longname) = getjobname($job, $runpath);

	# Compose the output file path
	my $output = "$outpath/$longname.res";

	# Get the job directory (full path)
	my $jobdir = $job;
	$jobdir =~ s{(.*/)[^/]+}{$1};

	# Run the job according to its type (based on the extension)
	my $type = $job =~ /\.[^.]+/ ? $& : '';
	if ($type eq ".m") {
		runmatlab($host, $longname, $shortname, $jobdir, $output);
	}
	elsif ($type eq ".sh") {
		runbash($host, $longname, $job, $output);
	}
	else {
		printfail("Invalid job type '$type'");
	}
}


# Actually run a job and log its output
sub runandlog {
	my $hostname = shift;
	my $longname = shift;
	my $cmdline = shift;
	my $output = shift;

	printmsg($hostname, "Running $longname");

	verbose "Job info";
	verbose "  name   : $longname";
	verbose "  output : $output";
	verbose "  cmdline: $cmdline";

	my $starttime = `date`;
	chomp $starttime;
	verbose "Running job $longname";
	my $progoutput = `$cmdline`;
	my $progstatus = $?;
	verbose "Finished job $longname";
	my $endtime = `date`;
	chomp $endtime;

	open OUTPUT, ">$output" or die "Error opening $output";
	print OUTPUT "$starttime -- [$hostname] Running $longname\n";
	print OUTPUT "> $cmdline\n";
	print OUTPUT "$endtime -- Finished running\n";
	print OUTPUT "Program exited with status $progstatus\n";
	print OUTPUT "Program output follows\n";
	print OUTPUT "\n";
	print OUTPUT $progoutput;
	close OUTPUT;
}


# Run a MATLAB job
sub runmatlab {
	my $host = shift;
	my $longname = shift;
	my $shortname = shift;
	my $jobdir = shift;
	my $output = shift;

	if (-f "$shortname.m") {
		printfail "A script named '$shortname.m' in the current working dir causes conflict";
		return;
	}

	print "<<";
	my $matlabcmd ="try; $shortname; catch e, fprintf('Failed: %s\\n', e.message); end";
	my $cmdline = "matlab -singleCompThread -nodisplay -nodesktop -nosplash -r \"addpath('$jobdir'); $matlabcmd; quit;\"";
	print ">>\n";
	runandlog($host, $longname, $cmdline, $output);
}


# Run a bash job
sub runbash {
	my $host = shift;
	my $longname = shift;
	my $job = shift;
	my $output = shift;

	my $cmdline = "bash '$job'";
	runandlog($host, $longname, $cmdline, $output);
}



return 1;
