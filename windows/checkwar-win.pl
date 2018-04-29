#! /usr/bin/perl
# Worked all redditors progress check utility by VK3DAN
# Thanks to molo1134 for borrowed code snippets
# and arodland N2EON for code style and cleanup help
#
# version 0.4

use strict;
use warnings;

my $count = 0;
my $qslcount = 0;
my $uniquecalls = 0;
my $nickfile = "./nicks.csv";
my $nicksurl = "https://raw.githubusercontent.com/molo1134/qrmbot/master/lib/nicks.csv";
my $exceptsurl = "https://raw.githubusercontent.com/vk3dan/checkWAR/master/overrides.csv";
my $overridesfile = "./overrides.csv";
my $uniques = "";
our $displaycall = "";
our $irc = "";
our $userid = "";

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
        print "\nredditor list may be outdated - would you like to fetch a fresh copy? (y/n)\n";
        my $freshy = <STDIN>;
        if ($freshy == "y") 
        {
            system("powershell -command \"start-bitstransfer -source $nicksurl -destination .\\nicks.csv\"");
        }
    }
    print "redditor list found -- ";
} else {
    print "redditor list not found: fetching\n"; # no nicks.csv file so download a copy
            system("powershell -command \"start-bitstransfer -source $nicksurl -destination .\\nicks.csv\"");
}
if (-e $overridesfile ) # check for exception file existance and if it is more than 4 weeks old prompt to download new copy
{
    if (-M "$overridesfile" >= 28)
    {
        print "\nException file may be outdated - would you like to fetch a fresh copy? (y/n)\n";
        my $freshy = <STDIN>;
        if ($freshy == "y")
        {
            system("powershell -command \"start-bitstransfer -source $exceptsurl -destination .\\overrides.csv\"");
        }
    }
    print "exception list found\n";
} else {
    print "exception list not found: fetching\n"; # no exceptions.csv file so download a copy
            system("powershell -command \"start-bitstransfer -source $exceptsurl -destination .\\overrides.csv\"");
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
        overridecheck();
    }
}

close($adif);
print "\nTotals:\n  $count QSOs with known redditor amateurs\n  $qslcount QSOs confirmed by either eQSL, LotW or Paper Card\n* $uniquecalls Unique redditor calls worked AND confirmed\n\n";

sub overridecheck
{
    $/ = "\n";
    if (-e $overridesfile)
    {
        open (my $overrides, "<", $overridesfile); #read overrides for calls that can't work in main nicks file
        while (<$overrides>)
        {
            chomp;
            my ($override1, $override2, $overridedatestart, $overridedateend) = split /,/;
            if ($overridedatestart eq "" and $overridedateend eq "")
            {
                $overridedatestart = $date;
                $overridedateend = $date;
            }
            if ( lc $call eq lc $override1 and $date >= $overridedatestart and $date <= $overridedateend )
            {
                $displaycall = $call;
                $call = $override2;
                csvstuff();
            } else {
                csvstuff();
            }
        }
    }
}

sub csvstuff
{
   if (-e $nickfile) 
   {
       $/ = "\n";
       open (my $nicks, "<", $nickfile); # read nicks.csv into memory
       nickloop:{ while (<$nicks>)
       {
           our ($csvcall, $irc, $userid) = split /,/; # each line has callsign, irc username and reddit u/name
           $userid =~ s/\R//g;
           if (lc $call eq lc $csvcall)
           {
               if ($displaycall eq "")
               {
                   $displaycall = $call;
               }
               displaystuff();
               last nickloop;
           } 
       }}
       if ($displaycall ne "")
       {
           $userid = "";
           $irc = "";
           displaystuff();
       }
       $/ = "<EOR>";
    
       close($nicks);
    }
}

sub displaystuff
{
    $count++;
    if ( $eqsl eq "Y" or $lotw eq "Y" or $card eq "Y") # perform actions only on confirmed contacts
    {
        $qslcount++;
        if ( index(lc $uniques, lc " $displaycall ") == -1) # perform actions only on unique confirmed contacts
        {
            $uniques = lc "${uniques} ${displaycall}";
            $uniquecalls++;
            $displaycall = "$displaycall *";
        }
    }
    if ( $eqsl eq "Y" ) { $eqsl = "Yes" }; # Change for display
    if ( $lotw eq "Y" ) { $lotw = "Yes" };
    if ( $card eq "Y" ) { $card = "Yes" };
    printf("%-5s%-10s%-25s%-18s%-8s%-8s%-10s%-5s%-5s%-5s\n",$count,$displaycall,$userid,$irc,$band,$mode,$date,$eqsl,$lotw,$card);
    $eqsl = "";
    $lotw = "";
    $card = "";
    $call = "";
    $displaycall = "";
    $userid = "";
    $irc = "";
}