#!/usr/bin/perl -w

 use constant DIR => ".legit";

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

$cmd = $ARGV[0];

if ($cmd eq "add") {

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

}


sub init {
    if (-d DIR) {
        die "legit.pl: error .legit already exists\n";
    } else {    
        mkdir DIR;
        print "Initialized empty legit repository in ",DIR,"\n";
    }
}