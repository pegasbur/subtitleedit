# syntax=docker/dockerfile:1.12

ARG BASE_IMAGE=ghcr.io/linuxserver/baseimage-selkies:debiantrixie

FROM ${BASE_IMAGE} AS media-builder

ARG FFMPEG_VERSION=9.0.1
ARG FFMPEG_SHA256=cf38e0e28c7e5605942c4a77755349b0145804a397af37eb1fb4c77cb237f635
ARG MPV_VERSION=0.41.0
ARG MPV_SHA256=ee21092a5ee427353392360929dc64645c54479aefdb5babc5cfbb5fad626209
ARG TESSERACT_VERSION=5.5.3
ARG TESSERACT_SHA256=9218e62793116d42a9f6d14cd9348518b27f382096eea3d0f2d1a24616bb5884
ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN \
  echo "**** install build dependencies ****" && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    autoconf \
    autoconf-archive \
    automake \
    build-essential \
    ca-certificates \
    curl \
    ffmpeg \
    libaom-dev \
    libarchive-dev \
    libass-dev \
    libbluray-dev \
    libcairo2-dev \
    libcurl4-openssl-dev \
    libdav1d-dev \
    libdrm-dev \
    libffmpeg-nvenc-dev \
    libfontconfig-dev \
    libfreetype-dev \
    libfribidi-dev \
    libgnutls28-dev \
    libharfbuzz-dev \
    libicu-dev \
    libleptonica-dev \
    libmp3lame-dev \
    libmpv-dev \
    libopenjp2-7-dev \
    libopus-dev \
    libpango1.0-dev \
    libplacebo-dev \
    libpng-dev \
    libsoxr-dev \
    libsrt-gnutls-dev \
    libsvtav1enc-dev \
    libtool \
    libva-dev \
    libvdpau-dev \
    libvorbis-dev \
    libvpl-dev \
    libvpx-dev \
    libvulkan-dev \
    libwebp-dev \
    libx264-dev \
    libx265-dev \
    libxml2-dev \
    libzimg-dev \
    libzvbi-dev \
    meson \
    nasm \
    ninja-build \
    ocl-icd-opencl-dev \
    pkgconf \
    python3-docutils \
    yasm \
    zlib1g-dev && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/build

RUN \
  echo "**** build FFmpeg ${FFMPEG_VERSION} ****" && \
  curl -fL --retry 3 \
    -o ffmpeg.tar.xz \
    "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz" && \
  echo "${FFMPEG_SHA256}  ffmpeg.tar.xz" | sha256sum -c - && \
  mkdir ffmpeg && \
  tar --no-same-owner --strip-components=1 -xJf ffmpeg.tar.xz -C ffmpeg && \
  cd ffmpeg && \
  ./configure \
    --prefix=/opt/media \
    --bindir=/opt/media/bin \
    --libdir=/opt/media/lib \
    --shlibdir=/opt/media/lib \
    --disable-doc \
    --disable-static \
    --enable-shared \
    --enable-gpl \
    --enable-version3 \
    --enable-gnutls \
    --enable-libaom \
    --enable-libass \
    --enable-libbluray \
    --enable-libdav1d \
    --enable-libdrm \
    --enable-libfontconfig \
    --enable-libfreetype \
    --enable-libfribidi \
    --enable-libharfbuzz \
    --enable-libmp3lame \
    --enable-libopenjpeg \
    --enable-libopus \
    --enable-libplacebo \
    --enable-libsoxr \
    --enable-libsrt \
    --enable-libsvtav1 \
    --enable-libvpl \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libwebp \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libxml2 \
    --enable-libzimg \
    --enable-libzvbi \
    --enable-opencl \
    --enable-opengl \
    --extra-ldflags="-Wl,-rpath,/opt/media/lib" && \
  make -j"$(nproc)" && \
  make install && \
  mkdir -p /opt/media/share/licenses/ffmpeg && \
  cp COPYING.GPLv3 LICENSE.md /opt/media/share/licenses/ffmpeg/

