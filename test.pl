# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5 };
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use IO::File;
ok(2);
use IO::Zlib;
ok(3);
use File::MergeSort;
ok(4);

my @files = ('test/file1.txt', 'test/file2.txt', 'test/file4.txt', 'test/file3.txt.gz', 'test/file5.txt.gz'); #  

my $sort = new File::MergeSort( 
	\@files, 
	# OR, ['file1.txt', 'file2.txt', 'file4.txt', 'file3.txt.gz', 'file5.txt.gz'] , 
	\&index 
);

my $n = 0;

while (my $line = $sort->next_line) {
	# print "$line \n";
	$n++;
}

# $sort->dump();



sub index {
	my $line = shift;
	# print "index .. $line\n";
	my @fields = split(/\t/, $line);
	return $fields[1];
}



ok($n, 36);
