####################################################################################################################################
# National CZ Maps of Earnin
# By Kai Matheson/cz edits by Clare
####################################################################################################################################

#***********************************************************************************************************************************
# Set-up: Load packages, set filepaths, load functions
#***********************************************************************************************************************************

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


# loading file paths in the profile and setting relevant paths

source("C:/rpaths/profile.R")

maps_folder <- file.path(research, '/outside/covid/derived/City maps')

data_folder <- file.path(maps_folder, "mapping data")

paychex_folder <- file.path(research, 'outside/covid/derived/Paychex')

cz_folder <- file.path(data_folder, "cz_shapefile")

crosswalks <- file.path(research, '/outside/covid_rawdata/crosswalks')


#***********************************************************************************************************************************
# Set your specific options HERE!!! This is the only chunk of code you should have to touch!
#***********************************************************************************************************************************

# read in county-level national datasets
# earnin
cz_nat <- read.csv(file.path(paychex_folder, "combined series national cz map data.csv"), stringsAsFactors = FALSE)

cz_nat$emp_combined_q1 = cz_nat$emp_combined_q1*100
cz_nat$emp_combined_q4 = cz_nat$emp_combined_q4*100

# make your list of variables to map
map_vars <- c("emp_combined_q1","emp_combined_q4")

# make your list of variable units (percent, comma or dollar currently implemented -- if you have a different unit, ask kai for help)
map_var_types <- rep("percent",2)

# make your list of variable labels
map_var_labels <- c("Change in Low-Wage</br>Employment from</br>Jan to Apr 2020","Change in High Income</br>Employment</br>(Combined Series)")

# set color scheme for each variable
# "atlas" or "pink-purple" like atlas covariates
color_scheme_names <- rep("atlas",2)

# reverse the color scheme for each variable
reverse_color_schemes <- rep(FALSE,2)

# how many colors/deciles do you want?
number_of_colors = 10

# what opacity you want the shapes to be
opacity = 0.7

#***********************************************************************************************************************************
# Loop over geographies (national & CA)
#***********************************************************************************************************************************

# set legend position
legendpos <- "bottomleft"

# get the dataset and assign it to "mapdata"
mapdata <- cz_nat

# loading in the cz shapefile data
cz_shp <- st_read(file.path(cz_folder, "cz1990.shp"))


#***********************************************************************************************************************************
# Join spatial data with your data
#***********************************************************************************************************************************

# join together the cz spatial data with the mapdata
cz_shp <- geo_join(cz_shp, mapdata, by="cz", how="left")


#***********************************************************************************************************************************
# Loop through mapping variables
#***********************************************************************************************************************************

# create list of indices of map vars
loopvars <- 1:length(map_vars)

