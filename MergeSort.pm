package File::MergeSort;

our $VERSION = '1.07';

use 5.006;     # 5.6.0
use strict;
use warnings;
use Carp;
use IO::File;
use IO::Zlib;

our @ISA = qw();

### PRIVATE METHODS

sub _open_file {

    my $file = shift;
    my $fh;

    if ( $file =~ /\.(z|gz)$/ ) {           # Files matching .z .gz or .zip
	$fh = IO::Zlib->new("$file", "rb");
    } else {
	$fh = new IO::File "< $file";
    }

    return $fh || undef;
}


sub _get_line {

    my $fh = shift;
    my $line = <$fh>;

    if ($line) {
	$line =~ s/\015?\012/\n/;           # This is necessary to fix CRLF problem
	chomp $line;
	return $line;
    } else {
	$fh->close;
	return undef;
    }
}


sub _get_index {

    # Given a line of code and a reference to code that extracts a
    # value from the line 'get_index' will return an index value that
    # can be used to compare the lines.

    my $line           = shift;
    my $index_code_ref = shift;

    my $index = $index_code_ref->($line);

    if ($index) {
	return $index;
    } else {
	carp "Unable to return an index.  Continuing regardless";
	return 0;
    }
}

### PUBLIC METHODS

sub new {

    my $class = shift;
    croak "Expecting a class not a reference" if ref $class;

    ### ARGUMENTS
    my $files_ref = shift;    # ref to array of files.
    my $index_ref = shift;    # ref to sub that will extract index value from line
    my $comp_ref  = shift;    # ref to sub used to compare index values
                              #       currently not used.

    ### CREATE SKELETON OBJECT
    my $self = { index      => $index_ref,
		 comparison => $comp_ref,
		 num_files  => 0,
	       };

    ### CREATE A RECORD FOR EACH FILE.
    my $n = 0;
    foreach my $file(@{$files_ref}) {

	if ( my $fh = _open_file($file) ) {
	
	    $self->{files}->[$n]->{fh} = $fh;               # Store object.
	    $self->{num_files} = $self->{num_files} + 1;    # Increase Count of open files

	    # Get line and index for each file.
	    $self->{files}->[$n]->{line}  = _get_line($fh);
	    $self->{files}->[$n]->{index} = _get_index($self->{files}->[$n]->{line}, $self->{index});
	    $n++;

	} else {
	    carp "Error. Unable to open file, $file. Continuing regardless";
	}
    }

    ### Now that the first records are complete for each file, SORT THEM.
    ### Create a sorted arrays based on the index values of each file.
    ### INITIAL SORT $self->{sorted}->hash

    my $array_ref = $self->{files};

    my %shash;
    $n = 0;
    foreach my $a_ref ( @{$self->{files}} ) {
	$shash{$n} = $a_ref->{index};
	$n++;
    }

    $n=0;
    foreach my $index ( sort { $shash{$a} cmp $shash{$b} } keys %shash ) {
	$self->{sorted}->[$n] = $self->{files}->[$index];
	$n++;
    }

    undef $self->{files};

    bless $self, $class;

} # End of sub new()

sub next_line {

    ### Main method.  This returns the next line from the stack.

    my $self = shift;

    my $line = $self->{sorted}->[0]->{line} || return undef;

    # print STDERR "extracting ...", $line, "\n";  # Debug.

    # Re-populate LOW VALUE, i.e. $self->{sorted}->[0]
    if ( my $newline = _get_line($self->{sorted}->[0]->{fh}) ) {
	$self->{sorted}->[0]->{line}  = $newline;
	$self->{sorted}->[0]->{index} = _get_index( $newline, $self->{index} );
    } else {
	shift @{$self->{sorted}};
	$self->{num_files}--;
    }

    ### One Pass Bubble Sort of $self->{sorted}
    ### We only need to find the new positions in the stack for the
    ### new index of the file.

    return $line if ($self->{num_files} <= 1);   # Abandon sorting when there is only one file left.

    my $i = 0;
    while ( $self->{sorted}->[$i]->{index} gt $self->{sorted}->[$i+1]->{index} ) {

	# Swap elements
	my $place_holder = $self->{sorted}->[$i];
	$self->{sorted}->[$i] = $self->{sorted}->[$i+1];
	$self->{sorted}->[$i+1] = $place_holder;

	$i++;
	last if ($i > $self->{num_files} - 2);

    }

    return $line;
}


sub dump {

    # Dump the contents of the file to either STDOUT or FILE.
    # Default: STDOUT

    my $self = shift;
    my $file = shift;

    if ($file) {
	# print STDERR "Printing to file: $file\n";  # Debug
	open( FILE, "> $file" ) or croak "Unable to create output file $file: $!";

	while ( my $line = $self->next_line ) {
	    print FILE $line, "\n";
	}

	close FILE or croak "Problems when closing output file $file: $!";

    } else {
	# print STDERR "Printing to STDOUT\n";  # Debug
	while ( my $line = $self->next_line ) {
	    print $line, "\n";
	}
    }
}


1;


