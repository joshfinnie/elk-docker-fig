FROM ubuntu:14.10
MAINTAINER Chris Shenton <chris@shenton.org>
ENV REFRESHED_AT 2014-12-13

RUN apt-get -yqq update
RUN apt-get -yqq install wget
RUN wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
# 1.4.2 is presently current
RUN echo 'deb http://packages.elasticsearch.org/logstash/1.4/debian stable main' > /etc/apt/sources.list.d/logstash.list
RUN apt-get -yqq update
RUN apt-get -yqq install logstash

ADD logstash.conf /etc/

WORKDIR /opt/logstash
ENTRYPOINT [ "bin/logstash" ]
CMD [ "--config=/etc/logstash.conf" ]

