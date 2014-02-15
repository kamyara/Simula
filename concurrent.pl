#!/usr/bin/perl

use threads;
use threads::shared;
use Getopt::Std;
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
    print "$MainURL\n";
    if (system("wget -q -t 2 -4 -O tmp_index.html $MainURL") ne 0){
	if(system("wget -q -t 2 -4 -O tmp_index.html www.$MainURL") eq 0) {
	    $MainURL= "www." . $MainURL;
	}
    }
    
    findIP($MainURL);

    my $thr1 = threads->new(\&CONCURRENT,1,"traceroute $entry") ;
    my $thr2 = threads->new(\&CONCURRENT,2, "wget -a wget.txt -t 3 -4 -O tmp_index.html $entry") ;  

    my $ReturnData = $thr1->join ;
    $thr2->join ;
    
    while (stat ("/proc/$ReturnData") ) {
	# print "trace PID is: $ReturnData\n";
	system("wget -a wget_extra.txt -d -t 3 -4 -O tmp_index.html $entry");
	system("curl -s -w '%{time_total}\n' -o /dev/null $entry >> Timer.txt");
	$DL_Counter+=1;
    }
    
    my $TimerSum=0;
    my $TimerCount=0;
    my $TimeAVG=0;
    if (stat ("Timer.txt")) {
	open (TIMER, "Timer.txt") or die "Error opening Timer.txt file $!\n";
	while ( my $TIMERline = <TIMER> ) {
	    if ($TIMERline =~ /(\d+.\d+)/) {
		$TimerSum+=$1;
		$TimerCount+=1;
	    }
	}
    	$TimeAVG = $TimerSum / $TimerCount;
        close (TIMER);
    }
	system("rm -rf Timer.txt");
    
    my $URL_IP=0;
    my $ServerType="N/A";
    my $DocSize=0;
    my $PoweredBy="N/A";
    
    my $DL_Speed;
    my $Saved_Size;
    my $Wget_DLTime;
    
    if (stat("wget_extra.txt")){
	open (WGET_EXTRA, "wget_extra.txt") or die "Error opening wget_extra.txt $!\n";
	while ( my $WGETline = <WGET_EXTRA> ) {
	    if ($WGETline =~ /Connecting to \w*.+\)\|(\d+.\d+.\d+.\d+)/ ) {
		$URL_IP= $1;
	    }
	    
	    if ( $WGETline =~ /^Server:\s+(.*)/ ){
		$ServerType= $1;
	    }
	    
	    if ( $WGETline =~ /^X-Powered-By:\s+(.*)/ ) {
		$PoweredBy=$1;
	    }
	    
	    if ( $WGETline =~ /^Content-Length:\s+(.*)/ ) {
		$DocSize=$1;
	    }
	    
	    if ( $WGETline =~/^\d+.*(\(\d+.*\))\s+\-\s+.*saved\s+\[(\d+\/*\d+)\]/ ) {
		$DL_Speed = $1;
		$Saved_Size = $2;
	    }
	    
	    if ( $WGETline =~/.*\=(\d+.\d+)/ ){
		$Wget_DLTime = $1;
	    }
	}
	
	close (WGET_EXTRA);
    }
    system("rm -rf wget_extra.txt");
    
    print "\nTraceroute finished for $entry and the URL downloaded $DL_Counter times during the traceoute!\n";
    print "URL Region(From File): $FILE \n";
    print "IP: $URL_IP , Server Location: ($country_code) $country_name1 \n" ;
    print "Average download time for $DL_Counter downloads (By Curl): ";  printf("%.2f", $TimeAVG ); print "\n";
    print "Server Type: $ServerType\n";
    print "Powered-By: $PoweredBy\n";
    print "Content-Length: $DocSize\n";
    print "Download Speed (By Wget): $DL_Speed \n";
    print "Size of the saved document from the URL: $Saved_Size\n";
    print "Download time (by Wget): $Wget_DLTime\n";
    print "------------------------------------------------------------------------------------------------\n";
    system("rm -rf tmp_index.html");  
 }

close (LOG);

######################
# CONCURRENT RUNNING #
######################

sub CONCURRENT {
    my ( $id ) = @_[0] ;
    my $command = @_[1] ;
    if ($command =~ /traceroute/i) {
	system("$command&");
	
	my $USER = qx("whoami");
	chomp $USER;
	open(PSAUX,"ps aux |") or die  "Error creating PSAUX file  $!\n";
	while ( my $targetline = <PSAUX> ) {
	    if ($targetline =~ /^$USER\s+(\d+)\s.*\d:\d\d\s+traceroute $entry/) {
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


sub findIP {
    my $IP;
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
