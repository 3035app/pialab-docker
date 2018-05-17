# Install Pialab without Docker

## Purpose

This is a 'How To' install Pialab without Docker.

It is based on the content of the Dockerfile: https://github.com/pia-lab/pialab-docker/blob/master/Dockerfile

You may want to read it as an example implentation of this document.

## Prerequis

Before start the installation. You should have installed and configured the following element:

- A Linux Apache Server with PHP 7.1
- A PostgresSQL server with a database and a user dedicated to Pialab (PostgresSQL 9.6 Recomended)
- Composer installed : https://getcomposer.org/
- Nvm installed: https://github.com/creationix/nvm

## Pialab-Back Installation

You should read the complete documentation about pialab-back https://github.com/pia-lab/pialab-back/

Here is a quick start guide.

### Clone the github repository

```bash
git clone https://github.com/pia-lab/pialab-back.git
```

It should be cloned in a directory accesible by your Apache Server

### Edit environment file

Copy .env.dist to .env and open it in your favorite text editor.

```bash
cd pialab-back
cp .env.dist .env
```

You need some information about your database and update of the following variable as they are mandatory:

```bash
DBHOST=< localhost or postgreSQL server adress >
DBNAME=< database name (ex: pialab)>
DBUSER=< database user name (ex: pialabuser)>
DBPASSWORD=< database user name (ex: 1234)>
```

You should check and update other variable too...

### Install dependancy

```bash
./bin/ci-scripts/install.sh
```
It will download all the symfony dependency of the pialab-back project

### Create Database Schema

```bash
./bin/ci-scripts/create_schema.sh
```
It will create and/or update the PostgresSql schema

### Create User

```bash
 ./bin/ci-scripts/create_user.sh
```
It will create a super admin named lici@pialab.io with pia42 as password.
You may want to edit the script to change the default password ...

### Create Application Secret

```bash
export CLIENTURL="http://localhost:4200"
 ./bin/ci-scripts/create_client_secret.sh
```
CLIENTURL: is the future adresse of your pialab-front app.

Next, run:
```bash
cat .api.env
```
And get the value of the two variable : APICLIENTID & APICLIENTSECRET.
They will be used in the pialab-front configuration.

### Post Install

```bash
./bin/ci-scripts/post_install.sh
```
It will copy asset (image and css) in the good directory

### Configure apache

You may configure a virtual host on your apache server to use pialab-back/public as DocumentRoot.

Or copy https://github.com/pia-lab/pialab-docker/blob/master/apache/pialab.back.conf as /etc/apache2/conf-enabled/pialab.back.conf

And of course restart your apache server after configuration update.

### Go to admin Panel

Open firefox and go to your Pialab-back url.
Example: http://localhost/back

You should login with the super admin lici@pialab.io created in previous step "Create User" and add a new user for your Pialab-front app.



## Pialab-Front Installation

You should read the complete documentation about pialab-back https://github.com/pia-lab/pialab/

Here is a quick start guide.

### Install Node and Angular


```bash
export NVM_DIR="${HOME}/.nvm"
. "${NVM_DIR}/nvm.sh"
nvm install 8.11.1
npm install -g @angular/cli
```
NVM_DIR should be set to location where nvm is installed

### Clone the github repository


```bash
git clone https://github.com/pia-lab/pialab.git
```

It should be cloned in a directory accesible by your Apache Server

### Edit environment file

With your favorite text editor, update the api part of this file : src/environments/environment.ts

```javascript
 api: {
    client_id:     '1_49i8o287f8kk00840cg4ggkws0o0g44ocsogkc0w0g84o80co4',
    client_secret: '22zpxqpr0r40wo0g8kw00k4kccg0wwkso8ccc0ogsgwogcssss',
    host:          'http://localhost:8001',
    token_path:    '/oauth/v2/token'
},
```

Replace client_id and client_secret with the value from previous step "Create Application Secret"

Replace host by the url of you Pialab-back installation.

### Install dependancy

```bash
./bin/ci-scripts/install.sh
```

It will install node module needed by the Pialab-front app. You must have NVM_DIR set before running this script.

### Build

```bash
./bin/ci-scripts/build.sh
```

It will create the distribuable archive of the angular app. You must have NVM_DIR set before running this script.

### Configure apache

You may configure a virtual host on your apache server to use pialab/dist as DocumentRoot.

Or copy https://github.com/pia-lab/pialab-docker/blob/master/apache/pialab.front.conf as /etc/apache2/conf-enabled/pialab.front.conf

And of course restart your apache server after configuration update.

### Go to Pialab

Open firefox and go to your Pialab-back url.
Example: http://localhost/front

You should login with the user created in the Pialab-back GUI.

## Please report any bug to :

https://github.com/pia-lab/pialab and/or https://github.com/pia-lab/pialab-back
