FROM java:7
MAINTAINER Chris Shenton <chris@shenton.org>
ENV REFRESHED_AT 2015-01-01b

# Need Java for Kibana-4.0.0b3
# It runs a server which allows us to link containers
# instead of reconfigging the JSON config

WORKDIR /var/www/html
RUN wget -O - https://download.elasticsearch.org/kibana/kibana/kibana-4.0.0-beta3.tar.gz | tar zxf -

# Wasn't doing it relative to WORKDIR, but to /
ADD ./kibana.yml /var/www/html/kibana-4.0.0-beta3/config/

WORKDIR /var/www/html/kibana-4.0.0-beta3/
ENTRYPOINT [ "bin/kibana" ]


