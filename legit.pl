#!/usr/bin/perl -w
use File::Copy;
use File::Find;
use Digest::MD5 qw(md5_hex);

# use File::Slurp;

use constant DIR => ".legit";
use constant INDEX => ".legit/index/";
use constant TEMP_INDEX => ".legit/old_index";
use constant REPO => ".legit/repository/";

use constant TEMP => ".legit/temp";

use constant BRANCH_CUR => ".legit/branch.cur";

sub _getLastCommit;
sub _isSameFiles;
sub _get_cur_branch;

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
    branch(@ls);
} elsif ($cmd eq "checkout") {
    checkout(@ls);
} elsif ($cmd eq "commit") {
    commit(@ls);
} elsif ($cmd eq "init") {
    init();
} elsif ($cmd eq "log") {
    myLog();
} elsif ($cmd eq "merge") {
    merge(@ls);
} elsif ($cmd eq "rm") {
    rm(@ls);
} elsif ($cmd eq "show") {
    show($ARGV[1]);
} elsif ($cmd eq "status") {
    status();
} else {

}

sub _merge_files{
    my ($file_base, $file_a, $file_b) = @_;
    open my $handle, '<', $file_base;
    chomp(my @base = <$handle>);
    close $handle;

    open $handle, '<', $file_a;
    chomp(my @a = <$handle>);
    close $handle;

    open $handle, '<', $file_b;
    chomp(my @b = <$handle>);
    close $handle;

    my @result = ();
    my $counter = 0;
    while (@base) {
        if ($a[$counter] eq $b[$counter]) {
            push @result, $b[$counter];
        } elsif ($a[$counter] eq $base[$counter]) {
            push @result, $b[$counter];
        } elsif ($b[$counter] eq $base[$counter]) {
            push @result, $a[$counter];
        } else {
            push @result, $base[$counter];
        }
    }

    return @result;
}

sub _get_common_ancestor {
    my ($branch_0, $branch_1) = @_;
    
    open FL, "<", DIR."/branch.ls";
    while (<FL>) {
        @words = split / /, $_;
        
        if ($words[0] eq $branch_0 && $words[1] eq $branch_1) {
            close FL;
            return $words[2];
        } 
    }
    close FL;
}