=head1 NAME

File::MergeSort - Mergesort ordered files.

=head1 SYNOPSIS

 use File::MergeSort;

 # Create the MergeSort object.
 my $sort = new File::MergeSort( 
                [ $file_1, ..., $file_n ],  # Anonymous array of input files
                \&extract_function,         # Sub to extract merge key
                );


 # Retrieve the next line for processing
 my $line = $sort->next_line;
 print $line, "\n";

 # Dump remaining records in sorted order to a file.
 $sort->dump( $file );    # Omit $file to default to STDOUT


=head1 DESCRIPTION

File::MergeSort provides methods to merge and process a number of
B<pre-sorted> files into a single sorted output.

Merge keys are extracted from the input lines using a user defined
subroutine. Comparisons on the keys are done lexicographically.

Plaintext and compressed (.z or .gz) files are catered for.
C<IO::Zlib> is used to handle compressed files.

File::MergeSort is a hopefully straightforward solution for situations
where one wishes to merge data files with presorted records. An
example might be application server logs which record events
chronologically from a cluster.

=head2 POINTS TO NOTE

Comparisons on the merge keys are carried out lexicographically. The
user should ensure that the subroutine used to extract merge keys
formats the keys if required so that they sort correctly.

Note that earlier versions (< 1.06) of File::MergeSort preformed
numeric, not lexicographical comparisons.

=head2 DETAILS


The user is expected to supply a list of file pathnames and a function
to extract an index value from each record line (the merge key).

By calling the "next_line" or "dump" function, the user can retrieve
the records in an ordered manner.

As arguments, MergeSort takes a reference to an anonymous array of
file paths/names and a reference to a subroutine that extracts a merge
key from a line.

The anonymous array of the filenames are the files to be sorted with
the subroutine determining the sort order.

For each file MergeSort opens the file using IO::File or IO::Zlib for
compressed files.  MergeSort handles mixed compressed and uncompressed
files seamlessly by detecting for files with .z or .gz extensions.

When passed a line (a scalar, passed as the first and only argument,
$_[0]) from one of the files, the user supplied subroutine must return
the merge key for the line.

The records are then output in ascending order based on the merge
keys returned by the user supplied subroutine.
A stack is created based on the merge keys returned by the subroutine.

When the C<next_line> method is called, File::MergeSort returns the
line with the lowest merge key/value.

File::MergeSort then replenishes the stack, reads a new line from the
corresponding file and places it in the proper position for the next
call to C<next_line>.

If a simple merge is required, without any user processing of each
line read from the input files, the C<dump> method can be used to read
and merge the input files into the specified output file, or to STDOUT
if no file is specified.

=head1 CONSTRUCTOR

=over 4

=item new( ARRAY_REF, CODE_REF );

Create a new C<File::MergeSort> object.

There are two required arguments:

A reference to an array of files to read from.
These files can be either plaintext, or compressed.
Any file with a .gz or .z suffix will be opened using C<IO::Zlib>.

A code reference. When called, the coderef should return the merge key
for a line, which is given as the only argument to that
subroutine/coderef.

=back

=head1 METHODS

=over 4

=item next_line( );

Returns the next line from the merged input files.

=item dump( [ FILENAME ] );

Reads and merges from the input files to FILENAME, or STDOUT if
FILENAME is not given, until all files have been exhausted.

=back

=head1 EXAMPLES

  # This program looks at files found in /logfiles, returns the
  # records of the files sorted by the date in mm/dd/yyyy format

  use File::MergeSort;

  my $files = qw[ logfiles/log_server_1.log
                  logfiles/log_server_2.log
                  logfiles/log_server_3.log
                ];

  my $sort = File::MergeSort->new( $files, \&index_sub );

  while (my $line = $sort->next_line) {
     # some operations on $line
  }

  sub index_sub{

    # Use this to extract a date of the form mm-dd-yyyy.

    my $line = shift;

    # Be cautious that only the date will be extracted.
    $line =~ /(\d{2})-(\d{2})-(\d{4})/;

    return "$3$1$2";  # Index is an interger, yyyymmdd
                      # Lower number will be read first.
  }



  # This slightly more compact example performs a simple merge of
  # several input files with fixed width merge keys into a single
  # output file.

  use File::MergeSort;

  my $files   = qw [ input_1 input_2 input_3 ];
  my $extract = sub { substr($_[0], 15, 10 ) };  # To substr merge key out of line

  my $sort = File::MergeSort->new( $files, $extract );

  $sort->dump( "output_file" );

=head1 TODO

 + Implement a generic test/comparison function to replace text/numeric comparison.
 + Implement a configurable record seperator.
 + Allow for optional deletion of duplicate entries.

=head1 EXPORTS

Nothing. OO interface. See CONSTRUCTOR and METHODS

=head1 AUTHOR

Chris Brown: <chris.brown@cal.berkeley.edu>

Copyright(c) 2003 Christopher Brown.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<IO::File>, L<IO::Zlib>,  L<Compress::Zlib>.

L<File::Sort> as an alternative.

=cut
