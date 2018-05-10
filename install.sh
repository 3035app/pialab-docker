#!/usr/bin/env bash

set -ex

if [ -z "${FRONTURL}" ]
then
 FRONTURL='http://localhost:8042/front'
fi

if [ -z "${BACKURL}" ]
then
 BACKURL='http://localhost:8042/back'
fi

# clean
docker rm -v -f etcd.for.pia.cnt || echo "Ok"
docker rm -v -f postgresql.for.pia.cnt || echo "Ok"
docker rm -v -f apache.for.pia.cnt || echo "Ok"
docker network rm pia.network || echo "Ok"

# create network
docker network create pia.network

# install etcd
REGISTRY=quay.io/coreos/etcd
docker run -dt --network=pia.network \
       --name etcd.for.pia.cnt ${REGISTRY}:v3.1.1 \
       /usr/local/bin/etcd \
       --data-dir=/etcd-data --name node1 \
       --initial-advertise-peer-urls http://0.0.0.0:2380 --listen-peer-urls http://0.0.0.0:2380 \
       --advertise-client-urls http://0.0.0.0:2379 --listen-client-urls http://0.0.0.0:2379 
ETCDHOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' etcd.for.pia.cnt)

# install postgres
DBROOTUSER=postgres
DBROOTPASSWORD=postgres24
docker run -dt --network=pia.network -e POSTGRES_PASSWORD=${DBROOTPASSWORD} \
       --name postgresql.for.pia.cnt postgres:9.6
DBHOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgresql.for.pia.cnt)

# install pia
docker rm -f apache.for.pia.cnt|| echo "Ok"
docker -D build --network=pia.network --build-arg CACHEBUST=$(shuf -n 1 -i 100-1000) \
       --build-arg DBHOST=${DBHOST} --build-arg ETCDHOST=${ETCDHOST} \
       --build-arg FRONTURL=${FRONTURL} --build-arg BACKURL=${BACKURL} \
       -f Dockerfile -t pia.img .
docker run -dt --network=pia.network -p 8042:80 --name apache.for.pia.cnt pia.img
