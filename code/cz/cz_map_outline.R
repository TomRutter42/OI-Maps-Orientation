# make sure all the packages we need are installed
list.of.packages <- c("leaflet", "tigris","dplyr","leaflet.extras","stringr","mapview","imager","scales","rgeos","haven", "sf")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

# load all the required packages
require(leaflet)
require(tigris)
options(tigris_use_cache = TRUE)
require(dplyr)
require(leaflet.extras)
require(stringr)
require(mapview)
require(imager)
require(scales)
require(rgeos)
require(sf)
require(haven)
require(here)

maps_folder <- file.path(research, '/outside/covid/derived/City maps')

data_folder <- file.path(maps_folder, "mapping data")

paychex_folder <- file.path(research, 'outside/covid/derived/Paychex')

cz_folder <- file.path(data_folder, "cz_shapefile")

crosswalks <- file.path(research, '/outside/covid_rawdata/crosswalks')

output_folder <- 
  here("outputs")



# loading in the cz shapefile data
cz_shp <- st_read(file.path(cz_folder, "cz1990.shp"))
latlong <- c( -104.87, 39.5)
zoom <- 3.35
vwidth <- 650
vheight = .45*vwidth


basemap2 <- "https://api.mapbox.com/styles/v1/tomrutter42/ckljiydyu0hub17o8nmaezrni/tiles/256/{z}/{x}/{y}?access_token=pk.eyJ1IjoidG9tcnV0dGVyNDIiLCJhIjoiY2tjdGNmdjZiMXd6ZDJ4bGZpbnRiYnUyNCJ9.RFkulnlN2IG_mf6TM95tDA"
basemap_labels <- "https://api.mapbox.com/styles/v1/kaimatheson/ck21z38gi4nap1cmdw87c2h8n/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoia2FpbWF0aGVzb24iLCJhIjoiY2p6bXVvMGY3MGgwejNia3p5NGY4ZHNxbyJ9.4W1gdX9t8hveowSiVstyhQ"
bm_attr <- "<a href='https://www.mapbox.com/map-feedback/'>Mapbox</a>"

mymap <- leaflet(cz_shp, options = leafletOptions(zoomSnap = 0.01, zoomDelta = 0.01)) %>%
  addMapPane("background", zIndex = 410) %>%
  addMapPane("polygons", zIndex = 420) %>%
  addMapPane("labels", zIndex = 430) %>%
  # set basemap
  addTiles(urlTemplate = basemap2, attribution = bm_attr,
           options = pathOptions(pane = "background")) %>%
  addTiles(urlTemplate = basemap_labels,
           options = pathOptions(pane="labels")) %>%
  addPolygons(color = "#444444",
              weight = 1,
              fillOpacity = opacity,
              fillColor = "white",
              options = pathOptions(pane = "polygons")
  ) %>%
  setView(lat = latlong[2], lng = latlong[1], zoom = zoom)

mymap %>%  mapshot(file = "C:/Users/Tom/Downloads/cz_outlines.jpg",
                   vwidth = vwidth, vheight = vheight, zoom = 2,
                   useragent = 'Mozilla/5.0 (compatible; MSIE 10.6; Windows NT 6.1; Trident/5.0; InfoPath.2; SLCC1; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; .NET CLR 2.0.50727) 3gpp-gba UNTRUSTED/1.0',
                   delay = 2)

saveWidget(mymap, 
           file = "C:/Users/Tom/Downloads/cz_outlines_map.html")


# display map
mymap
