#!/usr/bin/perl
# Needed packages
# use strict "vars";
use Getopt::Std;
use Term::ANSIColor;
use DBI;

# command line options
my $opt_string = "hf:";
getopts( "$opt_string", \my %opt ) or usage() and exit(1);


if (not $opt{'f'}) {
    print "Please provide a filename! \n";
    usage();
    exit 0;
}
  
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

# Opening the File contains the Sites from Alexa
open(LOG, "$FILE") or die "Error opening $FILE $!\n";
while ( my $line = <LOG> ) {
    # print color 'green';
    print $line;
    # print color 'reset';
    findIP($line);
}
close(LOG);

exit 0;
#####################################################
# subroutines

sub usage {
    print "Usage:\n";
    print "-h for help\n";
    print "-f <filename> File containing the site addresses from Alexa to process \n";
}



sub findIP {
    my $IP;
    my $counter=0;
    our $counter2=0;
    my $entry;

    my $SERVER_IP1 = 0;
    my $SERVER_IP2 = 0;
    my $SERVER_IP3 = 0;
    my $SERVER_IP4 = 0;
    my $SERVER_IP5 = 0;

   our $country_code1 = "";
   our $country_code2 = "";
   our $country_code3 = "";    
   our $country_code4 = "";
   our $country_code5 = "";
    
    
   our $country_name1 = "";
   our $country_name2 = "";
   our $country_name3 = "";
   our $country_name4 = "";
   our $country_name5 = "";    
    
    
    open(NSLOOKUP, "nslookup $_[0] | ") or die "Error doing NSLOOKUP $!\n";
    while (my $targetline = <NSLOOKUP> and $counter < 6) {
	if ($targetline =~/Address: (.*)(.*)(.*)(.*)$/) {
	    $counter+=1;
	    if ($counter == 1){ $SERVER_IP1 =  "$1$2$3$4" }
	    if ($counter == 2){ $SERVER_IP2 =  "$1$2$3$4" }
	    if ($counter == 3){ $SERVER_IP3 =  "$1$2$3$4" }
	    if ($counter == 4){ $SERVER_IP4 =  "$1$2$3$4" }
	    if ($counter == 5){ $SERVER_IP5 =  "$1$2$3$4" }
	}   
    }
    if ( $counter == 0){
	$entry = "www." . $_[0];
    }
	else {
	  $entry = $_[0];  
    }
    
    open(NSLOOKUP, "nslookup $entry | ") or die "Error doing NSLOOKUP $!\n";
    while (my $targetline = <NSLOOKUP> ) {
	if ($targetline =~/Address: (.*)(.*)(.*)(.*)$/) {
	   if ($counter ==0) {
	       $IP= "$1$2$3$4"; 
	       $SERVER_IP1 =  "$1$2$3$4";
	       $counter2=1;
	       findlocation2($IP);
	   } else { 
	    $IP= "$1$2$3$4";
#	    print "$IP,";
	       $counter2+=1;
	       findlocation2($IP);
	       }
	}
    }
#    print "IP1:" . $SERVER_IP1 . ", IP2:" . $SERVER_IP2 . ", IP3:" . $SERVER_IP3 . ", IP4:" . $SERVER_IP4 . ", IP5:" . $SERVER_IP5 . "\n";

    print "IP1:" . $SERVER_IP1 . ", CC1: " . $country_code1 . " ,Country1: ". $country_name1 . "\n";
    print "IP2:" . $SERVER_IP2 . ", CC2: " . $country_code2 . " ,Country2: ". $country_name2 . "\n";    
    print "IP3:" . $SERVER_IP3 . ", CC3: " . $country_code3 . " ,Country3: ". $country_name3 . "\n";    
    print "IP4:" . $SERVER_IP4 . ", CC4: " . $country_code4 . " ,Country4: ". $country_name4 . "\n";    
    print "IP5:" . $SERVER_IP5 . ", CC5: " . $country_code5 . " ,Country5: ". $country_name5 . "\n";    
   
    print "\n";

    $sql = "insert into Alexa2 (category,url,dns1,cc1,country1,dns2,cc2,country2,dns3,cc3,country3,dns4,cc4,country4,dns5,cc5,country5,updated_date) values ('South-America', '$entry', '$SERVER_IP1', '$country_code1', '$country_name1', '$SERVER_IP2', '$country_code2', '$country_name2', '$SERVER_IP3', '$country_code3', '$country_name3', '$SERVER_IP4', '$country_code4', '$country_name4', '$SERVER_IP5', '$country_code5', '$country_name5', CURDATE() )";
# $sql = "insert into Alexa (url,dns1,cc1,country1) values ('$entry', '$SERVER_IP1', '$country_code1', '$country_name1')";
    $sth = $dbh->prepare($sql);
 $sth->execute
   or die "SQL Error: $DBI::errstr\n";
# while (@row = $sth->fetchrow_array) {
#      print "@row\n";
#      } 
# print "----------------------------------------------------------------------\n";

}


=pod
sub findlocation {
     open(GEO,"wget -q -O - http://www.geoiptool.com/en/?IP=$_[0] | ") or die "Error creating file  $!\n";
        while ( my $targetline = <GEO> ) {
	            if ($targetline =~ /^.*Country<\/strong>: (.*)<br><strong>/) {
			# print "IP GEO-LOCATION is: ";
			# print color 'bold red';
			print $1;
			# print color 'reset';
			print "\n";
          }
    }
 return 0 ;
 }
=cut


sub findlocation2 {
    my $country_code;

    open (GEO, "whois -h whois.cymru.com ' -v $_[0] ' | ") or die "Error creating file  $!\n";
    while ( my $targetline = <GEO> ) {
	# print $targetline;
	if ($targetline =~ /^\d+\s+\|\s+\d+.\d+.\d+.\d+\s+\|\s+\d+.\d+.\d+.\d+\/\d+\s+\|\s+([A-Z]*)/) {
	    $country_code = $1;
	    # print $country_code;

	    if ($country_code eq 'EU')
	    {
		$country_code1= 'EU';
		$country_name1='Europe';
	    }
		    
	    open(COUNTRYCODES,"wget -q -O - http://www.iso.org/iso/country_names_and_code_elements_txt | ") or die "Error creating file  $!\n";
	    while ( my $targetline2 = <COUNTRYCODES> ) {
	    	if ($targetline2 =~/(.*)\;$country_code/) {
#	    	    print " " . $country_code . "=>" . $1 . " ";
#		    print "counter2 is: " . $counter2 . "\n";  
		    if ($counter2 == 1){ $country_code1 =  $country_code; $country_name1 = $1 }
		    if ($counter2 == 2){ $country_code2 =  $country_code; $country_name2 = $1 }
		    if ($counter2 == 3){ $country_code3 =  $country_code; $country_name3 = $1 }
		    if ($counter2 == 4){ $country_code4 =  $country_code; $country_name4 = $1 }
		    if ($counter2 == 5){ $country_code5 =  $country_code; $country_name5 = $1 }		    
		}
		
	    }
	}
    }
}
