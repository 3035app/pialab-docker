FROM debian:stable

#######################
#### UPDATE DEBIAN ####
#######################

RUN apt-get update && apt-get install -y apt-transport-https lsb-release ca-certificates net-tools lsof postgresql-client wget \
    && apt-get install -y git curl build-essential unzip \
    && apt-get install -y dnsutils vim-nox emacs-nox\
    && apt-get autoremove -y && apt-get clean

#####################
#### INSTALL PHP ####
#####################
ARG PHPVER=7.2
RUN echo "deb http://ftp.debian.org/debian $(lsb_release -sc)-backports main" >> /etc/apt/sources.list \
    && apt-get update \
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
    && apt-get update \
    && apt-get install -y php${PHPVER} php${PHPVER}-cli php${PHPVER}-pgsql php${PHPVER}-mysql php${PHPVER}-curl php${PHPVER}-json php${PHPVER}-gd php${PHPVER}-intl php${PHPVER}-sqlite3 php${PHPVER}-gmp php${PHPVER}-geoip php${PHPVER}-mbstring php${PHPVER}-redis php${PHPVER}-xml php${PHPVER}-zip \
    && if [ ! '7.2' = $PHPVER ]; then apt-get install --no-install-recommends -y php${PHPVER}-mcrypt; fi \
    && apt-get autoremove -y && apt-get clean

RUN echo "phar.readonly = Off" >> /etc/php/${PHPVER}/cli/conf.d/42-phar-readonly.ini \
    && echo "memory_limit=-1" >> /etc/php/${PHPVER}/cli/conf.d/42-memory-limit.ini \
    && echo "date.timezone=Europe/Paris" >> /etc/php/${PHPVER}/cli/conf.d/68-date-timezone.ini

########################
#### INSTALL APACHE ####
########################
RUN apt-get install -y apache2 apache2-utils libapache2-mod-php${PHPVER} \
    && apt-get autoremove -y && apt-get clean

RUN a2enmod headers && a2enmod rewrite && a2dismod mpm_event && a2enmod mpm_prefork && a2enmod php${PHPVER}
RUN echo "memory_limit=-1" >> /etc/php/${PHPVER}/apache2/conf.d/42-memory-limit.ini \
    && echo "date.timezone=Europe/Paris" >> /etc/php/${PHPVER}/apache2/conf.d/68-date-timezone.ini
RUN sed -i -e s/'php_admin_flag engine Off'/'php_admin_flag engine On'/g /etc/apache2/mods-enabled/php${PHPVER}.conf

RUN apache2ctl configtest

RUN echo '<?php phpinfo(); ?>' > /var/www/html/phpinfo.php && chmod 755 /var/www/html/phpinfo.php && chown www-data:www-data /var/www/html/phpinfo.php

##########################
#### INSTALL COMPOSER ####
##########################
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && chmod 755 /usr/local/bin/composer

#######################
#### INSTALL CONFD ####
#######################
ARG CONFDVER=0.15.0
RUN wget -q https://github.com/kelseyhightower/confd/releases/download/v${CONFDVER}/confd-${CONFDVER}-linux-amd64 -O /usr/local/bin/confd \
    && chmod 755 /usr/local/bin/confd \
    && mkdir -p /etc/confd/conf.d \
    && mkdir -p /etc/confd/templates

######################
#### INSTALL ETCD ####
######################
ARG ETCDVER=3.3.1
RUN wget -q https://github.com/coreos/etcd/releases/download/v${ETCDVER}/etcd-v${ETCDVER}-linux-amd64.tar.gz -O /tmp/etcd.tar.gz \
    && tar -xzf /tmp/etcd.tar.gz -C /tmp \
    && mv /tmp/etcd-v${ETCDVER}-linux-amd64/etcd* /usr/local/bin/ \
    && chmod 755 /usr/local/bin/etcd* \
    && rm -rf /tmp/etcd*

ENV ETCDCTL_API=3
ARG ETCDHOST=localhost

#####################
#### CREATE USER ####
#####################

#ENV HOME=/home/pia
#ENV USER=pialab
#ENV GROUP=users
#RUN useradd -d ${HOME} -g ${GROUP} -m $USER -s /bin/bash \
#    && usermod -a -G www-data ${USER}

ENV HOME=/var/www

RUN mkdir -p /usr/share/pialab-back  /usr/share/pialab \
    && chown -R www-data:www-data /usr/share/pialab-back  /usr/share/pialab \
    && chown -R www-data:www-data ${HOME}

USER www-data:www-data

WORKDIR ${HOME}

ENV PATH=/usr/sbin:/usr/bin:/bin:/usr/local/sbin:/usr/local/bin


