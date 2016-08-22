FROM ytnobody/alpine-perl:latest
MAINTAINER ytnobody <ytnobody@gmail.com>

RUN apk update && apk add openssl-dev

RUN mkdir -p /opt/kaotag
WORKDIR /opt/kaotag

RUN git clone https://github.com/colon-limited/p5-Amagi.git modules/amagi
RUN git clone https://github.com/ytnobody/p5-Net-Microsoft-CognitiveServices-Face.git modules/cognitiveservices-face
RUN cpm install --cpanfile=modules/amagi/cpanfile
RUN cpm install --cpanfile=modules/cognitiveservices-face/cpanfile

ADD app.psgi app.psgi

EXPOSE 5000

CMD plackup -Ilocal/lib/perl5 -Imodules/amagi/lib -Imodules/cognitiveservices-face/lib app.psgi
