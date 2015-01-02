# Kibana-4 runs a server which allows us to link containers
# instead of reconfigging the JSON config to our dynamic IP.

FROM java:openjdk-8-jre
MAINTAINER Chris Shenton <chris@shenton.org>
ENV REFRESHED_AT 2015-01-02

ENV KIBANA_PKG_NAME kibana-4.0.0-beta3

WORKDIR /kibana
RUN wget -O - https://download.elasticsearch.org/kibana/kibana/kibana-4.0.0-beta3.tar.gz | tar zxf - --strip-components 1

ADD ./config/kibana.yml     /kibana/config/
ADD ./config/kibana-dev.yml /kibana/config/
ADD ./bin/kibana-dev        /kibana/bin/

ENTRYPOINT [ "bin/kibana" ]