# loop through the map vars
for (num in loopvars){
  # get current map var and corresponding info
  map_var <- map_vars[num]
  map_var_type <- map_var_types[num]
  map_var_label <- map_var_labels[num]
  color_scheme_name <- color_scheme_names[num]
  reverse_color_scheme <- reverse_color_schemes[num]
  
  
  #***********************************************************************************************************************************
  # Create color palette and legend labels
  #***********************************************************************************************************************************
  
  if (color_scheme_name =="atlas"){
    raw_color_scheme <- c("#890024","#a94138","#c86e4f","#e19e6f","#f2cd97","#ffffc2","#ccdcb5","#98baa8","#6a9799","#447586","#195473")
  } else {
    raw_color_scheme <- c("#FEE8E4","#F878A7","#6A0072")
  }
  
  color_pal2 <- colorRampPalette(raw_color_scheme)
  
  # calculate percentiles of the map var using number_of_colors
  quantiles <- unique(quantile(
    c(cz_shp[[map_var]]),
    prob = (1:(number_of_colors-1)) / number_of_colors, na.rm=TRUE))
  
  color_palette <- color_pal2(length(quantiles))
  
  # format legend labels according to map var type
  if(map_var_type == "percent" | map_var_type=="dollar" | map_var_type == "comma"){
    if(map_var_type == "percent"){
      calc_quantiles <- quantiles
      # number of decimal places in legend
      precision = 1
      # multiply by 1, not 100 which is default for percent
      scale = 1
    } else if(map_var_type=="dollar") {
      calc_quantiles <- quantiles
      precision = 1
      scale = 1
    } else {
      calc_quantiles <- quantiles
      precision = 0.1
      scale = 1
    }
    formatter <- get(map_var_type)
    legend_labels <- paste0(formatter(calc_quantiles[-length(calc_quantiles)], accuracy=precision, scale = scale), " to ", formatter(calc_quantiles[-1], accuracy=precision, scale = scale))
    legend_labels <- c(paste0("< ", formatter(calc_quantiles[1], accuracy=precision, scale = scale)),
                       legend_labels,
                       paste0("> ", formatter(calc_quantiles[length(calc_quantiles)], accuracy=precision, scale = scale)))  
  }
  
  # create the color palette with cut points
  quantile_palette <- colorBin(color_palette, 
                               c(cz_shp[[map_var]])
                               , bins=c(-Inf,quantiles,Inf), reverse=reverse_color_scheme, right = FALSE)
  
  #***********************************************************************************************************************************
  # Produce the map
  #***********************************************************************************************************************************
  
  # load basemaps and attribution
  basemap <- "https://api.mapbox.com/styles/v1/kaimatheson/ck21z1gw10ojz1cp9nohuo064/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoia2FpbWF0aGVzb24iLCJhIjoiY2p6bXVvMGY3MGgwejNia3p5NGY4ZHNxbyJ9.4W1gdX9t8hveowSiVstyhQ"
  basemap_labels <- "https://api.mapbox.com/styles/v1/kaimatheson/ck21z38gi4nap1cmdw87c2h8n/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoia2FpbWF0aGVzb24iLCJhIjoiY2p6bXVvMGY3MGgwejNia3p5NGY4ZHNxbyJ9.4W1gdX9t8hveowSiVstyhQ"
  bm_attr <- "� <a href='https://www.mapbox.com/map-feedback/'>Mapbox</a>"
  
  # create the map!
  mymap <- leaflet(cz_shp, options = leafletOptions(zoomSnap = 0.01, zoomDelta = 0.01)) %>% 
    addMapPane("background", zIndex = 410) %>%
    addMapPane("czs", zIndex = 425) %>%
    addMapPane("labels", zIndex = 430) %>%
    # set basemap
    addTiles(urlTemplate = basemap, attribution = bm_attr,
             options = pathOptions(pane = "background")) %>% 
    #addTiles(urlTemplate = basemap_labels, 
    #         options = pathOptions(pane="labels")) %>%
    addPolygons(data = cz_shp, 
                color = ~quantile_palette(get(map_var)),
                weight = 1,
                fillOpacity = opacity,
                options = pathOptions(pane = "czs")
    ) %>%
    addLegend(legendpos, pal = quantile_palette, values = ~get(map_var),
              title = map_var_label,
              opacity=1, 
              labFormat = function(type, cuts) {
                cuts = paste0(legend_labels)
              }, na.label = "No Data"
    ) 
  
  for (image_size in c("papersize")){
    if (image_size=="normalsize"){
      # set zoom
      zoom <- 5
      vwidth <- 1500
      vheight = 744/992*vwidth
      
      # set lat long to the center of the counties included
      latlong <- c( -98.35, 39.5)
    } else if (image_size == "papersize"){
      # set zoom
      zoom <- 3.35
      vwidth <- 650
      vheight = .45*vwidth
      
      # set lat long to the center of the counties included
      latlong <- c( -104.87, 39.5)
    }
    
    mymap2 <- mymap %>% 
      setView(lat = latlong[2], lng = latlong[1], zoom = zoom) 
    
    #***********************************************************************************************************************************
    # Save the map as an image file
    #***********************************************************************************************************************************
    
    
    # create filename
    filename <- paste("cz_nat_apr", map_var, image_size, "map_final.png" , sep = "_")
    
    
    # screenshot the map and save it in your current working directory
    mymap2 %>%  mapshot(file = file.path(getwd(),filename),
                        vwidth = vwidth, vheight = vheight, zoom = 4,
                        useragent =  'Mozilla/5.0 (compatible; MSIE 10.6; Windows NT 6.1; Trident/5.0; InfoPath.2; SLCC1; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; .NET CLR 2.0.50727) 3gpp-gba UNTRUSTED/1.0',
                        delay = 2)
    
    # save the image in the maps folder and remove it from your current working directory
    save.image(load.image(file.path(getwd(),filename)),file.path(maps_folder,filename))
    file.remove(file.path(getwd(),filename))
    
  }
  
}
