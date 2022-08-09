FROM rocker/shiny:4.2.1

RUN apt-get update \
	&& apt-get install -y \
		python-is-python3 \
		python3-pip \
		openjdk-11-jdk \
	&& pip install numpy scipy fastcluster requests

RUN mkdir /home/shiny/projects \
	&& mkdir /home/shiny/interpro \
	&& mkdir /home/shiny/sanz \
	&& mkdir /home/shiny/app

RUN R -e "install.packages(c('seqinr', 'shinyFiles', 'DT', 'shinybusy'))"
COPY app.R /home/shiny/app/app.R

CMD ["R", "-e", "shiny::runApp(file.path('/home/shiny/app', 'app.R'), host = '0.0.0.0', port = 3838)"]
