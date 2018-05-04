#! /usr/bin/perl
# Worked all redditors progress check utility by VK3DAN
# Thanks to molo1134 for borrowed code snippets
# and arodland N2EON for new ADIF parser code which is
# more able to cope with different software's ADIF files,
# code style and cleanup help
#
# version 0.5

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

use constant {
  ST_BOF => 0,
  ST_HEADER => 1,
  ST_HTAG => 2,
  ST_TAG => 3,
  ST_TAGNAME => 4,
  ST_LEN => 5,
  ST_TYPE => 6,
  ST_DATA => 7,
};

our $state = ST_BOF;

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
        print "\nredditor list may be outdated - would you like to fetch a fresh copy? (y/n)";
        my $freshy = <STDIN>;
        if (lc $freshy eq "y\n") 
        {
            system("wget --no-verbose $nicksurl -O $nickfile");
        }
    }
    print "redditor list found -- ";
} else {
    print "redditor list not found: fetching\n"; # no nicks.csv file so download a copy
    system("wget --no-verbose $nicksurl");
}
open (my $nicks, "<", $nickfile); #read overrides for calls that can't work in main nicks file 
my @nickarray = <$nicks>;
if (-e $overridesfile ) # check for exception file existance and if it is more than 4 weeks old prompt to download new copy
{
    if (-M "$overridesfile" >= 28)
    {
        print "\nException file may be outdated - would you like to fetch a fresh copy? (y/n)";
        my $newexc = <STDIN>;
        if (lc $newexc eq "y\n")
        {
            system("wget --no-verbose $exceptsurl -O $overridesfile");
        }
    }
    print "exception list found\n";
} else {
    print "exception list not found: fetching\n"; # no exceptions.csv file so download a copy
    system("wget --no-verbose $exceptsurl");
}
open (my $overrides, "<", $overridesfile); #read overrides for calls that can't work in main nicks file
my @overridearray = <$overrides>;

printf ("\n%-5s%-10s%-25s%-18s%-8s%-8s%-10s%-5s%-5s%-5s\n\n","#","Callsign","Reddit username","#redditnet nick","Band","Mode","Date","eQSL","LotW","Card"); 

my ($call, $mode, $date, $band, $eqsl, $lotw, $card);

while (my $record = read_adif($adif)) {
    $call = $record->{call};
    $mode = $record->{mode};
    $card = $record->{qsl_rcvd};
    if (!defined $card or $card eq "R" or $card eq "N" )
    {
      $card = "";
    }
    $date = $record->{qso_date};
    $band = $record->{band};
    $eqsl = $record->{eqsl_qsl_rcvd};
    if (!defined $eqsl or $eqsl eq "R" or $eqsl eq "N" )
    {
      $eqsl = "";
    }
    $lotw = $record->{lotw_qsl_rcvd};
    if (!defined $lotw or $lotw eq "R" or $lotw eq "N" )
    { 
      $lotw = "";
    }
    overridecheck();
}

close($adif);
print "\nTotals:\n  $count QSOs with known redditor amateurs\n  $qslcount QSOs confirmed by either eQSL, LotW or Paper Card\n* $uniquecalls Unique redditor calls worked AND confirmed\n\n";

sub overridecheck
{
    $/ = "\n";
    if (-e $overridesfile)
    {
        foreach (@overridearray)
        {
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
       nickstuff: { foreach (@nickarray)
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
               last nickstuff;
           } 
       }
       if ($displaycall ne "")
       {
           $userid = "";
           $irc = "";
           displaystuff();
       }}
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

sub read_adif {
  my ($fh) = @_;

  my ($char, $tag, $val, $len) = ("", "", "", "");
  my $ret = {};

  while (read $fh, $char, 1) {
    if ($state == ST_BOF) {
      if ($char eq '<') {
        $state = ST_TAGNAME; # No header on this file
      } else {
        $state = ST_HEADER;
      }
    } elsif ($state == ST_HEADER) {
      if ($char eq '<') {
        $state = ST_HTAG; # Possible beginning of <eor>
      }
    } elsif ($state == ST_HTAG) {
      if ($char eq '>' && $tag eq 'eoh') {
        $tag = "";
        $state = ST_TAG; # Header is over.
      } elsif ($char eq '<' || length($tag) > 3) {
        $tag = "";
        $state = ST_HTAG; # Try again
      } else {
        $tag .= lc $char;
      }
    } elsif ($state == ST_TAG) {
      if ($char eq '<') {
        $state = ST_TAGNAME;
      }
    } elsif ($state == ST_TAGNAME) {
      if ($char eq '>') {
        if ($tag eq 'eor') {
          $tag = "";
          $state = ST_TAG;
          return $ret;
        } else {
          die "Unknown tag <$tag>";
        }
      } elsif ($char eq ':') {
        $state = ST_LEN;
      } else {
        $tag .= lc $char;
      }
    } elsif ($state == ST_LEN) {
      if ($char eq '>') {
        if ($len > 0) {
          $state = ST_DATA;
        } else {
          $ret->{$tag} = "";
          $tag = $val = $len = "";
          $state = ST_TAG;
        }
      } elsif ($char eq ':') {
        $state = ST_TYPE;
      } else {
        $len .= $char;
      }
    } elsif ($state == ST_TYPE) {
      if ($char eq '>') {
        if ($len > 0) {
          $state = ST_DATA;
        } else {
          $ret->{$tag} = "";
          $tag = $val = $len = "";
          $state = ST_TAG;
        }
      }
      # we ignore the type.
    } elsif ($state == ST_DATA) {
      $val .= $char;
      $len--;
      if (!$len) {
        $val =~ s/\s+$//;
        $ret->{$tag} = $val;
        $tag = $val = $len = "";
        $state = ST_TAG;
      }
    }
  }
  return;
}