sub merge {
    my ($branch, $m, $msg) = @_;
    my $cur_branch = _get_cur_branch();
    
    my $lastCommit_0 = _getLastCommit3($cur_branch);
    my $lastCommit_1 = _getLastCommit3($branch);
    
    my $common = _get_common_ancestor($cur_branch,$branch);

    opendir my $dir, "." or die "Cannot open directory: $!\n";
    my @work = grep(/^[a-zA-Z0-9]{1,}[\.\-\_]{0,}/, readdir $dir);
    closedir $dir;
    @work = sort @work;

    opendir $dir, REPO."$common" or die "Cannot open directory: $!\n";
    my @common = grep(/^[a-zA-Z0-9]{1,}[\.\-\_]{0,}/, readdir $dir);
    closedir $dir;
    @common = sort @common;

    opendir $dir, REPO."$lastCommit_0" or die "Cannot open directory: $!\n";
    my @b_0 = grep(/^[a-zA-Z0-9]{1,}[\.\-\_]{0,}/, readdir $dir);
    closedir $dir;
    @b_0 = sort @b_0;

    opendir $dir, REPO."$lastCommit_1" or die "Cannot open directory: $!\n";
    my @b_1 = grep(/^[a-zA-Z0-9]{1,}[\.\-\_]{0,}/, readdir $dir);
    closedir $dir;
    @b_1 = sort @b_1;

    my %union = ();

    foreach(@work){
        $union{$_}+=1;
    }

    foreach(@common){
        $union{$_}+=2;
    }

    foreach(@b_0){
        $union{$_}+=4;
    }

    foreach(@b_0){
        $union{$_}+=8;
    }

    foreach $key (sort keys %union) {
        if ($union{$key} == 1) {
            
            unlink($key);
        } elsif ($union{$key} == 2) {
            # do nothing
            
        } elsif ($union{$key} == 3) {
            unlink($key);           
            
        } elsif ($union{$key} == 4) {
            copy(REPO."$lastCommit_0/$key", $key);

            
        } elsif ($union{$key} == 5) {
            unlink($key);
            copy(REPO."$lastCommit_0/$key", $key);           

        } elsif ($union{$key} == 6) {
            copy(REPO."$lastCommit_0/$key", $key);    
            
        } elsif ($union{$key} == 7) {
            unlink($key);    
            copy(REPO."$lastCommit_0/$key", $key);           
            
        } elsif ($union{$key} == 8) {
            copy(REPO."$lastCommit_1/$key", $key);
            
        } elsif ($union{$key} == 9) {
            unlink($key);  
            copy(REPO."$lastCommit_1/$key", $key);
            
        } elsif ($union{$key} == 10) {
            copy(REPO."$lastCommit_1/$key", $key);
            
        } elsif ($union{$key} == 11) {
            unlink($key);
            copy(REPO."$lastCommit_1/$key", $key);

        } elsif ($union{$key} == 12) {
            if (_isSameFiles(REPO."$lastCommit_0/$key",REPO."$lastCommit_1/$key")) {
                copy(REPO."$lastCommit_1/$key", $key);
            } else {

            }
            
        } elsif ($union{$key} == 13) {
            unlink($key); 
            if (_isSameFiles(REPO."$lastCommit_0/$key",REPO."$lastCommit_1/$key")) {
                copy(REPO."$lastCommit_1/$key", $key);
            } else {

            } 

            
        } elsif ($union{$key} == 14) {
            if (_isSameFiles(REPO."$lastCommit_0/$key",REPO."$lastCommit_1/$key")) {
                copy(REPO."$lastCommit_1/$key", $key);
            } else {
                # compare with common
                if (_isSameFiles(REPO."$common/$key",REPO."$lastCommit_1/$key")) {
                    copy(REPO."$lastCommit_0/$key", $key);
                } elsif (_isSameFiles(REPO."$common/$key",REPO."$lastCommit_0/$key")) {
                    copy(REPO."$lastCommit_1/$key", $key);
                } else {
                    @output = _merge_files(REPO."$common/$key",REPO."$lastCommit_0/$key",REPO."$lastCommit_1/$key");
                    open FL, ">", $key;
                    foreach $line(@output) {
                        print FL "$line\n";
                    }
                    close FL;
                }
            }
            
        } elsif ($union{$key} == 15) {
            unlink($key); 
            if (_isSameFiles(REPO."$lastCommit_0/$key",REPO."$lastCommit_1/$key")) {
                copy(REPO."$lastCommit_1/$key", $key);
            } else {
                # compare with common
                if (_isSameFiles(REPO."$common/$key",REPO."$lastCommit_1/$key")) {
                    copy(REPO."$lastCommit_0/$key", $key);
                } elsif (_isSameFiles(REPO."$common/$key",REPO."$lastCommit_0/$key")) {
                    copy(REPO."$lastCommit_1/$key", $key);
                } else {
                    
                }
            }
            
        }
    }
    
}

