FROM eboraas/debian:stable
MAINTAINER Falko Gloeckler <falko.gloeckler@mfn-berlin.de>

RUN echo "deb http://packages.dotdeb.org wheezy all" >> /etc/apt/sources.list  && \
	echo "deb-src http://packages.dotdeb.org wheezy all" >> /etc/apt/sources.list

RUN apt-get update && \
	apt-get -y install wget
	
RUN wget https://www.dotdeb.org/dotdeb.gpg && \
	apt-key add dotdeb.gpg  && \
	apt-get update

RUN apt-get -y install git python-pip python-virtualenv build-essential curl vim apache2 libapache2-mod-python libapache2-mod-wsgi python-mysqldb mysql-client libmysqlclient-dev

RUN cd /tmp && \
	curl -sL https://deb.nodesource.com/setup_4.x | bash -

RUN apt-get -y install nodejs

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN cd /usr/local/ && \
	git clone git://github.com/specify/specify7.git
	
# In the directory specify7/specifyweb/settings you will find the specify_settings.py file. Make a copy of this file as local_specify_settings.py and edit it. The file contains comments explaining the various settings.

COPY specify7_config/local_specify_settings.py /usr/local/specify7/specifyweb/settings/

RUN useradd specify && \
	chown -R specify:specify /usr/local/

RUN cd /usr/local/specify7/ && \
	pip install virtualenv --no-cache-dir && \
	virtualenv /usr/local/specify7/ve &&\
	bash -c "source /usr/local/specify7/ve/bin/activate"

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2

# link log files to stdout and stderr
RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log

RUN /usr/sbin/a2ensite default-ssl
RUN /usr/sbin/a2enmod ssl
RUN /usr/sbin/a2dismod python
RUN /usr/sbin/a2enmod wsgi
RUN /usr/sbin/a2enmod cgid

# copy specify6 installation
COPY specify6_thick_client /usr/local/specify6
# RUN ln -s /usr/local/specify6/ /opt/Specify

# as bower command can't be run as root by default, we'll have to set the global options
RUN echo '{ "allow_root": true }' > /root/.bowerrc

RUN chown -R specify:specify /usr/local/specify7 && \
	chown -R specify:www-data /usr/local/specify6 && \
	cd /usr/local/specify7/ && \
	su - root -c "cd /usr/local/specify7/ && make all"

RUN rm /etc/apache2/sites-enabled/000-default.conf
COPY specify7_config/local_specifyweb_apache.conf /etc/apache2/sites-enabled/

COPY specify7_config/apache2-foreground /usr/local/bin/

# add databases libraries
# COPY MySQL-python-1.2.3.tar.gz /usr/local/bin/

RUN  chmod +x /usr/local/bin/apache2-foreground	

# VOLUME [ "/usr/local/specify6" ]

EXPOSE 80
EXPOSE 443

CMD ["/usr/local/bin/apache2-foreground", "-D", "FOREGROUND"]
