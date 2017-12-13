FROM eboraas/debian:stable
MAINTAINER Falko Gloeckler <falko.gloeckler@mfn-berlin.de>



##############################################
### DOWNLOAD AND INSTALL THE MAIN PACKAGES ###

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

RUN cd /usr/local/ && \
	git clone git://github.com/specify/specify7.git

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

	

#######################################	
### INSTALL AND CONFIGURE SPECIFY 7 ###
	
# copy the config directory for initial build, but it will be overwritten by the (optionally) mounted volume
COPY specify7_config /usr/local/specify_config

RUN ls -l /usr/local/specify_config

# link specify7 config file from the mounted config volume
RUN ln -sf /usr/local/specify_config/local_specify_settings.py /usr/local/specify7/specifyweb/settings/

# create specify user that runs the web application
RUN useradd specify && \
	mkdir /home/specify && \
	chown specify.specify /home/specify && \
	chown -R specify:specify /usr/local/

# install virtual environment	
RUN cd /usr/local/specify7/ && \
	pip install virtualenv --no-cache-dir && \
	virtualenv /usr/local/specify7/ve &&\
	bash -c "source /usr/local/specify7/ve/bin/activate"

# copy specify6 installation
COPY specify6_thick_client /usr/local/specify6

# as bower command can't be run as root by default, we'll have to set the global options
RUN echo '{ "allow_root": true }' > /root/.bowerrc

# set permissions and add the group www-data and specify to the docker group (necessary to avoid permission conflicts for the mounted Docker volumes)
RUN chown -R specify:specify /usr/local/specify7 && \
	chown -R specify:www-data /usr/local/specify6 && \
	groupadd -g 999 docker && \
	usermod -aG docker www-data && \
	usermod -aG docker specify	
	
# build the web application
RUN	cd /usr/local/specify7/ && \
	su - root -c "cd /usr/local/specify7/ && make all"

# remove Specify 6 in order to keep the container smaller (it will be mounted via a docker volume)
RUN rm -rf /usr/local/specify6/*

	
############################	
### APACHE CONFIGURATION ###

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2

# link log files to stdout and stderr
RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log
	
# link apache config file and service script from the mounted config volume
RUN rm /etc/apache2/sites-enabled/000-default.conf  && \
	ln -sf /usr/local/specify_config/local_specifyweb_apache.conf /etc/apache2/sites-enabled/ && \ 
	ln -sf /usr/local/specify_config/apache2-foreground /usr/local/bin/
	
RUN /usr/sbin/a2ensite default-ssl
RUN /usr/sbin/a2enmod ssl
RUN /usr/sbin/a2dismod python
RUN /usr/sbin/a2enmod wsgi
RUN /usr/sbin/a2enmod cgid	

RUN  chmod +x /usr/local/bin/apache2-foreground	



#################################
### EXPOSED DOCKER PARAMETERS ###

VOLUME [ "/usr/local/specify6" ]
VOLUME [ "/usr/local/specify_config" ]

EXPOSE 80
EXPOSE 443

CMD ["/usr/local/bin/apache2-foreground", "-D", "FOREGROUND"]