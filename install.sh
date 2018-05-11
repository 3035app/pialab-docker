#!/usr/bin/env bash

set -ex

if [ -z "${Name}" ]
then
    Name=pialab
fi

if [ -z "${SERVERPORT}" ]
then
    SERVERPORT=8042
fi

if [ -z "${FRONTURL}" ]
then
    FRONTURL="http://localhost:${SERVERPORT}/front"
fi

if [ -z "${BACKURL}" ]
then
    BACKURL="http://localhost:${SERVERPORT}/back"
fi

# clean
docker rm -v -f etcd.${Name}.cnt || echo "Ok"
docker rm -v -f postgresql.${Name}.cnt || echo "Ok"
docker rm -v -f apache.${Name}.cnt || echo "Ok"
docker network rm ${Name}.network || echo "Ok"

# create network
docker network create ${Name}.network

# install etcd
REGISTRY=quay.io/coreos/etcd
docker run -dt --network=${Name}.network \
       --name etcd.${Name}.cnt ${REGISTRY}:v3.1.1 \
       /usr/local/bin/etcd \
       --data-dir=/etcd-data --name node1 \
       --initial-advertise-peer-urls http://0.0.0.0:2380 --listen-peer-urls http://0.0.0.0:2380 \
       --advertise-client-urls http://0.0.0.0:2379 --listen-client-urls http://0.0.0.0:2379 
ETCDHOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' etcd.${Name}.cnt)

# install postgres
DBROOTUSER=postgres
DBROOTPASSWORD=postgres24
docker run -dt --network=${Name}.network -e POSTGRES_PASSWORD=${DBROOTPASSWORD} \
       --name postgresql.${Name}.cnt postgres:9.6
DBHOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgresql.${Name}.cnt)

# install ${Name}
docker rm -f apache.${Name}.cnt|| echo "Ok"
docker -D build --network=${Name}.network --build-arg CACHEBUST=$(shuf -n 1 -i 100-1000) \
       --build-arg DBHOST=${DBHOST} --build-arg ETCDHOST=${ETCDHOST} \
       --build-arg FRONTURL=${FRONTURL} --build-arg BACKURL=${BACKURL} \
       -f Dockerfile -t ${Name}.img .
docker run -dt --network=${Name}.network -p ${SERVERPORT}:80 --name apache.${Name}.cnt ${Name}.img
