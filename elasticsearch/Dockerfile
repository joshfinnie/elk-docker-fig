FROM java:openjdk-8-jre
MAINTAINER Chris Shenton <chris@shenton.org>

ENV ES_PKG_NAME elasticsearch-1.4.2

WORKDIR /elasticsearch
RUN wget --quiet -O - https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.2.tar.gz | tar zxf - --strip-components 1

ADD ./elasticsearch.yml /elasticsearch/config/elasticsearch.yml

VOLUME ["/data"]
WORKDIR /data

ENTRYPOINT ["/elasticsearch/bin/elasticsearch"]
CMD ["-D es.config=/elasticsearch/config/elasticsearch.yml"]

EXPOSE 9200
EXPOSE 9300
