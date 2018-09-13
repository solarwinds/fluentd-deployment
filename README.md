# fluentd-deployment
Fluentd deployment manifests for integration with Loggly and Papertrail.

## Description

This repository contains Docker and Kubernetes assets for deploying a combined Fluentd Papertrail & Loggly log-aggregation toolset to your environment.

## Kubernetes

The Kubernetes DaemonSet yaml files [in this repo](https://github.com/solarwinds/fluentd-deployment/blob/master/kubernetes/) are preconfigured to work with Loggly or Papertrail.

By default they will generate log records from all running pods and any journald services running on the host machines.

To deploy this plugin as a DaemonSet to your Kubernetes cluster, simply adjust the `FLUENT_*` environment variables in `kubernetes/fluentd-daemonset-papertrail.yaml` or `kubernetes/fluentd-daemonset-loggly.yaml` and push it to your cluster with:

```
kubectl apply -f kubernetes/fluentd-daemonset-(papertrail,loggly).yaml
```

The Docker [image](https://quay.io/repository/solarwinds/fluentd-kubernetes) that's used in the DaemonSet is buillt from `docker/Dockerfile` in this repo.

If you're deploying this to a cluster with RBAC and to a namespace where you need to explicitly spell out your RBAC privileges, reference this snippet for a ServiceAccount below. You'll need to explicitly attach this ServiceAccount to the DaemonSet above:

```
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: fluentd-logging
rules:
  - apiGroups:
      - ""
    resources:
      - namespaces
      - pods
    verbs:
      - get
      - list
      - watch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: fluentd-logger
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: fluentd-logging
subjects:
- kind: ServiceAccount
  name: fluentd-logging
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluentd-logging
  namespace: kube-system
---
```

## Advanced Usage

### Kubernetes Annotations

**Papertrail**

Once the DaemonSet is running on your cluster, you can redirect logs to alternate Papertrail destinations by adding annotations to your Pods or Namespaces:

```
solarwinds.io/papertrail_host: 'logs0.papertrailapp.com'
solarwinds.io/papertrail_port: '12345'
```

If both the Pod and Namespace have annotations for any running Pod, the Pod's annotation is used.

**Loggly**

Once the DaemonSet is running on your cluster, you can redirect logs to alternate Loggly destinations by adding annotations to your Pods or Namespaces:

```
solarwinds.io/loggly_token: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
```

If both the Pod and Namespace have annotations for any running Pod, the Pod's annotation is used.

### Kubernetes Audit Logs

If you'd like to redirect Kubernetes API Server Audit logs to a seperate Papertrail or Loggly destination, add a second match statement to your `fluent.conf`:
```
<match kube-apiserver-audit>
    type papertrail
    num_threads 4

    papertrail_host "#{ENV['FLUENT_PAPERTRAIL_AUDIT_HOST']}"
    papertrail_port "#{ENV['FLUENT_PAPERTRAIL_AUDIT_PORT']}"
</match>
```

This requires you to configure an [audit policy file](https://kubernetes.io/docs/tasks/debug-application-cluster/audit/) on your cluster.

### Docker Details

The fluentd process expects a fluentd configuration file at: `/fluentd/etc/fluent.conf`

The Docker image bundles a default `fluent.conf` as well as other import-able fluentd config files.

The Kubernetes assets are a good example of overriding the default `fluent.conf` and importing configurations for things such as gathering pod logs from kubernetes or journald logs from systemd.

**Plugins**

This Docker image bundles the following (optional) fluentd plugins:
- [fluent-plugin-papertrail](https://github.com/solarwinds/fluent-plugin-papertrail)
- [fluent-plugin-loggly-syslog](https://github.com/solarwinds/fluent-plugin-loggly-syslog)
- [fluent-plugin-systemd](https://github.com/reevoo/fluent-plugin-systemd)
- [fluent-plugin-kubernetes_metadata_input](https://github.com/ViaQ/fluent-plugin-kubernetes_metadata_input)
- [fluent-plugin-kubernetes_metadata_filter](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter)

The papertrail plugin allows us to treat Papertrail accounts as outputs.

The loggly-syslog plugin allows us to treat Loggly accounts as outputs using the syslog protocol.

The systemd plugin allows us to treat a host's journald logs as fluent input. The image is based on Debian, so that we can easily bundle the required systemd libraries.

The kubernetes_metadata_input plugin lets us treat the Kubernetes Event API as fluent input.

The kubernetes_metadata_filter plugin lets us recognize and bind Kubernetes specific metadata to logs from Kubernetes pods.

## Development

We have a [Makefile](Makefile) to wrap common functions and make life easier.

### Release in [Quay.io](https://quay.io/repository/solarwinds/fluentd-kubernetes)

`make release-docker TAG=$(VERSION)`

## Contributing

Bug reports and pull requests are welcome on GitHub at: https://github.com/solarwinds/fluentd-deployment

# Questions/Comments?

Please [open an issue](https://github.com/solarwinds/fluentd-deployment/issues/new), we'd love to hear from you. As a SolarWinds Innovation Project, this adapter is supported in a best-effort fashion.
