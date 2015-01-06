# Kibana-4 runs a server which allows us to link containers
# instead of reconfigging the JSON config to our dynamic IP.

FROM java:openjdk-8-jre
MAINTAINER Chris Shenton <chris@shenton.org>

ENV KIBANA_PKG_NAME kibana-4.0.0-beta3

WORKDIR /kibana
RUN wget --no-verbose -O - https://download.elasticsearch.org/kibana/kibana/kibana-4.0.0-beta3.tar.gz | tar zxf - --strip-components 1

ADD ./kibana.yml     /kibana/config/

ENTRYPOINT [ "bin/kibana" ]