sub branch {
    @ls = @_;
    my $isDel = 0;
    my $branch_name ='';
    if ( grep $_ eq "-d", @ls ) {
        $isDel = 1;
    }

    for $cmd (@ls) {
        if ($cmd ne "-d") {
            $branch_name = $cmd;
        }
    }
    $cur = _get_cur_branch();
    if ($isDel == 0 && $branch_name eq''){

        $last = _getLastCommit();
        if ($last == -1) {
            die "legit.pl: error: your repository does not have any commits yet\n";
        }
        
        opendir(D, DIR);
        @files = grep { /\.log$/ } readdir(D);
        closedir(D);
        
        foreach $file(sort @files) {
            @temp = split /\./, $file;
            print $temp[0];
            # if ($temp[0] eq $cur) {
            #     print " *";
            # }
            print "\n";
        }

    } elsif ($branch_name ne '' && $isDel == 0) {
        if ( -e DIR."/$branch_name.log") {
            die "legit.pl: error: branch '$branch_name' already exists\n";
        }
        $common = _getLastCommit();
        open FL, ">>", DIR."/branch.ls";
        print FL "$cur $branch_name $common";
        close FL;

        copy(DIR."/".$cur.".log",DIR."/".$branch_name.".log");

    } elsif ($branch_name ne'' && $isDel == 1) {
        
        if ($branch_name eq 'master'){
            die "legit.pl: error: can not delete branch 'master'\n";
        }
        
        if (! -e DIR."/$branch_name.log") {
            die "legit.pl: error: branch '$branch_name' does not exist\n";
        }

        unlink DIR."/".$branch_name.".log";
        print "Deleted branch '$branch_name'\n";
        
    }

}

sub checkout {
    my $branch = shift;
    $cur = _get_cur_branch();

    if ($cur eq $branch) {

    }
    $other = _getLastCommit();

    # print $branch;
    if (! -e DIR."/$branch.log") {
        die "legit.pl: error: unknown branch '$branch'\n";
    }

    open FL , ">" ,BRANCH_CUR;
    print FL  $branch;
    close FL;

    # # to do load the last commit into the working dir

    print "Switched to branch '$branch'\n";
    $last = _getLastCommit();
    if ($last >=0){
        $indexDir = INDEX;
        $commitDir = REPO."$last/";
        $otherDir = REPO."$other/";
        $workDir = ".";
        %files = ();

        opendir $dir, $workDir;
        while (my $thing = readdir $dir) {
            if ($thing eq '.' or $thing eq '..' or $thing eq 'legit.pl'or $thing eq 'diary.txt' or $thing =~ /^\./) {
                next;
            }

            $files{$thing} += 1;
        }
        closedir $dir;

        opendir $dir, $indexDir;
        while (my $thing = readdir $dir) {
            if ($thing eq '.' or $thing eq '..' or $thing eq 'legit.pl'or $thing eq 'diary.txt' or $thing =~ /^\./) {
                next;
            }

            $files{$thing} += 2;
        }
        closedir $dir;

        opendir $dir, $commitDir;
        while (my $thing = readdir $dir) {
            if ($thing eq '.' or $thing eq '..' or $thing eq 'legit.pl'or $thing eq 'diary.txt' or $thing =~ /^\./) {
                next;
            }

            $files{$thing} += 4;
        }
        closedir $dir;

        foreach $file (keys %files) {
            if ($files{$file} == 1) {
                # unlink($file);
            } elsif ($files{$file} == 2) {
                # copy($indexDir.$file, $file);

            } elsif ($files{$file} == 3) {
                unlink($file);
                # copy($indexDir.$file, $file);
                
            } elsif ($files{$file} == 4) {
                copy($commitDir.$file, $file);

            } elsif ($files{$file} == 5) {
                copy($commitDir.$file, $file);
                
            } elsif ($files{$file} == 6) {
                copy($commitDir.$file, $file);
                
            } elsif ($files{$file} == 7) {
                if (!_isSameFiles($commitDir.$file, $file) && !_isSameFiles($indexDir.$file, $file) && _isSameFiles($indexDir.$file, $commitDir.$file) ) {
                    if (!_isSameFiles($commitDir.$file,$otherDir.$file)) {
                        copy($commitDir.$file, $file);

                    }

                } elsif (!_isSameFiles($commitDir.$file, $file) && _isSameFiles($indexDir.$file, $file) && ! _isSameFiles($indexDir.$file, $commitDir.$file) ) {
                    if (!_isSameFiles($commitDir.$file,$otherDir.$file)) {
                        copy($commitDir.$file, $file);

                    }

                } else {
                    copy($commitDir.$file, $file);
                }

                
                
            }
        }

        
    }
}