################################
#### INSTALL NODE & ANGULAR ####
################################
# "/usr/share/nvm"

ENV NVM_DIR="${HOME}/.nvm"
RUN curl -so- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash \
    && [ -s "${NVM_DIR}/nvm.sh" ] \
    && . "${NVM_DIR}/nvm.sh" \
    && nvm install 8.11.1 \
    && npm install -g @angular/cli



###################################################################
#### PRECACHE COMPOSER PACKAGE BEFORE DOCKER CACHE is DISABLED ####
###################################################################

RUN nd=$(mktemp -d) \
    && cd $nd \
    && git clone https://github.com/pia-lab/pialab-back.git \
    && cd pialab-back \
    && composer install --no-interaction --no-scripts --prefer-dist \
    && cd /tmp \
    && rm -rf $nd


#####################################################################################
#### DISABLE DOCKER CACHE AFTER THIS AS WE WANT NEXT STEP TO BE RUN ON ALL BUILD ####
#####################################################################################
ARG CACHEBUST=1

###########################
#### CONFIG POSTGRESQL ####
###########################
ARG DBHOST=localhost
ARG DBROOTUSER=postgres
ARG DBROOTPASSWORD=postgres24

RUN etcdctl put /default/postgres/hostname ${DBHOST} --endpoints=http://${ETCDHOST}:2379 \
    && etcdctl put /default/postgres/root/username ${DBROOTUSER} --endpoints=http://${ETCDHOST}:2379 \
    && etcdctl put /default/postgres/root/password ${DBROOTPASSWORD} --endpoints=http://${ETCDHOST}:2379 \
    && etcdctl get --prefix /default --endpoints=http://${ETCDHOST}:2379

################################
#### INSTALL VARIABLE ####
################################
ARG NAME=dck
ENV RND=${NAME}
ARG BRANCH=master
ARG BACKBRANCH=${BRANCH}
ARG FRONTBRANCH=${BRANCH}
ARG BUILDENV=dev
ARG CREATEUSER=true
ARG BACKURL='http://localhost:8042/back'
ARG FRONTURL='http://localhost:8042/front'

################################
#### INSTALL PIALAB BACKEND ####
################################

RUN git clone https://github.com/pia-lab/pialab-back.git -b ${BACKBRANCH} /usr/share/pialab-back \
    && cd /usr/share/pialab-back \
    && BUILDENV=${BUILDENV} Suffix=${NAME} ./bin/ci-scripts/set_env_with_etcd.sh \
    && ./bin/ci-scripts/set_pgpass.sh \
    && ./bin/ci-scripts/install.sh \
    && ./bin/ci-scripts/create_database.sh \
    && ./bin/ci-scripts/create_schema.sh \
    && if [ "$CREATEUSER" = "true" ]; then ./bin/ci-scripts/create_user.sh; fi \
    && CLIENTURL=${FRONTURL} ./bin/ci-scripts/create_client_secret.sh \
    && ./bin/ci-scripts/post_install.sh

COPY apache/pialab.back.conf /etc/apache2/conf-enabled/pialab.back.conf

##############################
#### INSTALL PIALAB FRONT ####
##############################

RUN . /usr/share/pialab-back/.api.env \
    && etcdctl put /default/api/client/id ${APICLIENTID} --endpoints=http://${ETCDHOST}:2379 \
    && etcdctl put /default/api/client/secret ${APICLIENTSECRET} --endpoints=http://${ETCDHOST}:2379 \
    && etcdctl put /default/api/host/url ${BACKURL} --endpoints=http://${ETCDHOST}:2379 \
    && etcdctl get --prefix /default --endpoints=http://${ETCDHOST}:2379

RUN git clone https://github.com/pia-lab/pialab.git -b ${FRONTBRANCH} /usr/share/pialab \
    && cd /usr/share/pialab \
    && confd -onetime -backend etcdv3 -node http://${ETCDHOST}:2379 -confdir ./etc/confd -log-level debug -prefix /default \
    && . ${NVM_DIR}/nvm.sh \
    && ./bin/ci-scripts/install.sh \
    && BUILDENV=${BUILDENV} ./bin/ci-scripts/build.sh

COPY apache/pialab.front.conf /etc/apache2/conf-enabled/pialab.front.conf


##############################
#### START APACHE AS ROOT ####
##############################
#RUN chown -R www-data:www-data /var/www/html
#RUN chown -R www-data:www-data /usr/share/pialab-back
#RUN chown -R www-data:www-data /usr/share/pialab
USER root
RUN apache2ctl configtest
EXPOSE 80
CMD /usr/sbin/service apache2 restart && tail -f /var/log/apache2/error.log
