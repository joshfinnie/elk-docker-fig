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

 ★ chris@Vampyre:elk-from-book$ tail /var/log/system.log >> hostlogs/system.log

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

For Kibana in the browser to access ElasticSearch, we have to enable CORS::

  path:
    logs: /data/log
    data: /data/data
  http.cors.enabled: true
  http.cors.allow-origin: "*"

DANGER: the above is way too permissive, the allow-origin should be a
regex of the host serving Kibana. But what is it in the Docker
context?

Kibana
======

Kibana is just HTML, CSS, and JavaScript so we'll just run an Apache
container and mount the code from a local dir.

https://download.elasticsearch.org/kibana/kibana/kibana-3.1.2.tar.gz

Edit the config.js to point the elasticsearch parameter at our
'elasticsearch' hostname; docs say it wants an FQDN but we don't have
that. Replace::

  elasticsearch: "http://"+window.location.hostname+":9200",

with::

  elasticsearch: "http://192.168.59.105:9200",

We can NOT use the Docker-provided DNS name we gave it::

  elasticsearch: "http://elasticsearch:9200",     // WRONG!

because the browser will try to resolve that name in JavaScript and
won't find it. Until we find a better way, we have to hard-code the IP
address, and this will change each time Docker restarts.

While we might later want an image of Kibana built on an Apache image::

  FROM httpd:2.4
  COPY ./kibana/ /usr/local/apache2/htdocs/

this would create an image with a fixed version of Kibana burned into
it, making updates harder. Or making it more stable with a pinned
version, depending on your point of view.

Apache
======

There's an official Apache server image `httpd`.  We'll run it
mounting the local Kibana directory onto the Apache document
directory::

  docker run --hostname=apache --name=apache --publish=8888:80 --link=elasticsearch:elasticsearch -v `pwd`/kibana-3.1.2:/usr/local/apache2/htdocs/ httpd:2.4

Test::

  http://192.168.59.105:8889/

Running them all together
=========================

ElasticSearch needs to start before LogStash so the DNS name is registered::

  docker run --hostname=elasticsearch --name=elasticsearch -d -p 9200:9200 -p 9300:9300  -v `pwd`/elasticsearch/data:/data dockerfile/elasticsearch /elasticsearch/bin/elasticsearch -Des.config=/data/elasticsearch.yml

Test ElasticSearch::

  http://192.168.59.103:9200/
  http://192.168.59.105:9200/_search?pretty

Then LogStash::

  docker run --hostname=logstash --name=logstash -d --link=elasticsearch:elasticsearch -v `pwd`/hostlogs:/hostlogs shentonfreude/logstash

And Apache, mounting Kibana source as a data volume::

  docker run --hostname=apache --name=apache --publish=8888:80 --link=elasticsearch:elasticsearch -v `pwd`/kibana-3.1.2:/usr/local/apache2/htdocs/ httpd:2.4

Test Kibana::

  http://192.168.59.103:8888/

We load the page then a few seconds later get Connection Failed; I
need to update the Kibana config with the new IP of the Docker VM so
it can find ElasticSearch::

      elasticsearch: "http://192.168.59.103:9200",

This time we get a page, so go to the sample newbie dashboard::

  http://192.168.59.103:8888/index.html#/dashboard/file/guided.json

