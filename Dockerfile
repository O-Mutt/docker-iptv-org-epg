# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.18

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CRON="*/10 * * * *"
ARG SITE="**"
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="o-mutt"

# environment variables.
ENV \
  HOME="/app/epg" \
  NODE_ENV="production"

COPY ./ /app/epg
COPY root/ /

RUN mkdir -p /app/epg && \
  echo "**** install build dependencies ****" && \
  apk add --no-cache --virtual=build-dependencies \
  g++ \
  make \
  git && \
  echo "**** pulling epg repo to build****" && \
  git clone --depth 1 -b master https://github.com/iptv-org/epg.git /tmp/epg && \
  mv /tmp/epg/* /app/epg && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
  nodejs \
  curl \
  npm

WORKDIR /app/epg

RUN npm install && \
  ln -s /config /app/epg && \
  touch /config/DOCKER && \
  echo "**** cleanup ****" && \
  apk del --purge \
  build-dependencies && \
  rm -rf \
  /tmp/* \
  $HOME/.cache \
  /app/epg/.next/cache/*
RUN crontab -l | { cat; echo "$CRON cd /app/epg && && npm run grab -- --site \"$SITE\" --maxConnections=10 > /dev/stdout 2>&1"; } | crontab -

# ports and volumes
EXPOSE 3000

VOLUME /config