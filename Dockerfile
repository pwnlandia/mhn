FROM ubuntu:latest
MAINTAINER threatstream

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update && apt-get upgrade -y && apt-get install git wget gcc supervisor expect psmisc lsb-release -y
RUN mkdir -p /opt/mhn /data/db /var/log/mhn /var/log/supervisor

ADD ./ /opt/mhn/
ADD scripts/docker_supervisord-mhn.conf /etc/supervisor/conf.d/mhn.conf
ADD scripts/docker_entrypoint.sh /entrypoint.sh

RUN chmod a+x /entrypoint.sh /opt/mhn/scripts/docker_expect.sh /opt/mhn/install.sh
RUN echo supervisorctl start mongod >> /opt/mhn/scripts/install_mongo.sh

ENV SUPERUSER_EMAIL "root@localhost"
ENV SUPERUSER_PASSWORD "password"
ENV SERVER_BASE_URL "http://localhost:80"
ENV HONEYMAP_URL "http://localhost:3000"
ENV DEBUG_MODE "n"
ENV SMTP_HOST "localhost"
ENV SMTP_PORT "25"
ENV SMTP_TLS "n"
ENV SMTP_SSL "n"
ENV SMTP_USERNAME ""
ENV SMTP_PASSWORD ""
ENV SMTP_SENDER ""
ENV MHN_LOG "/var/log/mhn/mhn.log"

EXPOSE 80
EXPOSE 10000
EXPOSE 3000
EXPOSE 8089

CMD ["/entrypoint.sh"]
