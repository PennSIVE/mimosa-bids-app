FROM pennsive/mass
FROM pennsive/mimosa
COPY --from=0 /opt/dramms-1.5.1 /opt/dramms-1.5.1
COPY --from=0 /opt/mass-1.1.1 /opt/mass-1.1.1
ENV PATH=/opt/dramms-1.5.1/bin:/opt/mass-1.1.1/bin:${PATH}

