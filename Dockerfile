# syntax=docker/dockerfile:1.12

ARG BASE_IMAGE=ghcr.io/linuxserver/baseimage-selkies:ubunturesolute
FROM ${BASE_IMAGE}

ARG BUILD_DATE
ARG VCS_REF=unknown
ARG IMAGE_REVISION=1
ARG SELKIES_VERSION=unknown
ARG SUBTITLE_EDIT_VERSION=5.1.0
ARG SUBTITLE_EDIT_SHA256=455938238969d3aa0a2a500ac061b66161bed1602a96846e01c883322cd5255f
ARG SUBTITLE_EDIT_ICON_SHA256=dac76c5c0efaf1710a97b9f0b07d67e46ff816962b391014988e4310cfd36d44
ARG DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.title="Subtitle Edit for Unraid" \
      org.opencontainers.image.description="Native Linux Subtitle Edit with a Selkies browser desktop" \
      org.opencontainers.image.source="https://github.com/pegasbur/subtitleedit" \
      org.opencontainers.image.url="https://github.com/pegasbur/subtitleedit" \
      org.opencontainers.image.documentation="https://github.com/pegasbur/subtitleedit#readme" \
      org.opencontainers.image.version="${SUBTITLE_EDIT_VERSION}-r${IMAGE_REVISION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      io.pegasbur.selkies.version="${SELKIES_VERSION}" \
      io.pegasbur.subtitleedit.version="${SUBTITLE_EDIT_VERSION}" \
      io.pegasbur.multimedia.source="Ubuntu Resolute repositories"

ENV TITLE="Subtitle Edit" \
    NO_FULL=true \
    NO_GAMEPAD=true \
    SELKIES_DESKTOP=true \
    PIXELFLUX_WAYLAND=true \
    START_DOCKER=false \
    TESSDATA_PREFIX="/config/tessdata"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN \
  echo "**** install Ubuntu Resolute runtime packages ****" && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    ca-certificates \
    caja \
    curl \
    ffmpeg \
    fonts-dejavu-core \
    fonts-liberation \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-noto-core \
    libfontconfig1 \
    libicu78 \
    libmpv2 \
    mpv \
    tesseract-ocr \
    tesseract-ocr-eng \
    tesseract-ocr-osd \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-utils && \
  echo "**** expose libmpv for Subtitle Edit ****" && \
  mpv_library="$(ldconfig -p | awk '/libmpv\.so\.[0-9]+/{print $NF; exit}')" && \
  test -n "${mpv_library}" && \
  ln -sfn "$(basename "${mpv_library}")" "$(dirname "${mpv_library}")/libmpv.so" && \
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
    "https://raw.githubusercontent.com/SubtitleEdit/subtitleedit/v${SUBTITLE_EDIT_VERSION}/src/libse/Icon.png" && \
  echo "${SUBTITLE_EDIT_ICON_SHA256}  /usr/share/selkies/www/icon.png" | sha256sum -c - && \
  echo "**** verify runtime stack ****" && \
  ffmpeg -version | head -n 1 && \
  ffprobe -version | head -n 1 && \
  mpv --version | head -n 1 && \
  tesseract --version | head -n 1 && \
  ldconfig -p | grep -F 'libmpv.so' && \
  echo "**** cleanup ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

COPY root/ /

EXPOSE 3000 3001

VOLUME /config
