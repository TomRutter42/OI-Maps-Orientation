FROM rocker/r-base
COPY . /app
USER root
RUN apt-get update
RUN apt-get install -y  gdal-bin \
                        proj-bin \
                        libgdal-dev \
                        libproj-dev \
                        libssl-dev \
                        libcurl4-openssl-dev \
                        libgeos-dev
CMD Rscript /app/code/zcta/zcta_maps.R
