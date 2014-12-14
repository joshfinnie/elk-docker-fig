===================================================================
 Create ELK stack based on The Docker Book's ElasticSearch example
===================================================================

LogStash
========

Using own Dockerfile here which reads from mapped volume on
'/hostlog'. Below we set the hostname so that Docker can tell
ElasticSearch about it::

  docker run -d --name logstash -h logstash -v `pwd`/hostlogs:/hostlogs shentonfreude/logstash

Watch the logs::

  ★ chris@Vampyre:elk-from-book$ docker logs -f logstash

Then append some system logs to our sample logs::

 ★ chris@Vampyre:elk-from-book$ tail -f /var/log/system.log >> hostlogs/system.log

The log tail above should show stuff if the config has::

  output {
    stdout {
      codec => rubydebug
    }
  }

We then want to send it to elasticsearch, so change the config::

  output {
    elasticsearch {
      host => "elasticsearch"
    }
    stdout {
      codec => rubydebug
    }
  }

After you get ElasticSearch running with a hostname 'elasticsearch',
rebuild, stop, rm, and run again linking::

  docker run --hostname=logstash --name=logstash -d --link=elasticsearch:elasticsearch -v `pwd`/hostlogs:/hostlogs shentonfreude/logstash


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

Start a container by mounting data directory and specifying the custom configuration file, specifying the hostname 'elasticsearch' so that logstash can find it::

docker run -d -p 9200:9200 -p 9300:9300 -v <data-dir>:/data dockerfile/elasticsearch /elasticsearch/bin/elasticsearch -Des.config=/data/elasticsearch.yml
After few seconds, open http://<host>:9200 to see the result.

Mount my local elasticsearch data dir and run giving it a hostname that LogStash can link to::

  docker run --hostname=elasticsearch --name=elasticsearch -d -p 9200:9200 -p 9300:9300  -v `pwd`/elasticsearch/data:/data dockerfile/elasticsearch /elasticsearch/bin/elasticsearch -Des.config=/data/elasticsearch.yml

Make sure the data dir is where you think it is, else the container will abort.


Testing
-------

Get the IP of the docker host::

  ★ chris@Vampyre:elk-from-book$ boot2docker ip
  The VM's Host only interface IP address is: 192.168.59.105

Verify the port for ElasticSearch::

  ★ chris@Vampyre:elk-from-book$ docker port elasticsearch
  9200/tcp -> 0.0.0.0:9200
  9300/tcp -> 0.0.0.0:9300

Then curl or browse to it::


  ★ chris@Vampyre:elk-from-book$ curl 192.168.59.105:9200
  {
    "status" : 200,
    "name" : "Bobster",
    "cluster_name" : "elasticsearch",
    "version" : {
      "number" : "1.4.1",
      "build_hash" : "89d3241d670db65f994242c8e8383b169779e2d4",
      "build_timestamp" : "2014-11-26T15:49:29Z",
      "build_snapshot" : false,
      "lucene_version" : "4.10.2"
    },
    "tagline" : "You Know, for Search"
  }

And a search on your still-empty corpus::

  ★ chris@Vampyre:elk-from-book$ curl http://192.168.59.105:9200/_search?pretty
  {
    "took" : 1,
    "timed_out" : false,
    "_shards" : {
      "total" : 0,
      "successful" : 0,
      "failed" : 0
    },
    "hits" : {
      "total" : 0,
      "max_score" : 0.0,
      "hits" : [ ]
    }
  }

After we link LogStash to ElasticSearch we can find hits when we search.

Kibana
======

