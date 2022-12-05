FROM docker.elastic.co/logstash/logstash:7.17.7
MAINTAINER <me.wmf@foxmail.com> cangyan

RUN /usr/share/logstash/bin/logstash-plugin install logstash-integration-jdbc

COPY ./jars/postgresql-42.5.1.jar /usr/share/logstash/logstash-core/lib/jars/postgresql.jar

COPY ./config/postgres-jdbc-input.conf /usr/share/logstash/pipeline/logstash.conf
