package rxplib::config;

use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(readconfig);

my $home = $ENV{HOME};

sub readconfig {
	return () unless -f "$home/.runexp";

	my %validkeys = map {$_ => 1} qw(port qmanager hostname);

	my %conf;
	open FILE, "<$home/.runexp" or die "Error opening config file";
	while (my $line = <FILE>) {
		$line =~ s/^\s*//;
		next if $line =~ /^#/;

		chomp $line;
		die "~/.runexp: bad entry: $line\n" unless $line =~ /^([A-Za-z0-9]+)\s*=(.+)/;
		my $key = lc $1;
		my $value = $2;
		die "~/.runexp: bad key: $key\n" unless defined $validkeys{$key};
		$conf{$key} = $value;
	}
	close FILE;

	return %conf;
}


return 1;
