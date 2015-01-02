# This is naive: the targets don't match the resulting images
# so Make rebuilds each time. We should create markers (e.g.,
#   touch $@
# to indicate success, and remove them with 'clean' targets

build: .elasticsearch-image .logstash-image .kibana-image

.elasticsearch-image: elasticsearch/Dockerfile elasticsearch/config/elasticsearch.yml
	docker build --rm --no-cache -t shentonfreude/elasticsearch:1.4.2 elasticsearch
	touch $@

.logstash-image: logstash/Dockerfile logstash/logstash.conf
	docker build --rm --no-cache -t shentonfreude/logstash:1.4 logstash
	touch $@

.kibana-image: kibana/Dockerfile kibana/kibana.yml
	docker build --rm --no-cache -t shentonfreude/kibana:4b3 kibana
	touch $@

# .httpd-image:
# 	docker pull httpd:2.4

# build-elasticsearch-image:
# 	docker pull dockerfile/elasticsearch

clean: clean-elasticsearch-image clean-logstash-image clean-kibana-image

clean-elasticsearch-image: .logstash-image
	docker rmi shentonfreude/elasticsearch:1.4.2
	rm $<

clean-logstash-image: .logstash-image
	docker rmi shentonfreude/logstash:latest
	rm $<

clean-kibana-image: .kibana-image
	docker rmi shentonfreude/kibana:4b3
	rm $<

# Cleanup crap

remove-dangling:
	docker images -q --filter dangling=true | xargs docker rmi
