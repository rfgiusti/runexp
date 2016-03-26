package rxplib::sys;

use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(interpmemsize);

use threads::shared;


# Interpretate a string as a memory size value, possibly with k/m/Kb/Mb/MB/... suffix and
# return the equivalent size in bytes
sub interpmemsize {
	my $str = shift;

	my ($value, $prefix);
	if ($str =~ /^\s*(\d+(\.\d+)?)\s*(([kmgtKMGT])[bB]?)?\s*/) {
		$value = $1;
		$prefix = defined $4 ? lc($4) : '';
	}

	my $mem;
	if ($prefix eq '') {
		$mem = $value;
	}
	elsif ($prefix eq 'k') {
		$mem = $value * 1024;
	}
	elsif ($prefix eq 'm') {
		$mem = $value * 1024 ** 2;
	}
	elsif ($prefix eq 'g') {
		$mem = $value * 1024 ** 3;
	}
	elsif ($prefix eq 't') {
		$mem = $value * 1024 ** 4;
	}
	else {
		return undef;
	}

	return int($mem + 0.5);
}


return 1;
