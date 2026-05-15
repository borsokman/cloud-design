FROM debian:bullseye

RUN apt-get update && apt-get install -y postgresql postgresql-contrib && rm -rf /var/lib/apt/lists/*

# Allow remote connections
RUN echo "listen_addresses='*'" >> /etc/postgresql/13/main/postgresql.conf && \
    echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/13/main/pg_hba.conf

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 5432

USER postgres
CMD ["/usr/local/bin/entrypoint.sh"]