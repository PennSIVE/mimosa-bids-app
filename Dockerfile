FROM pennsive/neuror:4.0

RUN apt-get update && \
    apt-get install -y python3 nodejs npm && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    npm install -g bids-validator@0.19.2

ENV PYTHONPATH=""

COPY . /

ENTRYPOINT ["/run.py"]

# docker build -t pennsive/mimosa:latest .
# docker run -v ~/Downloads/mscamras/sites/NIH:/bids_dataset:ro -v $PWD/out:/out pennsive/mimosa:latest /bids_dataset /out participant