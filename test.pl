#!/usr/bin/perl

use strict;
use warnings;
use File::MergeSort 1.06;

my $files = ['t/_test/file1.txt', 't/_test/file2.txt', 't/_test/file3.txt.gz', 't/_test/file4.txt',  't/_test/file5.txt.gz'];

sub index {
	my $line = shift;
	# print "index .. $line\n";
	my @fields = split(/\t/, $line);
	return $fields[1];
}

# Create MergeSort object
my $sort = File::MergeSort->new( $files, \&index );

my $n = 0;
while (my $line = $sort->next_line) {
	print STDERR $line, "\n";
	$n++;
}

