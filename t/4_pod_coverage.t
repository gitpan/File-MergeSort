#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

eval { require Test::Pod::Coverage; };
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

plan tests => 1;
pod_coverage_ok( "File::MergeSort" );
