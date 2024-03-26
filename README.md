
# Cassandra Docker image including Prometheus JMX exporter

Sometimes, you need to monitor Cassandra metrics and tune cluster. This Docker image can help you to do that.

This project contains Docker image to monitor Cassandra using Prometheus jmx_exporter.
This setup is running on Kubernetes cluster.

Cassandra exposes metric endpoint at `http://ip:5556/metrics`.

**Background:** there is 2 ways how we can monitor Cassandra:
1)[jmx_exporter](https://github.com/prometheus/jmx_exporter)
2)cassandra_exporter(there is multiple forks, [this](https://github.com/instaclustr/cassandra-exporter) is just a one example)

I have chosen the first option because:
- jmx_exporter is still growing and developing by the community
- it supports mostly all versions of Cassandra

Tested with versions:
Cassandra v.4.1.3
Prometheus v.2.49.1
Grafana v.10.3.1

### Premetheus setup

Dont forget to configure Prometheus scrapping endpoint and open K8 Service port. 

To tell Prometheus where metrics are located - add `annotation` configs to Cassandra Kubernetes POD:

```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: test-cassandra
  labels:
    app: cassandra
    chart: cassandra-0.15.4
    release: test-release
    heritage: Helm
spec:
  selector:
    matchLabels:
      app: cassandra
      release: test-release
  serviceName: cassandra-service-test
  replicas: 3
  podManagementPolicy: OrderedReady
  updateStrategy:
    type: OnDelete
  template:
    metadata:
      labels:
        app: cassandra
        release: test-release
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "5556"
...
```

### Grafana dashboard

Download .json or import by URL [this](https://grafana.com/grafana/dashboards/5408-cassandra/) dashboard

### Build docker image

To build and tag image on MAC M1- run command from terminal: 
`docker buildx build --platform linux/amd64 -t "my-cassandra-jmx-metrics:1.0" .`

Verify that image was built:
`docker images`

### Possible Issues

##### java.net.BindException: Address already in use
Current Docker image contains fix for "Caused by: java.net.BindException: Address already in use". 
Fix details: you need to forward $JVM_OPTS into cassandra-env.sh

Exception example:

```
Exception in thread "main" java.lang.reflect.InvocationTargetException
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at sun.instrument.InstrumentationImpl.loadClassAndStartAgent(InstrumentationImpl.java:386)
	at sun.instrument.InstrumentationImpl.loadClassAndCallPremain(InstrumentationImpl.java:401)
Caused by: java.net.BindException: Address already in use
	at sun.nio.ch.Net.bind0(Native Method)
	at sun.nio.ch.Net.bind(Net.java:461)
	at sun.nio.ch.Net.bind(Net.java:453)
	at sun.nio.ch.ServerSocketChannelImpl.bind(ServerSocketChannelImpl.java:222)
	at sun.nio.ch.ServerSocketAdaptor.bind(ServerSocketAdaptor.java:85)
	at sun.net.httpserver.ServerImpl.<init>(ServerImpl.java:100)
	at sun.net.httpserver.HttpServerImpl.<init>(HttpServerImpl.java:50)
	at sun.net.httpserver.DefaultHttpServerProvider.createHttpServer(DefaultHttpServerProvider.java:35)
	at com.sun.net.httpserver.HttpServer.create(HttpServer.java:130)
	at io.prometheus.jmx.shaded.io.prometheus.client.exporter.HTTPServer.<init>(HTTPServer.java:179)
	at io.prometheus.jmx.shaded.io.prometheus.jmx.JavaAgent.premain(JavaAgent.java:31)
	... 6 more
```

##### Problems with importing Grafana dash
After the import process, no visualization shows the data. 

- Problem was in wrong populated "Instance" dropdown on the top of dash. My Cassandra k8 POD labels 
didnt match predefined pattern. You can fix this from Grafana UI: Dashboard Settings -> Variables -> Instance
- During import process Prometheus datasource wasnt overrided. Fix: change in dashboard.json
```
"datasource": {
            "uid": "Prometheus Data"
          }
```
to
```
"datasource": {}
```
OR use default Prometheus datasource.
