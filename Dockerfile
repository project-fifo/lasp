FROM ubuntu:trusty

MAINTAINER Christopher Meiklejohn <christopher.meiklejohn@gmail.com>

RUN apt-get -y install curl && \
    curl -s https://packagecloud.io/install/repositories/cmeiklejohn/lasp/script.deb.sh | sudo bash && \
    apt-get install lasp

CMD sudo lasp console
