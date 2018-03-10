# checkWAR
Perl utility to take an ADIF format logbook and spit out only the contacts with known reddit amateurs.
Written by VK3DAN, with thanks to molo1134 for some code and maintaining the csv file etc,
and thanks to arodland for code style tips and cleanup help.

usage: ./checkwar.pl <adifile.adi>

This utility uses the nicks.csv file from molo1134's qrmbot as the reference for known redditors.
If nicks.csv is not present the utility will download it directly from molo1134's github.
If nicks.csv is more than 28 days old the utility will ask if you wish to download a new version.

Example run:
```
$ ./checkwar.pl log.adi

Utility for checking Worked All Redditors progress from an ADIF logbook
by VK3DAN with thanks to molo1134

log.adi found -- redditor list found

#    Callsign      Reddit username          Band    Mode    Date

1    ZL3CC         /u/zl3cc                 6M      FT8     20171208
2    K1NZ          /u/nickenzi              30M     JT65    20171211
3    K1NZ          /u/nickenzi              30M     FT8     20171127

Total of 3 contacts with known redditor amateurs
```

Further update will be made as needed within my capabilities.
