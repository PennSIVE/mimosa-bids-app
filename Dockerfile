FROM mimosa_base

RUN apt-get update && \
    apt-get install -y python3 nodejs npm && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    npm install -g bids-validator@0.19.2


RUN Rscript -e "chooseCRANmirror(graphics=FALSE, ind=60); \
                install.packages(c('rlist', 'xml', 'argparser')); \
                source('https://neuroconductor.org/neurocLite.R'); neuro_install(c('ANTsRCore', 'extrantsr', 'fslr', 'neurobase', 'mimosa'))"

ENV PYTHONPATH=""

COPY . /

ENTRYPOINT ["/run.py"]

