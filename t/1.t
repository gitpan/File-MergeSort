# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;

BEGIN { use_ok('IO::File') };
BEGIN { use_ok('IO::Zlib') };
BEGIN { use_ok('File::MergeSort') };

my $files = [
		  't/_test/file1.txt',
	      't/_test/file2.txt',
	      't/_test/file3.txt.gz',
	      't/_test/file4.txt',
	      't/_test/file5.txt.gz'
	    ];

sub index {
	my $line = shift;
	# print "index .. $line\n";
	my @fields = split(/\t/, $line);
	return $fields[1];
}

my $output   = 't/_test/output';
my $expected = 't/_test/expected';

my $exp;    # To hold expected test results.
my $out;    # To hold actual test results.

### Create MergeSort object
my $sort = File::MergeSort->new( $files, \&index );

ok( ref $sort eq "File::MergeSort", "Create MergeSort Object" );

open(OUT, "> $output") or die "Can't create test output $output: $!";

while (my $line = $sort->next_line() ) {
    print OUT $line, "\n";
}

close(OUT) or die "Problems closing test output $output: $!";

open(OUT,    "< $output")   or die "Can't read test output $output: $!";
open(EXPECT, "< $expected") or die "Can't read expected results $expected: $!";

{
    local $/ = undef;
    $exp = <EXPECT>;
    $out = <OUT>;
}

close OUT;
close EXPECT;

### Compare output using $sort->next_line() to expected output.
cmp_ok( $exp, "eq", $out, "next_line() output check");

undef $out;
unlink $output or warn "Unable to unlink $output: $!";


### Create another MergeSort object
my $sort2 = File::MergeSort->new( $files, \&index );

$sort2->dump( $output );

open(OUT, "< $output") or die "Can't read test output $output: $!";

{
    local $/ = undef;
    $out = <OUT>;
}

### Compare output using $sort->dump() to expected output.
cmp_ok( $exp, "eq", $out, "dump() output check");

undef $out;
unlink $output or warn "Unable to unlink $output: $!";
