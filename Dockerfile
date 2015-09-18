############################################################ 
# Dockerfile based on Ubuntu Image for metaboanalyst
############################################################ 
# Set the base image to use to Ubuntu 
FROM ubuntu:14.04

# Set the file maintainer (your name - the file's author) 
MAINTAINER "Philipp Ross" philippross369@gmail.com

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19 
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \ 
	&& /usr/sbin/update-locale LANG=en_US.UTF-8 

ENV LC_ALL en_US.UTF-8 
ENV LANG en_US.UTF-8

RUN apt-get update && apt-get install -y \
		ed \
		wget \
		cmake \
		git \
		vim \
		ghostscript \
		graphviz \
		openjdk-7-jre \
		libnetcdf-dev \
		lmodern \
		texlive-fonts-recommended \
		texlive-humanities \
		texlive-latex-extra \
		texinfo \
		tomcat7 \
		supervisor

### R 
ENV R_BASE_VERSION 3.0.2

## Now install R and littler, and create a link for littler in /usr/local/bin 
## Also set a default CRAN repo, and make sure littler knows about it too 
RUN apt-get update && apt-get install -y \ 
		littler \
		r-base=${R_BASE_VERSION}* \
		r-base-dev=${R_BASE_VERSION}* \
		r-recommended=${R_BASE_VERSION}* \
		&& echo 'options(repos = list(CRAN = "http://cran.us.r-project.org"))' >> /etc/R/Rprofile.site \
		&& echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
		&& ln -s /usr/share/doc/littler/examples/install.r /usr/local/bin/install.r \
		&& ln -s /usr/share/doc/littler/examples/install2.r /usr/local/bin/install2.r \
		&& ln -s /usr/share/doc/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
		&& ln -s /usr/share/doc/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
		&& install.r docopt \
		&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
		&& rm -rf /var/lib/apt/lists/*

# Fixing stuff...
RUN apt-get update && apt-get install -y \
		r-cran-plyr \
		r-cran-reshape2 \
		r-cran-car \
		libxt-dev \
		libcairo2-dev \
		r-cran-xml \
		ant

# Install R packages
RUN install.r \
	Rserve \
	ellipse \
	scatterplot3d \
	pls \
	caret \
	lattice \
	Cairo \
	randomForest \
	e1071 \
	gplots \
	som \
	xtable \
	RColorBrewer \
	pheatmap \
	RJSONIO

# Install Bioconductor packages
RUN Rscript -e 'source("http://bioconductor.org/biocLite.R"); biocLite(c("xcms", "impute", "pcaMethods", "siggenes", "globaltest", "GlobalAncova", "Rgraphviz", "KEGGgraph", "preprocessCore", "genefilter"))'

# multicore package has been removed from CRAN
RUN wget https://cran.r-project.org/src/contrib/Archive/multicore/multicore_0.2.tar.gz -O /multicore_0.2.tar.gz
RUN Rscript -e 'install.packages("/multicore_0.2.tar.gz", repos = NULL, type="source")'
RUN rm -rf /multicore_0.2.tar.gz

# download WAR file
RUN wget https://dl.dropboxusercontent.com/u/95163184/MetaboAnalyst.war -O /var/lib/tomcat7/webapps/MetaboAnalyst.war

ADD start_tomcat.sh /usr/local/bin/start_tomcat.sh
RUN chmod +x /usr/local/bin/start_tomcat.sh
ADD start_rserve.sh /usr/local/bin/start_rserve.sh
RUN chmod +x /usr/local/bin/start_rserve.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8080

CMD ["/usr/bin/supervisord"]
