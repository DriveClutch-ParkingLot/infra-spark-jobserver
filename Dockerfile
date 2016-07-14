FROM anapsix/alpine-java:jdk8

MAINTAINER Sang Venkatraman <sang@driveclutch.com>

USER root
WORKDIR /

RUN apk update && apk upgrade && \
apk add curl git

ENV SBT_VERSION 0.13.11
ENV SCALA_VERSION 2.11.8
ENV SPARK_VERSION 1.6.2
ENV SPARK_JOBSERVER_BRANCH master
ENV SPARK_VERSION_STRING spark-$SPARK_VERSION-bin-hadoop2.6
ENV SPARK_DOWNLOAD_URL http://d3kbcqa49mib13.cloudfront.net/$SPARK_VERSION_STRING.tgz

ENV SPARK_JOBSERVER_BUILD_HOME /spark-jobserver
ENV SPARK_JOBSERVER_APP_HOME /app
RUN git clone --branch $SPARK_JOBSERVER_BRANCH https://github.com/spark-jobserver/spark-jobserver.git
RUN mkdir -p $SPARK_JOBSERVER_APP_HOME

#sbt installation
#RUN mkdir -p /usr/local/bin && wget -P /usr/local/bin/ http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch/$SBT_VERSION/sbt-launch.jar && ls /usr/local/bin
#COPY sbt /usr/local/bin/

WORKDIR /opt
RUN wget http://dl.bintray.com/sbt/native-packages/sbt/0.13.11/sbt-0.13.11.tgz && \
tar zxvf sbt-0.13.11.tgz
ENV PATH="/opt/sbt/bin/:$PATH"
RUN echo "$PATH"
#RUN mv /opt/sbt-0.13.11/bin/sbt /usr/local/bin/sbt

# Build Spark-Jobserver
WORKDIR $SPARK_JOBSERVER_BUILD_HOME
RUN bin/server_deploy.sh docker && \
    cd / && \
    rm -rf -- $SPARK_JOBSERVER_BUILD_HOME

WORKDIR /opt/
RUN wget http://mirror.stjschools.org/public/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz && \
tar zxvf apache-maven-3.3.9-bin.tar.gz
RUN export PATH="/opt/apache-maven-3.3.9/bin:$PATH"
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
