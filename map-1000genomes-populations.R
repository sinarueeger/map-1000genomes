## -----------------------------------
## map reference panel locations onto a world map
## -----------------------------------

## why? cause the one on their webpage: http://www.internationalgenome.org/ is not terrific

## how to make such a map
## ------------------------
## parts of this code is from here:
## https://github.com/rladies/Map-RLadies-Growing
## but instead of making a ggplot map, we make a leaflet

## data
## --------
library(tidyverse)
library(readxl)

## download file first
url <- "ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/working/20130606_sample_info/20130606_sample_info.xlsx"
url.bitly <- "http://bit.ly/2MQTr02"
download.file(url, "20130606_sample_info.xlsx", mode="wb")

## import file
df <- read_excel("20130606_sample_info.xlsx", sheet="Sample Info")
#  >> Sample Info
## count number of individuals by population
## rename population > POP
n.pop <- df %>% group_by(Population) %>% summarise(n = n()) %>% rename(POP = Population)

## import super population names and details to location of populations
## copied from here: 
url.spop <- "http://www.internationalgenome.org/faq/which-populations-are-part-your-study/"
## added location manually (!) - found this the only option to prevent overlapping locations. Also, description involves a mix of location and origin.

## rename superpopulation > SPOP
n.spop <- read_csv("sample_info_superpop.csv") %>% rename(POP = `Population Code`, SPOP = `Super Population Code`)

## join the two information
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

## glue POP and `Population Description`
#n.1kg <- n.1kg %>% mutate(pop.desc = paste(sep = "<br/>", POP, `Population Description`))
n.1kg <- n.1kg %>% mutate(pop.desc = paste0(POP, " : ", `Population Description`, " (", SPOP, ")"))

## map onto a world map
## with leaflet
## ---------------------
library(leaflet) 

## define icons
icons <- awesomeIcons(
  icon = 'user', #people',
  iconColor = 'black',
  library = 'fa', #ion
  markerColor = as.character(forcats::fct_recode(as.factor(n.1kg$SPOP), red = "EUR", blue = "AFR", green = "AMR", gray = "EAS", orange = "SAS")) ## ok, thats ugly, but who cares! turns out, hex colors won't work
)

## now it gets even uglier, cause we need to create a vector that maps cols to SPOP from the markerColor argument above
cols <- c("#E50102", "#00A9DD", "#57BA1F", "#575757", "#FD8E00")
SPOP <- c("EUR",  "AFR", "AMR", "EAS", "SAS")

## separate icon that will display the information
icon.info <- awesomeIcons(
  icon = 'info', #people',
  iconColor = 'white',
  library = 'fa', #ion
  markerColor = "white"
)

## make map
m <- leaflet(data = n.1kg) %>%
  addTiles() %>%  # Add default OpenStreetMap map tiles
  addAwesomeMarkers(lat=~lat, lng=~lon, label = ~htmltools::htmlEscape(pop.desc), icon = icons) %>% 
  addAwesomeMarkers(lat=-45, lng=-107, popup = glue::glue("Source: https://github.com/sinarueeger/map-1000genomes/"), icon = icon.info) %>% ## this bit has potential to be displayed as a href. 
  #glue::glue("Source: {url.bitly} + {url.spop} (manual tidying)"), icon = icon.info) %>% 
  addLegend("bottomright", 
  colors =cols,
labels= SPOP,
opacity = 1)
  
m  # Print the map

## save to png
mapview::mapshot(m, file = "map-1000genomes-populations.png")

## save to hmtl
library(htmlwidgets)
saveWidget(m, file="map-1000genomes-populations.html")
