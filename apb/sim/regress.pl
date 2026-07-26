#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Basename qw(basename);

my $config_file = 'regress.cfg';
my $report_only = 0;
GetOptions('f=s' => \$config_file, 'r' => \$report_only)
  or die "Usage: $0 [-f config] [-r]\n";

sub slurp {
  my ($path) = @_;
  open my $handle, '<', $path or die "Cannot open $path: $!\n";
  local $/;
  my $text = <$handle>;
  close $handle;
  return $text;
}

sub classify_log {
  my ($path, $pass_word, $fail_word) = @_;
  return 'UNKNOWN' unless -f $path;
  my $text = slurp($path);
  return 'FAILED' if index($text, $fail_word) >= 0;
  return 'PASSED' if index($text, $pass_word) >= 0;
  return 'UNKNOWN';
}

sub write_report {
  my ($rows) = @_;
  open my $report, '>', 'regress.rpt'
    or die "Cannot write regress.rpt: $!\n";
  printf {$report} "%-24s %-8s %-8s %s\n", 'TEST', 'SEED', 'STATUS', 'LOG';
  printf {$report} "%s\n", '-' x 80;
  for my $row (@{$rows}) {
    printf {$report} "%-24s %-8s %-8s %s\n", @{$row};
  }
  close $report;
}

my $config = slurp($config_file);
$config =~ s/#.*$//mg;

my ($cov) = $config =~ /^\s*cov\s*=\s*(on|off)\s*$/mi;
my ($pass_word) = $config =~ /^\s*pass_key_word\s*=\s*"([^"]+)"\s*$/mi;
my ($fail_word) = $config =~ /^\s*fail_key_word\s*=\s*"([^"]+)"\s*$/mi;
my ($timeout) = $config =~ /^\s*timeout_seconds\s*=\s*(\d+)\s*$/mi;
die "Invalid regression settings in $config_file\n"
  unless defined $cov && defined $pass_word && defined $fail_word && defined $timeout;

my @rows;

if ($report_only) {
  for my $path (sort glob('log/*.log')) {
    my $file = basename($path);
    next unless $file =~ /^(.*)_(\d+)\.log$/;
    push @rows, [$1, $2, classify_log($path, $pass_word, $fail_word), $path];
  }
} else {
  my ($test_block) = $config =~ /tc_list\s*\{(.*?)\}/s;
  die "Missing tc_list in $config_file\n" unless defined $test_block;

  my @tests;
  while ($test_block =~ /([A-Za-z_][A-Za-z0-9_]*)\s*,\s*run_times\s*=\s*(\d+)\s*,\s*run_opts\s*=\s*([^;]*)\s*;/g) {
    push @tests, [$1, $2, $3];
  }
  die "No tests found in $config_file\n" unless @tests;

  my $cov_value = uc($cov);
  system('make', 'clean') == 0 or die "make clean failed\n";
  system('make', 'build', "COV=$cov_value") == 0 or die "make build failed\n";

  for my $test (@tests) {
    my ($name, $runs, $run_opts) = @{$test};
    $run_opts =~ s/^\s+|\s+$//g;
    for (1 .. $runs) {
      my $seed = int(rand(900_000)) + 100_000;
      my @command = ('timeout', $timeout, 'make', 'run',
                     "TESTNAME=$name", "SEED=$seed", "COV=$cov_value",
                     "RUNARG=$run_opts");
      system(@command);
      my $path = "log/${name}_${seed}.log";
      push @rows, [$name, $seed,
                   classify_log($path, $pass_word, $fail_word), $path];
    }
  }
}

write_report(\@rows);
print slurp('regress.rpt');

my $failed = grep { $_->[2] ne 'PASSED' } @rows;
exit($failed ? 1 : 0);
