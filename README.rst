===================================================================
 Create ELK stack based on The Docker Book's ElasticSearch example
===================================================================

LogStash
========

Using own Dockerfile here which reads from mapped volume on '/hostlog'::

  docker run -d --name logstash -v `pwd`/hostlogs:/hostlogs shentonfreude/logstash

ElasticSearch
=============

This uses an Oracle java base image, so it's not small. See:

  https://registry.hub.docker.com/u/dockerfile/elasticsearch/

Using certified dockerfile/elasticsearch image exposing HTTP=9200, transport=9300::

  docker run -d -p 9200:9200 -p 9300:9300 dockerfile/elasticsearch

Create a mountable data directory <data-dir> on the host. See ./elasticsearch/data/

Create ElasticSearch config file at <data-dir>/elasticsearch.yml.

path:
  logs: /data/log
  data: /data/data

Start a container by mounting data directory and specifying the custom configuration file:

docker run -d -p 9200:9200 -p 9300:9300 -v <data-dir>:/data dockerfile/elasticsearch /elasticsearch/bin/elasticsearch -Des.config=/data/elasticsearch.yml
After few seconds, open http://<host>:9200 to see the result.

Mount my local elasticsearch data dir and run::

  docker run -d -p 9200:9200 -p 9300:9300 -v `pwd`/elasticsearch/data:/data dockerfile/elasticsearch /elasticsearch/bin/elasticsearch -Des.config=/data/elasticsearch.yml

  docker run -d -p 9200:9200 -p 9300:9300 --name elasticsearch -v `pwd`/elasticsearch/data:/data dockerfile/elasticsearch /elasticsearch/bin/elasticsearch -Des.config=/data/elasticsearch.yml

Kibana
======

