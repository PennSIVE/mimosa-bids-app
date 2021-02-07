FROM mimosa_base

RUN apt-get update && \
    apt-get install -y python3 nodejs npm && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    npm install -g bids-validator && \
    echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /usr/local/lib/R/etc/Rprofile.site && \
    Rscript -e "install.packages(c('devtools', 'rlist', 'xml', 'argparser', 'fslr'))" && \
    Rscript -e "remotes::install_github(c('ANTsX/ANTsRCore@v0.7.4.9', 'ANTsX/ANTsR@v0.5.7.4', 'muschellij2/extrantsr', 'muschellij2/oasis'))"
RUN Rscript -e "remotes::install_github('avalcarcel9/mimosa')"

ENV PYTHONPATH=""

COPY . /

ENTRYPOINT ["/run.py"]

