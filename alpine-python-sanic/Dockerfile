FROM python:3.7.1-alpine3.8

MAINTAINER Mingfeng Wang <me.wmf@foxmail.com>

RUN apk add --no-cache gcc musl-dev make jpeg-dev zlib-dev

ENV LIBRARY_PATH=/lib:/usr/lib

RUN pip3 install --no-cache-dir sanic MyQR Sanic-Cors

WORKDIR /usr/src/app

#COPY ./main.py /usr/src/app
#
#EXPOSE ****
#
#CMD [ "python", "/usr/src/app/main.py" ]