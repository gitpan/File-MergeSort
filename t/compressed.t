#!/usr/bin/perl

use 5.006;
use warnings;
use strict;

my $have_io_zlib;

BEGIN {
    eval "require IO::Zlib";
    unless ($@) {
        require IO::Zlib;
        $have_io_zlib++;
    }
}

use Test::More 'no_plan';


exit 0 unless $have_io_zlib;

BEGIN { use_ok('IO::File') };         # test 1
BEGIN { use_ok('File::MergeSort') };  # test 2
use_ok('IO::Zlib');                   # test 3

my $m;
my @compress_files   = qw( t/1.gz t/2.gz );
my @uncompress_files = qw( t/1 t/2 );
my @mix_files        = qw( t/1.gz t/2 );

my $coderef = sub { my $line = shift; substr($line,0,2); };

# Test 4: create object with purely compressed files.

eval {
    $m = File::MergeSort->new( \@compress_files, $coderef );
};

ok( ref $m eq 'File::MergeSort'); # test 4

my $in_lines = 0;

foreach my $file ( @uncompress_files ) {
    open F, "< $file" or die "Unable to open test file $file: $!";
    while (<F>) { $in_lines++ };
    close F or die "Problems closing test file, $file: $!";
}

my $d;

$d = $m->dump();

ok($d eq $in_lines); # test 5

# Test 6: create object with mixed compressed/uncompress files.

eval {
    $m = File::MergeSort->new( \@mix_files, $coderef );
};

ok( ref $m eq 'File::MergeSort'); # test 6

$d = $m->dump();

ok($d eq $in_lines); # test 7

eval {
    $m = File::MergeSort->new( \@compress_files, $coderef );
};

# Check data being returned by next_line really is in sorted order.

my $i = 0;
my $last;

while ( my $line = $m->next_line() ) {
    my $key = $coderef->( $line );
    ok( $key ge $last) if $i > 1;
    $last = $key;
    $i++;
}

ok($i eq $in_lines );
