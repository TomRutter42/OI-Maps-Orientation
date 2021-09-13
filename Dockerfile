FROM rocker/r-base
COPY . /app
CMD Rscript /app/code/zcta/zcta_maps.R
