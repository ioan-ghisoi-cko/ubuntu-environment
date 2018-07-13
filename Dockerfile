FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

# Set Apache environment variables (can be changed on docker run with -e)
#
ENV APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_PID_FILE=/var/run/apache2.pid \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2a \
    PATH="/root/.composer/vendor/bin:${PATH}"

RUN apt-get update && \
    apt-get -y install software-properties-common \
    xvfb \
    locales && \
    locale-gen en_US.UTF-8 && \
    export LC_ALL=en_US.UTF-8 && \
    export LANG=en_US.UTF-8 && \
    add-apt-repository ppa:ondrej/php && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install \
    apache2 \
    php7.1 \
    php7.1-dev \
    php7.1-curl \
    php7.1-cli \
    php7.1-gd \
    php7.1-bcmath \
    php7.1-json \
    php7.1-ldap \
    php7.1-intl \
    php7.1-mbstring \
    php7.1-mcrypt \
    php7.1-mysql \
    php7.1-xml \
    php7.1-xsl \
    php7.1-zip \
    php7.1-soap \
    php5.6 \
    php5.6-dev \
    php5.6-curl \
    php5.6-cli \
    php5.6-gd \
    php5.6-bcmath \
    php5.6-json \
    php5.6-ldap \
    php5.6-intl \
    php5.6-mbstring \
    php5.6-mcrypt \
    php5.6-mysql \
    php5.6-xml \
    php5.6-xsl \
    php5.6-zip \
    php5.6-soap \
    libapache2-mod-php5.6 \
    php-pear \
    curl \
    git \
    wget \
    nano \
    wkhtmltopdf \
    pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up alisa comands for PHP
#
RUN alias use-php-7="update-alternatives --set php /usr/bin/php7.1  && a2dismod php5.6 && a2enmod php7.1 && service apache2 restart"
RUN alias use-php-5="update-alternatives --set php /usr/bin/php5.6  && a2dismod php7.1 && a2enmod php5.6 && service apache2 restart"

# Customise bash
#
RUN echo "force_color_prompt=yes \n" >> ~/.bashrc

# install nodejs
#
RUN curl -sL https://deb.nodesource.com/setup_9.x | bash - && \
    apt-get install -y nodejs

# allow root permistions for npm
#
RUN npm config set user 0 \
    && npm config set unsafe-perm true

# install general dependecies
#
RUN pecl install xdebug && \
    pecl install apcu && \ 
    apt-get update && \
    apt-get install -f && \
    apt-get install -y unzip && \
    apt-get install fonts-liberation && \
    apt-get install libgconf2-4 libnss3-1d libxss1 -y

# install composer
#
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer 
RUN composer init --no-interaction && composer config -a http-basic.repo.magento.com e3fe1cabf752165bd79fbbbcb0e626fd 11543462ae0104c9792bd3d79b57663a

# install java 8 and chrome
#
RUN if grep -q Debian /etc/os-release && grep -q jessie /etc/os-release; then \
    echo "deb http://http.us.debian.org/debian/ jessie-backports main" |   tee -a /etc/apt/sources.list \
    && echo "deb-src http://http.us.debian.org/debian/ jessie-backports main" |   tee -a /etc/apt/sources.list \
    &&   apt-get update;   apt-get install -y -t jessie-backports openjdk-8-jre openjdk-8-jre-headless openjdk-8-jdk openjdk-8-jdk-headless \
  ; elif grep -q Ubuntu /etc/os-release && grep -q Trusty /etc/os-release; then \
    echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" |   tee -a /etc/apt/sources.list \
    && echo "deb-src http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" |   tee -a /etc/apt/sources.list \
    &&   apt-key adv --keyserver keyserver.ubuntu.com --recv-key DA1A4A13543B466853BAF164EB9B1D8886F44E2A \
    &&   apt-get update;   apt-get install -y openjdk-8-jre openjdk-8-jre-headless openjdk-8-jdk openjdk-8-jdk-headless \
  ; else \
      apt-get update;   apt-get install -y openjdk-8-jre openjdk-8-jre-headless openjdk-8-jdk openjdk-8-jdk-headless \
  ; fi

RUN apt-get install xdg-utils -y && apt-get install libappindicator1 -y

RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
      && (  dpkg -i /tmp/google-chrome-stable_current_amd64.deb ||   apt-get -fy install)  \
      && rm -rf /tmp/google-chrome-stable_current_amd64.deb \
      &&   sed -i 's|HERE/chrome"|HERE/chrome" --disable-setuid-sandbox --no-sandbox|g' \
           "/opt/google/chrome/google-chrome" \
      && google-chrome --version

RUN export CHROMEDRIVER_RELEASE=$(curl --location --fail --retry 3 http://chromedriver.storage.googleapis.com/LATEST_RELEASE) \
      && curl --silent --show-error --location --fail --retry 3 --output /tmp/chromedriver_linux64.zip "http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_RELEASE/chromedriver_linux64.zip" \
      && cd /tmp \
      && unzip chromedriver_linux64.zip \
      && rm -rf chromedriver_linux64.zip \
      &&   mv chromedriver /usr/local/bin/chromedriver \
      &&   chmod +x /usr/local/bin/chromedriver \
      && chromedriver --version


COPY ./config/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./config/php.ini /etc/php/7.1/cli/php.ini 

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Install MYSQL and create DB
#
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

RUN usermod -d /var/lib/mysql/ mysql

# start xvfb automatically to avoid needing to express in circle.yml
#
ENV DISPLAY :99
RUN printf '#!/bin/sh\nXvfb :99 -screen 0 1280x1024x24 &\nexec "$@"\n' > /tmp/entrypoint \
  && chmod +x /tmp/entrypoint \
        &&   mv /tmp/entrypoint /docker-entrypoint.sh
WORKDIR /var/www/html
EXPOSE 80 9001

# restart apache and mysql upan the container start
#
ENTRYPOINT chown -R mysql:mysql /var/lib/mysql && service mysql restart && service apache2 restart && /bin/bash
