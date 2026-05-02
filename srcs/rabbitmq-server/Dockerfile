FROM debian:bullseye

RUN apt-get update && apt-get install -y rabbitmq-server && rm -rf /var/lib/apt/lists/*

RUN rabbitmq-plugins enable rabbitmq_management

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 5672
EXPOSE 15672

CMD ["/usr/local/bin/entrypoint.sh"]