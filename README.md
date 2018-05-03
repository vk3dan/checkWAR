# checkWAR
Perl utility to take an ADIF format logbook and spit out only the contacts with known reddit amateurs.
Written by VK3DAN, with thanks to molo1134 for some code and maintaining the csv file etc,
and thanks to arodland for the much nicer ADIF parser, code style tips and cleanup help.

usage: ./checkwar.pl <adifile.adi>

This utility uses the nicks.csv file from molo1134's qrmbot as the reference for known redditors.

If nicks.csv is not present the utility will download it directly from molo1134's github.

If overrides.csv is not present the utility will download it directly from my github.

If nicks.csv or overrides.csv is more than 28 days old the utility will ask if you wish to download a new version.

This latest version allows you to see which contacts are confirmed and also how many unique callsigns had been both worked and confirmed as this appears to be the metric which will be used for this award when the details are sorted out.

Example run:
```
$ ./checkwar.pl log.adi

Utility for checking Worked All Redditors progress from an ADIF logbook
by VK3DAN with thanks to molo1134 and arodland

log.adi found -- redditor list found -- exception list found

#    Callsign  Reddit username          #redditnet nick   Band    Mode    Date      eQSL LotW Card

1    KC4AAA *  /u/hanavi                ai4lx             20M     FT8     20171114       Yes  Yes
2    K1NZ *    /u/nickenzi              K1NZ              30M     FT8     20171127       Yes  Yes
3    ZL3CC *   /u/zl3cc                                   6M      FT8     20171208       Yes
4    K1NZ      /u/nickenzi              K1NZ              30M     JT65    20171211       Yes
5    VK2DDS    /u/VK2DDS                vk2dds            40M     FT8     20180311
6    ZL4BEN *  /u/benstwhite            zl4ben            40M     FT8     20180412       Yes
7    DJ5TD *                            DJ5TD             20M     JT65    20180417       Yes
8    ZL4BEN    /u/benstwhite            zl4ben            40M     FT8     20180422       Yes
9    ZL4BEN    /u/benstwhite            zl4ben            30M     FT8     20180423       Yes
10   ZL4BEN    /u/benstwhite            zl4ben            40M     FT8     20180425       Yes
11   ZL4BEN    /u/benstwhite            zl4ben            40M     FT8     20180501       Yes

Totals:
  11 QSOs with known redditor amateurs
  10 QSOs confirmed by either eQSL, LotW or Paper Card
* 5 Unique redditor calls worked AND confirmed

```

Further update will be made as needed within my capabilities. If you can implement anything needed or desired, feel free to submit a PR.
