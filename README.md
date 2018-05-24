# Pialab-docker

## Purpose

This is for demo and dev only, please do not use it on production server !

## Requirements

Have docker installed and well configured on you favorite linux distribution

## Installation

```bash
git clone https://github.com/pia-lab/pialab-docker.git
cd pialab-docker
./install.sh

```

While it install everything, please be patient and have a drink

## Create a user in backend

Open firefox and go to http://localhost:8042/back

Login as lici@pialab.io / pia42

Create a new user (or not)

## Login in Pialab

Open firefox and go to http://localhost:8042/front

Login with the new created user (lici@pialab.io account will not work on the front part as it is an admin of the back)

Start using Pialab (or not)

## Please report any bug to :

https://github.com/pia-lab/pialab and/or https://github.com/pia-lab/pialab-back

## Environement Variable

Some variable change the installation process

### ${NAME}

Default NAME=pialab

It used for various isolation tricks, like container name, database user and more ...

### ${BRANCH}

Default BRANCH=master

It the git branch where to get pialab and pialab-back.
It can also be a tag like : BRANCH=0.4.2

### ${BUILDENV}

Default BUILDENV="dev"

It is the environement for build symfony and angular app.

It can be set to "prod" to change installation command behaviour like "ng build" or "bin/console cache:clear" ...

### ${ETCDDATA}

Default ETCDDATA="$(pwd)/var/${NAME}-etcd-data"

Local directory where etcd data are stored . (You should not need it)

### ${POSTGRESDATA}

Default  POSTGRESDATA="$(pwd)/var/${NAME}-postgres-data"

Local directory where postgresql data are stored. (You may need it if you want to save or move them)

### ${SERVERPORT}

Default SERVERPORT=8042

The docker rediction to container port 80

### ${FRONTURL}

Default FRONTURL="http://localhost:${SERVERPORT}/front"

The pialab url, it used when pialba-back build as paramater.

It must be the future url where you will use the front office app

### ${BACKURL}

Default BACKURL="http://localhost:${SERVERPORT}/back"

The pialab-back url, it used when pialba build as paramater.

It must be the future url where you will use the back office app

### ${CREATEUSER}

Default CREATEUSER=true

Used to enable or disable default user creation (lici@pialab.io and api@pialab.io).

It is usefull to set it to false if you want to re-use the same postgresql database several time (to avoid try to create several time the same user)

Warning if you set it to false you will have to connect to the docker container and create user with symfony command

### Example

```bash
export SERVERPORT=8042
export FRONTURL=http://demo.pialab.io:$SERVERPORT/front
export BACKURL=http://demo.pialab.io:$SERVERPORT/back
export NAME=demo.pialab
export ETCDDATA=$(pwd)/var/etcd-data
export POSTGRESDATA=$(pwd)/var/postgres-data
export CREATEUSER=true
export BUILDENV=prod
git clone https://github.com/pia-lab/pialab-docker.git
cd pialab-docker
./install.sh

```
