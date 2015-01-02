# This is naive: the targets don't match the resulting images
# so Make rebuilds each time. We should create markers (e.g.,
#   touch $@
# to indicate success, and remove them with 'clean' targets

build: .logstash-image .kibana-image

.logstash-image: logstash/Dockerfile logstash/logstash.conf
	docker build -t shentonfreude/logstash logstash
	touch $@

.kibana-image: kibana4b3/Dockerfile kibana4b3/kibana.yml
	docker build -t shentonfreude/kibana:4b3 kibana4b3
	touch $@

# .httpd-image:
# 	docker pull httpd:2.4

# build-elasticsearch-image:
# 	docker pull dockerfile/elasticsearch

clean: clean-logstash-image clean-kibana-image

clean-logstash-image: .logstash-image
	docker rmi shentonfreude/logstash:latest
	rm $<


clean-kibana-image: .kibana-image
	docker rmi shentonfreude/kibana:4b3
	rm $<