sub status {
    $lastCommit = _getLastCommit();
    $lastDir = REPO.$lastCommit."/";

    opendir my $dir, $lastDir or die "Cannot open directory: $!\n";
    my @repo = grep(/^[a-zA-Z0-9]{1,}[\.\-\_]{0,}/, readdir $dir);
    closedir $dir;
    @repo = sort @repo;

    opendir $dir, INDEX or die "Cannot open directory: $!\n";
    my @index = grep(/^[a-zA-Z0-9]{1,}[\.\-\_]{0,}/, readdir $dir);
    closedir $dir;
    @index = sort @index;

    opendir $dir, "." or die "Cannot open directory: $!\n";
    my @work = grep(/^[a-zA-Z0-9]{1,}[\.\-\_]{0,}/,readdir $dir);
    closedir $dir;
    @work = sort @work;

    my %union = ();
    foreach(@repo){
        $union{$_}+=1;
    }
    foreach(@index){
        $union{$_}+=2;
    }
    foreach(@work){
        $union{$_}+=4;
    }

    foreach $key (sort keys %union) {
        print "$key - ";
        if($union{$key} == 1 ) {
            print "deleted";
        } elsif($union{$key} == 2 || $union{$key} == 3 ) {
            print "file deleted";
        } elsif ($union{$key} == 4){
            print "untracked";
        } elsif ($union{$key} == 5) {
            #two-way compare
            print "untracked";

        } elsif ($union{$key} == 6) {
            print "added to index";
        } elsif ($union{$key} == 7) {
            #three-way compare
            if (_isSameFiles($key,$lastDir.$key)) {
                print "same as repo";
            } else {
                print "file changed, ";
                if (! _isSameFiles($key,INDEX.$key) && ! _isSameFiles($lastDir.$key,INDEX.$key) ) {
                    print "different changes staged for commit";
                } elsif ( _isSameFiles($key,INDEX.$key) && ! _isSameFiles($lastDir.$key,INDEX.$key)) {
                    print "changes staged for commit";
                } else {
                    print "changes not staged for commit";
                }
            }
        } else {
            print "$union{$key}";
        }
        print "\n";
        
    }
}

sub init {
    if (-d DIR) {
        die "legit.pl: error: .legit already exists\n";
    } else {    
        mkdir DIR;
        print "Initialized empty legit repository in ",DIR,"\n";
    }

    #create master.$log

    open FL, ">", DIR."/master.log";
    print FL '';
    close FL;

    # open FL, ">", BRANCH_LS;
    # print FL "master\n";
    # close FL;
    
    #create branch.cur
    open FL, ">", BRANCH_CUR;
    print FL "master\n";
    close FL;

}

