# Ubuntu Environment

Test environment in Ubuntu.

Contains:
- PHP 5.6 and 7.1
- MYSQL 5.6
- Apache
- Node JS 9
- Java 8

## Installation 
```sh
$ git clone https://github.com/ioan-ghisoi-cko/ubuntu-environment.git
$ cd ubuntu-environment
$ docker build -t imageName .
```
## Run Container
```sh
// this will run the on 127.0.0.1
$ docker run --name containerName -i -d -p 127.0.0.1:80:80 imageName
// enter the containers bash
$ docker exec -i -t containerName /bin/bash
```
## Use PHP 7.1
```sh
$ alias use-php-7="update-alternatives --set php /usr/bin/php7.1  && a2dismod php5.6 && a2enmod php7.1 && service apache2 restart"
$ use-php-7
```

## Use PHP 5.6
```sh
$ alias use-php-5="update-alternatives --set php /usr/bin/php5.6  && a2dismod php7.1 && a2enmod php5.6 && service apache2 restart"
$ use-php-5
```