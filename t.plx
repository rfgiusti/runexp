#!/usr/bin/perl

use strict;

sub test2 {
	return 0;
}

sub endit {
	print "Ended\n";
	return 1;
}

sub test {
	my $val = shift;

	print "Testing it\n";

	(endit and return) unless test2;

	print "Should not be printed\n";
}

test;
