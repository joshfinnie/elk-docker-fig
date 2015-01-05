FROM java:openjdk-8-jre
MAINTAINER Chris Shenton <chris@shenton.org>
ENV REFRESHED_AT 2014-01-05

WORKDIR /logstash
RUN wget --quiet -O - https://download.elasticsearch.org/logstash/logstash/logstash-1.4.2.tar.gz | tar zxf - --strip-components 1

ADD ./logstash.conf /logstash/logstash.conf

ENTRYPOINT [ "bin/logstash" ]
CMD [ "--config=/logstash/logstash.conf" ]

