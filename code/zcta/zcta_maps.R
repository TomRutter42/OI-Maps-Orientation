####################################################################################################################################
# City Maps
# By Kai Matheson
# May 14, 2020

# Substantially Revised by Tom R, Feb 2021; July 2021
####################################################################################################################################

#***********************************************************************************************************************************
# Set-up: Load packages, set filepaths, load functions
#***********************************************************************************************************************************

# Load packages (install first if you don't have them yet) 

requiredPackages <- 
  c("rmarkdown", 
    "leaflet", 
    "tigris",
    "dplyr",
    "leaflet.extras",
    "stringr",
    "mapview",
    "imager",
    "scales",
    "sf",
    "rgeos", 
    "here", 
    "htmlwidgets")

for(p in requiredPackages) {
  
  if(!require(p, character.only = TRUE)) {
    
    install.packages(p, dependencies = TRUE)
    
  } 
  
  library(p, character.only = TRUE)
  
}

options(tigris_use_cache = TRUE)

# Set Directories: 
input_folder <- 
  here("inputs", "zcta")
output_folder <- 
  here("outputs")

# source in scale-flipping helper function
source(here("code", "zcta", "helper_functions", "flip_scale.R"))


#***********************************************************************************************************************************
# Set your specific options BELOW!!! This is the only chunk of code you should have to touch!
#***********************************************************************************************************************************

# list of cities to map --- should match one of the cityfn options below (you can add new ones to the list)
cities <- 
  c("chicago")

# this should be your dataset with a zcta variable and the variables you want to map!
mapdata <- 
  read.csv(file.path(input_folder, 
                     "zcta_data.csv"), 
           stringsAsFactors = FALSE)

# make your list of variables to map 
map_vars <- 
  c("frac_blw_med_pooled_pld", 
    "frac_blw_med_black_pld", 
    "frac_blw_med_white_pld")

## multiply fractions by 100 
mapdata$frac_blw_med_pooled_pld <- 
  100 * mapdata$frac_blw_med_pooled_pld 
mapdata$frac_blw_med_black_pld <- 
  100 * mapdata$frac_blw_med_black_pld 
mapdata$frac_blw_med_white_pld <- 
  100 * mapdata$frac_blw_med_white_pld 

# make your list of variable units (percent, comma or dollar currently implemented)
map_var_types <- 
  c("percent", 
    "percent", 
    "percent")

# make your list of variable labels
map_var_labels <- 
  c("All Races", 
    "Black", 
    "White")

# set color scheme for each variable
# "atlas" or "pink-purple" like atlas covariates
color_scheme_names <- 
  rep("RdYlBu", times = length(map_vars))

# reverse the color scheme for each variable
reverse_color_schemes <- 
  rep("TRUE", times = length(map_vars))

# how many colors/deciles do you want?
number_of_colors = 10

# what opacity you want the shapes to be
opacity = 0.7

#***********************************************************************************************************************************
# Loop through cities
#***********************************************************************************************************************************

# in case your zcta variable is named ZCTA
names(mapdata) <- tolower(names(mapdata))

