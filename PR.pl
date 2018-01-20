use strict; use warnings;
use Data::Dumper;
###############################################
# PR - all in one payroll machine

# INPUT STRUCT ################################
# payroll_name = filename
# employee hrs ohrs pto lpto loan hsa deff

# PDF OUTPUT ##################################
# payroll-stubbs
# payroll-reports
# tax-quarterlies
# accountant-entries

# INTERNAL STRUCT #############################
# hash-of-hashes
# $obj = employee or array
# %2018{Jan_19}{$obj}{$slot}

# ADD EMPLOYEE ################################
# append the MASTER.txt with all data of new employee

# INPUT #######################################
my @ifield = qw(name hr ohr pto lpto other hsa loan);

my ($file) = @ARGV;
die "ARG1 payroll input file" if (!defined $file);

my $pr = $file; $pr =~ s/\..*//;
my %annual;

open(my $fh, '<', $file) or die "FAIL open $file";
my @input = readline $fh;
close $fh; chomp @input; shift @input;

for (@input)
{
  my @data = split / /, $_;
  fill(\@ifield, \@data);
}
# MASTER #####################################
my @mfield = qw(name ssn x m salary r_hr r_ohr r_d def hel dent);

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
my @yfield = qw(name t_gross t_net t_hr t_ohr t_pto t_other t_fit t_sit t_ss t_med t_admed t_def t_hel t_dent t_hsa t_loan);
open(my $Yfh, '<', '2018.txt');
# year totals
my @ytd = readline $Yfh;
close $Yfh; chomp @ytd; shift @ytd;

for (@ytd)
{
  my @data = split / /, $_;
  fill(\@yfield, \@data);
}
# CALC ########################################
my @cfield = qw(name gross fit sit ss med admed net);

$annual{$pr}{$_}{'gross'} = $annual{$pr}{$_}{'hr'}*$annual{$pr}{$_}{'r_hr'}
+ $annual{$pr}{$_}{'ohr'}*$annual{$pr}{$_}{'r_ohr'}
+ $annual{$pr}{$_}{'pto'}*$annual{$pr}{$_}{'r_hr'}
+ $annual{$pr}{$_}{'other'}
  for (keys %{$annual{$pr}});

calc($annual{$pr}{$_}{'gross'}, $annual{$pr}{$_}{'x'}, $annual{$pr}{$_}{'m'}) for (keys %{$annual{$pr}});

$annual{$pr}{$_}{'ss'} = $annual{$pr}{$_}{'gross'}*.062 for (keys %{$annual{$pr}});
$annual{$pr}{$_}{'med'} = $annual{$pr}{$_}{'gross'}*.012 for (keys %{$annual{$pr}});


 for (keys %{$annual{$pr}})
 {
   $annual{$pr}{$_}{'admed'} = $annual{$pr}{$_}{'gross'}*.009 if ($annual{$pr}{$_}{'t_gross'} > 250_000);
 }

$annual{$pr}{$_}{'net'} = $annual{$pr}{$_}{'gross'}
- $annual{$pr}{$_}{'fit'}
- $annual{$pr}{$_}{'sit'}
- $annual{$pr}{$_}{'ss'}
- $annual{$pr}{$_}{'med'}
- $annual{$pr}{$_}{'admed'}
- $annual{$pr}{$_}{'def'}
- $annual{$pr}{$_}{'r_d'}*$annual{$pr}{$_}{'gross'}
- $annual{$pr}{$_}{'hsa'}
- $annual{$pr}{$_}{'loan'}
- $annual{$pr}{$_}{'dent'}
- $annual{$pr}{$_}{'hel'}
  for (keys %{$annual{$pr}});

###############################################
###############################################
#print Dumper(%annual);
get('gross');
###############################################
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
sub calc
{
  my ($ssalary, $exception, $type) = @_;
  my $f_tax; my $s_tax;
  if ($type eq "0")
  {
       $annual{$pr}{$_}{'fit'} = single_fwh($exception, $ssalary);
       $annual{$pr}{$_}{'sit'} = single_swh($exception, $ssalary);
  }
  elsif ($type eq "1")
  {
       $annual{$pr}{$_}{'fit'} = married_fwh($exception, $ssalary);
       $annual{$pr}{$_}{'sit'} = married_swh($exception, $ssalary);
  }
}
sub single_fwh
{
  my $xcept = shift; $xcept+=2;
  my $ssalary = shift;
  my $Fed_table = "SingleFWH.txt";
  open(my $ffp, '<', $Fed_table) or die "can't open SingleFWH.txt";
  my @Single;
  while (my $line = readline $ffp)
  {
      my @tmp = split ' ', $line;
      foreach my $item (@tmp)
          { $item =~ s/,//; }
      push @Single, [ @tmp ];
  }
  my $i = 0;
  foreach (@Single)
  {
      if (($ssalary > $Single[$i][0]) and ($ssalary < $Single[$i][1]))
          { return $Single[$i][$xcept]; }
      else { $i++; next; }
  }
}
sub single_swh
{
  my $xcept = shift; $xcept+=2; # adjust $xcept for table format
  my $ssalary = shift;
  my $State_table = "SingleSWH.txt";
  open(my $sfp, '<', $State_table) or die "can't open SingleSWH.txt";
  my @State;
  while (my $line = readline $sfp)
  {
      my @tmp = split ' ', $line;
      foreach my $item (@tmp)
          { $item =~ s/,//; }
      push @State, [ @tmp ];
  }
  my $i = 0;
  foreach (@State)
  {
      if (($ssalary > $State[$i][0]) and ($ssalary < $State[$i][1]))
          { return $State[$i][$xcept]; }
      else { $i++; next; }
  }
}
sub married_fwh
{
  my $xcept = shift; $xcept+=2; # adjust $xcept for table format
  my $ssalary = shift;
  my $Fed_table = "MarriedFWH.txt";
  open(my $ffp, '<', $Fed_table) or die "can't open MarriedFWH.txt";
  my @Fed;
  while (my $line = readline $ffp)
  {
      my @tmp = split ' ', $line;
      foreach my $item (@tmp)
          { $item =~ s/,//; }
      push @Fed, [ @tmp ];
  }
  my $i = 0;
  foreach (@Fed)
  {
      if (($ssalary > $Fed[$i][0]) and ($ssalary < $Fed[$i][1]))
          { return $Fed[$i][$xcept]; }
      else { $i++; next; }
  }
}
sub married_swh
{
  my $xcept = shift; $xcept+=2; # adjust $xcept for table format
  my $ssalary = shift;
  my $State_table = "MarriedSWH.txt";
  open(my $mfp, '<', $State_table) or die "can't open MarriedSWH.txt";
  my @State;
  while (my $line = readline $mfp)
  {
      my @tmp = split ' ', $line;
      foreach my $item (@tmp)
          { $item =~ s/,//; }
      push @State, [ @tmp ];
  }
  my $i = 0;
  foreach (@State)
  {
      if (($ssalary > $State[$i][0]) and ($ssalary < $State[$i][1]))
          { return $State[$i][$xcept]; }
      else { $i++; next; }
  }
}
