#!/usr/bin/perl -w

use strict;
use SCM::FixEnv;
use SCM::Argv;
use SCM::Log;

my $logFile = "$main::TEMP/$main::PROG"; $logFile =~ s/\.pl$/.log/;

my ($inFN, $outFN);
my $divideBy = 1;
my @cn = map { "cond$_" } (1..10);
my $condNames = \@cn;

my @PROG_ARGS = (
    { FLAG => '-i', TYPE => 'file', UNAME => '<src-file>', VAR => \$inFN, OPTIONAL => 0,
        FULL_TEXT => "Source file (CSV)." },
    { FLAG => '-o', TYPE => 'scalar', UNAME => '<dest-file>', VAR => \$outFN, OPTIONAL => 0,
        FULL_TEXT => "Destination file (matlab)." },
    { FLAG => '-div', TYPE => 'scalar_fmt', UNAME => '<divide-by>', VAR => \$divideBy, OPTIONAL => 1,
        FORMAT => '^\d+$', FULL_TEXT => "Factor to divide times by (default=100)" },
    { FLAG => '-cn', TYPE => 'carray_fmt', UNAME => '<cond-names>', VAR => \$condNames, OPTIONAL => 1,
        FORMAT => '.*', FULL_TEXT => "Matlab var names of each condition" },
    { FLAG => '-l', TYPE => 'scalar', UNAME => '<log-file>', VAR => \$logFile, OPTIONAL => 1,
        FULL_TEXT => "Log file name (default: $logFile)." },
    { FLAG => '-h', TYPE => sub { print_usage(1); }, HELP => 1, VAR => '', OPTIONAL => 1 }
);


sub main {
	
	parse_argv();

	open(IN, "<$inFN") || die;
	open(OUT, ">$outFN") || die;
	
	my %cols;
	my $inLine = <IN>;
	chomp $inLine;
	my @line = split/,/, $inLine;
	my $i=0;
	map { $cols{lc $_} = $i++; } @line;
	
	map { die "Column '$_' missing in file!" unless (defined $cols{$_}); } qw(condition subject trialnum onset peak override wrongdir changeofmind);
	
	while ($inLine = <IN>) {
		chomp $inLine;
		@line = split/,/, $inLine;
		
		if ($line[$cols{onset}] =~ m/onset/i) {
			$line[$cols{onset}] = "[]";
		} else {
			$line[$cols{onset}] /= $divideBy;
		}
		
		if ($line[$cols{peak}] =~ m/peak/i) {
			$line[$cols{peak}] = "[]";
		} else {
			$line[$cols{peak}] /= $divideBy;
		}
		
		$line[$cols{condition}] = $1-1 if ($line[$cols{condition}] =~ m/^cond(\d+)$/);
		my $cond = $condNames->[$line[$cols{condition}]];
		
		print OUT "setOnsetVelocityTime($cond.d, '$line[$cols{subject}]', $line[$cols{trialnum}], $line[$cols{onset}], $line[$cols{peak}], $line[$cols{wrongdir}], $line[$cols{changeofmind}], $line[$cols{override}]);\n";
	}
	
	close(IN);
	close(OUT);
	
	print "Done.\n";
}


#=======================================================================

#--------------------------------------------------------
sub print_usage(;$) {
	my ($full) = @_;
	
	SCM::Argv::prt_usage(DEFS => \@PROG_ARGS, FULL => $full, 
                         PURPOSE => "Convert onset/peak times to matlab code");
	                     
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
}

#=========================================================================================

my $rc = main();
SCM::Log::close();

exit($rc);
