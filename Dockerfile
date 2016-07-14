FROM anapsix/alpine-java:jdk8

MAINTAINER Sang Venkatraman <sang@driveclutch.com>

USER root
WORKDIR /opt/

RUN apk update && apk upgrade && \
apk add curl

#RUN export MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m"

RUN wget http://mirror.stjschools.org/public/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz && \
tar zxvf apache-maven-3.3.9-bin.tar.gz
RUN PATH="/opt/apache-maven-3.3.9/bin:$PATH"
ENV JOBSERVER_MEMORY="2G"

RUN ["mkdir", "-p", "\/database"]
RUN wget http://d3kbcqa49mib13.cloudfront.net/spark-1.6.2.tgz && \
tar zxvf spark-1.6.2.tgz
WORKDIR spark-1.6.2
RUN ./dev/change-scala-version.sh 2.11
RUN ./make-distribution.sh  --name spark-1.6.2-hadoop-2.6.2-scala-2.11 --mvn /opt/apache-maven-3.3.9/bin/mvn -Phadoop-2.6 -Dhadoop.version=2.6.2 -Dscala-2.11 -Phive

WORKDIR /opt/
RUN mv spark-1.6.2/dist /spark && \
rm spark-1.6.2.tgz && \
rm -r spark-1.6.2
VOLUME ["\/database"]

RUN mkdir /opt/spark/app
WORKDIR spark
COPY app/spark-job-server.jar app/spark-job-server.jar
COPY app/server_start.sh app/server_start.sh
COPY app/server_stop.sh app/server_stop.sh
COPY app/manager_start.sh app/manager_start.sh
COPY app/setenv.sh app/setenv.sh
COPY app/log4j-stdout.properties app/log4j-server.properties
COPY app/docker.conf app/docker.conf
COPY app/docker.sh app/settings.sh

ENV SPARK_HOME="/spark"

ENTRYPOINT ["app\/server_start.sh"]
