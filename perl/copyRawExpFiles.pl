#!/usr/bin/perl
#=======================================================================
#       Copy experiment raw result files
#=======================================================================

use strict;
use SCM::FixEnv;
use SCM::Argv;
use SCM::Log;
use XML::DOM;
use POSIX;
use Date::Parse;
use Text::CSV;


my $WINDOWS = 0;

my $COPY_MODE_NONE = 0;
my $COPY_MODE_MOVE = 1;
my $COPY_MODE_COPY = 2;
my $copyMode = $COPY_MODE_NONE;
my ($doCopy, $doMove);

my ($inDir, $outDir);
my ($sessionIDFilter, $sessionIDREFilter, $subjectIDFilter, $subjectNameFilter, $subjectNameREFilter, $expTypeFilter, $expIDFilter, $expIDREFilter, $noFilter);

my $logFile = "$main::TEMP/$main::PROG"; $logFile =~ s/\.pl$/.log/;


my $basePath = $ENV{IPAD_DATA_BASE_PATH};
my $SUBJECTS_FILE = "subjects.csv";

#=======================================================================

my @PROG_ARGS = (
    { FLAG => '-i', TYPE => 'dir', UNAME => '<src-dir>', VAR => \$inDir, OPTIONAL => 0,
        FULL_TEXT => "Source directory." },
    { FLAG => '-o', TYPE => 'dir', UNAME => '<dest-dir>', VAR => \$outDir, OPTIONAL => 1,
        FULL_TEXT => "Destination directory." },
    { FLAG => '-session', TYPE => 'scalar', UNAME => '<session-id>', VAR => \$sessionIDFilter, OPTIONAL => 1,
        FULL_TEXT => "ID of session to copy (exact match)" },
    { FLAG => '-sessionre', TYPE => 'scalar', UNAME => '<session-id-regexp>', VAR => \$sessionIDREFilter, OPTIONAL => 1,
        FULL_TEXT => "ID of session to copy (regular expression)" },
    { FLAG => '-subjid', TYPE => 'scalar', UNAME => '<subject-id>', VAR => \$subjectIDFilter, OPTIONAL => 1,
        FULL_TEXT => "Subject ID (exact match)" },
    { FLAG => '-subjname', TYPE => 'scalar', UNAME => '<subject-name>', VAR => \$subjectNameFilter, OPTIONAL => 1,
        FULL_TEXT => "Subject name (exact match)" },
    { FLAG => '-subjnamere', TYPE => 'scalar', UNAME => '<subject-name-regexp>', VAR => \$subjectNameREFilter, OPTIONAL => 1,
        FULL_TEXT => "Subject name (regular expression)" },
    { FLAG => '-exptype', TYPE => 'scalar', UNAME => '<experiment-type>', VAR => \$expTypeFilter, OPTIONAL => 1,
        FULL_TEXT => "Experiment type (exact match)" },
    { FLAG => '-expid', TYPE => 'scalar', UNAME => '<experiment-id>', VAR => \$expIDFilter, OPTIONAL => 1,
        FULL_TEXT => "Experiment ID (exact match)" },
    { FLAG => '-expidre', TYPE => 'scalar', UNAME => '<experiment-id-regexp>', VAR => \$expIDREFilter, OPTIONAL => 1,
        FULL_TEXT => "Experiment ID (regular expression)" },
    { FLAG => '-all', TYPE => 'flag', VAR => \$noFilter, OPTIONAL => 1,
        FULL_TEXT => "Move/copy ALL files (you should specify this if you provide no filter)" },
    { FLAG => '-mv', TYPE => 'flag', VAR => \$doMove, OPTIONAL => 1,
        FULL_TEXT => "Move files from source to dest dir" },
    { FLAG => '-cp', TYPE => 'flag', VAR => \$doCopy, OPTIONAL => 1,
        FULL_TEXT => "Copy files from source to dest dir" },
    { FLAG => '-l', TYPE => 'scalar', UNAME => '<log-file>', VAR => \$logFile, OPTIONAL => 1,
        FULL_TEXT => "Log file name (default: $logFile)." },
    { FLAG => '-h', TYPE => sub { print_usage(1); }, HELP => 1, VAR => '', OPTIONAL => 1 }
);


#========================================================================================================

sub main {
	
	parse_argv();
    
    my $subjects = readSubjectFile();
    my $sessions = getSessionData($inDir, $subjects);
    
    my $sessionsToCopy = filterSessions($sessions, $copyMode != $COPY_MODE_NONE);
    
    if (@$sessionsToCopy == 0) {
        print "No files to copy.\n";
        return 1;
    }
    
    copyFiles($sessionsToCopy, $inDir, $outDir, $copyMode);
    
    return 0;
}


