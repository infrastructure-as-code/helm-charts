chart = ./redis-cluster
release = red1

create:
	helm install --name $(release) $(chart) \
		--values values.yaml

status:
	helm status $(release)

delete:
	helm delete --purge $(release)
