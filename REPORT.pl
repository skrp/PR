use strict; use warnings;
use Data::Dumper;
###############################################
# REPORT - all in one payroll machine
# output ytd information

my ($item) = @ARGV;
die "ARG1 item" if (!defined $item);

my %annual;
my $pr = 'ytd';
# MASTER #####################################
my @mfield = qw(name ssn x m salary r_hr r_ohr r_d deff r_med r_dent r_loan);

open(my $Mfh, '<', 'MASTER.txt');
# field delimited aggregate data
my @master = readline $Mfh;
close $Mfh; chomp @master; shift @master;

for (@master)
{
  my @data = split / /, $_;
  fill(\@mfield, \@data);
}
# YTD #########################################
my @yfield = qw(name t_gross t_net t_hr t_ohr t_fit t_sit t_ss t_med t_admed t_deff t_med t_dent t_loan);
open(my $Yfh, '<', '2018.txt');
# year totals
my @ytd = readline $Yfh;
close $Yfh; chomp @ytd; shift @ytd;

for (@ytd)
{
  my @data = split / /, $_;
  fill(\@yfield, \@data);
}
###############################################
get($item);
###############################################
sub fill
{
  my ($field, $data) = @_;
  my @field = @{$field}; my @data = @{$data};

  my $max = @field; $max--; my $i = 1;

  while ($i <= $max)
  {
    $annual{$pr}{$data[0]}{$field[$i]} = $data[$i];
    $i++;
  }
}
sub save
{
  my @time = localtime(time);
  my $y = $time[5]+1900; my $m = $time[4]+1;
  my $time = $y.'_'.$m."_$time[3]_$time[2]_$time[1]";
  open(my $Sfh, '>', "$time.txt");
}
sub get
{
  my $v = shift;
  print "$v\n";
  print "$_: $annual{$pr}{$_}{$v}\n" for keys %{$annual{$pr}};
}
