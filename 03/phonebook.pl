use strict;
use warnings;

my $filename = '03/phonebook.txt';
sub add_contact {
    my ($name, $number) = @_;
    open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
    print $fh "$name | $number\n";
    close $fh;
    print "Added $name - $number\n";
}
sub update_contact {
    my ($name_to_update, $new_name, $new_number) = @_;

    open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";
    my @lines = <$fh>;
    close $fh;

    open($fh, '>', $filename) or die "Could not open file '$filename' $!";

    my $updated = 0;
    foreach my $line (@lines) {
        chomp $line;
        my ($name, $number) = split(/\s*\|\s*/, $line);

        if ($name eq $name_to_update) {
            $name = $new_name if defined $new_name;
            $number = $new_number if defined $new_number;
            print $fh "$name | $number\n";
            $updated = 1;
        } else {
            print $fh "$line\n";
        }
    }

    close $fh;

    if ($updated) {
        print "Updated contact: $name_to_update to $new_name | $new_number\n";
    } else {
        print "Contact '$name_to_update' not found.\n";
    }
}
sub delete_contact {
    my ($name_to_delete) = @_;
    
    open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";
    my @lines = <$fh>;
    close $fh;

    open($fh, '>', $filename) or die "Could not open file '$filename' $!";
    
    my $deleted = 0;
    foreach my $line (@lines) {
        chomp $line;
        my ($name, $number) = split(/\s*\|\s*/, $line);

        if ($name eq $name_to_delete) {
            $deleted = 1;
            next; 
        } else {
            print $fh "$line\n";
        }
    }

    close $fh;

    if ($deleted) {
        print "Contact '$name_to_delete' deleted.\n";
    } else {
        print "Contact '$name_to_delete' not found.\n";
    }
}
sub view_contacts {
    open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";
    print "Phonebook:\n";
    while (my $row = <$fh>) {
        chomp $row;
        print "$row\n";
    }
    close $fh;
}
sub show_menu {
    print "\nPhonebook Manager\n";
    print "1. Add Contact\n";
    print "2. View Contacts\n";
    print "3. Update Contact\n";
    print "4. Delete Contact\n";
    print "5. Exit\n";
    print "Choose an option: ";
}

while (1) {
    show_menu();
    my $choice = <STDIN>;
    chomp $choice;

    if ($choice == 1) {
        print "Enter the contact name: ";
        my $name = <STDIN>;
        chomp $name;
        print "Enter the contact number: ";
        my $number = <STDIN>;
        chomp $number;
        add_contact($name, $number);
    } elsif ($choice == 2) {
        view_contacts();
    } elsif ($choice == 3) {
        view_contacts();
        print "\nEnter the name of the contact to update: ";
        my $name_to_update = <STDIN>;
        chomp $name_to_update;
        print "Enter the new name (leave blank to keep current): ";
        my $new_name = <STDIN>;
        chomp $new_name;
        $new_name = undef if $new_name eq '';
        print "Enter the new number (leave blank to keep current): ";
        my $new_number = <STDIN>;
        chomp $new_number;
        $new_number = undef if $new_number eq '';
        update_contact($name_to_update, $new_name, $new_number);
    } elsif ($choice == 4) {
        print "Enter the name of the contact to delete: ";
        my $name_to_delete = <STDIN>;
        chomp $name_to_delete;
        delete_contact($name_to_delete);
    } elsif ($choice == 5) {
        print "Goodbye!\n";
        last;
    } else {
        print "Invalid choice, please try again.\n";
    }
}
