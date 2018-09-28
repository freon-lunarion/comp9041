#!/usr/bin/perl -w
use File::Copy;

use constant DIR => ".legit";
use constant INDEX => ".legit/index/";

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