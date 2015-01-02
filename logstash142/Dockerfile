# do we want ubuntu or a generic java?
FROM java:openjdk-8-jre
MAINTAINER Chris Shenton <chris@shenton.org>
ENV REFRESHED_AT 2014-12-13

WORKDIR /logstash
RUN wget -O - https://download.elasticsearch.org/logstash/logstash/logstash-1.4.2.tar.gz | tar zxf - --strip-components 1

ADD ./etc/logstash.conf /etc/

ENTRYPOINT [ "bin/logstash" ]
CMD [ "--config=/etc/logstash.conf" ]

