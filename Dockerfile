FROM cassandra:4.1.3

RUN mkdir /prometheus
ADD "https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.20.0/jmx_prometheus_javaagent-0.20.0.jar" /prometheus
RUN chmod 644 /prometheus/jmx_prometheus_javaagent-0.20.0.jar
ADD cassandra.yml /prometheus/cassandra.yml

RUN echo 'JVM_OPTS="$JVM_OPTS -javaagent:/prometheus/jmx_prometheus_javaagent-0.20.0.jar=5556:/prometheus/cassandra.yml"' >> /etc/cassandra/cassandra-env.sh

EXPOSE 5556