RUN \
  echo "**** build MPV ${MPV_VERSION} against FFmpeg ${FFMPEG_VERSION} ****" && \
  curl -fL --retry 3 \
    -o mpv.tar.gz \
    "https://github.com/mpv-player/mpv/archive/refs/tags/v${MPV_VERSION}.tar.gz" && \
  echo "${MPV_SHA256}  mpv.tar.gz" | sha256sum -c - && \
  mkdir mpv && \
  tar --no-same-owner --strip-components=1 -xzf mpv.tar.gz -C mpv && \
  cd mpv && \
  export PKG_CONFIG_PATH="/opt/media/lib/pkgconfig:${PKG_CONFIG_PATH:-}" && \
  export LD_LIBRARY_PATH="/opt/media/lib:${LD_LIBRARY_PATH:-}" && \
  meson setup build \
    --prefix=/opt/media \
    --libdir=lib \
    --buildtype=release \
    -Dcplayer=true \
    -Dlibmpv=true \
    -Dtests=false \
    -Dmanpage-build=disabled \
    -Dc_link_args="-Wl,-rpath,/opt/media/lib" && \
  meson compile -C build -j "$(nproc)" && \
  meson install -C build && \
  mkdir -p /opt/media/share/licenses/mpv && \
  cp LICENSE.GPL LICENSE.LGPL /opt/media/share/licenses/mpv/

RUN \
  echo "**** build Tesseract ${TESSERACT_VERSION} ****" && \
  curl -fL --retry 3 \
    -o tesseract.tar.gz \
    "https://github.com/tesseract-ocr/tesseract/archive/refs/tags/${TESSERACT_VERSION}.tar.gz" && \
  echo "${TESSERACT_SHA256}  tesseract.tar.gz" | sha256sum -c - && \
  mkdir tesseract && \
  tar --no-same-owner --strip-components=1 -xzf tesseract.tar.gz -C tesseract && \
  cd tesseract && \
  ./autogen.sh && \
  ./configure \
    --prefix=/opt/media \
    --disable-static \
    --enable-shared && \
  make -j"$(nproc)" && \
  make install && \
  mkdir -p /opt/media/share/licenses/tesseract && \
  cp LICENSE /opt/media/share/licenses/tesseract/

FROM ${BASE_IMAGE}

ARG BUILD_DATE
ARG VCS_REF=unknown
ARG IMAGE_REVISION=1
ARG SELKIES_VERSION=unknown
ARG SUBTITLE_EDIT_VERSION=5.1.0
ARG SUBTITLE_EDIT_SHA256=455938238969d3aa0a2a500ac061b66161bed1602a96846e01c883322cd5255f
ARG SUBTITLE_EDIT_ICON_SHA256=dac76c5c0efaf1710a97b9f0b07d67e46ff816962b391014988e4310cfd36d44
ARG FFMPEG_VERSION=9.0.1
ARG MPV_VERSION=0.41.0
ARG TESSERACT_VERSION=5.5.3
ARG DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.title="Subtitle Edit for Unraid" \
      org.opencontainers.image.description="Native Linux Subtitle Edit with a Selkies browser desktop" \
      org.opencontainers.image.source="https://github.com/pegasbur/subtitle-edit" \
      org.opencontainers.image.url="https://github.com/pegasbur/subtitle-edit" \
      org.opencontainers.image.documentation="https://github.com/pegasbur/subtitle-edit#readme" \
      org.opencontainers.image.version="${SUBTITLE_EDIT_VERSION}-r${IMAGE_REVISION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      io.pegasbur.selkies.version="${SELKIES_VERSION}" \
      io.pegasbur.subtitle-edit.version="${SUBTITLE_EDIT_VERSION}" \
      io.pegasbur.ffmpeg.version="${FFMPEG_VERSION}" \
      io.pegasbur.mpv.version="${MPV_VERSION}" \
      io.pegasbur.tesseract.version="${TESSERACT_VERSION}"

ENV TITLE="Subtitle Edit" \
    NO_FULL=true \
    NO_GAMEPAD=true \
    SELKIES_DESKTOP=true \
    PIXELFLUX_WAYLAND=true \
    START_DOCKER=false \
    PATH="/opt/media/bin:${PATH}" \
    LD_LIBRARY_PATH="/opt/media/lib" \
    TESSDATA_PREFIX="/config/tessdata"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-noto-core \
    libfontconfig1 \
    libicu76 \
    mpv \
    tesseract-ocr \
    tesseract-ocr-eng \
    tesseract-ocr-osd \
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
    "https://raw.githubusercontent.com/SubtitleEdit/subtitleedit/v${SUBTITLE_EDIT_VERSION}/src/libse/Icon.png" && \
  echo "${SUBTITLE_EDIT_ICON_SHA256}  /usr/share/selkies/www/icon.png" | sha256sum -c - && \
  echo "**** cleanup ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

COPY --from=media-builder /opt/media /opt/media
COPY root/ /

EXPOSE 3000 3001

VOLUME /config
