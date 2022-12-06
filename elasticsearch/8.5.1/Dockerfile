FROM docker.elastic.co/elasticsearch/elasticsearch:8.5.1
MAINTAINER cangyan <me.wmf@foxmail.com>

ENV VERSION=8.5.1

RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install -b https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v${VERSION}/elasticsearch-analysis-ik-$VERSION.zip

RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install -b https://github.com/medcl/elasticsearch-analysis-pinyin/releases/download/v${VERSION}/elasticsearch-analysis-pinyin-$VERSION.zip

RUN rm -rf /tmp/*
