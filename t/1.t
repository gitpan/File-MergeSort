# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;


#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
# its man page ( perldoc Test ) for help writing this test script.

BEGIN { use_ok('IO::File') };
BEGIN { use_ok('IO::Zlib') };
BEGIN { use_ok('File::MergeSort') };


my $files = ['_test/file1.txt', '_test/file2.txt', '_test/file4.txt', '_test/file3.txt.gz', '_test/file5.txt.gz']; #  

## CREATE MS OBJECT
my $sort = new File::MergeSort( $files, \&index );
ok( $sort, "Create MergeSort Object" );


my $n = 0;
while (my $line = $sort->next_line) {
	# print "$line\n";
	$n++;
}

ok(1, "MergeSort");

## $sort->dump();



sub index {
	my $line = shift;
	# print "index .. $line\n";
	my @fields = split(/\t/, $line);
	return $fields[1];
}



