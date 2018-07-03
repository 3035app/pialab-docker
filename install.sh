#!/usr/bin/env bash

set -ex



if [ -z "${NAME}" ]
then
    NAME=pialab
fi

if [ -z "${BRANCH}" ]
then
   BRANCH=master
fi

if [ -z "${BUILDENV}" ]
then
    BUILDENV="dev"
fi

if [ -d "$(pwd)/var" ]; then
  tar -cvzf "$(date '+%Y-%m-%d').var-backup.tgz"
fi

if [ -n "${RESET}" ]
then
    rm -rf $(pwd)/var
fi

 mkdir -p $(pwd)/var

if [ -n "${ETCDDATA}" ]
then
    ETCDARG="--volume ${ETCDDATA}:/etcd-data"
fi

if [ -n "${POSTGRESDATA}" ]
then
    POSTGRESARG="--volume ${POSTGRESDATA}:/var/lib/postgresql/data"
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

if [ -z "${CREATEUSER}" ]
then
    CREATEUSER=true
fi

# clean
docker rm -f etcd.${NAME}.cnt || echo "Ok"
docker rm -f postgresql.${NAME}.cnt || echo "Ok"
docker rm -f apache.${NAME}.cnt || echo "Ok"
docker network rm ${NAME}.network || echo "Ok"

# create network
docker network create ${NAME}.network

# install etcd
REGISTRY=quay.io/coreos/etcd
docker run -dt --network=${NAME}.network \
       $ETCDARG \
       --name etcd.${NAME}.cnt ${REGISTRY}:v3.1.1 \
       /usr/local/bin/etcd \
       --data-dir=/etcd-data --name node1 \
       --initial-advertise-peer-urls http://0.0.0.0:2380 \
       --listen-peer-urls http://0.0.0.0:2380 \
       --advertise-client-urls http://0.0.0.0:2379 \
       --listen-client-urls http://0.0.0.0:2379

ETCDHOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' etcd.${NAME}.cnt)

# install postgres
DBROOTUSER=postgres
DBROOTPASSWORD=postgres24
docker run -dt --network=${NAME}.network \
       $POSTGRESARG \
       -e POSTGRES_PASSWORD=${DBROOTPASSWORD} \
       --name postgresql.${NAME}.cnt postgres:9.6

DBHOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgresql.${NAME}.cnt)

echo 'var' > .dockerignore

# install ${NAME}
docker rm -f apache.${NAME}.cnt|| echo "Ok"
docker -D build --network=${NAME}.network --build-arg CACHEBUST=$(shuf -n 1 -i 100-1000) \
       --build-arg DBHOST=${DBHOST} --build-arg ETCDHOST=${ETCDHOST} \
       --build-arg FRONTURL=${FRONTURL} --build-arg BACKURL=${BACKURL} \
       --build-arg CREATEUSER=${CREATEUSER} \
       --build-arg BRANCH=${BRANCH} --build-arg NAME=${NAME} \
       --build-arg BUILDENV=${BUILDENV} \
       -f Dockerfile -t ${NAME}.img .
docker run -dt --network=${NAME}.network -p ${SERVERPORT}:80 --name apache.${NAME}.cnt ${NAME}.img
