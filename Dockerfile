# syntax=docker/dockerfile:1

FROM python:3.9-slim-buster

COPY requirements.txt requirements.txt

RUN pip3 install -r requirements.txt

COPY . .

ENV FLASK_APP=bucketlist

ENTRYPOINT ["app/docker-entrypoint.sh"]