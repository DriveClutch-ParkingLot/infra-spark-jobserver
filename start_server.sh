#!/bin/bash
docker run -v `pwd`/jobs/:/opt/spark/jobs/ -d -p 8091:8090 --net=spark driveclutch/infra-spark-jobserver
