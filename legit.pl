#!/usr/bin/perl -w
use File::Copy;
use File::Find;
use Digest::MD5 qw(md5_hex);
use File::Slurp;

use constant DIR => ".legit";
use constant INDEX => ".legit/index/";
use constant REPO => ".legit/repository/";
use constant LOG => ".legit/log";
use constant TEMP => ".legit/temp";

sub _getLastCommit;
sub _isSameFiles;

sub add;
sub branch;
sub checkout;
sub commit;
sub init;
sub myLog;
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
    myLog();
} elsif ($cmd eq "merge") {

} elsif ($cmd eq "rm") {
    rm(@ls);
} elsif ($cmd eq "show") {
    show($ARGV[1]);
} elsif ($cmd eq "status") {
    status();
} else {

}

sub status() {
    
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

sub rm {
    @ls = @_;
    my $isCurDir = 0;
    my $isForce = 0;
    my $lastCommit = _getLastCommit();

    if ( grep $_ eq "--force", @ls ) {
        $isForce = 1;
    }

    if (! grep $_ eq "--cache", @ls ) {
        $isCurDir = 1;
    }

    $dirCommit = REPO.$lastCommit."/";
    if ($isForce == 0 ){
        foreach $file (@ls) {
            if (! _isSameFiles(INDEX.$file, $dirCommit.$file) ){
                die "index file diffrent from last commit";
            }

            if ($isCurDir == 1) {
                if (! _isSameFiles(INDEX.$file, $dirCommit.$file) ){
                    die "current file diffrent from last commit";
                }
            }
        }

    }

    foreach $file (@ls) {
        if ($file ne '--cache' &&  $file ne '--force') {
            unlink INDEX.$file;
            if ($isCurDir == 1) {
                unlink $file; 
            }
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

    $filenum = -1;
    find(
        sub {
            -e && $filenum++;
        },INDEX
    );

    if ($filenum <= 0) {
        die "no file to commit";
    }

    $dirnum = _getLastCommit();
    if ($dirnum < 0) {
        $dirnum = 0;
    } else {
        $dirnum += 1;
    }
    
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

sub myLog {
    open FL ,"<", LOG;
    while (<FL>) {
        print $_;
    }
    close FL;
}

sub show {

    my ($commit,$filename) = split /\:/,shift;
    # print "$commit\n$filename\n";
    
    if ($commit ne '') {
        $dir = REPO.$commit.'/';
    } else {
        $dir = INDEX;
    }

    if (! -d $dir) {
        die "directory not exists";
    }

    if (! -e $dir.$filename) {
        die "file not exists";
    }

    open FL ,"<", $dir.$filename;
    while (<FL>) {
        print $_;
    }
    close FL;
    print "\n";
}

sub _getLastCommit {
    $dirnum = -2;
    if (-d REPO) {
        find(
        sub {
            -d && $dirnum++;
            # print $FILE::Find::name, "\n";
        },
        REPO);
    }
    

    return $dirnum;
}

sub _isSameFiles {
    my ($file_1, $file_2) = @_;
    if (md5_hex(read_file($file_1)) eq md5_hex(read_file($file_2))) {
        return 1;
    } else {
        return 0;
    }
}
