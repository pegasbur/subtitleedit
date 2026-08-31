# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

ARG BUILD_DATE
ARG SUBTITLE_EDIT_VERSION=5.1.0
ARG SUBTITLE_EDIT_SHA256=455938238969d3aa0a2a500ac061b66161bed1602a96846e01c883322cd5255f

LABEL org.opencontainers.image.title="Subtitle Edit for Unraid" \
      org.opencontainers.image.description="Native Linux Subtitle Edit with a Selkies browser desktop" \
      org.opencontainers.image.source="https://github.com/SubtitleEdit/subtitleedit" \
      org.opencontainers.image.version="${SUBTITLE_EDIT_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}"

ENV TITLE="Subtitle Edit" \
    NO_FULL=true \
    NO_GAMEPAD=true \
    SELKIES_DESKTOP=true \
    PIXELFLUX_WAYLAND=true \
    START_DOCKER=false

ARG DEBIAN_FRONTEND=noninteractive

RUN \
  echo "**** install runtime packages ****" && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    ca-certificates \
    caja \
    curl \
    ffmpeg \
    fonts-dejavu-core \
    fonts-liberation \
    fonts-noto-core \
    libfontconfig1 \
    libicu76 \
    libmpv-dev \
    mpv \
    xdg-utils && \
  echo "**** install Subtitle Edit ${SUBTITLE_EDIT_VERSION} ****" && \
  mkdir -p /opt/subtitleedit && \
  curl -fL --retry 3 \
    -o /tmp/subtitleedit.tar.gz \
    "https://github.com/SubtitleEdit/subtitleedit/releases/download/v${SUBTITLE_EDIT_VERSION}/SubtitleEdit-Linux-x64.tar.gz" && \
  echo "${SUBTITLE_EDIT_SHA256}  /tmp/subtitleedit.tar.gz" | sha256sum -c - && \
  tar --no-same-owner -xzf /tmp/subtitleedit.tar.gz -C /opt/subtitleedit && \
  chmod +x /opt/subtitleedit/SubtitleEdit && \
  ln -s /opt/subtitleedit/SubtitleEdit /usr/local/bin/subtitleedit && \
  echo "**** install browser icon ****" && \
  curl -fL --retry 3 \
    -o /usr/share/selkies/www/icon.png \
    https://raw.githubusercontent.com/SubtitleEdit/subtitleedit/main/src/libse/Icon.png && \
  echo "**** cleanup ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

COPY root/ /

EXPOSE 3000 3001

VOLUME /config
