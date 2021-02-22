# Map 1000 Genomes populations

This repository provides the R-Code to map the 26 populations of the 1000 genomes project.

## Goal

Create a map as on the front page of http://www.internationalgenome.org/ in a reproducible manner. 

![Version on internationalgenome.org](1000genomes-map.png)

## Data
- The population counts and labels are from [here](ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/working/20130606_sample_info/20130606_sample_info.xlsx)
- The super population labels are from [here](http://www.internationalgenome.org/faq/which-populations-are-part-your-study/) (pasted into a csv, then location was inferred)

## Result

HTML version [here](https://github.com/sinarueeger/map-1000genomes/blob/master/map-1000genomes-populations.html).

![New version](map-1000genomes-populations.png)

Some deviation, see comment below. 

### Reason for deviation from the original

There are many populations for which the current location is the same as the ancestry, e.g. TSI (Toscani in Italy(. But others, such as ITU (Indian Telugu from the UK) are living in the UK. E.g. CEU is difficult to pin down with a single location in Europe. 
