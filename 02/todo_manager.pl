use strict;
use warnings;

my $filename = '02/todo.txt';

sub add_task {
    my ($task) = @_;
    open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
    print $fh "$task | not done\n";
    close $fh;
    print "Task added: $task\n";
}

sub view_tasks {
    open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";
    print "To-Do List:\n";
    while (my $row = <$fh>) {
        chomp $row;
        print "$row\n";
    }
    close $fh;
}

sub mark_task_completed {
    my ($task_number) = @_;
    open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";
    my @lines = <$fh>;
    close $fh;

    open($fh, '>', $filename) or die "Could not open file '$filename' $!";
    for (my $i = 0; $i < @lines; $i++) {
        if ($i == $task_number - 1) {
            $lines[$i] =~ s/not done/done/;
        }
        print $fh $lines[$i];
    }
    close $fh;
    print "Task $task_number marked as completed.\n";
}

sub delete_task {
    my ($task_number) = @_;
    open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";
    my @lines = <$fh>;
    close $fh;

    open($fh, '>', $filename) or die "Could not open file '$filename' $!";
    for (my $i = 0; $i < @lines; $i++) {
        next if $i == $task_number - 1;
        print $fh $lines[$i];
    }
    close $fh;
    print "Task $task_number deleted.\n";
}

sub show_menu {
    print "\nTo-Do List Manager\n";
    print "1. Add Task\n";
    print "2. View Tasks\n";
    print "3. Mark Task as Completed\n";
    print "4. Delete Task\n";
    print "5. Exit\n";
    print "Choose an option: ";
}

while (1) {
    show_menu();
    my $choice = <STDIN>;
    chomp $choice;

    if ($choice == 1) {
        print "Enter the task description: ";
        my $task = <STDIN>;
        chomp $task;
        add_task($task);
    } elsif ($choice == 2) {
        view_tasks();
    } elsif ($choice == 3) {
        print "Enter the task number to mark as completed: ";
        my $task_number = <STDIN>;
        chomp $task_number;
        mark_task_completed($task_number);
    } elsif ($choice == 4) {
        print "Enter the task number to delete: ";
        my $task_number = <STDIN>;
        chomp $task_number;
        delete_task($task_number);
    } elsif ($choice == 5) {
        print "Goodbye!\n";
        last;
    } else {
        print "Invalid choice, please try again.\n";
    }
}
