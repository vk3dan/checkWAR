#! /usr/bin/perl
# Worked all redditors progress check utility by VK3DAN
# Thanks to molo1134 for borrowed code snippets
# and arodland N2EON for code style and cleanup help
#
# version 0.3w

use strict;
use warnings;

my $count = 0;
my $qslcount = 0;
my $uniques = "";
my $uniquecalls = 0;
my $nickfile = "./nicks.csv";
my $nicksurl = "https://raw.githubusercontent.com/molo1134/qrmbot/master/lib/nicks.csv";

print "\nUtility for checking Worked All Redditors progress from an ADIF logbook\nby VK3DAN with thanks to molo1134 and arodland\n\n";

unless (@ARGV)
{
    die "No ADIF file specified or incorrect usage\nusage: checkwar <adifile.adi>\n\n";  #show usage if called without args
}

my $adifFileName = shift @ARGV;

open(my $adif, $adifFileName) or die "$! -- File $adifFileName doesn't exist or unreadable\n\n"; #open file or show error and die
print "$adifFileName found -- ";

if (-e $nickfile ) # check for nickfile existance and if it is more than 4 weeks old prompt to download new copy
{
    if (-M "$nickfile" >= 28) 
    {
        print "Nick file may be outdated - would you like to fetch a fresh copy? (y/n)\n";
        my $freshy = <STDIN>;
        if ($freshy == "y") 
        {
            system("powershell -command \"start-bitstransfer -source $nicksurl -destination .\\nicks.csv\"");
        }
    }
    print "redditor list found\n";
} else {
    print "redditor list not found: fetching\n"; # no nicks.csv file so download a copy
    system("powershell -command \"start-bitstransfer -source $nicksurl -destination .\\nicks.csv\"");
}

printf ("\n%-5s%-10s%-25s%-18s%-8s%-8s%-10s%-5s%-5s%-5s\n\n","#","Callsign","Reddit username","#redditnet nick","Band","Mode","Date","eQSL","LotW","Card"); 

my ($call, $mode, $date, $band, $eqsl, $lotw, $card);

$/ = "<EOR>";

while (my $line = <$adif>)	# process ADIF data in array
{
    if($line =~ /<CALL:\d+>([^<]*)/i) # Get callsign
    {  
        $call=$1;
        $call=~s/\s+$//;
    }
    if($line =~ /<MODE:\d+>([^<]*)/i) # Get mode
    {
        $mode=$1;
        $mode=~s/\s+$//;
    }
    if($line =~ /<QSL_Rcvd:\d+>([^<]*)/i) # Paper QSL card received?
    {
        $card = $1;
        $card =~s/\s+$//;
        if ( $card eq "R" or $card eq "N" )
        {
            $card = "";
        }
    } else {
        $card = "";
    }
    if($line =~ /<QSO_DATE:\d+:\d+>([^<]*)/i) # Get date (Format 1)
    {
        $date=$1;
        $date=~s/\s+$//;
    }
    if($line =~ /<QSO_DATE:\d+>([^<]*)/i) # Get date (Format 2)
    {
        $date=$1;
        $date=~s/\s+$//;
    }
    if($line =~ /<BAND:\d+>([^<]*)/i) # Get band
    {
        $band = $1;
        $band =~s/\s+$//;
    }
    if($line =~ /<EQSL_QSL_RCVD:\d+>([^<]*)/i) # EQSL confirmation received?
    {
        $eqsl = $1;
        $eqsl =~s/\s+$//;
         if ( $eqsl eq "R" or $eqsl eq "N" )
        {
            $eqsl = "";
        }
    } else {
        $eqsl = "";
    }
    if($line =~ /<LOTW_QSL_RCVD:\d+>([^<]*)/i) # LotW confirmation received?
    {
        $lotw = $1;
        $lotw =~s/\s+$//;
        if ( $lotw eq "R" or $lotw eq "N" )
        { 
            $lotw = "";
        }
    } else {
        $lotw = "";
    }
    if($line =~ /<EOR>/i) # End of record, now go check against redditor list.
    { 
        csvstuff();
    }
}

close($adif);
print "\nTotals:\n  $count QSOs with known redditor amateurs\n  $qslcount QSOs confirmed by either eQSL, LotW or Paper Card\n* $uniquecalls Unique redditor calls worked AND confirmed\n\n";

sub csvstuff
{
   if (-e $nickfile) 
   {
       $/ = "\n";
       open (my $nicks, "<", $nickfile); # read nicks.csv into memory
       while (<$nicks>)
       {
           chomp;
           my ($csvcall, $irc, $userid) = split /,/; # each line has callsign, irc username and reddit u/name
           if (lc $call eq lc $csvcall)
           {
               $count++;
               if ( $eqsl eq "Y" or $lotw eq "Y" or $card eq "Y") # perform actions only on confirmed contacts
               {
                   $qslcount++;
                   if ( index(lc $uniques, lc " $call ") == -1) # perform actions only on unique confirmed contacts
                   {
                       $uniques = lc "${uniques} ${call}";
                       $uniquecalls++;
                       $call = "$call *";
                   }
               if ( $eqsl eq "Y" ) { $eqsl = "Yes" }; # Change for display
               if ( $lotw eq "Y" ) { $lotw = "Yes" };
               if ( $card eq "Y" ) { $card = "Yes" };
               }
               printf("%-5s%-10s%-25s%-18s%-8s%-8s%-10s%-5s%-5s%-5s\n",$count,$call,$userid,$irc,$band,$mode,$date,$eqsl,$lotw,$card); # display formatted result for current redditor QSO
               $eqsl = "";
               $lotw = "";
               $card = "";
           }
       }
       $/ = "<EOR>";
       close($nicks);
    }
}