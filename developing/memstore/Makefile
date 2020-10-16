SHELL = /bin/bash
chart_name = memstore
chart = .
release = dev
namespace = shards
type ?= memcached
values = values-$(type).yaml

ifeq ($(type),memcached)
port = 11211
protocol = memcache_text
else ifeq ($(type),redis)
port = 6379
protocol = redis
endif

update:
	helm upgrade --wait $(release) $(chart) \
		--values $(values) \
		--namespace $(namespace)

create:
	kubectl create namespace $(namespace)
	helm install --wait $(release) $(chart) \
		--values $(values) \
		--namespace $(namespace)

status:
	helm status $(release) \
		--namespace $(namespace)

delete:
	-helm delete --purge $(release)
	-kubectl delete namespace $(namespace)
	-kubectl delete pod benchmark

redis-benchmark:
	kubectl run $@ -it --rm --restart="Never" \
		--image=redis:5.0-alpine \
		-- \
		/usr/local/bin/redis-benchmark \
			-h $(release)-$(chart_name).$(namespace) \
			-q \
			-t set,get,incr,lpush,lpop,sadd,spop,lpush,lrange \
			-p 6379 \
			-c 100

hosts_headless_service = \
	$(release)-$(chart_name)-headless.$(namespace)

hosts_headless_shards = \
	$(release)-$(chart_name)-headless-0.$(release)-$(chart_name)-headless.$(namespace) \
	$(release)-$(chart_name)-headless-1.$(release)-$(chart_name)-headless.$(namespace) \
	$(release)-$(chart_name)-headless-2.$(release)-$(chart_name)-headless.$(namespace)

hosts_proxy_service = \
	$(release)-$(chart_name).$(namespace)

hosts_shards = \
	$(release)-$(chart_name)-shard-0.$(namespace) \
	$(release)-$(chart_name)-shard-1.$(namespace) \
	$(release)-$(chart_name)-shard-2.$(namespace)

benchmark:
	kubectl run $@-$${RANDOM} -it --rm --restart="Never" \
		--image=redislabs/memtier_benchmark:edge \
		-- \
		memtier_benchmark \
			--server=$(host) \
			--port=$(port) \
			--protocol=$(protocol) \
			--requests=1000

benchmark-headless-service:
	$(MAKE) benchmark host=$(release)-$(chart_name)-headless.$(namespace)

benchmark-headless-shards:
	$(MAKE) benchmark host=$(release)-$(chart_name)-headless-0.$(release)-$(chart_name)-headless.$(namespace)
	$(MAKE) benchmark host=$(release)-$(chart_name)-headless-1.$(release)-$(chart_name)-headless.$(namespace)
	$(MAKE) benchmark host=$(release)-$(chart_name)-headless-2.$(release)-$(chart_name)-headless.$(namespace)

benchmark-proxy-service:
	$(MAKE) benchmark host=$(release)-$(chart_name).$(namespace)

benchmark-shards:
	$(MAKE) benchmark host=$(release)-$(chart_name)-shard-0.$(namespace)
	$(MAKE) benchmark host=$(release)-$(chart_name)-shard-1.$(namespace)
	$(MAKE) benchmark host=$(release)-$(chart_name)-shard-2.$(namespace)

benchmarks: benchmark-headless-service benchmark-headless-shards benchmark-proxy-service benchmark-shards

shell:
	kubectl run $@-$$RANDOM -it --rm --restart="Never" \
		--image=redis:5.0-alpine \
		-- \
		/bin/sh
