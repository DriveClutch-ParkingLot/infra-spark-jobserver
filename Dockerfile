FROM driveclutch/alpine-java:1.0

MAINTAINER Sang Venkatraman <sang@driveclutch.com>

USER root
WORKDIR /opt/

RUN apk update && apk upgrade && \
apk add curl

#RUN export MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m"


ENV JOBSERVER_MEMORY="1G"

RUN ["mkdir", "-p", "\/database"]
RUN wget http://d3kbcqa49mib13.cloudfront.net/spark-1.6.2.tgz && \
tar zxvf spark-1.6.2.tgz
WORKDIR spark-1.6.2
RUN dev/change-scala-version.sh 2.11
RUN ./make-distribution.sh "-Phadoop-2.6 -Dscala-2.11 -Phive"

cd /opt
RUN mv spark-1.6.2/dist /opt/spark && \
rm spark-1.6.2.tgz && \
rm -r spark-1.6.2
VOLUME ["\/database"]

RUN mkdir /opt/spark/app
WORKDIR /opt/spark
COPY app/spark-job-server.jar app/spark-job-server.jar
COPY app/server_start.sh app/server_start.sh
COPY app/server_stop.sh app/server_stop.sh
COPY app/manager_start.sh app/manager_start.sh
COPY app/setenv.sh app/setenv.sh
COPY app/log4j-stdout.properties app/log4j-server.properties
COPY app/docker.conf app/docker.conf
COPY app/docker.sh app/settings.sh

ENV SPARK_HOME="/opt/spark"

ENTRYPOINT ["app\/server_start.sh"]
