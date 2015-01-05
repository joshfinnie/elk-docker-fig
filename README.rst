===================================================================
 Create ELK stack based on The Docker Book's ElasticSearch example
===================================================================

On OS X, start up Docker and set the environment variables so the
boot2docker VM is reachable::

  boot2docker up
  $(boot2docker shellinit)

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

  docker run --hostname=apache --name=apache --publish=8888:80 -v `pwd`/kibana-3.1.2:/usr/local/apache2/htdocs/ httpd:2.4

We don't have/need 'links' here because the host's browser trying to
do the resolution in Kibana3, exposing it to the container doesn't
help. In Kibana4 it should.

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

  docker run --name=apache --publish=8888:80 -v `pwd`/kibana-3.1.2:/usr/local/apache2/htdocs/ httpd:2.4

Test Kibana::

  http://192.168.59.103:8888/

We load the page then a few seconds later get Connection Failed; I
need to update the Kibana config with the new IP of the Docker VM so
it can find ElasticSearch::

      elasticsearch: "http://192.168.59.103:9200",

This time we get a page, so go to the sample newbie dashboard::

  http://192.168.59.103:8888/index.html#/dashboard/file/guided.json


Fig Orchestration
=================

We should be able to use Fig to orchestrate the various pieces above
from a single YAML file.

Install `fig`::

  curl -L https://github.com/docker/fig/releases/download/1.0.1/fig-`uname -s`-`uname -m` > /usr/local/bin/fig; chmod +x /usr/local/bin/fig

(I could not get this to work by creating a virtualenv (python 2 or 3)
and then installing fig in it; the standalone command above worked
fine.)

Edit the `fig.yml` file to define the containers and host connections::

  elasticsearch:
    image: dockerfile/elasticsearch
    command: /elasticsearch/bin/elasticsearch -D es.config=/data/elasticsearch.yml
    ports:
      - "9200:9200"
      - "9300:9300"
    volumes:
      - ./elasticsearch/data:/data

  logstash:
    image: shentonfreude/logstash
    volumes:
      - ./hostlogs:/hostlogs
    links:
      - elasticsearch

  apache:
    image: httpd:2.4
    ports:
      - 8888:80
    volumes:
      - ./kibana-3.1.2:/usr/local/apache2/htdocs

My apache image must be stupid because it doesn't release the
terminal, so a ^C stops the entire fig stack. 

With apache running, visit the app at 
http://192.168.59.103:8888/index.html#/dashboard/file/default.json

This is pretty nice and seems easier and more transparent than
Vagrant's Docker providers.

Kibana-4b3
==========

Kibana-4 uses its own server so it should be able to resolve the
Docker hostnames and find ElasticSearch, which Kibana-3's
browser-native host resolution cannot do. It requires Java so build an
image::

  docker build -t shentonfreude/kibana:4b3 kibana4b3

Then run it, exposing the port::

  docker run -p 5601:5601 shentonfreude/kibana

Gives long Java stack trace showing it couldn't connect, but doesn't
give the URL it's trying to connect to. :-( I can shell into the box
and test that I can get the connection via the /etc/hosts entry::

  docker exec -i -t elkfrombook_kibana_1  /bin/bash
  curl http://elasticsearch:9200/

The above works but I keep seeing Kibana saying it's finding ElasticSearch-1.1.1 which is too low::

  Kibana: This version of Kibana requires Elasticsearch 1.4.0 or higher on all nodes. I found the following incompatible nodes in your cluster: 
  Elasticsearch 1.1.1 @ inet[/172.17.0.17:9300] (172.17.0.17)

But that host, 0.17, is NOT what's in the /etc/hosts file edited by fig::

  172.17.0.15	elk_es_1
  172.17.0.15	es
  172.17.0.15	es_1

If we curlthat from-where .17 address, we connect::

  curl http://172.17.0.17:9300/

and the *logstash* logs show a stream error::

  logstash_1 | log4j, [2015-01-02T22:15:27.396]  WARN: org.elasticsearch.transport.netty:
               [logstash-0d41a1e702d3-1-4002]
               exception caught on transport layer
               [[id: 0x46fa96a9, /172.17.0.19:47681 => /172.17.0.17:9300]], closing connection
  logstash_1 | java.io.StreamCorruptedException: invalid internal transport message format

why is logstash involved at all?

The machine's own address is .19::

  ip route
  default via 172.17.42.1 dev eth0 
  172.17.0.0/16 dev eth0  proto kernel  scope link  src 172.17.0.19 

I try to specify the URL with the Fig name elasticsearch_1 (or
elk_elasticsearch_1) but it then complains of an invalud URL --
underscores are not allowed in DNS names and Java may enforce this::

  "name":"URI::InvalidURIError",
  "message":"the scheme http does not accept registry part: elasticsearch_1:9200 (or bad hostname?)

The config file is not getting my override::

  grep elasticsearch: /var/www/html/kibana-4.0.0-beta3/config/kibana.yml
  elasticsearch: "http://localhost:9200"

If I comment out the fig.yml 'logstash' stanza, Kibana comes up just
fine! WTF? how is logstash doing this? is it running the older
ElasticSearch and it's being found by some service discovery or
clustering?

See this thread discussing how LogStash is being by ElasticSearch as cluster member.

https://github.com/elasticsearch/kibana/issues/1629

You can see it after fig launches like:

  docker exec elk_elasticsearch_1 curl -XGET http://localhost:9200/_nodes


TODO
====

* INPROGRESS:  Kibana-4b3: has its own server (Java required) so can avoid DNS
  hostname problem in JS; use a container for this, but negates need
  for Apache.

* Redis: Put Redis in front of LogStash. Use a separate container so
  we could fan out LogStash processes.

* LogStash Filters: for syslog, apache, etc; parse logs to JSON for ElasticSearch

* Use logstash-forwarder on servers sending logs (but Redis can't accept encrypted streams?)

* Kibana: we've got lame visualization and parsing

* How to use fig to build the images
