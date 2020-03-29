SHELL = /bin/bash
chart_name = memstore
chart = .
release = dev
namespace = shards
type ?= redis
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

# https://www.digitalocean.com/community/tutorials/how-to-perform-redis-benchmark-tests
# https://github.com/twitter/twemproxy/blob/master/notes/redis.md
redis-benchmark:
	kubectl run $@ -it --rm --restart="Never" --generator=run-pod/v1 \
		--image=redis:5.0-alpine \
		-- \
		/usr/local/bin/redis-benchmark \
			-h $(release)-$(chart_name).$(namespace) \
			-q \
			-t set,get,incr,lpush,lpop,sadd,spop,lpush,lrange \
			-p 6379 \
			-c 100

# https://redislabs.com/blog/memtier_benchmark-a-high-throughput-benchmarking-tool-for-redis-memcached/
# https://hub.docker.com/r/redislabs/memtier_benchmark
benchmark:
	kubectl run $@ -it --rm --restart="Never" --generator=run-pod/v1 \
		--image=redislabs/memtier_benchmark:edge \
		-- \
		memtier_benchmark \
			--server=$(release)-$(chart_name).$(namespace) \
			--port=$(port) \
			--protocol=$(protocol) \
			--requests=1000

shell:
	kubectl run $@-$$RANDOM -it --rm --restart="Never" --generator=run-pod/v1 \
		--image=redis:5.0-alpine \
		-- \
		/bin/sh
