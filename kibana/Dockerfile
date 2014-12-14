FROM httpd:2.4
MAINTAINER Chris Shenton <chris@shenton.org>
ENV REFRESHED_AT 2014-12-13

RUN apt-get -yqq update
RUN apt-get -yqq install wget

WORKDIR /usr/local/apache2/htdocs
# Get and unpack kibana, stripping the top-level kibana-3.1.2/ dir so index is at top level
RUN wget -O - https://download.elasticsearch.org/kibana/kibana/kibana-3.1.2.tar.gz | tar zxf - --strip-components 1

COPY ./config.js ./


