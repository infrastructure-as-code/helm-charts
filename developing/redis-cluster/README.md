# MemStore Helm Chart

A Twemproxy-fronted, partitioned in-memory data store backed by Redis or Memcached data shards.

## Description

Have you ever needed a cluster of Redis or Memcached nodes so that you can store all your data in memory?  This chart may be for you.  This chart creates Redis or Memcached data nodes, and optionally, puts [Twemproxy](https://github.com/twitter/twemproxy) proxies in front of the data shards so that the client is none the wiser that it is connecting against a cluster of Redis or Memcached nodes.

  * [Description](#description)
  * [Limitations](#limitations)
  * [Configurations](#configurations)
     * [Proxy-Assisted Parititioning](#proxy-assisted-parititioning)
     * [Client-Side Partitioning](#client-side-partitioning)
     * [Redis Clustering](#redis-clustering)
  * [Chart Values](#chart-values)
  * [Motivation](#motivation)
  * [References](#references)

## Limitations

1. The Redis/Memcached data nodes are deployed without any failover capabilities, so you will experience a short outage for that node before Kubernetes restarts the node.
1. Twemproxy implements only [a subset of Redis and Memcached commands](https://github.com/twitter/twemproxy/tree/master/notes).


## Configurations

This chart can be deployed with a couple of configurations, depending on your use case or preference.

 * [Proxy-Assisted Parititioning](#proxy-assisted-parititioning)
 * [Client-Side Partitioning](#client-side-partitioning)
 * [Redis Clustering](#redis-clustering)

### Proxy-Assisted Parititioning

The proxy-assisted partitioning configuration was the initial goal of this Helm chart.  It creates a StatefulSet of Redis or Memcached data shards, and a Deployment of Twemproxy proxies in front of the data shards so that the clients can use the cluster as one monolithic cluster without being concerned about how the data is sharded.

```
                   +-------+
                   |Clients|
                   +-------+
                       |
                +------+------+
                |             |
           +---------+   +---------+
           |Twemproxy|   |Twemproxy|
           +---------+   +---------+
                |             |
   +---------+--+------+------+--+---------+
   |         |         |         |         |
+-----+   +-----+   +-----+   +-----+   +-----+
|Shard|   |Shard|   |Shard|   |Shard|   |Shard|
+-----+   +-----+   +-----+   +-----+   +-----+
```

**Configuration Values**

The following sample configuration creates 3 Redis data shards and 3 Twemproxy proxy instances, and exposes the proxies via a `LoadBalancer` service.

```
shards:
  type: redis
  isRedis: true
  count: 5
  image:
    repository: redis:5.0-alpine
    pullPolicy: IfNotPresent
  service:
    port: 6379

proxy:
  enabled: true
  count: 2
  image:
    repository: softonic/twemproxy:0.4.1
    pullPolicy: IfNotPresent
  service:
    type: LoadBalancer
    port: 6379
```

**Pros & Cons**

1. Twemproxy only supports a subset of Redis & Memcached commands. (Supported [Memcached commands](https://github.com/twitter/twemproxy/blob/master/notes/memcache.md) and [Redis commands](https://github.com/twitter/twemproxy/blob/master/notes/redis.md).)
1. Clients can treat the cluster as a single instance without knowing about the shards, or in the case of Redis, needing a client that supports [Redis Cluster](https://redis.io/topics/cluster-tutorial).
1. Adds an extra hop (via the proxy), so there will be a performance hit.
1. The proxy adds one more moving piece to the architecture.


### Client-Side Partitioning

Client-side partitioning is probably the most basic configuration with multiple independent data nodes that aren't aware of each other.  With this configuration, the client will be responsible for sharding the data across all the data nodes.

```
                   +-------+
                   |Clients|
                   +-------+
                       |
   +---------+---------+---------+---------+
   |         |         |         |         |
+-----+   +-----+   +-----+   +-----+   +-----+
|Shard|   |Shard|   |Shard|   |Shard|   |Shard|
+-----+   +-----+   +-----+   +-----+   +-----+
```

**Configuration Values**

```
shards:
  type: redis
  isRedis: true
  count: 5
  image:
    repository: redis:5.0-alpine
    pullPolicy: IfNotPresent
  service:
    port: 6379

proxy:
  enabled: false
```

**Pros & Cons**

1. This configuration does not expose any service outside of Kubernetes, and requires applications to connect to the data shards directly via the [headless](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) created internally.
1. Sharding needs to be handled by the clients.
1. It's a really simple setup.


### Redis Clustering

This is the native [Redis Clustering](https://redis.io/topics/cluster-tutorial) feature that comes with Redis.


```
                   +-------+
                   |Clients|
                   +-------+
                       |
   +---------+---------+---------+---------+
   |         |         |         |         |
+-----+   +-----+   +-----+   +-----+   +-----+
|Shard|---|Shard|---|Shard|---|Shard|---|Shard|
+-----+   +-----+   +-----+   +-----+   +-----+
```

**Configuration Values**

```
enableRedisCluster: true

shards:
  type: redis
  isRedis: true
  count: 5
  image:
    repository: redis:5.0-alpine
    pullPolicy: IfNotPresent
  service:
    port: 6379

proxy:
  enabled: false
```


## Chart Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cluster.domain | string | `"cluster.local"` | the Kubernetes cluster domain |
| enableRedisCluster | bool | `false` |  |
| fullnameOverride | string | `""` | Fullname override |
| nameOverride | string | `""` | Override the chart name |
| podSecurityContext | object | `{}` |  |
| proxy.count | int | `3` | number of replicas of the proxy |
| proxy.enabled | bool | `true` | is the problem to be enabled? |
| proxy.image.pullPolicy | string | `"IfNotPresent"` |  |
| proxy.image.repository | string | `"softonic/twemproxy:0.4.1"` |  |
| proxy.livenessProbe.enabled | bool | `true` |  |
| proxy.livenessProbe.failureThreshold | int | `5` |  |
| proxy.livenessProbe.initialDelaySeconds | int | `5` |  |
| proxy.livenessProbe.periodSeconds | int | `5` |  |
| proxy.livenessProbe.successThreshold | int | `1` |  |
| proxy.livenessProbe.timeoutSeconds | int | `5` |  |
| proxy.readinessProbe.enabled | bool | `true` |  |
| proxy.readinessProbe.failureThreshold | int | `5` |  |
| proxy.readinessProbe.initialDelaySeconds | int | `5` |  |
| proxy.readinessProbe.periodSeconds | int | `5` |  |
| proxy.readinessProbe.successThreshold | int | `1` |  |
| proxy.readinessProbe.timeoutSeconds | int | `1` |  |
| proxy.resources | object | `{}` |  |
| proxy.service.port | int | `6379` | the port to expose the service on |
| proxy.service.type | string | `"ClusterIP"` | ClusterIP, NodePort or LoadBalancer |
| securityContext | object | `{}` |  |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `false` | Specifies whether a service account should be created |
| serviceAccount.name | string | `nil` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| shards.count | int | `3` | number of data shards |
| shards.image.pullPolicy | string | `"IfNotPresent"` |  |
| shards.image.repository | string | `"redis:5.0-alpine"` |  |
| shards.isRedis | bool | `true` | are we using Redis data shards? |
| shards.livenessProbe.enabled | bool | `true` | enable Kubernetes liveness probe |
| shards.livenessProbe.failureThreshold | int | `5` | Number of failures to accept before giving up and marking the pod as Unready. |
| shards.livenessProbe.initialDelaySeconds | int | `5` | Number of seconds after the container has started before the probe is initiated. |
| shards.livenessProbe.periodSeconds | int | `5` | How often (in seconds) to perform the probe. |
| shards.livenessProbe.successThreshold | int | `1` | Minimum consecutive successes for the probe to be considered successful after having failed. |
| shards.livenessProbe.timeoutSeconds | int | `5` | Number of seconds after which the probe times out. |
| shards.readinessProbe.enabled | bool | `true` | enable Kubernetes readiness probe |
| shards.readinessProbe.failureThreshold | int | `5` | Number of failures to accept before giving up and marking the pod as Unready. |
| shards.readinessProbe.initialDelaySeconds | int | `5` | Number of seconds after the container has started before the probe is initiated. |
| shards.readinessProbe.periodSeconds | int | `5` | How often (in seconds) to perform the probe. |
| shards.readinessProbe.successThreshold | int | `1` | Minimum consecutive successes for the probe to be considered successful after having failed. |
| shards.readinessProbe.timeoutSeconds | int | `1` | Number of seconds after which the probe times out. |
| shards.resources | object | `{}` |  |
| shards.service.port | int | `6379` | the ClusterIP port for the sevice to listen on within the cluster |
| shards.type | string | `"redis"` | `redis` or `memcached` data shard |

## Motivation

This chart was first conceived when the author ran into a situation where a >300GB data set had to be cached in Redis, but the only machines available were Kubernetes worker nodes with 64GB of RAM each, while client application was hosted outside of the Kubernetes environment.

[Sharding](https://www.digitalocean.com/community/tutorials/understanding-database-sharding) across multiple worker nodes was the obvious choice, but the Redis Helm charts ([stable/redis](https://github.com/helm/charts/tree/master/stable/redis), [stable/redis-ha](https://github.com/helm/charts/tree/master/stable/redis-ha), and [bitnami/redis](https://github.com/bitnami/charts/tree/master/bitnami/redis)) from the popular sources did not manage shards, so the author decided to take a shot at creating one.


## References

1. https://stackoverflow.com/questions/57023084/how-to-get-a-pod-index-inside-a-helm-chart
1. https://itnext.io/exposing-statefulsets-in-kubernetes-698730fb92a1
1. https://github.com/helm/helm/issues/4982
1. https://github.com/helm/helm/issues/1311
1. https://dev.to/kaoskater08/building-a-headless-service-in-kubernetes-3bk8
1. http://highscalability.com/blog/2014/9/8/how-twitter-uses-redis-to-scale-105tb-ram-39mm-qps-10000-ins.html
1. https://www.digitalocean.com/community/tutorials/how-to-perform-redis-benchmark-tests
1. https://github.com/twitter/twemproxy/blob/master/notes/redis.md
1. https://redislabs.com/blog/memtier_benchmark-a-high-throughput-benchmarking-tool-for-redis-memcached/
1. https://hub.docker.com/r/redislabs/memtier_benchmark
1. https://code.flickr.net/2015/07/10/optimizing-caching-twemproxy-and-memcached-at-flickr/
1. https://tech.wayfair.com/2015/03/scaling-redis-and-memcached-at-wayfair/
1. https://redis.io/topics/partitioning
1. https://engineering.fb.com/web/introducing-mcrouter-a-memcached-protocol-router-for-scaling-memcached-deployments/
1. http://parasmalik.blogspot.com/2018/10/twemproxy-vs-rediscluster-for-high.html
1. https://tech.trivago.com/2017/01/25/learn-redis-the-hard-way-in-production/
1. https://github.com/helm/charts/tree/master/stable/redis
1. https://github.com/helm/charts/tree/master/stable/redis-ha
1. https://github.com/bitnami/charts/tree/master/bitnami/redis
