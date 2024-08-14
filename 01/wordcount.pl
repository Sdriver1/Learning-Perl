use strict;
use warnings;

my $filename = '01/wordcount.txt';
open(my $fh, '<:encoding(UTF-8)', $filename)
    or die "Could not open file '$filename' $!";

my $word_count = 0;

# Read the file line by line
while (my $row = <$fh>) {
    chomp $row;
    # Split the line into words
    my @words = split(/\W+/, $row);
    # Count the words
    $word_count += scalar @words;
}

close $fh;

# Print the total word count
print "Total words: $word_count\n";
