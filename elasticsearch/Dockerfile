FROM elasticsearch:5.6.4

MAINTAINER Mingfeng Wang <me.wmf@foxmail.com>

RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v5.6.4/elasticsearch-analysis-ik-5.6.4.zip

RUN mkdir -p /usr/share/elasticsearch/config/analysis-ik

RUN cp /etc/elasticsearch/analysis-ik/* /usr/share/elasticsearch/config/analysis-ik/

RUN chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/config/analysis-ik