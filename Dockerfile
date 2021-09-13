FROM rocker/r-ver:3.4.4
COPY . /app
CMD Rscript /app/code/zcta/zcta_maps.R
