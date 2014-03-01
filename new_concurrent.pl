#!/usr/bin/perl

use threads;
use threads::shared;
use Getopt::Std;
use Digest::MD5;
$|=1;

my ($global) : shared ;
my $DL_Counter = 0;
our $MainURL;

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

# Opening the File contains the Sites from Alexa
open(LOG, "$FILE") or die "Error opening $FILE $!\n";
while ( my $LOGline = <LOG> ) {
    $MainURL = trim($LOGline);    

# Some of the URLs don't respond without "www" prefix (such as nic.in). So, here I check if it is needed to add www to the URL or not
    if (system("curl -s -4 --connect-timeout 45 -o /dev/null $MainURL") ne 0 ){
	if(system("curl -s -4 --connect-timeout 45 -o /dev/null www.$MainURL") eq 0 ){
	    $MainURL= "www." . $MainURL;
	} else {
	    print "***** ERROR: $MainURL is not accesible! Curl exit code: $? *****\n";
	    print "------------------------------------------------------------------------------------------------\n";	    
	    system("echo ---------------------------------------------------------------------------------------------------------- | gzip -9 >> CurlTimer.txt.gz");
	    system("echo ERROR: $MainURL is not responding! Curl exit code: $? | gzip -9 >> CurlTimer.txt.gz");
	    next;
	}
    }
    
# Calling findIP subroutin(which automatically calls findlocation subroutin as well) to find URL's IP address and the server location    
    findIP($MainURL);


# Defining threads to run MTR and curl in concurrent mode    
    my $thr1 = threads->new(\&CONCURRENT,1,"mtr -c 3 -r -4 -w $entry") ;
    my $thr2 = threads->new(\&CONCURRENT,2, "curl --silent -4 --connect-timeout 45 -o /dev/null $entry") ;

    my $ReturnData = $thr1->join ;
    $thr2->join ;
# Creating Unique ID
    my $Unique_ID = Digest::MD5::md5_base64( rand );

    $DL_Counter=0;
    print "MTR to: $entry , Unique ID: $Unique_ID \n";
    system("echo ---------------------------------------------------------------------------------------------------------- | gzip -9 >> CurlTimer.txt.gz");
    system("echo $entry , Unique ID: $Unique_ID | gzip -9 >> CurlTimer.txt.gz");
    system("echo Counter, TotalTime [NameLookup, TimeConnect, PreTransfer, StartTransfer], DLSize [Header], DLSpeed, Exit Code | gzip -9 >> CurlTimer.txt.gz");
    
# Doing curl download continuesly until the MTR is going on 
    while (stat ("/proc/$ReturnData") ) {
	$DL_Counter+=1;
	my $trimd_Counter = trim($DL_Counter);
	system("curl --silent --write-out '$trimd_Counter, %{time_total} (%{time_namelookup}, %{time_connect}, %{time_pretransfer}, %{time_starttransfer}), %{size_download} (%{size_header}), %{speed_download} , $? \n' -o /dev/null $entry | gzip -9  >> CurlTimer.txt.gz");
    }
    
    print "\nMTR finished for ($entry) (ID: $Unique_ID). Curl download count during MTR trace: $DL_Counter times\n";
    print "URL Region(From File): $FILE \n";
    print "IP: $IP , Server Location: ($country_code) $country_name1 \n" ;
    print "------------------------------------------------------------------------------------------------\n";
 }

close (LOG);

######################
# CONCURRENT RUNNING #
######################

sub CONCURRENT {
    my ( $id ) = @_[0] ;
    my $command = @_[1] ;
    if ($command =~ /mtr/i) {
	system("$command&");
	
	my $USER = qx("whoami");
	chomp $USER;
	open(PSAUX,"ps aux |") or die  "Error creating PSAUX file  $!\n";
	while ( my $targetline = <PSAUX> ) {
	    if ($targetline =~ /^$USER\s+(\d+)\s.*\d:\d\d\s+mtr -c 3 -r -4 -w $entry/) {
		$PID = $1;
		 # print "traceroute process ID is $PID\n";
	    }
	}
		close (PSAUX);
	sleep(1);
    }
    else {system($command);}
    
    # print "command$id is: $command\n";
    return( $PID ) ;
}


######################
# Other Sub routines #
######################

sub usage {
        print "Usage:\n";
        print "-h for help\n";
        print "-f <filename> File containing the site addresses from Alexa to process \n";
}



######################
######################
######################

# This subroutine finds the IP address(es) of the URL, however just the first IP of each URL  will be used in the main part
sub findIP {
    our $IP;
    my $counter=0;
    our $counter2=0;
    our $entry;
    
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
		#           print "$IP,";
		$counter2+=1;
		findlocation2($IP);
	    }
	}
    }
}    
    
    
#############################################
#############################################
#############################################

    
 sub findlocation2 {
     our $country_code;
     
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
	     
	     open(COUNTRYCODES,"wget -q -O - http://www.iso.org/iso/home/standards/country_codes/country_names_and_code_elements_txt-temp.htm | ") or die "Error creating file  $!\n";
	     while ( my $targetline2 = <COUNTRYCODES> ) {
		 if ($targetline2 =~/^(.*)\;$country_code/) {
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


sub trim($)
    {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
    }
