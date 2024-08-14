use strict;
use warnings;

my $filename = '01/wordcount.txt';
open(my $fh, '<:encoding(UTF-8)', $filename)
    or die "Could not open file '$filename' $!";

my $word_count = 0;

while (my $row = <$fh>) {
    chomp $row;
    my @words = split(/\W+/, $row);
    $word_count += scalar @words;
}

close $fh;

print "Total words: $word_count\n";
