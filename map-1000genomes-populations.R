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

## glue POP and `Population Description`
#n.1kg <- n.1kg %>% mutate(pop.desc = paste(sep = "<br/>", POP, `Population Description`))
n.1kg <- n.1kg %>% mutate(pop.desc = paste(sep = " : ", POP, `Population Description`))

## map onto a world map
## with leaflet
## ---------------------
library(leaflet) 

## spec icons according to SPOP
cols <- brewer.pal(n = 5, "Dark2")




icons <- awesomeIcons(
  icon = '',
  iconColor = 'black',
  library = 'fa',
  markerColor = as.character(forcats::fct_recode(as.factor(n.1kg$SPOP), red = "EUR", blue = "AFR", green = "AMR", gray = "EAS", orange = "SAS")) ## ok, thats ugly, but who cares! turns out, hex colors won't work
)
cols <- c("red", "blue", "green", "gray", "orange")
SPOP <- c("EUR",  "AFR", "AMR", "EAS", "SAS")

## from here: https://github.com/bhaskarvk/leaflet/blob/master/inst/examples/awesomeMarkers.R
#icon.bike.blue <- makeAwesomeIcon(icon = 'bicycle', markerColor = 'blue', library='fa',
#                                  iconColor = 'white')
#icon.bike.green <- makeAwesomeIcon(icon = 'bicycle', markerColor = 'green', library='fa',
#                                   iconColor = 'white')

## make map
m <- leaflet(data = n.1kg) %>%
  addTiles() %>%  # Add default OpenStreetMap map tiles
  addAwesomeMarkers(lat=~lat, lng=~lon, label = ~htmltools::htmlEscape(pop.desc), icon = icons) %>% addLegend("bottomright", 
  colors =cols,
labels= SPOP,
opacity = 1)

#, popup = ~POP, icon = icons) #%>% 
  # Base groups
#  addProviderTiles(providers$MtbMap, group = "MTBmap") %>%
  # Layers control

m  # Print the map

## to hmtl
library(htmlwidgets)
saveWidget(m, file="map-1000genomes-populations.html")

## save to png
mapview::mapshot(m, file = "map-1000genomes-populations.png")

#  labs(title = "1000 Genomes reference panel populations", caption = glue::glue("Source: {url} \n {url.spop} (manual tidying)"))
#map.1kg