#--------------------------------------------------------
sub getSessionData {
    my ($dir, $subjects) = @_;
    
    my @filenames = glob("$dir/session_*.xml");
    
    my @sessions;
    
    foreach my $fn (@filenames) {
        my $bn = basename $fn;
        next unless ($fn =~ m/_session(\d+)\.xml$/);
        my $sessID = $1;
        
        open (IN, "<$fn") || die "ERROR: can't open $fn";
        my @lines = <IN>;
        @lines = grep { chomp } @lines;
        close IN;
        
        my @sessionLine = grep { m/\<session / } @lines;
        die "ERROR in $bn: can't identify a single 'session' element!" unless (@sessionLine == 1);
        die "ERROR in $bn: session.\@subject-id not found!" unless ($sessionLine[0] =~ m/ subject-id=\"(\d+)\"/);
        my $subjID = $1;
        
        my @expLine = grep { m/\<experiment / } @lines;
        die "ERROR in $bn: can't identify a single 'experiment' element!" unless (@expLine == 1);
        die "ERROR in $bn: experiment.\@type not found!" unless ($expLine[0] =~ m/ type=\"([^\"]+)\"/);
        my $expType = $1;
        die "ERROR in $bn: experiment.\@id not found!" unless ($expLine[0] =~ m/ id=\"([^\"]+)\"/);
        my $expID = $1;
        
        my $subjName;
        my @startSubjLineNum = grep { $lines[$_] =~ m/<subject/ } 0 .. (@lines-1);
        if (@startSubjLineNum > 0) {
            my $searchFrom = $startSubjLineNum[0]+1;
            my @endSubjLineNum = grep { $lines[$_] =~ m/<\/subject>/ } $startSubjLineNum[0]+1 .. (@lines-1);
            die "ERROR in $bn: found beginning of <subject> block in line $searchFrom, but can't find its end!" if (@startSubjLineNum == 0);
            my @nameLineNum = grep { $lines[$_] =~ m/<name>.*<\/name>/ } $startSubjLineNum[0]+1 .. $endSubjLineNum[0]-1;
            die "ERROR in $bn: can't find <name> in <subject> block!" if (@startSubjLineNum == 0);
            die "Huh?" unless $lines[$nameLineNum[0]] =~ m/<name>(.*)<\/name>/;
            $subjName = $1;
        } else {
            $subjName = $subjects->{$subjID};
        }
        
        my @timeLines = grep { m/\<start-time/ } @lines;
        my $sessionTime = (@timeLines > 1 && $timeLines[0] =~ m/<start-time>(.*)<\/start-time>/) ? $1 : "";
        
        
        push @sessions, {
            FILENAME => $fn,
            BASENAME => $bn,
            SESSION_ID => $sessID,
            SUBJECT_ID => $subjID,
            SUBJECT_NAME => $subjName,
            EXP_TYPE => $expType,
            EXP_ID => $expID,
            TIME => $sessionTime
        };
    }
    
    return \@sessions;
}

#--------------------------------------------------------
sub filterSessions {
    my ($sessions, $mustUseFilter) = @_;
    
    my @resultSessions = @$sessions;
    
    my $usedFilter = 0;
    
    if (defined $sessionIDFilter) {
        print "Filter session ID = '$sessionIDFilter'\n";
        @resultSessions = grep { $_->{SESSION_ID} eq $sessionIDFilter } @resultSessions;
        $usedFilter = 1;
    }
    
    if (defined $sessionIDREFilter) {
        print "Filter session ID =~ /$sessionIDREFilter/\n";
        @resultSessions = grep { $_->{SESSION_ID} =~ m/$sessionIDREFilter/ } @resultSessions;
        $usedFilter = 1;
    }
    
    if (defined $subjectIDFilter) {
        print "Filter subject ID = '$subjectIDFilter'\n";
        @resultSessions = grep { $_->{SUBJECT_ID} eq $subjectIDFilter } @resultSessions;
        $usedFilter = 1;
    }
    
    if (defined $subjectNameFilter) {
        print "Filter subject name = '$subjectNameFilter'\n";
        @resultSessions = grep { $_->{SUBJECT_NAME} eq $subjectNameFilter } @resultSessions;
        $usedFilter = 1;
    }
    
    if (defined $subjectNameREFilter) {
        print "Filter subject name =~ m/$subjectNameREFilter/\n";
        @resultSessions = grep { $_->{SUBJECT_NAME} =~ m/$subjectNameREFilter/ } @resultSessions;
        $usedFilter = 1;
    }
    
    if (defined $expTypeFilter) {
        print "Filter experiment type = '$expTypeFilter'\n";
        @resultSessions = grep { $_->{EXP_TYPE} eq $expTypeFilter } @resultSessions;
        $usedFilter = 1;
    }
    
    if (defined $expIDREFilter) {
        print "Filter experiment ID =~ /$expIDREFilter/\n";
        @resultSessions = grep { $_->{EXP_ID} =~ m/$expIDREFilter/ } @resultSessions;
        $usedFilter = 1;
    }
    
    if (defined $expIDFilter) {
        print "Filter experiment ID = '$expIDFilter'\n";
        @resultSessions = grep { $_->{EXP_ID} eq $expIDFilter } @resultSessions;
        $usedFilter = 1;
    }
    
    if ($mustUseFilter && !$usedFilter && !$noFilter) {
        die "ERROR: you must specify at least one filter!";
    } elsif ($usedFilter && $noFilter) {
        die "ERROR: you can't specify -all with a filter!";
    }
    
    return \@resultSessions;
}

#--------------------------------------------------------
sub copyFiles {
    my ($sessionsToCopy, $inDir, $outDir, $copyMode) = @_;
    
    foreach my $session (@$sessionsToCopy) {
        my $notYet = $copyMode ? "" : " (not yet)";
        my $s = sessionToString($session);
        my $copy = ($copyMode == $COPY_MODE_MOVE) ? "Move" : "Copy";
        print "$copy$notYet: $s\n";
        if ($copyMode) {
            copyFile($inDir, $outDir, $session, $copyMode);
        }
    }
}

#--------------------------------------------------------
sub copyFile {
    my ($srcDir, $destDir, $session, $copyMode) = @_;
    
    my $copyCmd;
    if ($copyMode == $COPY_MODE_MOVE) {
        $copyCmd = 'mv';
    } elsif ($copyMode == $COPY_MODE_COPY) {
        $copyCmd = 'cp';
    } else {
        die "Unknown copy mode $copyMode";
    }

    my $copied = 0;
    
    my $fn = "$srcDir/*$session->{SESSION_ID}.csv";
    my @files = glob($fn);
    if (@files > 0) {
        system("$copyCmd $fn $destDir/");
        $copied = 1;
    }

    $fn = "$srcDir/*$session->{SESSION_ID}_#*.csv";
    @files = glob($fn);
    if (@files > 0) {
        system("$copyCmd $fn $destDir/");
        $copied = 1;
    }
    
    die "ERROR: found no files matching $fn" unless ($copied);
    
    system("$copyCmd $srcDir/$session->{BASENAME} $destDir/");
}

#--------------------------------------------------------
sub sessionToString {
    my ($session) = @_;
    
    my $t = $session->{TIME} eq '' ? '' : ",$session->{TIME}";
    return "session=$session->{SESSION_ID},subject=$session->{SUBJECT_ID}($session->{SUBJECT_NAME}),expID=$session->{EXP_ID},expType=$session->{EXP_TYPE}$t";
}


#--------------------------------------------------------
# Return: hash with subject info.
# hash key: subject ID
# hash value: a hash with subject details
sub readSubjectFile {
    my $filename = "$basePath/$SUBJECTS_FILE";
    
    return {} unless (-f $filename);
    
    my $csv = Text::CSV->new ()  || die "Cannot use CSV: " . Text::CSV->error_diag ();
    
    open(IN, "<$filename") || die "Error - can't open subjects file $filename for read!";
    
    my %subjects;
    
    # read header line
    $csv->getline(*IN);
    
    while (my $row = $csv->getline(*IN)) {
        my $subjectID = $row->[0];
        my $name = $row->[2];
        $subjects{$subjectID} = $name;
    }
    
    close IN;
    
    return \%subjects;
}

#=======================================================================

#--------------------------------------------------------
sub print_usage(;$) {
	my ($full) = @_;
	
	SCM::Argv::prt_usage(DEFS => \@PROG_ARGS, FULL => $full, 
                         PURPOSE => "Copy experiment raw files");
	                     
	exit(1) unless($full);
	
	# more detailed help
	
	exit(1);
}

#--------------------------------------------------------
#-- Parse command-line arguments and open log file
sub parse_argv() {

	print_usage() if (@ARGV == 0);
	
	SCM::Argv::parse(DEFS => \@PROG_ARGS, ARGV => \@ARGV);
	SCM::Log::open($logFile);
    
    die "ERROR: you can't specify both -cp and -mv!" if ($doCopy && $doMove);
    $copyMode = $COPY_MODE_MOVE if ($doMove);
    $copyMode = $COPY_MODE_COPY if ($doCopy);
    
    die "ERROR: When copying/moving, you must specify destination directory!" if ($copyMode && !defined($outDir));
}

#=========================================================================================

my $rc = main();
SCM::Log::close();

exit($rc);
