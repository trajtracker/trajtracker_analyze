#!/usr/bin/perl
#=======================================================================
#       Rename a subject ID             
#=======================================================================

use strict;
use SCM::FixEnv;
use SCM::Argv;
use SCM::Log;
use XML::DOM;
use POSIX;
use Date::Parse;
use Text::CSV;
use File::Find;

my $WINDOWS = 0;

my $inXmlFN;
my ($inDir, $currID, $subjName);
my $newID;

my $logFile = "$main::TEMP/$main::PROG"; $logFile =~ s/\.pl$/.log/;


my $basePath = $ENV{IPAD_DATA_BASE_PATH};
my $SUBJECTS_FILE = "subjects.csv";

#=======================================================================

my @PROG_ARGS = (
    { FLAG => '-fn', TYPE => 'file', UNAME => '<filename>', VAR => \$inXmlFN, OPTIONAL => 1,
        FULL_TEXT => "Existing session info filename." },
    { FLAG => '-newid', TYPE => 'scalar', UNAME => '<subject-id>', VAR => \$newID, OPTIONAL => 0,
        FULL_TEXT => "New subject ID" },
    { FLAG => '-dir', TYPE => 'dir', UNAME => '<in-dir>', VAR => \$inDir, OPTIONAL => 1,
        FULL_TEXT => "Directory to scan." },
    { FLAG => '-subjid', TYPE => 'scalar_fmt', UNAME => '<existing-subj-id>', VAR => \$currID, OPTIONAL => 1,
        FORMAT => '^\d+$', FULL_TEXT => "Existing subject ID" },
    { FLAG => '-subjname', TYPE => 'scalar', UNAME => '<subject-name>', VAR => \$subjName, OPTIONAL => 1,
        FULL_TEXT => "Subject name" },
    { FLAG => '-l', TYPE => 'scalar', UNAME => '<log-file>', VAR => \$logFile, OPTIONAL => 1,
        FULL_TEXT => "Log file name (default: $logFile)." },
    { FLAG => '-h', TYPE => sub { print_usage(1); }, HELP => 1, VAR => '', OPTIONAL => 1 }
);


#========================================================================================================

sub main {
	
	parse_argv();
    
    if (defined $inXmlFN) {
        
        processOneSession($inXmlFN);
        
    } else {
        
        processFiles($inDir, $currID, $subjName);
    }
    
    
    return 0;
}

#--------------------------------------------------------
sub processFiles {
    my ($baseDir) = @_;
    
    find(\&checkAndProcessFile, ($baseDir));
    
    return ();
}

sub checkAndProcessFile {
    my $bn = $_;
    my $currDir = $File::Find::dir;
    my $fn = $File::Find::name;
    
    # Validate file and directory name
    return unless ($bn =~ m/^session_.*\.xml$/);
    return unless ($currDir =~ m/raw$/);
    
    # Check file contents
    open (IN, "<$bn") || die "ERROR: can't open $fn";
    my @lines = <IN>;
    close IN;
    
    return unless $currID eq getSubjectIDFromLines(\@lines);
    return unless $subjName eq getSubjectNameFromLines(\@lines);
    
    # Good! This is a match!
    print "\nProcessing $fn...\n";
    processOneSession($bn);
}

#--------------------------------------------------------
sub getSubjectIDFromLines {
    my ($lines) = @_;
    
    my @fnLine = grep { m/<subject id="(\d+)"/ } @$lines;
    die "ERROR: can't find subject ID!" if (@fnLine != 1);
    
    $fnLine[0] =~ m/<subject id="(\d+)"/;
    
    return $1;
}

#--------------------------------------------------------
sub getSubjectNameFromLines {
    my ($lines) = @_;
    
    my @fnLine = grep { m/^\s*<name>(.*)<\/name>\s*$/ } @$lines;
    die "ERROR: can't find subject name!" if (@fnLine != 1);
    
    $fnLine[0] =~ m/^\s*<name>(.*)<\/name>\s*$/;
    
    return $1;
}