for (cityfn in cities){
  
  #***********************************************************************************************************************************
  # Set city-specific options
  #***********************************************************************************************************************************
  
  mapdata_reduced <- mapdata
  
  # set zoom and lat long based on city
  if (cityfn == "atlanta") {
    latlong <- c(-84.414777, 33.764494)
    zoom <-
      legendpos <- "bottomright"
  } else if(cityfn == "newyorkcity") {
    latlong <- c(-73.959128, 40.711723)
    zoom <- 10 
    legendpos <- "topleft"
  } else if (cityfn == "sanfrancisco") {
    latlong <- c(-122.444719,37.764026)
    zoom <- 9.7
    legendpos <- "bottomleft"
  } else if(cityfn == "losangeles") {
    latlong <- c(-118.300100, 33.944987)
    zoom <- 9 
    legendpos <- "bottomleft"
  } else if(cityfn == "chicago") {
    latlong <- c(-87.8692, 41.8050) 
    zoom <-  9.5 
    legendpos <- "topright"
    mapdata_reduced <- 
      mapdata[substr(mapdata$zcta, 1, 2) == "60" | substr(mapdata$zcta, 1, 2) == "46", ]
  } else if(cityfn == "washington") {
    latlong <- c(-77.021454, 38.899391)
    zoom <- 12
    legendpos <- "topright"
  } else if(cityfn == "boston") {
    latlong <- c(-71.089257, 42.329114)
    zoom <- 11
    legendpos <- "topright"
  } else if(cityfn == "seattle") {
    latlong <- c(-122.15000, 47.54000)
    zoom <- 10
    legendpos <- "topright"
  } else if(cityfn == "charlotte") {
    latlong <- c(-80.832583, 35.246141)
    zoom <- 10.1
    legendpos <- "topright"
  } else {
    latlong <- coordinates(gCentroid(shpdata))
  }
  
  #***********************************************************************************************************************************
  # Pull in the spatial data
  #***********************************************************************************************************************************
  
  zip_starts_with = unique(str_extract(str_pad(mapdata$zcta,5,"left","0"), "^.{3}"))
  
  # loading in the census tract shapefile data
  shpdata <- zctas(starts_with = zip_starts_with, cb = TRUE)
  
  #***********************************************************************************************************************************
  # Join spatial data with your data
  #***********************************************************************************************************************************
  
  shpdata <- 
    as_Spatial(shpdata)
  
  shpdata@data <- shpdata@data %>%
    mutate(
      zcta = as.numeric(as.character(ZCTA5CE10))
    )
  
  shpdata <- geo_join(shpdata, mapdata_reduced, by="zcta",how="inner")
  
  # check that we haven't dropped any zctas from your dataset
  stopifnot(nrow(shpdata@data) == nrow(mapdata_reduced))
  
  #***********************************************************************************************************************************
  # Loop through mapping variables
  #***********************************************************************************************************************************
  
  for (num in 1:length(map_vars)){
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
    } else if (color_scheme_name == "RdYlBu") {
      
      raw_color_scheme <- c("#d73027", "#fc8d59", "#fee090", "#e0f3f8", "#91bfdb", "#4575b4")
      
    } else {
      raw_color_scheme <- c("#FEE8E4","#F878A7","#6A0072")
    }
    
    color_pal2 <- colorRampPalette(raw_color_scheme)
    
    min <- min(mapdata_reduced[[map_var]])
    max <- max(mapdata_reduced[[map_var]])
    
    quantiles <- unique(quantile(mapdata_reduced[[map_var]], prob = (1:(number_of_colors-1)) / number_of_colors, na.rm=TRUE))
    
    color_palette <- color_pal2(length(quantiles))
    
    
    if(map_var_type == "percent" | map_var_type == "dollar" | map_var_type == "comma"){
      if(map_var_type == "percent"){
        calc_quantiles <- quantiles/100
        # number of decimal places in legend
        precision = 1
      } else {
        # calc_quantiles <- c(min, quantiles, max)
        calc_quantiles <- quantiles
        precision = 0.01
      }
      formatter <- get(map_var_type)
      legend_labels <- paste0(formatter(calc_quantiles[-length(calc_quantiles)], accuracy=precision), " - ", formatter(calc_quantiles[-1], accuracy=precision))
      legend_labels <- c(paste0("< ", formatter(calc_quantiles[1], accuracy=precision)),
                         legend_labels,
                         paste0("> ", formatter(calc_quantiles[length(calc_quantiles)], accuracy=precision)))
    }
    
    quantile_palette <- 
      colorBin(color_palette, mapdata_reduced[[map_var]], 
               bins=c(-Inf,quantiles,Inf), 
               reverse=reverse_color_scheme, 
               right = FALSE)
    
    #***********************************************************************************************************************************
    # Produce the map
    #***********************************************************************************************************************************
    
    ## See here for additional info on Mapbox
    ## https://docs.mapbox.com/studio-manual/overview/publish-your-style/#mapboxjs-and-leaflet
    basemap2 <- "https://api.mapbox.com/styles/v1/tomrutter42/ckljiydyu0hub17o8nmaezrni/tiles/256/{z}/{x}/{y}?access_token=pk.eyJ1IjoidG9tcnV0dGVyNDIiLCJhIjoiY2tjdGNmdjZiMXd6ZDJ4bGZpbnRiYnUyNCJ9.RFkulnlN2IG_mf6TM95tDA"
    basemap_labels <- "https://api.mapbox.com/styles/v1/kaimatheson/ck21z38gi4nap1cmdw87c2h8n/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoia2FpbWF0aGVzb24iLCJhIjoiY2p6bXVvMGY3MGgwejNia3p5NGY4ZHNxbyJ9.4W1gdX9t8hveowSiVstyhQ"
    bm_attr <- "<a href='https://www.mapbox.com/map-feedback/'>Mapbox</a>"
    
    mymap <- leaflet(shpdata, options = leafletOptions(zoomSnap = 0.01, zoomDelta = 0.01)) %>%
      addMapPane("background", zIndex = 410) %>%
      addMapPane("polygons", zIndex = 420) %>%
      addMapPane("labels", zIndex = 430) %>%
      # set basemap
      addTiles(urlTemplate = basemap2, attribution = bm_attr,
               options = pathOptions(pane = "background")) %>%
      addTiles(urlTemplate = basemap_labels,
               options = pathOptions(pane="labels")) %>%
      addPolygons(color = ~quantile_palette(get(map_var)),
                  weight = 1,
                  fillOpacity = opacity,
                  options = pathOptions(pane = "polygons")
      ) %>%
      setView(lat = latlong[2], lng = latlong[1], zoom = zoom) %>%
      addLegend_decreasing(legendpos, pal = quantile_palette, values = ~get(map_var),
                           title = map_var_label,
                           opacity=1,
                           labFormat = function(type, cuts) {
                             cuts = paste0(legend_labels)
                           }, na.label = "No Data", 
                           decreasing = TRUE
      )
    
    
    # display map
    mymap
    
    # save map as an image file
    
    vwidth = 700
    vheight = 744/992*vwidth
    
    filename <- paste(cityfn, map_var, sep = "_")
    
    # change the file name if you want!
    mymap %>%  mapshot(file = file.path(output_folder, paste0(filename, ".png")),
                       vwidth = vwidth, vheight = vheight, zoom = 2,
                       useragent = 'Mozilla/5.0 (compatible; MSIE 10.6; Windows NT 6.1; Trident/5.0; InfoPath.2; SLCC1; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; .NET CLR 2.0.50727) 3gpp-gba UNTRUSTED/1.0')
    
    saveWidget(mymap, 
               file = file.path(output_folder, paste0(filename, ".html")))
    
    # tidy up
    unlink(file.path(output_folder, paste0(filename, "_files")), 
           recursive = TRUE)
    
  }
  
}
