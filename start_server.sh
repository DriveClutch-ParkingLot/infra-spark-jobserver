#!/bin/bash
docker run -d -p 8090:8090 --net=spark driveclutch/infra-spark-jobserver
