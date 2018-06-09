release-docker:
	cd docker; docker build -t quay.io/solarwinds/fluentd-kubernetes:$(TAG) .
	docker push quay.io/solarwinds/fluentd-kubernetes:$(TAG)