sub add {
    if (! -d DIR) {
        die "legit.pl: error: no .legit directory containing legit repository exists\n";
    }

    if (! -d INDEX) {
        mkdir INDEX;
    }

    @files = @_;
    foreach $file(@files){

        if (! -e $file && ! -e INDEX.$file) {
            die "legit.pl: error: can not open '$file'\n";
        } elsif (! -e $file && -e INDEX.$file) {
            unlink INDEX.$file;
        }
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
    my %files;
    $dirCommit = REPO.$lastCommit."/";

    if ( grep $_ eq "--force", @ls ) {
        $isForce = 1;
    }

    if (! grep $_ eq "--cached", @ls ) {
        $isCurDir = 1;
    }

    foreach $item(@ls){
        if($item ne "--force" && $item ne "--cached") {
            $files{$item} = 0;
        }
    }

    # print "$isForce, $isCurDir\n";
    foreach $file (keys %files) {
        if (-e $file) {
            $files{$file} += 1
        }

        if (-e INDEX.$file) {
            $files{$file} += 2
        }

        if (-e $dirCommit.$file) {
            $files{$file} += 4
        }
    }

    
    if ($isForce == 0) {
        foreach $file (sort keys %files) {
            # print "$file\n";

            if ($files{$file} == 1) {
                die "legit.pl: error: '$file' is not in the legit repository\n"

            } elsif ($files{$file} == 2) {
                #nothing
                
            } elsif ($files{$file} == 3) {
                
                if (! _isSameFiles(INDEX.$file, $file) || $isCurDir == 1) {
                    die "legit.pl: error: '$file' has changes staged in the index\n";
                } 
            } elsif ($files{$file} == 4) {
                #nothing
            } elsif ($files{$file} == 5) {
                #working & last repo
                if (! _isSameFiles($file, $dirCommit.$file) ){
                    die "legit.pl: error: '$file' in repository is different to working file\n";
                }
            } elsif ($files{$file} == 6) {
                #index & last repo

            } elsif ($files{$file} == 7 && $isCurDir == 1) {
                #three way
                if (! _isSameFiles($file, $dirCommit.$file) && ! _isSameFiles(INDEX.$file, $dirCommit.$file)  && ! _isSameFiles(INDEX.$file, $file)){
                    die "legit.pl: error: '$file' in index is different to both working file and repository\n";
                } elsif (! _isSameFiles($file, $dirCommit.$file) && _isSameFiles(INDEX.$file, $dirCommit.$file)) {
                    die "legit.pl: error: '$file' in repository is different to working file\n";

                } elsif (! _isSameFiles(INDEX.$file, $dirCommit.$file) ){
                    die "legit.pl: error: '$file' has changes staged in the index\n";
                }

            } elsif ($files{$file} == 7 && $isCurDir == 0) {
                #two way
                if ( ! _isSameFiles(INDEX.$file, $dirCommit.$file)  && ! _isSameFiles(INDEX.$file, $file)){
                    die "legit.pl: error: '$file' in index is different to both working file and repository\n";
                } 

            }
        }
    } else {
        foreach $file (keys %files) {
            if ($files{$file} == 1) {
                die "legit.pl: error: '$file' is not in the legit repository\n"

            } elsif ($files{$file} == 5) {
                die "legit.pl: error: '$file' is not in the legit repository\n"

            }
        }
    }

    foreach $file (keys %files) {
        # print "$file\n";
        unlink INDEX.$file;
        if ($isCurDir == 1) {
            unlink $file; 
        }
    }

}

sub commit {
    if ( grep $_ eq "-a", @_ ) {
        # move(TEMP_INDEX,INDEX);
        opendir my $dir, INDEX;
        while (my $thing = readdir $dir) {
            if ($thing eq '.' or $thing eq '..') {
                next;
            }
            add($thing);
        }
        closedir $dir;
    }
    if (! -d INDEX) {
        die "nothing to commit \n";
    } 

    if (! -d REPO) {
        mkdir REPO;
    } 

    $lastCommit = _getLastCommit2();
    if ($lastCommit >= 0) {
        $lastDir = REPO.$lastCommit."/";

        opendir my $dir, $lastDir or die "Cannot open directory: $!\n";
        my @repo = grep(/^[a-zA-Z0-9]{1,}[\.\-\_]{0,}/, readdir $dir);
        closedir $dir;
        @repo = sort @repo;

        opendir $dir, INDEX or die "Cannot open directory: $!\n";
        my @index = grep(/^[a-zA-Z0-9]{1,}[\.\-\_]{0,}/, readdir $dir);
        closedir $dir;
        @index = sort @index;

        my %union = ();
        my $allSame = 1;

        my $repo_size = @repo;
        my $index_size = @index;

        if ( $repo_size != $index_size) {
            $allSame = 0;

        } else {
            foreach(@repo){
                $union{$_}+=1;
            }
            foreach(@index){
                $union{$_}+=2;
            }

            foreach $key (sort keys %union) {
                # print "$key, $union{$key}\n";
                if($union{$key} == 1) {
                    $allSame = 0;
                    last;
                }elsif ($union{$key} == 2) {
                    $allSame = 0;
                    last;
                } elsif ($union{$key} == 3) {
                    if (-e $key && !_isSameFiles($key,$lastDir.$key)) {
                        $allSame = 0;
                        last;
                    }
                }
            }
        }

        if ($allSame == 1) {
            die "nothing to commit\n";
        }
        # my %index=map{$_ =>1} @index;
        # my %repo=map{$_=>1} @repo;
        # my @intersect = grep( $simpsindeons{$_}, @repo );
    }
    

    $dirnum = $lastCommit;
    if ($dirnum < 0) {
        $dirnum = 0;
    } else {
        $dirnum += 1;
    }
    
    mkdir REPO.$dirnum;

    opendir $dir, INDEX;
    while (my $thing = readdir $dir) {
        if ($thing eq '.' or $thing eq '..') {
            next;
        }
        copy(INDEX.$thing,REPO.$dirnum."/".$thing);
    }
    closedir $dir;

    $branch = _get_cur_branch();
    
    $log = DIR."/$branch.log";
    $msg = pop @_;
    if (-e $log ) {
        open my $new, ">", TEMP;
        open my $old, "<", $log;
        print $new  "$dirnum $msg\n";
        while (<$old>){
            print $new $_;
        }
        # close $old;
        close $new;

        unlink $log;
        rename TEMP, $log;
    } else {
        open my $new, ">", $log;
        print $new  "$dirnum $msg\n";
        close $new;
    }

    # move(INDEX,TEMP_INDEX);

    print "Committed as commit $dirnum\n"
}

sub myLog {
    $branch = _get_cur_branch();
    $log = DIR."/$branch.log";

    open FL ,"<", $log;
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
        die "legit.pl: error: unknown commit '$commit'\n";
    }

    if (! -e $dir.$filename) {
        if ($commit ne '') {
            die "legit.pl: error: '$filename' not found in commit $commit\n";

        } else {
            die "legit.pl: error: '$filename' not found in index\n";
            
        }
    }

    open FL ,"<", $dir.$filename;
    while (<FL>) {
        print $_;
    }
    close FL;
    # print "\n";
}

