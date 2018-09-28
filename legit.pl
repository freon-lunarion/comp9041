#!/usr/bin/perl -w
use File::Copy;
use File::Find;

use constant DIR => ".legit";
use constant INDEX => ".legit/index/";
use constant REPO => ".legit/repository/";
use constant LOG => ".legit/log";
use constant TEMP => ".legit/temp";

sub add;
sub branch;
sub checkout;
sub commit;
sub init;
sub log;
sub merge;
sub rm;
sub show;
sub status;

@ARGV > 0 or die "not enough parameter";

@ls = @ARGV;
$cmd = shift @ls;
if ($cmd eq "add") {
    add (@ls);
} elsif ($cmd eq "branch") {

} elsif ($cmd eq "checkout") {

} elsif ($cmd eq "commit") {
    commit(@ls);
} elsif ($cmd eq "init") {
    init();
} elsif ($cmd eq "log") {

} elsif ($cmd eq "merge") {

} elsif ($cmd eq "rm") {

} elsif ($cmd eq "show") {

} elsif ($cmd eq "status") {

} else {

}


sub init {
    if (-d DIR) {
        die "legit.pl: error .legit already exists\n";
    } else {    
        mkdir DIR;
        print "Initialized empty legit repository in ",DIR,"\n";
    }
}

sub add {
    if (! -d DIR) {
        die "legit.pl: error .legit not exists\n";
    }

    if (! -d INDEX) {
        mkdir INDEX;
    }

    @files = @_;
    foreach $file(@files){
        if ($file =~ /^[a-zA-Z0-9]{1,}[\.\-\_]{0,}/) {
            copy($file,INDEX.$file);
        }
    }
}

sub commit {
    if ( grep $_ eq "-a", @_ ) {

        opendir my $dir, INDEX;
        while (my $thing = readdir $dir) {
            if ($thing eq '.' or $thing eq '..') {
                next;
            }
            add($thing);
        }
        closedir $dir;
    }
    if (! -d REPO) {
        mkdir REPO;
    } 

    $dirnum = -1;
    find(
    sub {
        -d && $dirnum++;
        # print $FILE::Find::name, "\n";
    },
    REPO);
    # print $dirnum,"\n";
    mkdir REPO.$dirnum;

    opendir my $dir, INDEX;
        while (my $thing = readdir $dir) {
            if ($thing eq '.' or $thing eq '..') {
                next;
            }
            copy(INDEX.$thing,REPO.$dirnum."/".$thing);
        }
    closedir $dir;

    $msg = pop @_;
    
    # print $msg,"\n";

    if (-e LOG ) {
        open my $new, ">", TEMP;
        open my $old, "<", LOG;
        print $new  "$dirnum $msg\n";
        while (<$old>){
            print $new $_;
        }
        # close $old;
        close $new;

        unlink LOG;
        rename TEMP, LOG;
    } else {
        open my $new, ">", LOG;
        print $new  "$dirnum $msg\n";
        close $new;

    }

    print "Committed as commit as $dirnum\n"
}