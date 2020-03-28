SHELL = /bin/bash
chart = .
release = dev
namespace = shards
type ?= redis
port ?= 6379
protocol ?= redis
values = values-$(type).yaml

update:
	helm upgrade $(release) $(chart) \
		--values $(values) \
		--namespace $(namespace)

create:
	kubectl create namespace $(namespace)
	helm install $(release) $(chart) \
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
			-h $(release)-redis-cluster.$(namespace) \
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
			--server=$(release)-redis-cluster.$(namespace) \
			--port=$(port) \
			--protocol=$(protocol) \
			--requests=1000

shell:
	kubectl run $@-$$RANDOM -it --rm --restart="Never" --generator=run-pod/v1 \
		--image=redis:5.0-alpine \
		-- \
		/bin/sh