#--------------------------------------------------------
sub processOneSession {
    my ($sessionInfoFN) = @_;

    my ($dirName, $trialsFN, $trajFN) = fixSessionFile($sessionInfoFN);
    
    renameFile($dirName, $trajFN, newCsvFilename($trajFN, $newID));
    copyTrialsFile($dirName, $trialsFN, newCsvFilename($trialsFN, $newID), $newID);
    
    my $si = basename $sessionInfoFN;
    renameFile($dirName, $si, "BU_$si");
    renameFile($dirName, $trialsFN, "BU_$trialsFN");
}

#--------------------------------------------------------
sub fixSessionFile {
    my ($fn) = @_;
    
    my $bn = basename $fn;
    my $dirName = dirname $fn;
    die "Invalid session filename ($bn)!" unless ($bn =~ m/^session_.*subj(.*)_.*\.xml$/);
    my $oldID = $1;
    
    open (IN, "<$fn") || die "ERROR: can't open $fn";
    my @lines = <IN>;
    @lines = grep { chomp } @lines;
    close IN;
    
    my $trialsFN = getFilename(\@lines, "trials");
    my $trajFN = getFilename(\@lines, "trajectory");
    
    changeString(\@lines, "id=\"$oldID\"", "id=\"$newID\"", 2);
    changeString(\@lines, "_subj${oldID}_session", "_subj${newID}_session", 2);
    
    my $newFN = $bn;
    $newFN =~ s/_subj${oldID}_session/_subj${newID}_session/;
    
    print "Renaming (and modifying) $bn ==> $newFN\n";
    open (OUT, ">$dirName/$newFN") || die "ERROR: can't open $dirName/$newFN";
    print OUT map { "$_\n" } @lines;
    close OUT;
    
    return ($dirName, $trialsFN, $trajFN);
}

#--------------------------------------------------------
sub changeString {
    my ($lines, $from, $to, $nLinesExpected) = @_;
    
    my $n = grep { m/$from/ } @$lines;
    die "ERROR - expected $nLinesExpected with the pattern [$from], but found $n lines!" if ($n != $nLinesExpected);
    
    foreach my $i (0 .. @$lines-1) {
        next unless ($lines->[$i] =~ m/$from/);
        $lines->[$i] =~ s/$from/$to/;
    }
}


#--------------------------------------------------------
sub getFilename {
    my ($lines, $fileType) = @_;
    
    my @fnLine = grep { m/<file type="$fileType"\s+name=".*"/ } @$lines;
    die "ERROR: can't find definition of $fileType file!" if (@fnLine != 1);
    
    $fnLine[0] =~ m/<file type="$fileType"\s+name="(.*)"/;
    
    return basename $1;
}

#--------------------------------------------------------
sub renameFile {
    my ($dirName, $from, $to) = @_;
    print "Renaming $from ==> $to\n";
    system("mv $dirName/$from $dirName/$to");
}

#--------------------------------------------------------
sub copyTrialsFile {
    my ($dirName, $from, $to, $newID) = @_;
    
    print "Changing trials file: $from ==> $to\n";
    
    open (IN, "<$dirName/$from") || die "ERROR: can't open $from";
    my @lines = <IN>;
    close IN;
    
    open (OUT, ">$dirName/$to") || die "ERROR: can't open $to";
    my $headerLine = shift @lines;
    print OUT $headerLine;
    foreach my $line (@lines) {
        $line =~ s/^(\d+),/$newID,/;
        print OUT "$line";
    }
    close OUT;
}

#--------------------------------------------------------
sub newCsvFilename {
    my ($fn, $newID) = @_;
    
    die "Invalid file name ($fn)!" unless $fn =~ m/_subj(\d+)_session/;
    $fn =~ s/_subj(\d+)_session/_subj${newID}_session/;
    
    return $fn;
}

#=======================================================================

#--------------------------------------------------------
sub print_usage(;$) {
	my ($full) = @_;
	
	SCM::Argv::prt_usage(DEFS => \@PROG_ARGS, FULL => $full, 
                         PURPOSE => "Rename a subject ID");
    
    print "You must specify either -fn or a combination of -dir, -subjid, and -subjname\n";
	                     
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
    
    if (defined $inXmlFN) {
        # ok
    } elsif (defined($inDir) && defined($currID) && defined($subjName)) {
        # ok
    } else {
        die "Invalid arguments: You must specify either -fn or a combination of -dir, -subjid, and -subjname";
    }
}

#=========================================================================================

my $rc = main();
SCM::Log::close();

exit($rc);
