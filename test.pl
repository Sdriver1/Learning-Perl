#!/usr/bin/perl

use strict;
use warnings;

my $newvar = 10;
my @array = (1, 2, 3, 4, 5);
my %hash = ('key1' 5, 'key2' 10, 'key3', 15);

print "Value of hash is ", join(", ", %hash), "\n";
print "Value of array is @array\n";
print "Value of newvar is $newvar\n";
print "Hello, World!\n";
