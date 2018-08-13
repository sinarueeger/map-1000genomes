## -----------------------------------
## map reference panels on world map
## -----------------------------------

## how to make such a map
## ------------------------
## parts of this code is from here:
## https://github.com/rladies/Map-RLadies-Growing

## data
## --------
library(tidyverse)
library(readxl)

## download file first
url <- "ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/working/20130606_sample_info/20130606_sample_info.xlsx"
download.file(url, "20130606_sample_info.xlsx", mode="wb")

## import file
df <- read_excel("20130606_sample_info.xlsx", sheet="Sample Info")
#  >> Sample Info
## count number of samples by population
## call population POP
n.pop <- df %>% group_by(Population) %>% summarise(n = n()) %>% rename(POP = Population)

## add super populations
## copied from here: 
url.spop <- "http://www.internationalgenome.org/faq/which-populations-are-part-your-study/"
## added location manually (!)
## call super population SPOP
n.spop <- read_csv("sample_info_superpop.csv") %>% rename(POP = `Population Code`, SPOP = `Super Population Code`)

## join the two sample information
n.1kg <- left_join(n.pop, n.spop, by = c("POP" = "POP"))


## add coordinates
## --------
## where the individuals live, not where they are from!
library(ggmap)
# repeat this until there are no warnings() about QUERY LIMITS
#n.1kg <- n.1kg %>% mutate_geocode(.$location)
n.1kg <- n.1kg %>% mutate(purrr::map(.$location, geocode)) %>% unnest()

## running into the inevitable QUERY LIMITS problems, lets use the approach from https://github.com/rladies/Map-RLadies-Growing
n.1kg.withloc <- n.1kg %>% 
  filter(!is.na(lon))

while(nrow(n.1kg.withloc) != nrow(n.1kg))
{
  #   repeat this until there are no warnings() about QUERY LIMITS
  temp <- n.1kg %>% 
    select(-lon, -lat) %>% 
  anti_join(n.1kg.withloc %>% select(-lon, -lat)) %>% 
  mutate(longlat = purrr::map(.$location, geocode)) %>% 
  unnest() %>% 
  filter(!is.na(lon))

  n.1kg.withloc <- n.1kg.withloc %>% 
    bind_rows(temp) %>% 
  distinct()
}

n.1kg <- n.1kg.withloc

## map onto a world map
## ---------------------
library(ggplot2)
theme_set(theme_void()) ## removes all axes and default labels
library(maps) ## for googlemaps

## this gives us the world map
world <- ggplot() +
  borders("world", colour = "gray85", fill = "gray80")

## now we add the points
## and we jitter the points, cause some are at the same location (e.g. ITU, STU in United Kingdom)
world +
  geom_jitter(aes(x = lon, y = lat,
                  color = SPOP),   ## size = n, size is the ares
             data = n.1kg, alpha = .5, size = 2) +
  scale_size_area() +
  #labs(size = '#n (Area of point)') +
  labs(title = "1000 Genomes reference panel populations", caption = glue::glue("Source: {url} \n {url.spop} (manual tidying)"))

