FROM debian:jessie
MAINTAINER Frank Stolle "frank@stolle.email"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates apache2-mpm-worker apache2-suexec php5-cgi php5-curl php5-idn php5-imap php5-intl php5-xdebug php5-mysql php5-gd libapache2-mod-fcgid locales && \
	rm -r /var/lib/apt/lists/*

#Zeitzonen-Config
RUN echo "Europe/Berlin" > /etc/timezone && \
	dpkg-reconfigure -f noninteractive tzdata
RUN export LANGUAGE=de_DE.UTF-8 && \
	export LANG=de_DE.UTF-8 && \
	export LC_ALL=de_DE.UTF-8 && \
	locale-gen de_DE.UTF-8 && \
	DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

ENV APACHE_RUN_UID 1000

#Nutzer config
RUN useradd -d /var/www -u $APACHE_RUN_UID phpuser && \
	adduser www-data phpuser && \
	mkdir -p /var/www/site/htdocs

ADD ./php.sh /var/www/site
RUN chmod 0550 /var/www/site/php.sh && \
	chown -R phpuser:phpuser /var/www/site

RUN a2enmod rewrite
RUN a2enmod fcgid
RUN a2enmod suexec

ADD ./001-site.conf /etc/apache2/sites-available/
RUN ln -s /etc/apache2/sites-available/001-site.conf /etc/apache2/sites-enabled/

ADD ./xdebug.ini /etc/php5/cgi/conf.d/90-xdebug.ini

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_SERVERADMIN admin@localhost
ENV APACHE_SERVERNAME localhost
ENV APACHE_SERVERALIAS docker.localhost
ENV APACHE_DOCUMENTROOT /var/www/site/htdocs

EXPOSE 80
ADD apache.sh /apache.sh
RUN chmod 0755 /apache.sh
CMD ["bash", "apache.sh"]