sub _getLastCommit {
    my $branch = _get_cur_branch();
    my $cur ='';
    # return $dirnum;
    open my $file, '<', DIR."/$branch.log" ;

    $cur = <$file>;
    close $file;
    
    if (!$cur ) {
        return -1;
    }
    chomp $cur;
    @words = split / /, $cur;
    if ($words[0] ne '') {
        return $words[0];
    } else {
        return -1;
    }
}

sub _getLastCommit2 {
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

sub _getLastCommit3 {
    my $branch = shift;
    my $cur ='';

    open my $file, '<', DIR."/$branch.log" ;

    $cur = <$file>;
    close $file;
    
    if (!$cur ) {
        return -1;
    }
    chomp $cur;
    @words = split / /, $cur;
    if ($words[0] ne '') {
        return $words[0];
    } else {
        return -1;
    }
}

sub _isSameFiles {
    my ($file_1, $file_2) = @_;
    my $hash_1 = Digest::MD5->new;
    my $hash_2 = Digest::MD5->new;

    if (! -e $file_1 && ! -e $file_2 ) {
        return 1;
    } elsif (! -e $file_1 || ! -e $file_2 ) {
        return 0;
    }

    open FL , "<",$file_1 or die "Can't open '$file_1': $!\n";
    foreach $line (<FL>) {
        $hash_1->add($line);
    }
    close FL;

    open FL , "<",$file_2 or die "Can't open '$file_2': $!\n";
    foreach $line (<FL>) {
        $hash_2->add($line);
    }
    close FL;


    # if (md5_hex(read_file($file_1)) eq md5_hex(read_file($file_2))) {
    if ($hash_1->hexdigest eq $hash_2->hexdigest ) {
        return 1;
    } else {
        return 0;
    }
}

sub _get_cur_branch {
    #get current branch
    open my $file, '<', BRANCH_CUR; 
    my $cur = <$file>;
    close $file;
    chomp $cur;
    return $cur;
}