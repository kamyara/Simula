#!/usr/bin/perl
# Needed packages
# use strict "vars";
use Getopt::Std;
use DBI;

# command line options
my $opt_string = "hf:";
getopts( "$opt_string", \my %opt ) or usage() and exit(1);

if ( $opt{'h'} ) {
            usage();
            exit 0;
    }


#####################################################
# Main part
my $FILE= $opt{'f'};
# Connecting to Database
system("clear");
print "Connecting to Database... ";
$dbh = DBI->connect('dbi:mysql:Simula','root','metropolis')
     or die "Connection Error: $DBI::errstr\n";
print "Database connection OK. \n";

# my $date = `date + %Y%m%d`;
# my $date = (date "+%m_%d_%H:%M");
# chomp($date);
# print $date;
# my $MTR_file="MTR_" . $date . ".txt";
# open(MTR, '>MTR.txt');
# open(TRACERT, '>>TRACERT.txt');

my $sth=$dbh->prepare("select category,cc1,country1,url,dns1 from Alexa where dns1!=0"); # and cc1=''"); 
$sth->execute();
while (my @row=$sth->fetchrow_array)
  {
      my $timestamp = qx("date");
      my $properties = $timestamp . "Region: " . $row[0] . ", Server Location: (" . $row[1] . ") "  . $row[2] . ", " . "URL: " . trim($row[3]) . "\n";
      # print MTR $properties;
      print $properties;
      # system("mtr -c 5 -r -4 $row[4]");
      system("wget -4 -a wget-gzip.txt -t 1 $row[3]");
      system("rm index.html");
      system("traceroute -A $row[3]");
      print "\n";
      print "#####################################################################\n";
  }
$sth->finish;
# close(MTR);
# close(TRACERT);
exit 0;
#####################################################

# subroutines

sub usage {
        print "Usage:\n";
        print "-h for help\n";
        print "-f <filename> File to write output result of traceroute and MTR \n";
    }

sub trim($)
  {
      my $string = shift;
      $string =~ s/^\s+//;
      $string =~ s/\s+$//;
      return $string;
      }