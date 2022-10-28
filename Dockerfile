FROM ubuntu:latest
LABEL author=Waan<admin@waan.email>
LABEL version=1.0.0

ARG PASSWD

RUN apt update && \
    apt install -y sudo
    
# Create a sudo user without a password.
RUN adduser --disabled-password --gecos "" waan && \
    usermod -aG sudo waan && \
    echo  "waan:${PASSWD}" | sudo -S chpasswd

# Set timezone. Ref - $ timedatectl list-timezones for more details
RUN apt install -y tzdata && \
    echo "America/New_York" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

USER waan

RUN echo ${PASSWD} | sudo -S sudo apt install -y software-properties-common && \ 
    echo ${PASSWD} | sudo -S sudo LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php && \
    echo ${PASSWD} | sudo -S sudo apt update

RUN echo ${PASSWD} | sudo -S sudo apt install -y \
    php8.1 \
    php8.1-xml \
    php8.1-curl \
    php8.1-intl \
    php8.1-mbstring \
    php8.1-zip \
    apache2 \
    curl

RUN echo ${PASSWD} | sudo -S sudo a2enmod rewrite
RUN echo ${PASSWD} | sudo -S sudo a2enmod php8.1

ADD runtime/apache/apache-config.conf /etc/apache2/sites-available/000-default.conf

RUN echo ${PASSWD} | sudo -S sudo sh -c "echo 'ServerName localhost' >> /etc/apache2/apache2.conf" && \
    echo ${PASSWD} | sudo -S sudo sh -c "echo 'ServerSignature Off' >> /etc/apache2/apache2.conf" && \
    echo ${PASSWD} | sudo -S sudo sh -c "echo 'ServerTokens Prod' >> /etc/apache2/apache2.conf"

# Use of compose volumes is recommeded for development environment.
# ADD source folder to container is recommeded for production.
#
# Ex-
# volumes:
#   - ./services/webapp:/var/www:rw
# in docker-compose.yml
#
# ADD services/webapp /var/www
ADD services/webapp /var/www

# Set www-data permission for web server.
RUN echo ${PASSWD} | sudo -S sudo chown www-data:www-data -R /var/www/

# Set working directory
WORKDIR /var/www

# Delete /var/www/html.
RUN echo ${PASSWD} | sudo -S sudo rm -rf html/

# Composer download and setup, but can not install since all the files are added after 
# the container is created using docker compose volumes.
# Ref - start-scripts.sh for more details.
RUN echo ${PASSWD} | sudo -S sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    echo ${PASSWD} | sudo -S sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    echo ${PASSWD} | sudo -S sudo php -r "unlink('composer-setup.php');"

ADD runtime/start-script.sh /
RUN echo ${PASSWD} | sudo -S sudo chmod +x /start-script.sh

EXPOSE 80

# Entrypoint of the application is set to start.sh.
# You can include additional commands to start.sh using bash scripting.
CMD ["/start-script.sh"]
