# syntax=docker/dockerfile:1.12

ARG DOTNET_SDK_IMAGE=mcr.microsoft.com/dotnet/sdk:10.0@sha256:e1ffd2a92ae84c1291bc1b6887501f8af98e6331e7af6d4c8d37168c5e87a64c
ARG BASE_IMAGE=jlesage/baseimage-gui:ubuntu-26.04-v4@sha256:8e839e319c64c203a048f703c0c75da94715724eb873b5a3a756eaf1b80b62ab

FROM ${DOTNET_SDK_IMAGE} AS builder

ARG SUBTITLE_EDIT_VERSION=5.1.0
ARG SUBTITLE_EDIT_COMMIT=38f1dd4bac6c70bdf1f2d1bb5952aa414c6cb777
ARG GIT_HTTP_VERSION
ARG AVALONIA_VERSION=12.1.0
ARG AVALONIA_COMMIT=a21b9f573172f705a944dcc8aad7f036b9986f39
ARG AVALONIA_X11_PACKAGE_VERSION=12.1.1-local.1
ARG AVALONIA_X11_NUPKG_SHA256=9f6416cd4c3952c0ed3041c8fcc4a46cf16e71d4ad773ff580b0ea551e735bf0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    git \
    unzip \
    zip && \
  rm -rf /var/lib/apt/lists/*

COPY container/patches/avalonia-12.1.0-window-hints.patch /tmp/patches/
COPY container/patches/subtitleedit-5.1.0.patch /tmp/patches/

RUN \
  echo \
    "24b9585d07b6ac13e3c516d18a1e830e702370144baf60d3486773da56ff807e  /tmp/patches/avalonia-12.1.0-window-hints.patch" \
    | sha256sum -c - && \
  echo \
    "7535c7ac8b240f83b603c542daad77566831f91f5e9143fd6a98e9d1904eb377  /tmp/patches/subtitleedit-5.1.0.patch" \
    | sha256sum -c -

RUN \
  echo "**** fetch Avalonia ${AVALONIA_VERSION} source ****" && \
  if [ -n "${GIT_HTTP_VERSION}" ]; then \
    git config --global http.version "${GIT_HTTP_VERSION}"; \
  fi && \
  git clone \
    --depth 1 \
    --branch "${AVALONIA_VERSION}" \
    https://github.com/AvaloniaUI/Avalonia.git \
    /build/avalonia && \
  cd /build/avalonia && \
  test "$(git rev-parse HEAD)" = "${AVALONIA_COMMIT}" && \
  git submodule update --init --recursive && \
  git apply --check \
    /tmp/patches/avalonia-12.1.0-window-hints.patch && \
  git apply \
    /tmp/patches/avalonia-12.1.0-window-hints.patch && \
  dotnet build \
    src/Avalonia.X11/Avalonia.X11.csproj \
    --configuration Release \
    --framework net10.0 \
    --nologo && \
  test -s \
    src/Avalonia.X11/bin/Release/net10.0/Avalonia.X11.dll

RUN \
  echo "**** create patched Avalonia.X11 package ****" && \
  mkdir -p \
    /build/avalonia-package \
    /build/local-feed && \
  curl -fL --retry 3 \
    -o /tmp/Avalonia.X11.${AVALONIA_VERSION}.nupkg \
    "https://api.nuget.org/v3-flatcontainer/avalonia.x11/${AVALONIA_VERSION}/avalonia.x11.${AVALONIA_VERSION}.nupkg" && \
  echo \
    "${AVALONIA_X11_NUPKG_SHA256}  /tmp/Avalonia.X11.${AVALONIA_VERSION}.nupkg" \
    | sha256sum -c - && \
  unzip -q \
    /tmp/Avalonia.X11.${AVALONIA_VERSION}.nupkg \
    -d /build/avalonia-package && \
  install -m 0644 \
    /build/avalonia/src/Avalonia.X11/bin/Release/net10.0/Avalonia.X11.dll \
    /build/avalonia-package/lib/net10.0/Avalonia.X11.dll && \
  sed -i \
    "0,/<version>${AVALONIA_VERSION}<\/version>/s//<version>${AVALONIA_X11_PACKAGE_VERSION}<\/version>/" \
    /build/avalonia-package/Avalonia.X11.nuspec && \
  grep -Fq \
    "<version>${AVALONIA_X11_PACKAGE_VERSION}</version>" \
    /build/avalonia-package/Avalonia.X11.nuspec && \
  rm -f \
    /build/avalonia-package/.signature.p7s && \
  cd /build/avalonia-package && \
  zip -qr \
    "/build/local-feed/Avalonia.X11.${AVALONIA_X11_PACKAGE_VERSION}.nupkg" \
    .

RUN \
  echo "**** fetch Subtitle Edit ${SUBTITLE_EDIT_VERSION} source ****" && \
  git clone \
    --depth 1 \
    --branch "v${SUBTITLE_EDIT_VERSION}" \
    https://github.com/SubtitleEdit/subtitleedit.git \
    /build/subtitleedit && \
  cd /build/subtitleedit && \
  test "$(git rev-parse HEAD)" = "${SUBTITLE_EDIT_COMMIT}" && \
  git apply --check \
    /tmp/patches/subtitleedit-5.1.0.patch && \
  git apply \
    /tmp/patches/subtitleedit-5.1.0.patch && \
  grep -Fq \
    "Avalonia.X11\" Version=\"${AVALONIA_X11_PACKAGE_VERSION}" \
    src/ui/UI.csproj && \
  grep -Fq \
    'SetOptionString("hwdec", "auto");' \
    src/ui/Logic/VideoPlayers/LibMpvDynamic/LibMpvDynamicPlayer.cs

RUN \
  echo "**** publish patched Subtitle Edit ****" && \
  cd /build/subtitleedit && \
  dotnet restore \
    src/ui/UI.csproj \
    --runtime linux-x64 \
    --source /build/local-feed \
    --source https://api.nuget.org/v3/index.json \
    --force-evaluate && \
  dotnet publish \
    src/ui/UI.csproj \
    --configuration Release \
    --runtime linux-x64 \
    --self-contained true \
    --no-restore \
    -p:PublishSingleFile=true \
    -p:DebugSymbols=false \
    -p:DebugType=none \
    -p:Version="${SUBTITLE_EDIT_VERSION}" \
    -p:FileVersion="${SUBTITLE_EDIT_VERSION}.0" \
    -p:InformationalVersion="${SUBTITLE_EDIT_VERSION}" \
    --output /build/publish && \
  test -x /build/publish/SubtitleEdit && \
  grep -aqF \
    "\"Avalonia.X11/${AVALONIA_X11_PACKAGE_VERSION}\"" \
    /build/publish/SubtitleEdit

FROM ${BASE_IMAGE}

ARG BUILD_DATE
ARG VCS_REF=local
ARG IMAGE_REVISION=6
ARG SUBTITLE_EDIT_VERSION=5.1.0

LABEL org.opencontainers.image.title="Subtitle Edit" \
      org.opencontainers.image.description="Native Linux Subtitle Edit with a browser-accessible jlesage GUI" \
      org.opencontainers.image.version="${SUBTITLE_EDIT_VERSION}-r${IMAGE_REVISION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/pegasbur/subtitleedit" \
      io.pegasbur.gui.stack="jlesage-baseimage-gui" \
      io.pegasbur.subtitleedit.version="${SUBTITLE_EDIT_VERSION}"

ENV TESSDATA_PREFIX="/config/tessdata" \
    WEB_AUDIO="1"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN \
  mkdir -p /config/log && \
  echo "**** install runtime packages ****" && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    ffmpeg \
    fonts-dejavu-core \
    fonts-liberation \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-noto-core \
    i965-va-driver \
    intel-media-va-driver \
    libfontconfig1 \
    libgl1 \
    libice6 \
    libicu78 \
    libmpv2 \
    libopenblas0 \
    libsm6 \
    mesa-libgallium \
    mpv \
    tesseract-ocr \
    tesseract-ocr-eng \
    tesseract-ocr-osd \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-utils && \
  echo "**** expose libmpv ****" && \
  mpv_library="$(ldconfig -p | awk '/libmpv\.so\.[0-9]+/{print $NF; exit}')" && \
  test -n "${mpv_library}" && \
  ln -sfn \
    "$(basename "${mpv_library}")" \
    "$(dirname "${mpv_library}")/libmpv.so" && \
  echo "**** enable browser audio by default ****" && \
  grep -Fq \
    'audioEnabled: false,' \
    /opt/noVNC/app/ui.js && \
  grep -Fq \
    "readSetting('audio_enabled', '0')" \
    /opt/noVNC/app/ui.js && \
  sed -i \
    -e 's/audioEnabled: false,/audioEnabled: true,/' \
    -e "s/readSetting('audio_enabled', '0')/readSetting('audio_enabled', '1')/" \
    /opt/noVNC/app/ui.js && \
  echo "**** cleanup ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

COPY --from=builder \
  /build/publish/ \
  /opt/subtitleedit/

COPY --from=builder /build/subtitleedit/LICENSE /opt/subtitleedit/LICENSE
COPY --from=builder /build/avalonia/licence.md /opt/subtitleedit/licenses/Avalonia-LICENCE.md
COPY --from=builder /build/avalonia/NOTICE.md /opt/subtitleedit/licenses/Avalonia-NOTICE.md

COPY --from=builder \
  /build/subtitleedit/src/libse/Icon.png \
  /tmp/subtitleedit-icon.png

RUN \
  chmod 0755 /opt/subtitleedit/SubtitleEdit && \
  ln -s \
    /opt/subtitleedit/SubtitleEdit \
    /usr/local/bin/subtitleedit && \
  install_app_icon.sh \
    /tmp/subtitleedit-icon.png && \
  rm -f \
    /tmp/subtitleedit-icon.png && \
  ffmpeg -version | head -n 1 && \
  ffprobe -version | head -n 1 && \
  mpv --version | head -n 1 && \
  tesseract --version | head -n 1 && \
  ldconfig -p | grep -F 'libmpv.so'

COPY --chmod=755 \
  container/rootfs/startapp.sh \
  /startapp.sh

COPY --chmod=755 \
  container/rootfs/usr/local/bin/prepare-subtitleedit \
  /usr/local/bin/prepare-subtitleedit

COPY --chmod=755 \
  container/rootfs/usr/local/bin/healthcheck \
  /usr/local/bin/healthcheck

COPY --chmod=644 \
  container/rootfs/etc/openbox/main-window-selection.conf \
  /etc/openbox/main-window-selection.xml

RUN \
  set-cont-env APP_NAME "Subtitle Edit" && \
  set-cont-env APP_VERSION "${SUBTITLE_EDIT_VERSION}" && \
  set-cont-env DOCKER_IMAGE_VERSION "${SUBTITLE_EDIT_VERSION}-r${IMAGE_REVISION}"

HEALTHCHECK \
  --interval=30s \
  --timeout=10s \
  --start-period=30s \
  --retries=3 \
  CMD ["/usr/local/bin/healthcheck"]

EXPOSE 5800 5900

VOLUME ["/config"]
